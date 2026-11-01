using System.Diagnostics;
using System.Globalization;
using System.Runtime.InteropServices;
using System.Text.Json;
using Yorungez.Astronomy.Application;
using Yorungez.Astronomy.Domain;
using Yorungez.Astronomy.Infrastructure;

var root = Directory.GetCurrentDirectory();
var inputPath = Path.Combine(root, "tests/ReferenceData/Horizons/references.json");
using var input = JsonDocument.Parse(File.ReadAllText(inputPath));
var data = input.RootElement;
var calculator = new AstronomyEngineCalculator();
var samples = new List<Sample>();
var events = new List<Crossing>();
foreach (var collection in new[] { "positions", "events" })
foreach (var c in data.GetProperty(collection).EnumerateArray())
{
    var body = SkyValidation.Body(c.GetProperty("body").GetString());
    SkyContext Context(string instant) => SkyValidation.Context(c.GetProperty("latitude").GetDouble(),
        c.GetProperty("longitude").GetDouble(), instant, c.GetProperty("elevationMeters").GetDouble());
    var rows = c.GetProperty("rows").EnumerateArray().ToArray();
    foreach (var row in rows)
    {
        var instant = row.GetProperty("instantUtc").GetString()!;
        var position = calculator.Position(Context(instant), body);
        var az = row.GetProperty("azimuthDegrees").GetDouble();
        var alt = row.GetProperty("altitudeDegrees").GetDouble();
        var radians = Math.PI / 180;
        var dot = Math.Sin(alt * radians) * Math.Sin(position.AirlessAltitudeDegrees * radians)
            + Math.Cos(alt * radians) * Math.Cos(position.AirlessAltitudeDegrees * radians)
            * Math.Cos((az - position.AzimuthDegrees) * radians);
        var separation = Math.Acos(Math.Clamp(dot, -1, 1)) / radians * 60;
        samples.Add(new(c.GetProperty("id").GetString()!, instant, position.AzimuthDegrees,
            position.AirlessAltitudeDegrees, az, alt, separation,
            Math.Abs(alt - position.AirlessAltitudeDegrees) * 60,
            CalculationScope.CanPublishAzimuth(c.GetProperty("latitude").GetDouble()), separation <= 1));
    }
    if (collection == "events")
    {
        var actual = calculator.Crossings(Context(c.GetProperty("instantUtc").GetString()!), body);
        DateTimeOffset? Reference(bool rising)
        {
            for (var i = 1; i < rows.Length; i++)
            {
                var a = rows[i - 1].GetProperty("altitudeDegrees").GetDouble();
                var b = rows[i].GetProperty("altitudeDegrees").GetDouble();
                if (rising ? a <= 0 && b > 0 : a >= 0 && b < 0)
                {
                    var first = rows[i - 1].GetProperty("instantUtc").GetDateTimeOffset();
                    return first.AddSeconds((rows[i].GetProperty("instantUtc").GetDateTimeOffset() - first).TotalSeconds * -a / (b - a));
                }
            }
            return null;
        }
        var referenceRise = Reference(true);
        var referenceSet = Reference(false);
        double? Error(DateTimeOffset? a, DateTimeOffset? b) => a is null || b is null ? null : Math.Abs((a.Value - b.Value).TotalSeconds);
        events.Add(new(c.GetProperty("id").GetString()!, actual.RisingUtc, actual.SettingUtc,
            referenceRise, referenceSet, Error(actual.RisingUtc, referenceRise), Error(actual.SettingUtc, referenceSet),
            (actual.RisingUtc is null) == (referenceRise is null) && (actual.SettingUtc is null) == (referenceSet is null)));
    }
}

var benchmarkContext = SkyValidation.Context(41.0082, 28.9784, "2026-10-30T20:00:00Z", 0);
var bodies = Enum.GetValues<SolarSystemBody>();
void Batch() { foreach (var body in bodies) _ = calculator.Position(benchmarkContext, body); }
for (var i = 0; i < 200; i++) Batch();
var elapsed = new double[1000];
var allocated = GC.GetAllocatedBytesForCurrentThread();
for (var i = 0; i < elapsed.Length; i++)
{
    var start = Stopwatch.GetTimestamp();
    Batch();
    elapsed[i] = Stopwatch.GetElapsedTime(start).TotalMilliseconds;
}
allocated = GC.GetAllocatedBytesForCurrentThread() - allocated;
Array.Sort(elapsed);
var report = new
{
    schemaVersion = 1, generatedAtUtc = DateTimeOffset.UtcNow, engine = "Astronomy Engine", version = "2.1.19",
    environment = new { runtime = RuntimeInformation.FrameworkDescription, os = RuntimeInformation.OSDescription,
        architecture = RuntimeInformation.ProcessArchitecture.ToString(), logicalProcessors = Environment.ProcessorCount,
        scope = "local desktop process; not mobile, browser rendering, API throughput or production load" },
    tolerances = new { positionArcminutes = 1, crossingSeconds = 60, polarAzimuthPublication = "withheld at abs(latitude)>=89" },
    summary = new { directionComparisons = samples.Count, originalDirectionalTargetFailures = samples.Count(s => !s.DirectionalTargetMet),
        publishedDirectionComparisons = samples.Count(s => s.AzimuthPublished),
        maxPublishedDirectionErrorArcminutes = samples.Where(s => s.AzimuthPublished).Max(s => s.DirectionErrorArcminutes),
        maxRawDirectionErrorArcminutes = samples.Max(s => s.DirectionErrorArcminutes),
        maxAltitudeErrorArcminutes = samples.Max(s => s.AltitudeErrorArcminutes),
        maxCrossingErrorSeconds = events.SelectMany(e => new[] { e.RisingErrorSeconds, e.SettingErrorSeconds }).Where(e => e.HasValue).Max(),
        eventWindowStatusesMatch = events.All(e => e.WindowStatusesMatch) },
    benchmark = new { warmupBatches = 200, measuredBatches = elapsed.Length, bodiesPerBatch = 9,
        p50Milliseconds = elapsed[499], p95Milliseconds = elapsed[949], p99Milliseconds = elapsed[989],
        maxMilliseconds = elapsed[^1], allocatedBytesPerBatch = (double)allocated / elapsed.Length },
    samples, events
};
var outputPath = args.Length > 0 ? Path.GetFullPath(args[0]) : Path.Combine(root, ".local/science/csharp-report.json");
Directory.CreateDirectory(Path.GetDirectoryName(outputPath)!);
File.WriteAllText(outputPath, JsonSerializer.Serialize(report, new JsonSerializerOptions(JsonSerializerDefaults.Web) { WriteIndented = true }) + "\n");
Console.WriteLine($"C# report: {samples.Count} directions; {samples.Count(s => !s.DirectionalTargetMet)} original target failures (retained); {events.Count} crossing windows; p95 {elapsed[949].ToString("F4", CultureInfo.InvariantCulture)} ms / 9 bodies.");

record Sample(string Id, string InstantUtc, double AzimuthDegrees, double AltitudeDegrees,
    double ReferenceAzimuthDegrees, double ReferenceAltitudeDegrees, double DirectionErrorArcminutes,
    double AltitudeErrorArcminutes, bool AzimuthPublished, bool DirectionalTargetMet);
record Crossing(string Id, DateTimeOffset? RisingUtc, DateTimeOffset? SettingUtc,
    DateTimeOffset? ReferenceRisingUtc, DateTimeOffset? ReferenceSettingUtc,
    double? RisingErrorSeconds, double? SettingErrorSeconds, bool WindowStatusesMatch);
