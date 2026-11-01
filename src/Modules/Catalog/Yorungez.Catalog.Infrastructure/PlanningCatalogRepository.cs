using System.Globalization;
using System.IO.Compression;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Yorungez.Catalog.Application;
using Yorungez.Catalog.Domain;
namespace Yorungez.Catalog.Infrastructure;

public sealed class PlanningCatalogRepository:IPlanningCatalog {
    private static readonly JsonSerializerOptions Json=new(JsonSerializerDefaults.Web);
    private static byte[] Read(string name){using var stream=typeof(PlanningCatalogRepository).Assembly.GetManifestResourceStream("Yorungez.Catalog.Infrastructure.Data."+name)??throw new InvalidOperationException("Planning catalogue missing.");using var m=new MemoryStream();stream.CopyTo(m);return m.ToArray();}
    private static readonly Lazy<(CalendarData Data,CalendarProvenance Provenance)> Events=new(()=>{
        var bytes=Read("calendar.json");var p=JsonSerializer.Deserialize<CalendarProvenance>(Read("calendar-manifest.json"),Json)!;
        if(Convert.ToHexStringLower(SHA256.HashData(bytes))!=p.Sha256)throw new InvalidOperationException("Calendar fingerprint mismatch.");
        var d=JsonSerializer.Deserialize<CalendarData>(bytes,Json)!;
        if(d.Events.Length!=p.EventCount||d.Events.Select(e=>e.Id).Distinct().Count()!=d.Events.Length)throw new InvalidOperationException("Calendar identities invalid.");return(d,p);
    });
    private static string Normalize(string text)=>new string(text.Replace('ı','i').Normalize(NormalizationForm.FormD).Where(c=>CharUnicodeInfo.GetUnicodeCategory(c)!=UnicodeCategory.NonSpacingMark).ToArray()).ToLowerInvariant();
    private static readonly Lazy<(PlacePoint Place,string Key)[]> Places=new(()=>{
        var bytes=Read("cities.json.gz");using var m=JsonDocument.Parse(Read("places-manifest.json"));
        if(Convert.ToHexStringLower(SHA256.HashData(bytes))!=m.RootElement.GetProperty("sha256").GetString())throw new InvalidOperationException("Places fingerprint mismatch.");
        using var zip=new GZipStream(new MemoryStream(bytes),CompressionMode.Decompress);var rows=JsonSerializer.Deserialize<PlacePoint[]>(zip,Json)!;
        return rows.Select(p=>(p,Normalize($"{p.Name} {p.Ascii} {p.Region} {p.Country}"))).ToArray();
    });
    public CalendarMonth ReadMonth(int year,int month){var (d,p)=Events.Value;var a=new DateTimeOffset(year,month,1,0,0,0,TimeSpan.Zero).AddDays(-2);var b=new DateTimeOffset(year,month,1,0,0,0,TimeSpan.Zero).AddMonths(1).AddDays(2);return new(year,month,d.Events.Where(e=>e.InstantUtc>=a&&e.InstantUtc<b).ToArray(),p);}
    public LocatedPlace[] FindPlaces(string? query,double? latitude,double? longitude){
        if(query is not null){var words=Normalize(query.Trim()).Split(' ',StringSplitOptions.RemoveEmptyEntries);return Places.Value.Where(p=>words.All(p.Key.Contains)).OrderByDescending(p=>Normalize(p.Place.Name)==string.Join(' ',words)).ThenByDescending(p=>p.Place.Population).Take(8).Select(p=>new LocatedPlace(p.Place,null)).ToArray();}
        const double rad=Math.PI/180;PlacePoint? found=null;var best=100.0;
        foreach(var (p,_) in Places.Value){if(Math.Abs(p.Latitude-latitude!.Value)>.91)continue;var x=(p.Latitude-latitude.Value)*rad;var y=(p.Longitude-longitude!.Value)*rad;var h=Math.Pow(Math.Sin(x/2),2)+Math.Cos(latitude.Value*rad)*Math.Cos(p.Latitude*rad)*Math.Pow(Math.Sin(y/2),2);var distance=12742*Math.Asin(Math.Sqrt(Math.Min(1,h)));if(distance<best){best=distance;found=p;}}
        return found is null?[]:[new(found,best)];
    }
}
