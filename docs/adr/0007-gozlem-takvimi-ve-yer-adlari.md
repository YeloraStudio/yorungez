# ADR-0007 — Gözlem çizelgesi, olay takvimi ve yer adları

**Durum:** TECH-04C için seçildi/uygulandı; geniş bilimsel ve fiziksel kabul açık. **Tarih:** 31 Ekim 2026. **İz:** K-021; FR-01–05/FR-08/FR-11–12, UJ-01–03/UJ-06, AC-02–06/AC-09–11/AC-13–14.

## Karar ve gerekçe

Kullanıcı Bugün/Bu gece, kaynaklı takvim, yön yardımcısı, ufuk altı saydam arazi, daha geniş zoom ve adlandırılabilir hassas konum istedi. Keşfet'in arama odaklayan gereksiz düğmesi kaldırılır; FR-03 atlas hedefi ortak arama/kartla sürer. Mevcut tam ekran/palet/dil/katman ve bütün ürün planı korunur.

Yerel Worker, Astronomy Engine 2.1.19 standart doğuş/batışını hesaplar. Haritanın hava kırılmasız merkez/0° hesabı değiştirilmez. 34′ kırılma ve Güneş/Ay üst kenarı açıklanır. Harita elipsoidal yüksekliği deniz seviyesi yüksekliği sayılamayacağından çizelge 0 m deniz seviyesi referansıdır; geoit/göz yüksekliği/yerel engel modeli ayrıca doğrulanacaktır. Yerel gün sınırları Temporal/IANA ile UTC'ye çevrilir; takvim/timeline tıklaması UTC anı + kanonik hedefle simülasyona geçer. Gündüz ufuk üstü olmak gözlenebilirlik garantisi değildir.

Takvim genel ve donmuş katalogdur: USNO Ay evreleri + ayrı etiketli motor hesapları. USNO UT dakika değeri UTC dakika hassasiyetinde yorumlanır; hesap farkı ayrıca saklanır. .NET Catalog modülü CQRS/MediatR sınırını korur; BFF ve C# aynı kök veri/SHA'yı kullanır. Redis veya PostGIS bu genel dosyalar için yeni zorunluluk değildir. Açık yenileme ağ erişir; normal test/derleme donmuş veriyi okur.

Dış ters geocoding yerine yerel GeoNames cities500/Türkiye ADM2 seçildi. Lisans CC BY 4.0, atıf/hash saklanır. En yakın nokta en fazla 100 km; yakınında etiketi kullanılır, idari poligon/adres doğrulaması değildir. Manuel ad/koordinat/yükseklik düzenlenebilir. Hassas koordinatlar POST/no-store ile aynı köken içinde kalır; OSM döşemeleri önceki açık kullanıcı eylemi kuralını korur. Google API anahtarı, ücretli geocoder veya public Nominatim bağımlılığı eklenmedi. Yerel katalog sunucu RAM/soğuk yük maliyeti taşır; üretim yük ölçümü açık.

Stereografik projeksiyon 330°'ye açılır; antipod tekilliği dışarıda bırakılır. Fotoğraf katmanı hedef engelleniyorsa/aşağı bakışta saydamlaşır, astronomik yönler değiştirilmez. Görsel keşif ile gerçek ufuk durumu ayrıdır. GPU yoksa aynı ters ışını kullanan sade CPU arazi maskesi vardır; fiziksel cihaz performans kabulü değildir.

## Sonuç ve seçeneklerin sınırı

Bu karar ilk kapsamı çalışır hale getirir; tam atlas, gerçek arazi, hava/algılanabilirlik, otomatik veri yenileme, bütün olay türleri veya cihaz sensör doğruluğunu tamamlamaz. Meteor/asteroit/Ay–yıldız yakınlaşması gibi ek kaynaklar P1'de lisans/referansla genişletilecek. SMTP kapalı placeholder, kişisel kayıt/PWA ve fiziksel GPS/pusula işleri sırada kalır. İki kutup yön başarısızlığı ve abs(enlem)>=89 azimut koruması korunur.

[Uygulama, ölçümler ve kaynaklar](../gozlem-cizelgesi-ve-takvim.md), [olay veri sözleşmesi](../../data/events/README.md), [yer adı sözleşmesi](../../data/places/README.md).
