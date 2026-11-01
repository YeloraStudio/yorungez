using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.WebUtilities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using System.Net;
using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text.Json;
using Yorungez.Identity.Application;
using Yorungez.Identity.Infrastructure;
using Yorungez.Identity.Infrastructure.Persistence;
using Yorungez.Notebook.Application;
using Yorungez.Notebook.Infrastructure;

namespace Yorungez.Api.Tests.Recovery;

[Trait("Category", "Recovery")]
public sealed class RecoveryDrillTests
{
    private const string Password = "Synthetic recovery passphrase for tests 2026";
    private const string OutboxPurpose = "yorungez.identity.email-outbox.v1";
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);

    [Fact]
    public async Task Dump_and_copied_keys_restore_private_records_identity_and_encrypted_outbox_in_a_new_application()
    {
        await using var drill = new LocalRecoveryEnvironment(); await drill.PrepareAsync();
        var sourceKeys = Path.Combine(drill.DirectoryPath, "source-keyring"); Directory.CreateDirectory(sourceKeys);
        var backupKeys = Path.Combine(drill.BundlePath, "keyring"); Directory.CreateDirectory(backupKeys);
        using var rsa = RSA.Create(2048);
        var request = new CertificateRequest("CN=yorungez-synthetic-recovery", rsa, HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);
        using var sourceCertificate = request.CreateSelfSigned(DateTimeOffset.UtcNow.AddDays(-1), DateTimeOffset.UtcNow.AddDays(1));
        var wrappingPassword = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32));
        await File.WriteAllBytesAsync(Path.Combine(drill.BundlePath, "wrapping-certificate.pfx"), sourceCertificate.Export(X509ContentType.Pfx, wrappingPassword));
        var signingKey = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
        var ownerAddress = "owner-" + Guid.NewGuid().ToString("N") + "@example.invalid";
        var otherAddress = "other-" + Guid.NewGuid().ToString("N") + "@example.invalid";
        var pendingAddress = "pending-" + Guid.NewGuid().ToString("N") + "@example.invalid";
        var point = new NotebookLocation(41.00823456789, 28.97845678901, null, "Sentetik gözlem alanı / synthetic observing spot");
        var note = new EntryInput(Guid.NewGuid().ToString(), "note", 0, "Sentetik not · first revision", null,
            DateTimeOffset.Parse("2020-10-30T20:00:00Z"), point);
        var favorite = new EntryInput("favorite:jupiter", "favorite", 0, null, new("jupiter", "Jüpiter / Jupiter"), null, null);
        var observation = new EntryInput(Guid.NewGuid().ToString(), "observation", 0, "Sentetik kişisel gözlem beyanı", new("jupiter", "Jupiter"), null,
            point, ObservedAtUtc: DateTimeOffset.Parse("2020-10-30T20:00:00Z"), ObservationConfirmed: true);
        var place = new EntryInput(Guid.NewGuid().ToString(), "place", 0, null, null, null, point);
        var trash = new EntryInput(Guid.NewGuid().ToString(), "note", 0, "Sentetik çöp kutusu kaydı", null, null, null);
        EntryView[] ownerEntries, otherEntries;
        (string Hash, SortedDictionary<string, int> Rows) snapshot;
        string ownerCookie, otherCookie;
        Guid ownerId;
        string[] protectedPayloads, plaintextPayloads;
        await using (var source = new RecoveryAppFactory(drill.Connection(drill.Source), sourceKeys, sourceCertificate, signingKey))
        {
            await using (var scope = source.Services.CreateAsyncScope())
            {
                await scope.ServiceProvider.GetRequiredService<IdentityStore>().Database.MigrateAsync();
                await scope.ServiceProvider.GetRequiredService<NotebookDatabase>().Database.MigrateAsync();
            }
            using var owner = source.Client(); using var other = source.Client();
            await ConfirmAccount(source, owner, ownerAddress); await ConfirmAccount(source, other, otherAddress);
            (ownerCookie, ownerId) = await Login(owner, ownerAddress); (otherCookie, _) = await Login(other, otherAddress);
            await Save(owner, note); await Save(owner, note with { ExpectedRevision = 1, Body = "Sentetik not · ikinci sürüm / second revision" });
            foreach (var entry in new[] { favorite, observation, place, trash }) await Save(owner, entry);
            await Save(owner, place with { ExpectedRevision = 1, Location = new(0, 0, 250, "Changed saved place") });
            await Save(owner, trash with { ExpectedRevision = 1, Deleted = true });
            // The same record IDs belong to two different owners; restore must preserve the composite ownership key.
            await Save(other, note with { Body = "Another owner's synthetic note" }); await Save(other, favorite);
            ownerEntries = await Entries(owner); otherEntries = await Entries(other);
            using var pending = source.Client(); await Register(pending, pendingAddress);
            Assert.Equal(HttpStatusCode.Forbidden, (await pending.PostAsJsonAsync("/api/v1/auth/login", new { email = pendingAddress, password = Password })).StatusCode);
            Assert.Equal(HttpStatusCode.Accepted, (await owner.PostAsJsonAsync("/api/v1/auth/forgot-password", new { email = ownerAddress })).StatusCode);
            await using (var scope = source.Services.CreateAsyncScope())
            {
                protectedPayloads = await scope.ServiceProvider.GetRequiredService<IdentityStore>().PendingEmails.AsNoTracking()
                    .OrderBy(e => e.Id).Select(e => e.ProtectedPayload).ToArrayAsync();
                var protector = scope.ServiceProvider.GetRequiredService<IDataProtectionProvider>().CreateProtector(OutboxPurpose);
                plaintextPayloads = protectedPayloads.Select(protector.Unprotect).ToArray();
            }
            snapshot = await drill.FingerprintAsync(drill.Source); await drill.DumpAsync();
            await Save(owner, note with { Id = Guid.NewGuid().ToString(), Body = "Written after the backup; must not reappear" });
            Assert.True((await drill.FingerprintAsync(drill.Source)).Hash != snapshot.Hash);
        }
        foreach (var key in Directory.GetFiles(sourceKeys, "key-*.xml")) File.Copy(key, Path.Combine(backupKeys, Path.GetFileName(key)));
        await drill.SealBundleAsync();
        // A damaged archive is rejected before any restore statements reach the empty destination.
        var archive = await File.ReadAllBytesAsync(drill.DumpPath);
        await File.WriteAllBytesAsync(drill.DumpPath, archive[..^8]);
        await Assert.ThrowsAsync<InvalidDataException>(drill.RestoreAsync);
        Assert.Empty((await drill.FingerprintAsync(drill.Restored)).Rows);
        await File.WriteAllBytesAsync(drill.DumpPath, archive); await drill.RestoreAsync();
        var recovered = await drill.FingerprintAsync(drill.Restored);
        Assert.True(snapshot.Hash == recovered.Hash, "The complete database snapshot must match before the restored app writes anything.");
        Assert.True(snapshot.Rows.SequenceEqual(recovered.Rows));
        Assert.Equal(3, recovered.Rows["identity.AspNetUsers"]); Assert.Equal(7, recovered.Rows["notebook.Entries"]);
        Assert.True(recovered.Rows.ContainsKey("identity.__EFMigrationsHistory") && recovered.Rows.ContainsKey("notebook.__EFMigrationsHistory"));

        var restoredKeys = Path.Combine(drill.DirectoryPath, "restored-keyring"); Directory.CreateDirectory(restoredKeys);
        foreach (var key in Directory.GetFiles(backupKeys, "key-*.xml")) File.Copy(key, Path.Combine(restoredKeys, Path.GetFileName(key)));
        var restoredCertificatePath = Path.Combine(drill.DirectoryPath, "restored-wrapping-certificate.pfx");
        File.Copy(Path.Combine(drill.BundlePath, "wrapping-certificate.pfx"), restoredCertificatePath);
        using var restoredCertificate = X509CertificateLoader.LoadPkcs12FromFile(restoredCertificatePath, wrappingPassword, X509KeyStorageFlags.EphemeralKeySet);
        Assert.True(restoredCertificate.HasPrivateKey);
        var noKeys = DataProtectionProvider.Create(new DirectoryInfo(Path.Combine(drill.DirectoryPath, "missing-keyring")), options =>
        { options.SetApplicationName("yorungez").DisableAutomaticKeyGeneration(); options.Services.AddLogging(log => log.ClearProviders()); });
        var noCertificate = DataProtectionProvider.Create(new DirectoryInfo(restoredKeys), options =>
        { options.SetApplicationName("yorungez").DisableAutomaticKeyGeneration(); options.Services.AddLogging(log => log.ClearProviders()); });
        Assert.Throws<CryptographicException>(() => noKeys.CreateProtector(OutboxPurpose).Unprotect(protectedPayloads[0]));
        Assert.Throws<CryptographicException>(() => noCertificate.CreateProtector(OutboxPurpose).Unprotect(protectedPayloads[0]));

        await using (var restored = new RecoveryAppFactory(drill.Connection(drill.Restored), restoredKeys, restoredCertificate, signingKey))
        {
            using var owner = restored.Client(); using var other = restored.Client(); using var anonymous = restored.Client();
            SetCookie(owner, ownerCookie); SetCookie(other, otherCookie);
            Assert.True(Enumerable.SequenceEqual(ownerEntries, await Entries(owner))); Assert.True(Enumerable.SequenceEqual(otherEntries, await Entries(other)));
            var report = (await Entries(owner)).Single(e => e.Id == observation.Id);
            Assert.True(report.Location == point && report.ObservedAtUtc == observation.ObservedAtUtc && report.ObservationConfirmed);
            Assert.Equal(HttpStatusCode.Unauthorized, (await anonymous.GetAsync("/api/v1/notebook/")).StatusCode);
            other.DefaultRequestHeaders.Add("X-Yorungez-Account", ownerId.ToString());
            Assert.Equal(HttpStatusCode.Conflict, (await other.GetAsync("/api/v1/notebook/")).StatusCode);
            other.DefaultRequestHeaders.Remove("X-Yorungez-Account");
            Assert.Equal(HttpStatusCode.Conflict, (await other.PostAsJsonAsync("/api/v1/notebook/", note with { ExpectedRevision = 2 })).StatusCode);
            await using (var scope = restored.Services.CreateAsyncScope())
            {
                Assert.Empty(await scope.ServiceProvider.GetRequiredService<IdentityStore>().Database.GetPendingMigrationsAsync());
                Assert.Empty(await scope.ServiceProvider.GetRequiredService<NotebookDatabase>().Database.GetPendingMigrationsAsync());
                var protector = scope.ServiceProvider.GetRequiredService<IDataProtectionProvider>().CreateProtector(OutboxPurpose);
                Assert.True(protectedPayloads.Select(protector.Unprotect).SequenceEqual(plaintextPayloads));
                Assert.Equal(2, await scope.ServiceProvider.GetRequiredService<EmailOutboxDispatcher>().DispatchOnceAsync(default));
            }
            Assert.Equal(2, restored.Email.Messages.Count);
            var confirmation = restored.Email.Messages.Single(m => m.Recipient == pendingAddress);
            using var pending = restored.Client(); await Confirm(pending, confirmation); await Login(pending, pendingAddress);

            // A consistent backup also contains old sessions. Exercise explicit revocation in the isolated restored DB.
            await using (var scope = restored.Services.CreateAsyncScope())
            {
                var store = scope.ServiceProvider.GetRequiredService<IdentityStore>();
                foreach (var session in await store.RefreshSessions.ToListAsync()) session.Revoke(DateTimeOffset.UtcNow);
                await store.SaveChangesAsync();
                var users = scope.ServiceProvider.GetRequiredService<UserManager<Account>>();
                foreach (var user in await store.Users.ToListAsync()) Assert.True((await users.UpdateSecurityStampAsync(user)).Succeeded);
            }
            Assert.Equal(HttpStatusCode.Unauthorized, (await owner.GetAsync("/api/v1/notebook/")).StatusCode);
            Assert.Equal(HttpStatusCode.Unauthorized, (await other.GetAsync("/api/v1/notebook/")).StatusCode);
            await Login(owner, ownerAddress); Assert.True(Enumerable.SequenceEqual(ownerEntries, await Entries(owner)));
            Assert.Equal(HttpStatusCode.Conflict, (await owner.PostAsJsonAsync("/api/v1/notebook/", note with { ExpectedRevision = 1 })).StatusCode);
            Assert.Equal(3, (await Save(owner, note with { ExpectedRevision = 2, Body = "Edited after recovery" })).Revision);
            Assert.Null((await Save(owner, trash with { ExpectedRevision = 2 })).DeletedAtUtc);
        }
        await drill.CleanupDatabasesAsync();
        await drill.WriteReportAsync(new
        {
            status = "passed", scope = "local-synthetic-only", utc = DateTimeOffset.UtcNow,
            snapshotSha256 = snapshot.Hash, tables = snapshot.Rows, archiveBytes = archive.Length,
            checks = new[] { "complete-snapshot", "migration-history", "owner-isolation", "all-four-record-kinds", "revision-conflict",
                "trash-restore", "historical-coordinate-copy", "post-backup-write-excluded", "corrupt-archive-rejected",
                "copied-encrypted-keyring-and-certificate", "missing-keyring-rejected", "missing-wrapping-key-rejected",
                "encrypted-outbox", "pending-confirmation", "old-cookie-continuity", "explicit-session-revocation", "fresh-login-and-edit" },
            emailTransport = "in-memory capture only", productionAcceptance = false,
            certificatePasswordPersisted = false, createdDatabasesRemoved = true
        });
    }

    private static async Task Register(HttpClient client, string address) => Assert.Equal(HttpStatusCode.Accepted,
        (await client.PostAsJsonAsync("/api/v1/auth/register", new { firstName = "Çağrı", lastName = "Test", email = address, password = Password })).StatusCode);
    private static async Task ConfirmAccount(RecoveryAppFactory app, HttpClient client, string address)
    {
        await Register(client, address);
        await using var scope = app.Services.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<EmailOutboxDispatcher>().DispatchOnceAsync(default);
        await Confirm(client, app.Email.Messages.Single(m => m.Recipient == address));
    }
    private static async Task Confirm(HttpClient client, EmailMessage message)
    {
        var link = new Uri(message.Body.Split('\n', StringSplitOptions.RemoveEmptyEntries).Last());
        var fragment = QueryHelpers.ParseQuery(link.Fragment.TrimStart('#'));
        Assert.Equal(HttpStatusCode.OK, (await client.PostAsJsonAsync("/api/v1/auth/confirm-email",
            new { userId = fragment["userId"].ToString(), token = fragment["token"].ToString() })).StatusCode);
    }
    private static async Task<(string Cookie, Guid User)> Login(HttpClient client, string address)
    {
        client.DefaultRequestHeaders.Remove("Cookie");
        client.DefaultRequestHeaders.Remove("Origin"); client.DefaultRequestHeaders.Add("Origin", "http://localhost:3000");
        client.DefaultRequestHeaders.Remove("X-Yorungez-Request"); client.DefaultRequestHeaders.Add("X-Yorungez-Request", "1");
        var response = await client.PostAsJsonAsync("/api/v1/session/login", new { email = address, password = Password });
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var cookie = response.Headers.GetValues("Set-Cookie").Single().Split(';')[0]; SetCookie(client, cookie);
        return (cookie, (await response.Content.ReadFromJsonAsync<UserProfile>())!.Id);
    }
    private static void SetCookie(HttpClient client, string cookie)
    {
        client.DefaultRequestHeaders.Remove("Cookie"); client.DefaultRequestHeaders.Add("Cookie", cookie);
        client.DefaultRequestHeaders.Remove("Origin"); client.DefaultRequestHeaders.Add("Origin", "http://localhost:3000");
        client.DefaultRequestHeaders.Remove("X-Yorungez-Request"); client.DefaultRequestHeaders.Add("X-Yorungez-Request", "1");
    }
    private static async Task<EntryView> Save(HttpClient client, EntryInput input)
    {
        var response = await client.PostAsJsonAsync("/api/v1/notebook/", input); Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        return (await response.Content.ReadFromJsonAsync<EntryView>())!;
    }
    private static async Task<EntryView[]> Entries(HttpClient client)
    {
        var response = await client.GetAsync("/api/v1/notebook/"); Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var data = await response.Content.ReadFromJsonAsync<JsonElement>();
        return data.GetProperty("entries").Deserialize<EntryView[]>(Json)!.OrderBy(e => e.Id, StringComparer.Ordinal).ToArray();
    }
}
