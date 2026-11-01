# Yerel GeoNames yer adı kataloğu

**237831 nokta**, `cities.json.gz` **6.528.136 bayt**. Dünya `cities500` listesine 974 Türkiye ADM2 ilçe referans noktası eklendi; admin1 il/bölge adları bağlandı. [GeoNames günlük dosyaları](https://download.geonames.org/export/dump/), [kaynak açıklaması](https://download.geonames.org/export/dump/readme.txt). `manifest.json` özgün indirme SHA'larını, sıkıştırılmış/açık JSON SHA'sını ve derleme anını kaydeder. Ham ZIP/text bakım önbelleği `.local/geonames/`; paylaşım paketi türetilmiş gzip + manifesttir.

**GeoNames, CC BY 4.0.** [Atıf ve değişiklikler](../../third-party/geonames/NOTICE.md). Veri denetimsiz canlı ters geocoding değildir. Ad/ASCII yazımı/ülke/bölge ile yerel arama en fazla sekiz sonuç döndürür. En yakın nokta küresel büyük daire mesafesiyle, en fazla 100 km içinde aranır. “Yakınında” açıklaması idari ilçe sınırı, sokak adresi veya GPS doğruluğu değildir; okyanusta sonuç bulunmayabilir. Başka ülkelerin ilçe kapsamı Türkiye ek listesiyle eşit değildir.

Seçilen şehir/ilçe koordinatı bir merkezdir. Kullanıcı kesin enlem/boylamını ve adını düzenler; konum adı astronomik hesabı değiştirmez. GeoNames yükseklik alanı otomatik atanmaz. Cihaz belirsizliği/ölçüm zamanı korunur. Koordinatlar yalnız Yorungez BFF/.NET POST/no-store içinde işlenir, harici geocoder'a otomatik gönderilmez ve URL/storage/log'a yazılmaz. Sadece açık OSM haritası açma eylemi üçüncü taraf döşemesi ister.

Gzip katalog tembel şekilde sunucuda açılır/aranır; tarayıcı tüm dünya listesini almaz. Bu seçimin RAM ve soğuk yük CPU maliyeti vardır; eşzamanlı üretim bütçesi henüz ölçülmedi. PostGIS kurulmadı.

```powershell
python scripts/science/refresh_planning_sources.py --refresh --source places
```

Açık bakım işlemi `.local/geonames` indirme önbelleğini tekrar kullanır; yeni kaynak sürümü için bu önbellek bilinçli bakımda yenilenir. Normal build/test indirmez. Üretim `prebuild` SHA'yı doğrulayıp yok sayılan `generated/` kopyasını oluşturur. C# aynı kök kaynakları gömer. [ADR](../../docs/adr/0007-gozlem-takvimi-ve-yer-adlari.md).
