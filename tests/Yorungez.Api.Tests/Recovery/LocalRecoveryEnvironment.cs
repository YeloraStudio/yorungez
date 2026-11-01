using Npgsql;
using System.Diagnostics;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;

namespace Yorungez.Api.Tests.Recovery;

internal sealed class LocalRecoveryEnvironment : IAsyncDisposable
{
    private readonly HashSet<string> _created = [];
    private readonly NpgsqlConnectionStringBuilder _connection;
    private readonly string _run = Guid.NewGuid().ToString("N");
    public string Root { get; }
    public string DirectoryPath { get; }
    public string Source => $"yorungez_recovery_{_run}_source";
    public string Restored => $"yorungez_recovery_{_run}_restored";
    public string BundlePath => Path.Combine(DirectoryPath, "bundle");
    public string DumpPath => Path.Combine(BundlePath, "database.dump");

    public LocalRecoveryEnvironment()
    {
        var root = new DirectoryInfo(AppContext.BaseDirectory);
        while (root is not null && !File.Exists(Path.Combine(root.FullName, "Yorungez.slnx"))) root = root.Parent;
        Root = root?.FullName ?? throw new InvalidOperationException("Solution root not found.");
        using var settings = JsonDocument.Parse(File.ReadAllText(Path.Combine(Root, "src/Yorungez.Api/appsettings.Local.json")));
        _connection = new(Environment.GetEnvironmentVariable("YORUNGEZ_TEST_POSTGRES")
            ?? settings.RootElement.GetProperty("ConnectionStrings").GetProperty("Identity").GetString()!);
        if (_connection.Host is not ("127.0.0.1" or "localhost") || _connection.Username != "yorungez")
            throw new InvalidOperationException("Recovery drill requires this project's loopback PostgreSQL role.");
        _connection.Host = "127.0.0.1"; _connection.Database = "postgres"; _connection.IncludeErrorDetail = false;
        DirectoryPath = Path.GetFullPath(Path.Combine(Root, ".local/recovery-drills", _run));
        var intended = Path.GetFullPath(Path.Combine(Root, ".local/recovery-drills")) + Path.DirectorySeparatorChar;
        if (!DirectoryPath.StartsWith(intended, StringComparison.Ordinal)) throw new InvalidOperationException("Invalid drill directory.");
    }

    public async Task PrepareAsync()
    {
        var id = (await DockerAsync(["compose", "ps", "--quiet", "postgres"])).Trim();
        if (!Regex.IsMatch(id, "^[a-f0-9]{12,64}$")) throw new InvalidOperationException("Start this project's PostgreSQL service before the drill.");
        var labels = await DockerAsync(["inspect", "--format", "{{index .Config.Labels \"com.docker.compose.project\"}}|{{index .Config.Labels \"com.docker.compose.service\"}}", id]);
        var published = await DockerAsync(["compose", "port", "postgres", "5432"]);
        if (labels.Trim() != "yorungez|postgres" || published.Trim() != $"127.0.0.1:{_connection.Port}")
            throw new InvalidOperationException("The configured database does not match this project's loopback container.");
        Directory.CreateDirectory(BundlePath);
        foreach (var database in new[] { Source, Restored })
        {
            RequireOwnedName(database);
            await using var admin = new NpgsqlConnection(_connection.ConnectionString); await admin.OpenAsync();
            // Never reuse an existing database: CREATE must succeed before ownership is recorded.
            await using var command = new NpgsqlCommand($"CREATE DATABASE \"{database}\" TEMPLATE template0", admin);
            await command.ExecuteNonQueryAsync(); _created.Add(database);
        }
    }

    public string Connection(string database)
    {
        RequireCreated(database);
        return new NpgsqlConnectionStringBuilder(_connection.ConnectionString) { Database = database }.ConnectionString;
    }

    public async Task DumpAsync()
    {
        RequireCreated(Source);
        await DockerAsync(["compose", "exec", "-T", "postgres", "pg_dump", "--username=yorungez", "--no-password",
            "--format=custom", "--no-owner", "--no-acl", "--dbname=" + Source], output: DumpPath);
        if (new FileInfo(DumpPath).Length < 100) throw new InvalidOperationException("Empty recovery archive.");
    }

    public async Task RestoreAsync()
    {
        RequireCreated(Restored);
        await VerifyBundleAsync();
        await using var connection = new NpgsqlConnection(Connection(Restored)); await connection.OpenAsync();
        await using var check = new NpgsqlCommand("SELECT count(*) FROM information_schema.tables WHERE table_schema NOT IN ('pg_catalog','information_schema')", connection);
        if (Convert.ToInt64(await check.ExecuteScalarAsync()) != 0) throw new InvalidOperationException("Recovery destination is not empty.");
        await DockerAsync(["compose", "exec", "-T", "postgres", "pg_restore", "--username=yorungez", "--no-password",
            "--no-owner", "--no-acl", "--single-transaction", "--exit-on-error", "--dbname=" + Restored], input: DumpPath);
    }

    private sealed record BackupFile(string Path, long Bytes, string Sha256);
    public async Task SealBundleAsync()
    {
        var files = new List<BackupFile>();
        foreach (var file in Directory.GetFiles(BundlePath, "*", SearchOption.AllDirectories).Order(StringComparer.Ordinal))
        {
            var relative = Path.GetRelativePath(BundlePath, file).Replace('\\', '/');
            if (relative == "manifest.json") continue;
            RequireBundleFile(relative);
            var bytes = await File.ReadAllBytesAsync(file);
            files.Add(new(relative, bytes.Length, Convert.ToHexString(SHA256.HashData(bytes))));
        }
        if (!files.Any(f => f.Path.StartsWith("keyring/", StringComparison.Ordinal))
            || !files.Any(f => f.Path == "database.dump") || !files.Any(f => f.Path == "wrapping-certificate.pfx"))
            throw new InvalidDataException("Incomplete drill bundle.");
        await File.WriteAllTextAsync(Path.Combine(BundlePath, "manifest.json"), JsonSerializer.Serialize(files));
    }
    public async Task VerifyBundleAsync()
    {
        var files = JsonSerializer.Deserialize<BackupFile[]>(await File.ReadAllTextAsync(Path.Combine(BundlePath, "manifest.json")))
            ?? throw new InvalidDataException("Invalid drill manifest.");
        if (!files.Any(f => f.Path == "database.dump") || !files.Any(f => f.Path == "wrapping-certificate.pfx")
            || !files.Any(f => f.Path.StartsWith("keyring/", StringComparison.Ordinal))
            || files.Select(f => f.Path).Distinct(StringComparer.Ordinal).Count() != files.Length)
            throw new InvalidDataException("Incomplete drill manifest.");
        foreach (var file in files)
        {
            RequireBundleFile(file.Path);
            var bytes = await File.ReadAllBytesAsync(Path.Combine(BundlePath, file.Path));
            if (bytes.LongLength != file.Bytes || Convert.ToHexString(SHA256.HashData(bytes)) != file.Sha256)
                throw new InvalidDataException("Recovery bundle integrity check failed.");
        }
    }
    private static void RequireBundleFile(string file)
    {
        if (file is not ("database.dump" or "wrapping-certificate.pfx") && !Regex.IsMatch(file, "^keyring/key-[a-f0-9-]{36}\\.xml$"))
            throw new InvalidDataException("Invalid bundle file name.");
    }

    public async Task<(string Hash, SortedDictionary<string, int> Rows)> FingerprintAsync(string database)
    {
        await using var connection = new NpgsqlConnection(Connection(database)); await connection.OpenAsync();
        var tables = new List<(string Schema, string Table)>();
        await using (var list = new NpgsqlCommand("SELECT table_schema,table_name FROM information_schema.tables WHERE table_schema IN ('identity','notebook') AND table_type='BASE TABLE' ORDER BY table_schema,table_name", connection))
        await using (var reader = await list.ExecuteReaderAsync()) while (await reader.ReadAsync()) tables.Add((reader.GetString(0), reader.GetString(1)));
        using var hash = IncrementalHash.CreateHash(HashAlgorithmName.SHA256);
        var rows = new SortedDictionary<string, int>(StringComparer.Ordinal);
        void Append(string value)
        {
            var bytes = Encoding.UTF8.GetBytes(value); hash.AppendData(BitConverter.GetBytes(bytes.Length)); hash.AppendData(bytes);
        }
        foreach (var (schema, table) in tables)
        {
            var key = schema + "." + table; Append(key); var count = 0;
            static string Quote(string value) => '"' + value.Replace("\"", "\"\"") + '"';
            await using var command = new NpgsqlCommand($"SELECT to_jsonb(t)::text FROM {Quote(schema)}.{Quote(table)} t ORDER BY to_jsonb(t)::text COLLATE \"C\"", connection);
            await using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync()) { Append(reader.GetString(0)); count++; }
            rows.Add(key, count);
        }
        return (Convert.ToHexString(hash.GetHashAndReset()).ToLowerInvariant(), rows);
    }

    public async Task WriteReportAsync(object report) => await File.WriteAllTextAsync(Path.Combine(DirectoryPath, "result.json"),
        JsonSerializer.Serialize(report, new JsonSerializerOptions { WriteIndented = true }) + "\n");

    private void RequireOwnedName(string database)
    {
        if (database != Source && database != Restored) throw new InvalidOperationException("Not a database owned by this drill.");
        if (!Regex.IsMatch(database, "^yorungez_recovery_[a-f0-9]{32}_(source|restored)$")) throw new InvalidOperationException("Invalid drill database name.");
    }
    private void RequireCreated(string database)
    {
        RequireOwnedName(database);
        if (!_created.Contains(database)) throw new InvalidOperationException("Database was not created by this drill.");
    }

    // Binary streams avoid PowerShell/native-pipe text conversion. Neither credentials nor raw diagnostics are printed.
    private async Task<string> DockerAsync(string[] arguments, string? input = null, string? output = null)
    {
        var start = new ProcessStartInfo("docker") { WorkingDirectory = Root, UseShellExecute = false,
            RedirectStandardOutput = true, RedirectStandardError = true, RedirectStandardInput = input is not null, CreateNoWindow = true };
        foreach (var argument in arguments) start.ArgumentList.Add(argument);
        using var process = Process.Start(start) ?? throw new InvalidOperationException("Docker could not start.");
        using var timeout = new CancellationTokenSource(TimeSpan.FromMinutes(2));
        var errors = process.StandardError.ReadToEndAsync(timeout.Token);
        string result = "";
        try
        {
            var read = output is null ? ReadText() : WriteFile();
            if (input is not null)
            {
                await using var file = File.OpenRead(input); await file.CopyToAsync(process.StandardInput.BaseStream, timeout.Token);
                process.StandardInput.Close();
            }
            await Task.WhenAll(read, process.WaitForExitAsync(timeout.Token));
            _ = await errors;
            if (process.ExitCode != 0) throw new InvalidOperationException("Recovery Docker operation failed; sensitive diagnostics omitted.");
            return result;
        }
        catch
        {
            if (!process.HasExited) { process.Kill(entireProcessTree: true); await process.WaitForExitAsync(CancellationToken.None); }
            _ = await errors; throw;
        }
        async Task ReadText() => result = await process.StandardOutput.ReadToEndAsync(timeout.Token);
        async Task WriteFile()
        {
            await using var file = new FileStream(output!, FileMode.CreateNew, FileAccess.Write, FileShare.None);
            await process.StandardOutput.BaseStream.CopyToAsync(file, timeout.Token);
        }
    }

    public async Task CleanupDatabasesAsync()
    {
        foreach (var database in _created.ToArray())
        {
            RequireCreated(database);
            using (var pool = new NpgsqlConnection(Connection(database))) NpgsqlConnection.ClearPool(pool);
            await using var admin = new NpgsqlConnection(_connection.ConnectionString); await admin.OpenAsync();
            await using var drop = new NpgsqlCommand($"DROP DATABASE \"{database}\" WITH (FORCE)", admin);
            await drop.ExecuteNonQueryAsync(); _created.Remove(database);
        }
    }
    public async ValueTask DisposeAsync() => await CleanupDatabasesAsync();
}
