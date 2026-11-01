# yorungez

**K-029 / açık kaynak yayın (1 Kasım 2026):** Özgün kod ve özgün proje belgeleri Apache-2.0; üçüncü taraf veri/görseller kendi lisanslarında. Public kaynak hedefi `YeloraStudio/yorungez`; gerçek ortam/SMTP/Portainer/veritabanı verileri özel kalır. Public metinlerde `sender@example.com` redakte örnektir, gerçek gönderen özel yapılandırmadadır; tarihsel SMTP başarı kaydı örnek hesabın kullanıldığı anlamına gelmez. [Karar](adr/0014-acik-kaynak-yayin-ve-apache-2.md), [yayın incelemesi](open-source-publication.md). Önceki ürün planı ve açık kabul işleri korunur.

**Güncel TECH-07 / K-027–028 (1 Kasım 2026):** Menüde giriş/kayıt veya doğrulanmış oturumun ad-soyadı; kayıt için ad/soyad/e-posta/parola. Servis hatası ve çevrimdışı durum ayrıldı, ortak yerel başlatıcı eklendi. Genel katalog/terim/takvim için hash doğrulamalı PWA paketi ve yeniden açılış uygulandı; kişisel kayıt/oturum/koordinat cache'e girmez. 125 .NET/44 istemci testi; fiziksel cihaz/üretim backup kabulü açık. [Uygulama ve kanıt](hesap-menusu-ve-cevrimdisi-gokyuzu.md), [hesap ADR](adr/0012-hesap-menusu-ve-ad-soyad.md), [PWA ADR](adr/0013-genel-gokyuzu-pwa-ve-cevrimdisi-paket.md).

**Güncel K-026 / TECH-06 (1 Kasım 2026):** Hesap envanterinde not/favori yanında ayrı gözlem ve kayıtlı konum uygulandı. Gözlem açıklama + kişisel beyan ister; gerçek zaman/nesne/konum isteğe bağlıdır, simülasyon zamanı kendiliğinden bağlanmaz. Konum kopyası geçmişi korur; haritada kullanım an/mod/hedef/kamerayı korur. 120 .NET + 38 istemci testi ve üretim derlemesi geçti; 52 tr/en terim/cache .7. [Uygulama ve sınırlar](gozlem-kayitlari-ve-kayitli-konumlar.md), [ADR-0011](adr/0011-gozlem-kaydi-ve-kayitli-konumlar.md). Fiziksel cihaz, genel katalog PWA/offline ve üretim backup kabulü açık; kişisel tarayıcı kalıcılığı yoktur.

**Güncel K-025 / TECH-05B:** Gönderen `sender@example.com`; parola yalnız özel kök `.env`, Gmail STARTTLS/AUTH kontrolü başarılı (ileti gönderilmedi). İşlem e-postaları İngilizce markalı HTML + düz metin, uygulama/API varsayılan dili İngilizce; açık Türkçe seçimi korunur. [Güncel paket](eposta-ve-varsayilan-dil.md). Önceki SMTP placeholder ve iki dilde e-posta hükümleri bu kararla değişti.


**Güncel K-024 / TECH-05:** Kişisel kayıt için doğrulanmış hesap zorunlu; anonim/IndexedDB kişisel kalıcılığı kaldırıldı. Not ve favoriler kullanıcıya bağlı PostgreSQL modülünde; TR/EN kayıt/giriş/doğrulama/sıfırlama ve panel geri dönüşü bağlıdır. [Uygulama ve sınırlar](hesap-ve-sunucu-defteri.md), [ADR-0010](adr/0010-hesap-zorunlu-defter-ve-sunucu-kayitlari.md). Aşağıdaki eski paket kayıtları kendi aşamasının tarihsel kanıtıdır.


**TECH-04D:** Yalnız Bu gece, ortak özel seçim/tarih/saat kontrolleri, sensörsüz yön/dürbün rehberi ve ilk yerel Defterim (favori/not, açık bağ seçimi, JSON, çöp kutusu/revizyon). [Kanıt ve sınırlar](ortak-bilesenler-ve-sensorsuz-gozlem.md), [kişisel kayıt/hesap/çevrimdışı akışları](kisisel-kayit-hesap-cevrimdisi-akislari.md). 33 istemci testi/üretim derlemesi geçti; backend önceki93 test temelini korur. Gerçek cihaz/hesap eşitleme/PWA yeniden açılışı açık.

**Önceki TECH-04C:** Bugün/Bu gece çizelgesi, kaynaklı Takvim, 330° zoom, ufuk altı saydam arazi ve şehir/ilçe/manuel ad-yükseklik eklendi. [Uygulama ve kanıt](gozlem-cizelgesi-ve-takvim.md), [ADR-0007](adr/0007-gozlem-takvimi-ve-yer-adlari.md). Ortak arama/atlas korunur; aramaya odaklanan Keşfet düğmesi kaldırıldı.

**Seçtiğin konum ve zamanda gökyüzünü keşfet, anla ve gözlemlerini kaydet.**

yorungez; harita merkezli, açık kaynak ve PWA destekli bir astronomi platformu olarak geliştiriliyor. Adı **yörünge + gezmek** birleşiminden geliyor. Ürün ve teknik adlandırmada `yorungez` kullanılır.

**Planlanan alan adı:** `yorungez.com`. Kullanıcı tarafından satın alınacak; henüz satın alındığı veya yayında olduğu kabul edilmez.

## Mevcut aşama

1 Kasım 2026 itibarıyla **modüler backend ve tr/en tam ekran Next.js gökyüzü haritası** çalışıyor. Gri/bordo yüzey, kapalı sol menü, saydam kart, 5073 yıldız/9 Güneş Sistemi hedefi/88 figür/107 Messier eşleşmesi/85 kaynaklı çizim ve 52 terim bağlıdır. İzinli konum/manuel/OSM, IANA–UTC, simülasyon, Bu gece, kaynaklı Takvim ve sensörsüz rehber korunur. Hesap/kayıt/doğrulama/giriş/kurtarma ve PostgreSQL'de özel favori/not/gözlem/kayıtlı konum çalışır. **125 .NET + 44 istemci testi** ve üretim derlemesi geçti; [TECH-07 kanıtı ve sınırlar](hesap-menusu-ve-cevrimdisi-gokyuzu.md). Önceki bilimsel referanslar ve iki kutup yön istisnası korunur. Genel katalog PWA/offline sınırlı IAB kabulüyle çalışır. Gerçek cihaz GPS/pusula/ekran okuyucu, çok tarayıcı/kurulum, geniş bilimsel kapsam ve üretim backup kabulü açık; PostGIS kurulmadı, bütün MVP-0/P0 tamamlanmadı.

İlk teknik teslimat **MVP-0**: tek gözlem konumu ve seçili zamanla çalışan harita, temel nesne arama/seçme ve bilgi kartı. İlk akış uygulanıp geliştirici tarayıcısında doğrulandı; gerçek cihaz, ekran okuyucu, kullanıcı görevleri ve performans bütçeleri açık.

## Belgeler

| Belge | Kullanımı |
|---|---|
| [Ürün gereksinimleri](urun-gereksinimleri.md) | Güncel ürün kapsamı; FR, UJ ve AC kimlikleri; sürüm sınırları |
| [Ürün keşfi](urun-kesfi.md) | Değer önerisi, hedef kullanıcılar, kaynaklı benzer ürün incelemesi ve ölçüm taslağı |
| [Alan sözlüğü](alan-sozlugu.md) | Kavramlar, temel ilişkiler ve iş kuralları için ilk taslak |
| [Kullanıcı görevleri](kullanici-gorevleri.md) | Sekiz görev kartı, değerlendirme formu ve ölçüm yaklaşımı; kullanıcı oturumu henüz yok |
| [Bağlam ve sınır durumları](baglam-ve-sinir-durumlari.md) | Konum/zaman/görünürlük, kişisel kayıt ve çevrimdışı durumların davranış matrisi |
| [UX akışları ve wireframe'ler](ux-akislari.md) | Ekran envanteri, dört temel akış, masaüstü/mobil ve düzenleyici yerleşimleri |
| [Yol haritası ve iş listesi](yol-haritasi.md) | Dokümantasyon sırası, mevcut durum ve sıradaki somut işler |
| [Karar kaydı](kararlar.md) | Kesinleşen kararlar, öneriler ve açık sorular |
| [Teknik başlangıç](teknik-baslangic.md) | Backend'i çalıştırma, mevcut test kapsamı ve ilk harita için geliştirme sırası |
| [İlk teknik ADR](adr/0001-teknik-temel-ve-ilk-dikey-akis.md) | Backend çekirdeği, .NET 10 ve ilk harita akışının gerekçesi |
| [Modüler temel ADR'si](adr/0002-moduler-temel-cqrs-ve-lisanslar.md) | Katman/modül sınırları, CQRS ve sürüm/lisans seçimleri |
| [Altyapı ve kimlik](altyapi-ve-kimlik.md) | Yerel kurulum, uçlar, token/outbox davranışı ve üretim öncesi işler |
| [İki dil ve terimler](yerellestirme-ve-terimler.md) | Tam tr/en teslimat koşulu, terim modeli ve mevcut API kapsamı |
| [Bilimsel veri stratejisi](bilimsel-veri-stratejisi.md) | Astronomi–GIS ayrımı, aday araçlar, veri standartları ve doğrulama planı |
| [İlk hesap ADR'si](adr/0003-ilk-astronomi-adaptoru-ve-dogruluk-sinirlari.md) | Astronomy Engine seçimi, birimler/zaman/ufuk ve kutup yön sınırı |
| [Tekrarlanabilir astronomi denemesi](astronomi-denemesi.md) | Referanslar, offline doğrulama ve anonim hesap API'si |
| [Gereksinim izlenebilirliği](teslimat-izlenebilirligi.md) | Bütün FR/UJ/AC kimliklerinin mevcut kanıtı ve kalan işi |
| [İlk harita/katalog ADR'si](adr/0004-ilk-harita-ve-parlak-katalog.md) | Canvas seçimi, HYG/d3 verisi, istemci/Worker/BFF dağılımı |
| [Harita ve katalog denemesi](harita-ve-katalog-denemesi.md) | TR/EN akış, 144 yıldız referansı, çizim ölçümleri, ekran kanıtları ve sınırlar |
| [Tam ekran/konum/zaman paketi](tam-ekran-harita-gelistirmesi.md) | TECH-04 uygulaması, açılış düzeltmesi, katmanlar, Wikipedia, GPS/IANA ve doğrulama sınırları |
| [Tam ekran ve zaman ADR’si](adr/0005-tam-ekran-konum-ve-yerel-zaman.md) | Konum izinleri, yerel/UTC politikası, içerik/lisans ve Worker yaşam döngüsü |
| [Doğal görünüm ve pusula](dogal-gorunum-ve-pusula.md) | Kullanıcı paleti, gerçek panorama, yıldız ışıkları, dil listesi ve düz pusula sınırları |
| [Cihaz doğrulama protokolü](cihaz-konum-pusula-dogrulamasi.md) | Fiziksel GPS/pusula/ekran yönü/erişilebilirlik; henüz yürütülmedi |
| [Fotoğraf/pusula ADR’si](adr/0006-fotograf-cevre-ve-pusula-siniri.md) | Veri/hibrid çizim ve sensör-gerçek kuzey sınırı |
| [Ortak kontroller ve sensörsüz gözlem](ortak-bilesenler-ve-sensorsuz-gozlem.md) | Bu gece, özel seçim/tarih/saat, hedef yönü ve güncel kanıt |
| [Kişisel kayıt/hesap/çevrimdışı akışları](kisisel-kayit-hesap-cevrimdisi-akislari.md) | Çalışan ilk Defterim dilimi ve sonraki UX-02 işleri |
| [Ortak kontrol ADR’si](adr/0008-ortak-kontroller-ve-sensorsuz-rehber.md) | Özel bileşenler, gece ve sensörsüz rehber sınırları |
| [Önceki yerel Defterim ADR’si](adr/0009-yerel-defter-ve-kayipsiz-duzenleme.md) | IndexedDB, revizyon, mahremiyet ve kayıt yaşam döngüsü |
| [Bağımlılık envanteri](../THIRD_PARTY_NOTICES.md) | Sabit sürümler ve lisans kaynakları |
| [Katkı rehberi](../CONTRIBUTING.md) | Çalıştırma/doğrulama ve geliştirme kuralları |
| [Gmail/markalı e-posta ve varsayılan dil](eposta-ve-varsayilan-dil.md) | Yerel sır, SMTP kontrolü, İngilizce şablon ve sonraki adım |
| [Hesap ve sunucu defteri](hesap-ve-sunucu-defteri.md) | Güncel hesap zorunluluğu, PostgreSQL, oturum ve kanıt |
| [Hesap menüsü ve genel PWA](hesap-menusu-ve-cevrimdisi-gokyuzu.md) | Ad-soyad, ortak yerel başlatıcı, genel çevrimdışı paket ve güncel kanıt |
| [Gözlem ve kayıtlı konumlar](gozlem-kayitlari-ve-kayitli-konumlar.md) | Hesap envanteri, gerçek zaman/konum kopyası ve güncel doğrulama |
| [Gözlem/konum ADR’si](adr/0011-gozlem-kaydi-ve-kayitli-konumlar.md) | Minimum model, UTC ve geçmiş kayıt anlamı |
| [Çalışma kuralları](../AGENTS.md) | Sonraki çalışmaların ürün hedefine bağlı kalması için rehber |
| [Başlangıç belgesinin arşivi](arsiv/OpenSky_Proje_Gereksinimleri_UX_v1.md) | Değiştirilmemiş 1.0 referansı; tarihsel kayıt |

## Ürün omurgası

- **Gökyüzü:** Konum ve zaman kontrolleri, etkileşimli harita, hedef seçimi.
- **Bu gece:** Konuma göre ufuk üstü aralıklar, hedef/saat seçimi ve pusula yardımı.
- **Takvim:** Ay evreleri ve hesaplanan Güneş Sistemi olayları; kaynak, yerel saat/UTC ve haritaya geçiş.
- **Defterim:** Özel favoriler, gözlem kayıtları, kayıtlı konumlar ve not/anılar.

Temel keşif hesap veya ekipman gerektirmez. Kişisel kayıtlar için doğrulanmış hesap gerekir. TR/EN kayıt/giriş/e-posta doğrulama/sıfırlama ekranları, hesaba özel PostgreSQL favori/not/gözlem/konum kayıtları bağlıdır. Tarayıcıya kalıcı kişisel kayıt yazılmaz. Ekipman profilleri isteğe bağlı P2 genişlemesidir.

## Teknik yön

Next.js 16.4.3 + TypeScript/PWA yönü; C#/.NET 10, Clean Architecture, CQRS ve **modüler monolit** korunur. SDK 10.0.403, MediatR 12.5.0 (Apache-2.0), PostgreSQL ve Redis seçilmiştir. İlk hesap adaptörü MIT lisanslı Astronomy Engine 2.1.19; ilk çizim Canvas 2D, katalog HYG 4.1/d3-celestial verisidir (ADR-0003/0004). Python/Astropy yalnızca bilimsel referans aracıdır. PostGIS ileride Dünya üzerindeki gözlem alanı analizine hizmet edebilir; göksel konum hesabı için gerekmez.

**Türkçe ve İngilizce her özellikte birlikte ilerler.** Backend mesajları/e-postalar, ilk harita/kart/kontrol/arama/terim arayüzü eşli hazırdır. 52 terim kaynaklı iki dilde saklanır. Henüz uygulanmamış ürün ekranları nedeniyle bütün ürünün dil/erişilebilirlik kabulü tamamlandı denmez. Diğer diller sonraki aşamadır.

## Tüm uygulamayı yerelde açma

```powershell
./scripts/Start-LocalApp.ps1
# http://127.0.0.1:5190/en veya /tr; terminal açık kalmalı.
# Testler için: -EmailMode Mailpit
# Ayrı terminalden kapat: ./scripts/Stop-LocalApp.ps1
```

Docker Desktop çalışmalıdır. Başlatıcı API, PostgreSQL/Redis ve üretim Web/PWA'yı birlikte açar; portu dolu başka hizmete müdahale etmez. `Auto` mevcut özel Gmail ortamını kullanır. Kişisel kayıtlar için backend gerekir; genel çevrimdışı harita önceden hazırlanmış paketle açılır. [Sınırlar ve kurulum](hesap-menusu-ve-cevrimdisi-gokyuzu.md).

## Haritayı ayrı açma

```powershell
./scripts/Start-Web.ps1 -Production
# http://127.0.0.1:5190/tr veya /en
./scripts/Verify-Web.ps1
```

Node.js 22.20.0 ile doğrulandı. API kapalıyken harita aynı gömülü genel katalogla çalışır. Sunucu Ctrl+C ile kapatılır. Üretim derlemesi/çizim laboratuvarı ve kalan offline sınırları [Web rehberindedir](../src/Yorungez.Web/README.md).

## Backend'i yerelde çalıştırma

```powershell
./scripts/Start-LocalBackend.ps1
# Ayrı bir terminalde doğrulama:
./scripts/Verify-Backend.ps1
# API'yi Ctrl+C ile kapattıktan sonra yerel servisleri durdurma:
docker compose stop
```

PowerShell 7, Docker Compose ve .NET SDK gerekir. Script rastgele sırları yalnızca yoksa üretir, mevcut özel ayarları korur; yerel servisleri başlatır, migration uygular ve API'yi `http://127.0.0.1:5187` üzerinde açar. Sırlar `.env`/`appsettings.Local.json` dosyalarında tutulur ve paylaşılmaz. [Kurulum ayrıntıları](altyapi-ve-kimlik.md).

`/health/live` host, `/health/ready` veritabanı/önbellek, `/api/v1/status` servis kimliği içindir. `/api/v1/terms/` anonim terim aramasıdır; `Accept-Language: tr` veya `en` seçilir. `POST /api/v1/sky/positions` ve `/horizon-crossings` anonim hesap yapar; [girdi/model sözleşmesi](astronomi-denemesi.md). Kimlik ve özel yerel Gmail ayarı [altyapı belgesindedir](altyapi-ve-kimlik.md). Hesap zorunlu dört kayıt türü vardır; gözlem saati ile harita/sistem zamanı ayrıdır. Anonim aktarım hedefi kaldırıldı.

## Bir sonraki çalışma

TECH-04’ün harita/izinli konum/yerel saat yazılım bölümü uygulandı. Pusula yazılımı ve [cihaz protokolü](cihaz-konum-pusula-dogrulamasi.md) hazır. Sırada **gerçek GPS/pusula cihaz oturumları**, kalibrasyon/ekran yönü/erişilebilirlik ve mobil bütçe var; sensörsüz manuel kontrol korunur. Fiziksel mobil performans, ekran okuyucu ve gerçek kullanıcı görevleri açık. [Güncel kanıt](tam-ekran-harita-gelistirmesi.md) ve [bütün gereksinimlerin kalan işleri](teslimat-izlenebilirligi.md) kayıtlıdır. P0 hesap zorunlu dört kayıt türü uygulandı; genel katalog çevrimdışı yeniden açılışı TECH-07 ile uygulandı; sırada DB backup/geri yükleme ve cihaz kabulü [UX-02](kisisel-kayit-hesap-cevrimdisi-akislari.md) ile sürer.
