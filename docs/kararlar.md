# yorungez — Karar kaydı

**K-031 / TECH-09 (2 Kasım 2026):** Kullanıcının dört marka kaynağı web başlığı/menü/hesap, PWA (any/maskable/Apple touch), favicon ve gömülü e-posta logosuna bağlandı; kaynaklar ve içerik hash'leri korunur. Görsel Yörüngez yazımı sağlandığı gibi, teknik/erişilebilir ad yorungez. [Uygulama ve kanıt](marka-logolari.md), [kaynaklar](../data/branding/README.md). Fiziksel GPS/pusula/PWA ve önceki açık kabul işleri sürer.

**K-030 / TECH-08 (1 Kasım 2026):** Responsive safe-area/VisualViewport, anında geçersiz sensör/hizalama temizliği ve PWA açılış/geri dönüş kontrolü uygulandı; 49 istemci testi ve üretim derlemesi geçti. IAB/Brave kontrolleri fiziksel kabul değildir; S23/Chrome ve iPhone 15/Safari oturumu, erişilebilir HTTPS adresi henüz olmadığı için bekliyor. [Kanıt ve sınırlar](responsive-cihaz-ve-pwa-kabulu.md), [telefon kartı](telefon-kabul-oturumu.md), [ADR](adr/0015-responsive-sensor-ve-pwa-kabulu.md). Önceki plan ve bilimsel sınırlar korunur.

**K-029 / açık kaynak yayın (1 Kasım 2026):** Özgün kod ve özgün proje belgeleri Apache-2.0; üçüncü taraf veri/görseller kendi lisanslarında. Public kaynak hedefi `YeloraStudio/yorungez`; gerçek ortam/SMTP/Portainer/veritabanı verileri özel kalır. Public metinlerde `sender@example.com` redakte örnektir, gerçek gönderen özel yapılandırmadadır; tarihsel SMTP başarı kaydı örnek hesabın kullanıldığı anlamına gelmez. [Karar](adr/0014-acik-kaynak-yayin-ve-apache-2.md), [yayın incelemesi](open-source-publication.md). Önceki ürün planı ve açık kabul işleri korunur.

**Güncel TECH-07 / K-027–028 (1 Kasım 2026):** Menüde giriş/kayıt veya doğrulanmış oturumun ad-soyadı; kayıt için ad/soyad/e-posta/parola. Servis hatası ve çevrimdışı durum ayrıldı, ortak yerel başlatıcı eklendi. Genel katalog/terim/takvim için hash doğrulamalı PWA paketi ve yeniden açılış uygulandı; kişisel kayıt/oturum/koordinat cache'e girmez. 125 .NET/44 istemci testi; fiziksel cihaz/üretim backup kabulü açık. [Uygulama ve kanıt](hesap-menusu-ve-cevrimdisi-gokyuzu.md), [hesap ADR](adr/0012-hesap-menusu-ve-ad-soyad.md), [PWA ADR](adr/0013-genel-gokyuzu-pwa-ve-cevrimdisi-paket.md).

**Güncel K-026 / TECH-06 (1 Kasım 2026):** Hesap envanterinde not/favori yanında ayrı gözlem ve kayıtlı konum uygulandı. Gözlem açıklama + kişisel beyan ister; gerçek zaman/nesne/konum isteğe bağlıdır, simülasyon zamanı kendiliğinden bağlanmaz. Konum kopyası geçmişi korur; haritada kullanım an/mod/hedef/kamerayı korur. 120 .NET + 38 istemci testi ve üretim derlemesi geçti; 52 tr/en terim/cache .7. [Uygulama ve sınırlar](gozlem-kayitlari-ve-kayitli-konumlar.md), [ADR-0011](adr/0011-gozlem-kaydi-ve-kayitli-konumlar.md). Fiziksel cihaz, genel katalog PWA/offline ve üretim backup kabulü açık; kişisel tarayıcı kalıcılığı yoktur.

**Güncel K-025 / TECH-05B:** Gönderen `sender@example.com`; parola yalnız özel kök `.env`, Gmail STARTTLS/AUTH kontrolü başarılı (ileti gönderilmedi). İşlem e-postaları İngilizce markalı HTML + düz metin, uygulama/API varsayılan dili İngilizce; açık Türkçe seçimi korunur. [Güncel paket](eposta-ve-varsayilan-dil.md). Önceki SMTP placeholder ve iki dilde e-posta hükümleri bu kararla değişti.


**Güncel K-024 / TECH-05:** Kişisel kayıt için doğrulanmış hesap zorunlu; anonim/IndexedDB kişisel kalıcılığı kaldırıldı. Not ve favoriler kullanıcıya bağlı PostgreSQL modülünde; TR/EN kayıt/giriş/doğrulama/sıfırlama ve panel geri dönüşü bağlıdır. [Uygulama ve sınırlar](hesap-ve-sunucu-defteri.md), [ADR-0010](adr/0010-hesap-zorunlu-defter-ve-sunucu-kayitlari.md). Aşağıdaki eski paket kayıtları kendi aşamasının tarihsel kanıtıdır.


**K-022 — Kullanıcının kontrol/gece/rehber düzeltmesi:** Yalnız Bu gece; bütün görünür select/date/time kontrolleri ortak özel tasarım, İstanbul örneği ve sensörsüz hedef yön/yükseklik/dürbün brief'i. Önceki native liste kararı değişti. [ADR-0008](adr/0008-ortak-kontroller-ve-sensorsuz-rehber.md). **K-023 — K-024 ile yürürlükten kaldırılan yerel deney:** Hesapsız favori/not, ayrı opsiyonel bağlar, snapshot, transaction revizyonu/geri alınabilir çöp kutusu/JSON. Hesap aktarımı/PWA/fiziksel kabul devam eder. [ADR-0009](adr/0009-yerel-defter-ve-kayipsiz-duzenleme.md), [UX-02](kisisel-kayit-hesap-cevrimdisi-akislari.md).

**K-021 — TECH-04C / kullanıcı düzeltmeleri:** Bugün/Bu gece zaman çizelgesi ve hedefe navigasyon, kaynaklı Takvim, pusula hedef yardımı, ufuk altı/aşağı bakışta saydam arazi ve 330° stereografik zoom; yerel şehir/ilçe + manuel ad/koordinat/yükseklik. Keşfet düğmesi kaldırılır; ortak arama/FR-03 atlas sürer. [ADR-0007](adr/0007-gozlem-takvimi-ve-yer-adlari.md), [kanıt](gozlem-cizelgesi-ve-takvim.md). Hesaplanan olay ile bağımsız USNO evresi ayrı; tüm ürün/cihaz kabulü değildir.

**Güncelleme:** 1 Kasım 2026
**Amaç:** Kullanıcı kararlarını, başlangıç gereksinimlerini ve araştırılacak konuları birbirinden ayırmak.

Kaynak: [Ürün gereksinimleri](urun-gereksinimleri.md) ve kullanıcının 30 Ekim 2026 tarihli adlandırma/başlama talimatı. Bu kayıt hukuki marka uygunluğu veya alan adı sahipliği doğrulaması değildir.

## Kesinleşen yön

| ID | Karar | Dayanak / etkisi |
|---|---|---|
| K-001 | Ürün adı `yorungez` | Kullanıcı seçti; yörünge + gezmek. Türkçe karakterli yazım teknik ad olarak kullanılmayacak. |
| K-002 | Planlanan alan adı `yorungez.com` | Kullanıcı yakın zamanda satın alacak. Mevcut durum: satın alma bekliyor. |
| K-003 | Harita merkezli astronomi keşfi | Gereksinimler §1–3; temel kullanım hesap ve ekipman gerektirmez. |
| K-004 | Harita merkezli ortak arama ve menü | K-022 ile Gökyüzü/Bu gece/Takvim/Defterim; gereksiz Keşfet düğmesi kaldırıldı, FR-03 atlas kapsamı korunur. Konum seçici/Defterim erişimi sürer. |
| K-005 | Next.js + TypeScript, PWA, ASP.NET Core modüler monolit | Gereksinimler §7; ilk Web sürümleri Next 16.4.3/React 19.3.1/TS 5.9.3 sabit; PWA/dağıtım henüz yok. Python yardımcı doğrulama/veri işleri içindir. |
| K-006 | Önce dokümantasyon, ardından MVP-0 | Gereksinimler §9–10; ilk teknik doğrulama harita, konum/zaman ve nesne deneyimidir. |
| K-007 | Görünürlük üç ayrı değerlendirmedir | FR-05; geometrik durum, koşullar ve algılanabilirlik karıştırılmaz. |
| K-008 | Kişisel veriler varsayılan olarak özel | FR-01, FR-06–07; K-024 ile yalnız doğrulanmış hesaba özel sunucu kaydı, anonim kalıcılık yok. |
| K-009 | Harita, konum hassasiyeti ve pusula birincil teknik öncelik | Kullanıcı 30 Ekim 2026'da teyit etti. Cihaz konumu/GPS ve enlem-boylam işlenecek; kaynak doğruluğu, kullanıcı izinleri ve özel paylaşım kuralları korunur. |
| K-010 | Lisans ücreti gerektirmeyen altyapı önceliği; PostGIS koşullu | Kullanıcı gerektiğinde ücretsiz coğrafi araçlara başvurmayı onayladı. Barındırma/işletim maliyetleri ayrı; PostGIS henüz kurulmadı. |
| K-011 | İlk teknik temel backend host'u/çekirdeği; ilk ürün hedefi harita akışı | [ADR-0001](adr/0001-teknik-temel-ve-ilk-dikey-akis.md): .NET 10 temeli, ardından motor denemesi ve Next.js harita akışı. P0 hesap/üyelik işleri bu doğrulamayı geciktirmez. |
| K-012 | PostGIS çekirdek astronomi bağımlılığı değildir | Kullanıcının özellik ayrımı: göksel konum/görünürlük hesabı astronomi motoruna aittir. Basit koordinat saklama PostGIS istemez; gözlem noktası/alan/arazi sorguları sonraki aşamada değerlendirilir. |
| K-013 | Bütün ürün yüzeyleri Türkçe/İngilizce eşli geliştirilecek | FR-11/AC-13; backend/e-postalar ve ilk harita UI eşli uygulandı. Bütün ürün/hesap/offline/erişilebilirlik kabulü açık. |
| K-014 | Terimler ve kısaltmalar kaynaklı/sade açıklamalarla saklanacak | FR-12/AC-14; 52 tr/en terim ve ilk kart/sözlük penceresi çalışır. Ayrı sözlük/derin bağlantı/ekran okuyucu açık. |
| K-015 | .NET 10, Clean Architecture, CQRS/MediatR, PostgreSQL, Redis ve JWT/e-posta doğrulaması | Kullanıcı açıkça seçti; [ADR-0002](adr/0002-moduler-temel-cqrs-ve-lisanslar.md). MediatR 12.5.0 Apache-2.0 sabit; Identity ve Catalog modülleri, kalıcı oturumlar ve şifreli outbox yerelde sınandı. |

**K-019 — 31 Ekim kullanıcı düzeltmeleri:** Tam ekran harita; kalıcı üst/yan çubuk yok, kapalı sol menü, gri/bordo saydam kartlar. Varsayılan yalnız atmosfer/temsili arazi/DSO açık; çizgi/ad, gerçek kaynaklı çizim, azimutal/J2000 ekvatoral ızgara, gece ve tam ekran kapalı. İzin verilmiş cihaz konumu otomatik tazelenir; hassasiyet/ölçüm zamanı ve manuel/OSM seçimi korunur. Wikipedia özeti/gerçek fotoğraf/isteğe bağlı ayrıntı, rahat zoom/pan ve konuma göre yerel IANA/GMT + UTC birlikte sunulur. İlk an UTC’dir; dil/konum/bölge değişimi anı değiştirmez. [ADR-0005](adr/0005-tam-ekran-konum-ve-yerel-zaman.md), [uygulama ve sınırlar](tam-ekran-harita-gelistirmesi.md). Önceki hedefler, FR/UJ/AC, P0/P1/P2 korunur.

**K-020 — Kullanıcı görünüm düzeltmesi / TECH-04B:** Kaynak UI paleti #3C3F43, #9EA1A6, #8B2333, #C9B6A6, #F7F1E6; beğenilen yerleşim korunur, sol menüde native dil listesi. Düz/pastel arazi yerine kaynaklı gerçek fotoğraf çevre ve daha doğal atmosfer/kadir parlaması; astronomik hesap aynı kalır. Mevcut sonraki pusula basamağı izin/süre/hizalama aracıyla uygulanır, fiziksel kabul açık. [ADR-0006](adr/0006-fotograf-cevre-ve-pusula-siniri.md), [kanıt/kalanlar](dogal-gorunum-ve-pusula.md).

## Öneriler ve açık kararlar

**K-016:** İlk sınırlı hesap adaptörü Astronomy Engine 2.1.19 (MIT), [ADR-0003](adr/0003-ilk-astronomi-adaptoru-ve-dogruluk-sinirlari.md). C#/JS eşliği/JPL örnekleri; iki kutup yön istisnası korunur. **K-017:** SMTP göndereni `sender@example.com`; parola bekleniyor, placeholder ve gerçek Gmail gönderimi kapalı. **K-018:** İlk Canvas 2D/stereografik harita, HYG 4.1/d3-celestial verisi ve Worker/BFF dağılımı [ADR-0004](adr/0004-ilk-harita-ve-parlak-katalog.md). 144 Astropy referansı ve IAB deneyi; geniş katalog/fiziksel cihaz/offline kabulü açık.

| ID | Konu | Durum | Gerekli kanıt / sonraki işlem |
|---|---|---|---|
| A-001 | Açık kaynak kod lisansı | Apache-2.0 seçildi / K-029 | Kullanıcı açıkça seçti; özgün kod/belgeye uygulanır, üçüncü taraf lisansları korunur. ADR-0014. |
| A-002 | Harita motoru ve projeksiyon yaklaşımı | İlk prototip seçildi; cihaz/tam performans açık | ADR-0004/0005: Canvas 2D/stereografik; ortak SVG/WebGL deneyi, yeni katmanlar ve sınırlı yerel başlangıç ölçümü. Fiziksel mobil, tam kare/açılış/bellek ve ekran okuyucu açık. |
| A-003 | Astronomi hesaplama motoru | İlk adaptör seçildi; geniş doğrulama açık | ADR-0003: dokuz hedef, sınırlı teknik tarih aralığı, JPL örnekleri ve port eşliği. Kutup yönü, geniş hedef/tarih, standart doğuş-batışın geniş rakım/ufuk doğrulaması ve daha hassas zaman/Dünya yönelimi hâlâ açık (ilk 0 m çizelge ADR-0007 ile eklendi). |
| A-004 | PostgreSQL ve gerekirse PostGIS | PostgreSQL seçildi/yerelde kuruldu; PostGIS koşullu açık | PostgreSQL 18.6 ve Identity migration'ı gerçek servisle doğrulandı. PostGIS tip/SRID/indeks/kaynak ve sorgu ihtiyacı sonraki aşamada gerekçelendirilecek; henüz kurulmadı. [Özellik matrisi](bilimsel-veri-stratejisi.md). |
| A-005 | Katalog kapsamı ve içerik lisansları | İlk parlak yıldız/takımyıldız dilimi seçildi; geniş kapsam açık | HYG 4.1/d3 verisi: 5073 yıldız/88 iki dilli figür, CC BY-SA 4.0/BSD ve atıflar. TECH-04: 107 OpenNGC Messier eşleşmesi, 85 FAL çizimi, lisanslı Sun Wikipedia/Commons paketi eklendi. Tam katalog, otomatik yenileme ve kalite genişlemesi açık. |
| A-006 | Hesap zorunlu kişisel kalıcılık | K-024/ADR-0010; PostgreSQL, revizyon ve sahiplik uygulandı | Kalıcı silme/kota/içe aktarma/DB backup kabulü açık; anonim ve offline kişisel yazma kaldırıldı |
| A-007 | Konum yüksekliği, ufuk ve kırılma varsayımları | Açık | MVP-0/P0 hesap kapsamı; P1 yerel ufuk profilleriyle sınırın tanımlanması |
| A-008 | Hava ve ışık kirliliği kaynakları | Açık | P1 veri kapsamı, lisans, kapsanan tarih/konum, yenileme ve hata davranışı |
| A-009 | Doğruluk toleransları ve mobil performans bütçesi | İlk örnek tolerans/ölçüm var; geniş bütçe açık | 144 yıldız için 1 yay dakikası hedefi, JPL sınırları, IAB CPU nokta katmanı ölçümü. Fiziksel cihaz/tam kare/açılış/bellek ve bütün model toleransları açık. |
| A-010 | Barındırma, alan adı ve işletim | Açık | Alan adı satın alma; dağıtım, e-posta ve veri yenileme maliyetleri; henüz canlı ortam yok |
| A-011 | İlk kullanım için örnek konum | Prototipte etiketli İstanbul; üretim araştırması açık | Örnek kullanıcı konumu değildir; önceden izinli cihaz konumu tazelenir veya manuel/OSM ile değiştirilir. İlk kullanım gerçek kullanıcı/izin akışıyla değerlendirilecek. |
| A-012 | Keşif başarı ölçütleri | Değerlendirme protokolü hazır; ölçüm bekliyor | [Ürün keşfi ölçüm planı](urun-kesfi.md#başarı-ölçümü-taslağı) ve [sekiz görev kartı](kullanici-gorevleri.md); katılımcı oturumu ve sayısal eşikler henüz yok |
| A-013 | Kişisel kayıtların minimum içeriği ve yaşam döngüsü | Minimum model ADR-0011 ile seçildi/uygulandı; ileri bağlar açık | [Bağlam matrisi](baglam-ve-sinir-durumlari.md): isteğe bağlı bağlar, oluşturma/gözlem zamanı ve geçmiş anlamının korunması; açıklama+beyan, tek isteğe bağlı hedef/an/konum kopyası, geri alınabilir çöp ve export v2 seçildi; ekipman/olay/çoklu hedef, kalıcı silme/içe aktarma/kota açık |
| A-014 | Yerel tarih/saat girişinin yorumlanması | Yazılım sözleşmesi seçildi/uygulandı; veri bakımı/cihaz kabulü açık | ADR-0005: UTC anı korunur; konumdan geo-tz/all IANA, yerel/GMT/UTC birlikte, yerel/UTC giriş, Temporal boş saat reddi/çift saat oluşum seçimi. Çözümsüz/çoklu bölge görünür UTC/elle seçim. DST ve ülke örnekleri testli; gelecekteki yasal bölge/ofset değişimleri için veri güncelleme ve fiziksel cihaz kabulü açık. |

## Kararların kaydedilmesi

Bir açık konu çözüldüğünde kanıt, tarih, seçenekler, seçimin gerekçesi ve etkilenen FR/UJ/AC kimlikleri eklenir. Önemli mimari/veri kararları ayrıca ADR ile belgelenir. Araştırma tamamlanmadan adaylar seçilmiş bağımlılık olarak yazılmaz.

**K-024 — Kullanıcının kesin düzeltmesi:** Not/favori ve diğer envanter kayıtları için hızlı üyelik, e-posta doğrulama ve giriş zorunlu; PostgreSQL sahibi hesap. Tarayıcı kişisel kalıcılığı ve anonim aktarım hedefi kaldırıldı. Takvim/Bu gece ve diğer alt panellerde menüye geri dönüş. [ADR-0010](adr/0010-hesap-zorunlu-defter-ve-sunucu-kayitlari.md).

**K-025 — İngilizce varsayılan ve e-posta:** Gönderen `sender@example.com` olarak düzeltildi. Sır yalnız özel `.env`/sunucu ortamında, örneklerde placeholder. Yeni kayıt/kurtarma e-postaları her zaman İngilizce markalı HTML+plain; uygulama/API en varsayılan, açık tr korunur. Google TLS/AUTH kontrolü başarılı, gerçek alıcıya deneme iletisi gönderilmedi. [Uygulama/dağıtım sınırları](eposta-ve-varsayilan-dil.md).

**K-026 — Onaylanan P0 envanter devamı:** Ayrı `observation`/`place` türleri yalnız doğrulanmış hesabın PostgreSQL alanında. Gözlem minimumu açıklama+kişisel beyan; nesne/gerçek zaman/konum isteğe bağlı, simülasyon ve sistem zamanı otomatik gözlem olmaz. Konum bağı bağımsız kopyadır, yer değişikliği geçmişi değiştirmez. Haritada kullanma aynı UTC an/mod/hedef/kamerayı korur; bilinmeyen yükseklik bilinmiyor, yeni kaynaklı elipsoidal yükseklik terimiyle 52 kayıt. [ADR-0011](adr/0011-gozlem-kaydi-ve-kayitli-konumlar.md). Kalıcı silme/kota/import/üretim backup, fiziksel cihaz ve genel katalog PWA kabulü açık.

**K-027 — Kullanıcı hesap düzeltmesi:** Menüde giriş/kayıt veya ad-soyad. Yeni kayıt ad/soyad/e-posta/parola, eski hesapta isim tamamlama; servis/çevrimdışı/anonim durumları ayrı, ortak yerel başlatıcı. [ADR-0012](adr/0012-hesap-menusu-ve-ad-soyad.md).

**K-028 — Onaylanan genel offline devamı:** Yalnız genel katalog/terim/takvim/arayüz/hesaplama ve kaynaklı genel görseller sürümlü/hash kontrolüyle PWA paketinde. Kişisel kalıcı offline veri yok. Açık güncelleme/taslak uyarısı, fiziksel/çok tarayıcı/üretim kabulü ayrı. [ADR-0013](adr/0013-genel-gokyuzu-pwa-ve-cevrimdisi-paket.md).
