# yorungez — Bilimsel veri ve hesaplama stratejisi

**K-035 / TECH-11B (2 Kasım 2026):** Giriş/kayıt başlıkları ve alan hizası düzeltildi; iki dilde canlı/simülasyon/eski hesap durumu, sonuç UTC anı ve özgün katalog/olay hazırlanma tarihleri kaynak paneline eklendi. 53 istemci testi, tip kontrolü, üretim derlemesi ve 320 px/PWA yeniden açılış kontrolü geçti. Sürekli olay akışı henüz bağlı değil; geniş atlas/kaynak yenileme FR-08/P1 işidir. [Uygulama, canlı API envanteri ve sınırlar](canli-hesap-ve-veri-guncelligi.md). Önceki P0/P1/P2 ve K-032 beklemesi korunur.

**TECH-04D:** Gece penceresi standart sunset–sunrise kesişimidir; sivil/astronomik alacakaranlık ayrılır. Sensörsüz yön ve yaklaşık yumruk açısı NASA kaynaklı öğretici yardımdır, kalibre ölçüm/algılanabilirlik değildir. 0 m/üst kenar ve kutup yön sınırı korunur. [Model/kanıt](ortak-bilesenler-ve-sensorsuz-gozlem.md).

**TECH-04C:** [ADR-0007](adr/0007-gozlem-takvimi-ve-yer-adlari.md) ile donmuş USNO evreleri/bağımsız standart doğuş-batış örnekleri, hesaplanan olayların ayrı etiketi, yerel GeoNames kaynak/hash/CC BY 4.0 ve açık veri yenileme. Çizelge 0 m deniz seviyesi referansıdır; mevcut elipsoidal harita yüksekliği geoit dönüşümü olmadan atmosfer hesabına verilmez. Saydamlık/projeksiyon astronomik hesabı değiştirmez. [Raporlar](gozlem-cizelgesi-ve-takvim.md).

**TECH-04B görsel/sensör ayrımı:** Fotoğraf panorama ve yön bağımlı atmosfer/kadir halesi bilimsel hesabın yerine geçmez; arazi fotoğrafı yerel ufuk değildir. Düz pusula sensör kuzeyini açık hizalama olmadan gerçek kuzey saymaz, WMM kurulmadı. [ADR-0006](adr/0006-fotograf-cevre-ve-pusula-siniri.md).

**TECH-04 eklemesi:** [ADR-0005](adr/0005-tam-ekran-konum-ve-yerel-zaman.md): 107 OpenNGC Messier eşleşmesi ve 85 kaynaklı/FAL takımyıldız çizimi eklendi; bu tam katalog veya Stellarium AGPL motorunun alınması değildir. Yeni durağan J2000 DSO dönüşümü 72 Astropy örneğinde en fazla 0,427526 yay dakikasından küçük yön farkıyla 1 yay dakikası hedefini geçti; bütün kataloğun doğruluk iddiası değildir. Atmosfer/arazi temsili görseldir, kırılma/meteoroloji/topografya hesabı değildir. [Kaynaklar/eksikler/kanıt](tam-ekran-harita-gelistirmesi.md).

**Tarih:** 31 Ekim 2026. **İz:** FR-01–05, FR-08, FR-11–12; A-002–005, A-007–009. İlk hesap/parlak katalog/Canvas harita ve referans denemesi uygulandı; geniş doğruluk ve fiziksel mobil bütçe açık. [ADR-0003](adr/0003-ilk-astronomi-adaptoru-ve-dogruluk-sinirlari.md), [ilk hesap](astronomi-denemesi.md) ve [TECH-02B/03 harita kanıtı](harita-ve-katalog-denemesi.md) sonuç/sınırları ayırır.

## Astronomi ve Dünya coğrafyası

| Özellik | PostGIS ihtiyacı | Ürün önceliği |
|---|---|---|
| Canlı gökyüzü haritası | Gerekmez; hesap ve çizim katmanları gerekir | Çok yüksek |
| Gezegenlerin anlık konumları | Gerekmez; astronomik hesap | Çok yüksek |
| Yıldız/takımyıldız konumları | Gerekmez; katalog, koordinat dönüşümü ve çizim | Çok yüksek |
| Doğuş, batış ve görünürlük saatleri | Gerekmez; zaman/konum ve astronomik varsayımlar | Çok yüksek |
| Kullanıcı koordinatını saklama | Gerekmez; PostgreSQL sayısal alanları yeterli olabilir | Yüksek; hassasiyet korunur |
| Dünya üzerinde gözlem noktası arama | Mesafe/alan sorgularında faydalı | Sonraki aşama |
| Işık kirliliği bölgelerini analiz etme | Veri tipine göre faydalı; kaynak raster da olabilir | Sonraki aşama |
| Arazi yüksekliği/çevresel engeller | Faydalı olabilir; yükseklik modeli/ufuk algoritması ayrıca gerekir | İleri aşama |

“30 km çevremde daha karanlık gözlem alanları” mekânsal sorgu örneğidir; henüz MVP taahhüdü değildir. “23.00'te Satürn hangi yönde, kaç derece yüksekte?” astronomik hesap sorusudur. [PostGIS'in mekânsal rolü](https://postgis.net/) gezegen efemerisi üretmez. PostGIS/Q3C/pgSphere MVP-0 için kurulmaz. Göksel sağ açıklık/dik açıklık ile Dünya enlem/boylamı birbirine karıştırılmaz.

## Araçların ayrı rolleri

| Aday | Araştırılacak rol | Mevcut karar |
|---|---|---|
| [Astronomy Engine](https://github.com/cosinekitty/astronomy) | C#/JavaScript hesapları, konum ve olaylar; iki çalışma ortamında aynı girdilerle deneme | 2.1.19 ilk sınırlı hesap adaptöründe seçildi; iki kutup yön istisnası açık, çizim motoru değil |
| [Astropy](https://docs.astropy.org/en/stable/) | Python bilimsel koordinat/zaman/birim/veri araçları | 8.0.2 izole referans aracında 144 yıldız + 72 DSO örneği üretir; ürün runtime'ı/Python servis zorunluluğu yok |
| [Skyfield](https://rhodesmill.org/skyfield/) | Python efemeris ve konum hesabı; bağımsız deneme karşılaştırması | Yardımcı aday; aynı efemerisi kullanmak tek başına bağımsız doğruluk kanıtı sayılmaz |
| [Stellarium Web Engine](https://github.com/Stellarium/stellarium-web-engine) | Tarayıcı planetaryum çizimi ve harita etkileşimi | Mobil/bundle/çevrimdışı/lisans denemesi gerekli; AGPL kapsamı seçilecek sürümde ayrıca değerlendirilecek |
| [Aladin Lite](https://github.com/cds-astro/aladin-lite) | HiPS gökyüzü taramalarını ve katalog katmanlarını görüntüleme | Ufuk merkezli canlı planetaryumun eşdeğeri varsayılmaz; sonraki görüntüleme adayı |
| [JPL Horizons](https://ssd.jpl.nasa.gov/horizons/) | Sabit senaryolarda referans efemeris üretme | Çalışan haritanın her karede dış API'ye bağımlı olması gerekmez |

Bunlar birlikte kurulacak bir paket listesi değildir. TECH-02A hesap adaptörü ADR-0003; TECH-02B/03 Canvas/HYG/d3 ilk harita dilimi ADR-0004 ile kaydedildi. Fiziksel mobil/tam performans ve PWA/offline açık. [Aday durumu](science/motor-adaylari.md). Katalog ve görüntü verilerinin lisansı yazılım lisansından ayrıdır; atıf ve çevrimdışı dağıtım hakları ayrıca kaydedilir.

## Veri standartları ve öğrenme sırası

| Teknoloji | Yorungez açısından anlamı | Öğrenme önceliği |
|---|---|---|
| [FITS](https://fits.gsfc.nasa.gov/fits_standard.html) | Astronomik görüntü, spektrum ve tablo dosyaları | Orta |
| [WCS](https://fits.gsfc.nasa.gov/fits_wcs.html) | Görüntü pikselini fiziksel/göksel koordinata bağlama | Orta |
| [ADQL](https://www.ivoa.net/documents/ADQL/) | Astronomik tablolarda SQL benzeri sorgulama | Yüksek; katalog veri hattı hazırlanırken |
| [TAP](https://www.ivoa.net/documents/TAP/) | Tablo sorgusu/veri erişimi protokolü; ADQL ile birlikte incelenir | Yüksek; canlı haritanın her kare çağrısı değil |
| [HiPS](https://www.ivoa.net/documents/HiPS/) | Çok çözünürlüklü gökyüzü taramalarına hiyerarşik erişim | Orta |
| [HEALPix](https://healpix.sourceforge.io/) | Küreyi eşit alanlı hiyerarşik hücrelere bölme | İleri |
| [Q3C](https://github.com/segasai/q3c) / [pgSphere](https://pgsphere.github.io/) | PostgreSQL üzerinde küresel konum sorgulama/indeksleme | İleri; katalog ölçeği ve sorgu gerektirdiğinde |

Kullanıcının göreceli öğrenme sırası korunur: gözlemsel astronomi 100, astrometri/gök mekaniği 95, bilimsel hesaplama 85, astronomik veri mühendisliği 80, astrofizik 55, GIS/haritacılık 35, uzay mühendisliği 20. Bu puanlar bilim dallarının nesnel değeri veya bilimsel ölçüm değil, mevcut ürün kapsamına göre öğrenme önceliğidir. Veri standardını öğrenme önceliği onu MVP'ye kurma zorunluluğu yaratmaz.

## TECH-02 doğrulama çıktısı

1. Girdi sözleşmesi: enlem/boylam, UTC anı, varsa gözlemci yüksekliği ve bilinmeyen doğruluk; çıktı koordinat çerçevesi, azimut başlangıcı/yönü ve birimler.
2. Zaman ölçekleri ve varsayımlar: UTC/UT1/TT/TDB dönüşümlerinin motor tarafından nasıl yapıldığı; kullanılan efemeris ve geçerli tarih aralığı. Her ölçeği birbirinin yerine kullanmamak.
3. Geometrik/atmosferik kırılmalı yükseklik, topocentric/geocentric konum, Güneş/Ay kenarı-merkezi ve doğuş/batış ufuk ölçütünün açık kaydı. Arazi ve hava yokken varmış gibi hesap yapmamak.
4. Sabit referans dosyaları: farklı yarımküreler, sıfır koordinatı, kutup çevresi, tarih değişimi, ufka yakın/altında hedef, hiç doğmayan/batmayan nesne. Referans istek/yanıtı, kaynak zamanı, lisansı ve motor sürümüyle saklanır.
5. Bağımsız karşılaştırma ve özellik bazlı tolerans: gezegen açısı, olay zamanı ve katalog konumu aynı eşik değildir. Toleranslar ölçüm ve ürün gereğine göre yazılır; baştan “%100 doğru” etiketi verilmez.
6. Mobil çizim/hesap ölçümü: başlangıç maliyeti, bundle, kare süreleri, zaman/konum değişimi, çevrimdışı sınırlar. Saf astronomi hesabı kullanıcı hesabına veya gereksiz PostgreSQL çağrısına bağlanmaz; sık etkileşimlerin istemci/Web Worker'da yürütülmesi denemeyle değerlendirilir.

Hesap çıktısı kaynak/motor/sürüm/varsayımlarıyla açıklanabilir olmalı; dış veri güncelliği ve bilinmeyen koşullar ayrı gösterilmelidir. Sayısal hassasiyet, gözlemci cihazının fiziksel ölçüm doğruluğunun yerine geçmez.
