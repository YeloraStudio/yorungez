# yorungez — Gereksinim ve teslimat izlenebilirliği

**K-030 / TECH-08 (1 Kasım 2026):** Responsive safe-area/VisualViewport, anında geçersiz sensör/hizalama temizliği ve PWA açılış/geri dönüş kontrolü uygulandı; 49 istemci testi ve üretim derlemesi geçti. IAB/Brave kontrolleri fiziksel kabul değildir; S23/Chrome ve iPhone 15/Safari oturumu, erişilebilir HTTPS adresi henüz olmadığı için bekliyor. [Kanıt ve sınırlar](responsive-cihaz-ve-pwa-kabulu.md), [telefon kartı](telefon-kabul-oturumu.md), [ADR](adr/0015-responsive-sensor-ve-pwa-kabulu.md). Önceki plan ve bilimsel sınırlar korunur.

**K-029 / açık kaynak yayın (1 Kasım 2026):** Özgün kod ve özgün proje belgeleri Apache-2.0; üçüncü taraf veri/görseller kendi lisanslarında. Public kaynak hedefi `YeloraStudio/yorungez`; gerçek ortam/SMTP/Portainer/veritabanı verileri özel kalır. Public metinlerde `sender@example.com` redakte örnektir, gerçek gönderen özel yapılandırmadadır; tarihsel SMTP başarı kaydı örnek hesabın kullanıldığı anlamına gelmez. [Karar](adr/0014-acik-kaynak-yayin-ve-apache-2.md), [yayın incelemesi](open-source-publication.md). Önceki ürün planı ve açık kabul işleri korunur.

**Güncel TECH-07 / K-027–028 (1 Kasım 2026):** Menüde giriş/kayıt veya doğrulanmış oturumun ad-soyadı; kayıt için ad/soyad/e-posta/parola. Servis hatası ve çevrimdışı durum ayrıldı, ortak yerel başlatıcı eklendi. Genel katalog/terim/takvim için hash doğrulamalı PWA paketi ve yeniden açılış uygulandı; kişisel kayıt/oturum/koordinat cache'e girmez. 125 .NET/44 istemci testi; fiziksel cihaz/üretim backup kabulü açık. [Uygulama ve kanıt](hesap-menusu-ve-cevrimdisi-gokyuzu.md), [hesap ADR](adr/0012-hesap-menusu-ve-ad-soyad.md), [PWA ADR](adr/0013-genel-gokyuzu-pwa-ve-cevrimdisi-paket.md).

**Güncel K-026 / TECH-06 (1 Kasım 2026):** Hesap envanterinde not/favori yanında ayrı gözlem ve kayıtlı konum uygulandı. Gözlem açıklama + kişisel beyan ister; gerçek zaman/nesne/konum isteğe bağlıdır, simülasyon zamanı kendiliğinden bağlanmaz. Konum kopyası geçmişi korur; haritada kullanım an/mod/hedef/kamerayı korur. 120 .NET + 38 istemci testi ve üretim derlemesi geçti; 52 tr/en terim/cache .7. [Uygulama ve sınırlar](gozlem-kayitlari-ve-kayitli-konumlar.md), [ADR-0011](adr/0011-gozlem-kaydi-ve-kayitli-konumlar.md). Fiziksel cihaz, genel katalog PWA/offline ve üretim backup kabulü açık; kişisel tarayıcı kalıcılığı yoktur.

**Güncel K-025 / TECH-05B:** Gönderen `sender@example.com`; parola yalnız özel kök `.env`, Gmail STARTTLS/AUTH kontrolü başarılı (ileti gönderilmedi). İşlem e-postaları İngilizce markalı HTML + düz metin, uygulama/API varsayılan dili İngilizce; açık Türkçe seçimi korunur. [Güncel paket](eposta-ve-varsayilan-dil.md). Önceki SMTP placeholder ve iki dilde e-posta hükümleri bu kararla değişti.


**Güncel K-024 / TECH-05:** Kişisel kayıt için doğrulanmış hesap zorunlu; anonim/IndexedDB kişisel kalıcılığı kaldırıldı. Not ve favoriler kullanıcıya bağlı PostgreSQL modülünde; TR/EN kayıt/giriş/doğrulama/sıfırlama ve panel geri dönüşü bağlıdır. [Uygulama ve sınırlar](hesap-ve-sunucu-defteri.md), [ADR-0010](adr/0010-hesap-zorunlu-defter-ve-sunucu-kayitlari.md). Aşağıdaki eski paket kayıtları kendi aşamasının tarihsel kanıtıdır.


**Önceki TECH-04D / UX-02A:** [Kontroller/gece/sensörsüz rehber](ortak-bilesenler-ve-sensorsuz-gozlem.md), [yerel favori/not ve hesap/offline devamı](kisisel-kayit-hesap-cevrimdisi-akislari.md); PRD1.6, 33 istemci testi/üretim derlemesi. Backend önceki93 sonucu temel olarak korunur; bu tur tekrar çalıştırılmadı. Bütün kalanlar aşağıda sürer.

**Güncel TECH-04C:** [Çizelge/takvim/yer adı/saydam geniş açı](gozlem-cizelgesi-ve-takvim.md), [ADR-0007](adr/0007-gozlem-takvimi-ve-yer-adlari.md); 93 .NET +29 istemci testi, 51 terim/cache .6. 1781 USNO evresi ve 22 standart doğuş-batış örneği tolerans içinde; diğer olay türlerinin bağımsız doğrulaması ve fiziksel cihaz kabulü açık.

**Önceki TECH-04B:** [Fotoğraf çevre/palet/dil listesi ve pusula kanıtı](dogal-gorunum-ve-pusula.md). O aşamada 43 kaynaklı terim, 84 .NET + 24 istemci testi/üretim derlemesi. GPS/pusula fiziksel kabulü [protokolde](cihaz-konum-pusula-dogrulamasi.md) bekler. Bütün FR/UJ/AC kalanları korunur.

**1 Kasım 2026.** Kaynak [ürün gereksinimleri](urun-gereksinimleri.md) v1.10; kapsam daraltılmadı. Kısmi kanıt bütün kabul kriterinin geçtiği anlamına gelmez. [Güncel kanıt/sınırlar](gozlem-cizelgesi-ve-takvim.md): 93 .NET + 29 istemci testi, 144 yıldız + 72 DSO referansı ve IAB üretim denemesi. [Güncel TECH-04 kanıtı](tam-ekran-harita-gelistirmesi.md). Geliştirici/dar viewport testi gerçek kullanıcı/fiziksel cihaz/ekran okuyucu/üretim yükü ölçümü değildir.

## İşlevler

| Gereksinim | Mevcut kanıt | Kalan teslimat |
|---|---|---|
| FR-01 Konum/yön | Kayıpsız koordinat, önceden izinli taze yüksek doğruluk isteği/ret/süre aşımı/metre/ölçüm zamanı; manuel alternatif/geç GPS koruması, isteğe bağlı OSM nokta seçimi/IANA; düz pusula izin/süre/eğim/sapma/gerçek yönle hizalama/temizlik; yerel GeoNames/manuel ad/koordinat/yükseklik ve hedef pusula yardımı; sensörsüz yön/yükseklik/dürbün brief'i | Fiziksel GPS/pusula izin/ret/doğruluk/ekran yönü/kalibrasyon kabulü; kamera AR/WMM; ileri ufuk/yükseklik |
| FR-02 Canlı harita | Tam ekran/kapalı menü/gri-bordo; Canvas/Worker süre/ready/kurtarma; 5073 yıldız/9 Güneş Sistemi/88 figür/107 DSO/85 kaynaklı çizim, iki ızgara/gece/tam ekran, varsayılan üç katman; kaynaklı fotoğraf çevre/yön bağımlı atmosfer/kadir halesi, sade GPU fallback, yumuşak pan/zoom/klavye/seçim; 0,6°–330° ve saydam ufuk altı/aşağı bakış | Fiziksel dokunma/pinch, tam kare/ilk yükleme/bellek ve gerçek mobil bütçesi; geniş katalog/model |
| FR-03 Atlas | Kaynaklı katalog, iki dilli arama/ortak kimlik/kart; Güneş gerçek arşiv fotoğrafı/Wikipedia özeti/atıf/revizyon; kısa özet + açılır ayrıntı/hesaplanan RA/Dec/uzaklık; 107 DSO | Geniş atlas (gereksiz Keşfet düğmesi kaldırıldı), eksik Messier/diğer nesne görselleri ve belirsiz ad kapsamı, geniş fiziksel alanlar/eylemler ve ileri doğuş-batış/ufuk |
| FR-04 Zaman/olay | UTC anı; konuma göre IANA yerel/GMT/UTC; yerel/UTC giriş, Temporal boş saat reddi/çift saat seçimi; canlı/simülasyon/şimdiye dönüş; düzenlenen tarihi canlı render koruması, merkez/0° API; Bu gece standart 0 m çizelgesi, kaynaklı 2623 kayıtlı takvim ve UTC/hedef navigasyonu; yalnız gece/kutup penceresi, ortak özel tarih/saat/bölge seçimi | IANA/ofset veri bakımı ve geniş cihaz kabulü; geniş doğuş-batış/rakım/ufuk; meteor/asteroit/Ay–yıldız/tutulma verisi ve diğer olayların bağımsız kontrolü |
| FR-05 Görünürlük | Merkez-ufuk ayrımı, bilinmeyen koşullar/kutup yön sınırı; 144 yıldız/72 DSO/önceki JPL örnekleri; atmosfer/arazi temsili olduğu açık; saydam keşif gerçek gözlenebilirlikten ayrı | Astronomik gece/algılanabilirlik, geniş ufuk/zaman doğrulaması; P1 hava/ışık/yerel ufuk |
| FR-06 Kişisel alan | Hesap zorunlu PostgreSQL favori/not/gözlem/kayıtlı konum; opsiyonel hedef/an/koordinat snapshotları, sunucu revizyonu/çöp kutusu/dışa aktarma; bellekte taslak | İleri ekipman/olay/çoklu hedef bağı, kalıcı temizleme/içe aktarma, geniş kota/göç/backup kabulü |
| FR-07 Anonim/hesap | Ad/soyad/e-posta/parola, menü hesap durumu/profil tamamlama, ortak oturum ve TR/EN hesap ekranları; keşif hesapsız, kişisel kayıt yalnız doğrulanmış hesapla | SMTP TLS/AUTH geçti; gerçek alıcı teslimi/üretim oturum/işletim kabulü; anonim aktarım K-024 ile kaldırıldı |
| FR-08 Veri sistemi | Sürüm/hash/kaynak/atıflı ortak C#/BFF katalog/overlays; ilk kare backend bağımsız; ETag/304; süre sınırlı Worker ve eski yanıt koruması; USNO/GeoNames arşiv/hash/yerel POST-no-store; lisanslı Wikipedia/Commons kaynak/yeniden deneme | Genel veri güncellik/yenileme UX’i, dış kaynak sağlık işleri, otomatik veri yenileme politikası |
| FR-09 PWA/offline | ADR-0013 hash doğrulamalı 51 genel dosya, iki dil shell/Worker/katalog/terim/takvim, isteğe bağlı 88 görsel; sunucular kapalı yeni sekme/yenileme ve takvim→Ay hesabı testli; tek sekmeli açık güncelleme | Fiziksel kurulum/çok tarayıcı/kota/eviction ve DB backup kabulü; özel offline yazma yok |
| FR-10 Ekipman | İsteğe bağlı P2 sınırı korunuyor | Profiller ve görüş alanı; temel deneyimin ön koşulu olmayacak |
| FR-11 İki dil | Backend/UI/hesap ve dört envanter türü/özel gözlem tarihi ve 52 terim tr/en; varsayılan en/açık tr, K-025 ile İngilizce markalı e-posta; bağlamı koruyan dil geçişi; Wikipedia eksikse sessiz dil fallback yok | Kalan ürün/offline ekranları; ekran okuyucu ve kapsamlı iki dilde E2E; gerçek mail istemcisi render kabulü |
| FR-12 Terimler | 52 kaynaklı tr/en kayıt, AU/AB/IANA/GMT/DSO/ızgara/atmosfer/arazi dahil; karttan sözlük/arama, Enter/ESC odak dönüşü; sürüm .7 / NOAA elipsoidal yükseklik | Ayrı sözlük sayfası/derin bağlantı, ekran okuyucu/gerçek dokunma ve kullanıcı değerlendirmesi |

## Yolculuklar

| Yolculuk | Durum / sıradaki kanıt |
|---|---|
| UJ-01 İlk ziyaret/konum/nesne | Etiketli örnek/manuel/izinli cihaz konumundan anonim harita/kart; sınırlandırılmış açılış; gerçek GPS izin/ret ve kullanıcı kabulü açık |
| UJ-02 Arama/harita/kart | Satürn aynı kimlik/kart; Sirius HIP32349→hyg-32263; Sun/Güneş gerçek fotoğraf/iki dil Wikipedia/ayrıntı, 107 DSO; geniş atlas açık |
| UJ-03 Simülasyon | UTC/yerel giriş ve IANA/GMT gösterim, Balıkesir 14:24=11:24Z, dil/konum/bölge değişiminde aynı an; DST boş/çift saat testli; geniş cihaz/veri bakımı açık |
| UJ-04 Hesap zorunlu kayıt | Kayıt/doğrulama/giriş ve sunucu favori/not/gözlem/konum; gerçek DB sahiplik/ikinci giriş/revizyon testli. Üretim/gerçek cihaz kabulü açık |
| UJ-05 Gözlem/anı | Hesaba bağlı serbest not/anı, opsiyonel bağlar ve düzenleme var; gerçek gözlem/kayıtlı yer ve bağımsız konum kopyası uygulandı; ileri bağlar/gerçek cihaz kabulü açık |
| UJ-06 Mobil/pusula/panel | Tam ekran/kapalı menü/yüzen kart; dar viewport’ta kart küçültme/geri açma/yatay taşma yok, manuel klavye/pan/zoom; düz pusula yazılımı hazır; fiziksel dokunma/sensör/gerçek yön/cihaz kabulü açık |
| UJ-07 Kesinti/eşitleme | API yokluğunda aynı gömülü katalog var; genel katalog PWA/offline yeniden açılışı sınırlı IAB testli; hesap revizyon/sahiplik testli, üretim backup/cihaz kabulü açık; kişisel offline yazma yok |

## Kabul kriterleri

| Kriter | Durum / eksik kanıt |
|---|---|
| AC-01 | Anonim örnek/manuel harita, izinli GPS yazılımı, görünür hata/yeniden deneme var; gerçek kullanıcı/GPS kabulü açık |
| AC-02 | Manuel doğrulama/virgül/sıfır/hassasiyet, GPS hata durumları/manuel alternatif/OSM nokta seçimi var; gerçek cihaz izin reddi/doğruluk kabulü açık |
| AC-03 | Harita/kart tek Worker karesi/ready/sıra/gözetim ve referans testleri; IANA/UTC tek an/DST koruması var; bütün model/hedef/tarih/cihaz doğrulaması açık |
| AC-04 | Arama ve harita aynı Satürn kimlik/kartına ulaştı; geniş katalog/uçtan uca kapsam açık |
| AC-05 | Canlı/simülasyon, yerel/UTC seçimi, aynı an, şimdiye dönüş ve DST koruması testli; geniş cihaz ve siyasi saat verisi bakımı açık |
| AC-06 | Ufuk altı kartı/bilinmeyen koşullar/kutup neden metni var; standart olay örnekleri testli; geniş ufuk/gözlem koşulu modeli açık |
| AC-07 | K-024: anonim yazma ret, PostgreSQL sahiplik/ikinci giriş/eşzamanlı revizyon testleri geçti. Gerçek üretim yedek/geri yükleme ve cihaz kabulü açık |
| AC-08 | Doğrulanmamış hesap giriş/not işlevleri reddedilir; TR/EN doğrulama bekleme/yeniden gönderme/link ekranı ve yerel Mailpit denemesi var. Gmail TLS/AUTH geçti; İngilizce markalı e-posta bağlı, gerçek alıcı teslim/render kabulü açık |
| AC-09 | Özel ayarlar/oturum sınırları; keşif konumu URL/storage/log’a otomatik yazılmaz. IANA için aynı kökenli BFF POST/no-store, poligon yerelde; GeoNames ad/koordinat POST-no-store yerelde; OSM yalnız açık kullanıcı eylemiyle. Not/gözlem koordinatı ayrı açık bağ seçimiyle, kayıtlı yer koordinatı açık kaydetmeyle hesaba özel PostgreSQL kaydına girer; başka hesap erişimi API testleriyle reddedilir |
| AC-10 | 52 terim cache/BFF hash/ETag/atıf, Wikipedia kaynak tarihi/hata/yeniden deneme, süre sınırlı katalog/Worker var; genel güncellik/offline UX açık |
| AC-11 | Manuel klavye/yumuşak pan/zoom, katmanlar/tam ekran ve dar ekranda küçülen kart var; düz pusula yazılımı/izin/kalibrasyon açıklamaları var; fiziksel cihaz/gerçek yön/performans kabulü açık |
| AC-12 | Genel service worker/ilk kurulum/hash/ayrı görsel/sürüm akışı ve sunucular kapalı yeni sekme+yenileme+takvim→hesap geliştirici testli. İlk ziyaret/cache yoksa bağlantı gerekir; fiziksel kurulum/çok tarayıcı/eviction kabulü açık |
| AC-13 | Backend ve ilk frontend akışı iki dilde geliştirici testli; bütün ekranlar/cihaz/ekran okuyucu açık |
| AC-14 | Karttan açıklama, sade iki dil, kaynak ve klavye/ESC testi var; ayrı sözlük/derin bağlantı/ekran okuyucu açık |

## Sürüm ve açık kararlar

MVP-0 harita/konum-zaman/nesne akışıdır; P0 kişisel kayıtlar veya P1/P2 genişlemeleri MVP-0'a taşınmaz. P0 hesap/sunucu kişisel veri/PWA; P1 astronomi/hava/ufuk derinliği; P2 isteğe bağlı ekipman kaynak belgedeki sırada kalır.

A-001–014 [karar kaydında](kararlar.md) korunur. A-003 ilk hesap adaptörü ADR-0003; A-002/005 ilk çizim/parlak katalog ADR-0004 ile ilerledi. A-014 yerel/UTC/DST sözleşmesi ADR-0005 ile uygulandı; veri bakımı açık. Kutup, geniş tarih/hedef, ufuk ve fiziksel mobil doğruluk/bütçeler açık. Sekiz kullanıcı görevi, 35 sınır durumu, domain/UX taslakları ve gerçek kullanıcı/cihaz işleri tamamlandı sayılmadı. **TECH-04 yazılım bölümü uygulandı; sıradaki** gerçek cihaz konum/izin/doğruluk protokolü ve pusula/kalibrasyon fiziksel kabulü (yazılım aracı/protokol hazır); P0 UX-02/kişisel veri/hesap/offline planı korunur.
