# yorungez — Yol haritası ve başlangıç iş listesi

**K-036 / TECH-11C (2 Kasım 2026):** Kullanıcı yeni alanlar yerine mevcut deneyimin derinleştirilmesini önceliklendirdi. Aynı 52 kaynaklı terim ortak bileşende iki dilden aranır; kartta tam terim odağı/geri dönüş, ayrı statik sözlük, sabit terim bağlantıları ve genel PWA kapsamı geliştirildi. 55 istemci testi, tip/üretim derlemesi ve iki dil/320 px/sunucusuz sözlük kontrolü geçti. [Kanıt ve kalan kabul işleri](sozluk-ve-terim-baglantilari.md). Diğer P0/P1/P2 hedefleri ve K-032 beklemesi korunur.

**K-035 / TECH-11B (2 Kasım 2026):** Giriş/kayıt başlıkları ve alan hizası düzeltildi; iki dilde canlı/simülasyon/eski hesap durumu, sonuç UTC anı ve özgün katalog/olay hazırlanma tarihleri kaynak paneline eklendi. 53 istemci testi, tip kontrolü, üretim derlemesi ve 320 px/PWA yeniden açılış kontrolü geçti. Sürekli olay akışı henüz bağlı değil; geniş atlas/kaynak yenileme FR-08/P1 işidir. [Uygulama, canlı API envanteri ve sınırlar](canli-hesap-ve-veri-guncelligi.md). Önceki P0/P1/P2 ve K-032 beklemesi korunur.

**K-034 / TECH-11A (2 Kasım 2026):** İki dil/klavye ilk denetim paketi: seçimde Home/End başlangıç odağı, hesap görünümü değişiminde başlık odağı/etkin durum, parola ve tarih yardım ilişkileri düzeltildi. 51 istemci testi, tip kontrolü ve üretim derlemesi; iki dilde IAB klavye/320 px kontrolü geçti. [Kanıt ve açık kabul işleri](iki-dil-klavye-denetimi.md). Tam ekran okuyucu/kontrast/E2E/sözlük ve K-032 fiziksel/üretim işleri açık kalır.

**K-033 / TECH-10 (2 Kasım 2026):** Yerel sentetik PostgreSQL yedek/geri yükleme provası uygulandı: iki ayrı test DB, dört kayıt türü/sahiplik/revizyon, kopya şifreli keyring+test sertifikası, bozuk arşiv/eksik anahtar retleri, kuyruk ve oturum iptali/yeni giriş; 127 .NET testi geçti. Gerçek veriler/normal uygulama değişmedi; üretim backup kabulü ve K-032 deployment/HTTPS beklemesi sürer. [Kanıt ve tekrar çalıştırma](yerel-yedek-geri-yukleme.md). Sırada iki dil/erişilebilirlik yerel paketi var.

**K-032 (2 Kasım 2026):** Kullanıcı deployment, HTTPS erişimi ve uygulamanın canlı yayınını kendisi yeniden haber verene kadar erteledi; alt alan adı yalnız olası ileriki seçenektir. Buna bağlı fiziksel cihaz kabulü bekler. Sıradaki yerel paket: test verisiyle yedek/geri yükleme, ardından iki dil/erişilebilirlik, kayıt yaşam döngüsü ve ölçüm; P1/P2 hedefleri korunur. [Yerel çalışma sırası ve sınırlar](yayin-oncesi-yerel-plan.md).

**K-031 / TECH-09 (2 Kasım 2026):** Kullanıcının dört marka kaynağı web başlığı/menü/hesap, PWA (any/maskable/Apple touch), favicon ve gömülü e-posta logosuna bağlandı; kaynaklar ve içerik hash'leri korunur. Görsel Yörüngez yazımı sağlandığı gibi, teknik/erişilebilir ad yorungez. [Uygulama ve kanıt](marka-logolari.md), [kaynaklar](../data/branding/README.md). Fiziksel GPS/pusula/PWA ve önceki açık kabul işleri sürer.

**K-030 / TECH-08 (1 Kasım 2026):** Responsive safe-area/VisualViewport, anında geçersiz sensör/hizalama temizliği ve PWA açılış/geri dönüş kontrolü uygulandı; 49 istemci testi ve üretim derlemesi geçti. IAB/Brave kontrolleri fiziksel kabul değildir; S23/Chrome ve iPhone 15/Safari oturumu, erişilebilir HTTPS adresi henüz olmadığı için bekliyor. [Kanıt ve sınırlar](responsive-cihaz-ve-pwa-kabulu.md), [telefon kartı](telefon-kabul-oturumu.md), [ADR](adr/0015-responsive-sensor-ve-pwa-kabulu.md). Önceki plan ve bilimsel sınırlar korunur.

**K-029 / açık kaynak yayın (1 Kasım 2026):** Özgün kod ve özgün proje belgeleri Apache-2.0; üçüncü taraf veri/görseller kendi lisanslarında. Public kaynak hedefi `YeloraStudio/yorungez`; gerçek ortam/SMTP/Portainer/veritabanı verileri özel kalır. Public metinlerde `sender@example.com` redakte örnektir, gerçek gönderen özel yapılandırmadadır; tarihsel SMTP başarı kaydı örnek hesabın kullanıldığı anlamına gelmez. [Karar](adr/0014-acik-kaynak-yayin-ve-apache-2.md), [yayın incelemesi](open-source-publication.md). Önceki ürün planı ve açık kabul işleri korunur.

**Güncel TECH-07 / K-027–028 (1 Kasım 2026):** Menüde giriş/kayıt veya doğrulanmış oturumun ad-soyadı; kayıt için ad/soyad/e-posta/parola. Servis hatası ve çevrimdışı durum ayrıldı, ortak yerel başlatıcı eklendi. Genel katalog/terim/takvim için hash doğrulamalı PWA paketi ve yeniden açılış uygulandı; kişisel kayıt/oturum/koordinat cache'e girmez. 125 .NET/44 istemci testi; fiziksel cihaz/üretim backup kabulü açık. [Uygulama ve kanıt](hesap-menusu-ve-cevrimdisi-gokyuzu.md), [hesap ADR](adr/0012-hesap-menusu-ve-ad-soyad.md), [PWA ADR](adr/0013-genel-gokyuzu-pwa-ve-cevrimdisi-paket.md).

**Güncel K-026 / TECH-06 (1 Kasım 2026):** Hesap envanterinde not/favori yanında ayrı gözlem ve kayıtlı konum uygulandı. Gözlem açıklama + kişisel beyan ister; gerçek zaman/nesne/konum isteğe bağlıdır, simülasyon zamanı kendiliğinden bağlanmaz. Konum kopyası geçmişi korur; haritada kullanım an/mod/hedef/kamerayı korur. 120 .NET + 38 istemci testi ve üretim derlemesi geçti; 52 tr/en terim/cache .7. [Uygulama ve sınırlar](gozlem-kayitlari-ve-kayitli-konumlar.md), [ADR-0011](adr/0011-gozlem-kaydi-ve-kayitli-konumlar.md). Fiziksel cihaz, genel katalog PWA/offline ve üretim backup kabulü açık; kişisel tarayıcı kalıcılığı yoktur.

**Güncel K-025 / TECH-05B:** Gönderen `sender@example.com`; parola yalnız özel kök `.env`, Gmail STARTTLS/AUTH kontrolü başarılı (ileti gönderilmedi). İşlem e-postaları İngilizce markalı HTML + düz metin, uygulama/API varsayılan dili İngilizce; açık Türkçe seçimi korunur. [Güncel paket](eposta-ve-varsayilan-dil.md). Önceki SMTP placeholder ve iki dilde e-posta hükümleri bu kararla değişti.


**Güncel K-024 / TECH-05:** Kişisel kayıt için doğrulanmış hesap zorunlu; anonim/IndexedDB kişisel kalıcılığı kaldırıldı. Not ve favoriler kullanıcıya bağlı PostgreSQL modülünde; TR/EN kayıt/giriş/doğrulama/sıfırlama ve panel geri dönüşü bağlıdır. [Uygulama ve sınırlar](hesap-ve-sunucu-defteri.md), [ADR-0010](adr/0010-hesap-zorunlu-defter-ve-sunucu-kayitlari.md). Aşağıdaki eski paket kayıtları kendi aşamasının tarihsel kanıtıdır.


**Önceki TECH-04D + UX-02A:** [Özel kontroller/gece/sensörsüz rehber](ortak-bilesenler-ve-sensorsuz-gozlem.md) ve [yerel Defterim/hesap/çevrimdışı akışları](kisisel-kayit-hesap-cevrimdisi-akislari.md). 33 istemci testi ve üretim derlemesi; önceki93 .NET/bilimsel kaynak temeli korunur. Dokuz ADR. İlk yerel favori/not tamamlandı; hesap/aktarım, gözlem/kayıtlı yer, service worker ve gerçek cihaz kabulü sırada.

**TECH-04C uygulandı:** [Çizelge/takvim/yer adı/saydam geniş açı](gozlem-cizelgesi-ve-takvim.md), [ADR-0007](adr/0007-gozlem-takvimi-ve-yer-adlari.md); 93 .NET +29 istemci testi/üretim derlemesi, 1781 USNO evresi ve 22 standart doğuş-batış örneği. 51 terim; yedi ADR. Sıradaki gerçek cihaz protokolü ve UX-02; meteor/asteroit/Ay–yıldız olay kaynağı P1 genişlemesi. Tam MVP-0/P0 kabulü açık.

**Güncelleme:** 1 Kasım 2026
**Kaynak:** [Ürün gereksinimleri](urun-gereksinimleri.md), §9–10.  
**Mevcut aşama:** Modüler backend + tr/en tam ekran harita, hesap zorunlu dört kayıt türü (favori/not/gözlem/konum), 5073 yıldız/88 figür/9 Güneş Sistemi hedefi/107 Messier eşleşmesi/85 çizim/52 terim. İzinli GPS ölçümü, OSM nokta seçimi, IANA yerel/UTC, kaynaklı Wikipedia kartı ve süre sınırlı açılış uygulandı. 120 .NET + 38 istemci testi ve üretim derlemesi geçti; önceki 144 yıldız + 72 DSO referans temeli korunur. Kutup yönü, fiziksel cihaz/GPS/pusula, PWA ve tam MVP-0 kabulü açık. [TECH-04 kanıtı](tam-ekran-harita-gelistirmesi.md).

## Yol haritası

| Aşama | Mevcut kanıt | İlerlemek için gerekli çıktı |
|---|---|---|
| **1. Product Discovery** | PRD, kaynaklı ilk ürün keşfi, sekiz görev kartı ve değerlendirme formu var. Gerçek kullanıcı oturumu yok. | Temsilî kullanıcı görevleriyle değer önerisi/ilk kullanımın değerlendirilmesi; başarı ölçütlerinin netleştirilmesi |
| **2. Domain Discovery** | Alan sözlüğü, iş kuralları, 35 sınır durumu, keşif bağlamı ve kişisel kayıt yaşam döngüsü taslağı var. | Minimum alanlar, ilişki çoklukları, geçmiş kayıt bağları, motor kapsamının geniş doğrulanması, kişisel veri ve senkronizasyon politikalarının kesinleştirilmesi |
| **3. UX / Information Architecture** | Sitemap, 12 yüzeylik envanter, dört temel akış, durum metinleri ve üç SVG/PNG wireframe var. | UX-02 kişisel kayıt/hesap/çevrimdışı ekranları; gerçek görev değerlendirmesi, erişilebilirlik ve cihaz doğrulaması |
| **4. Architecture & Data Strategy** | On üç ADR; modül/katman sınırları, PostgreSQL/Redis/kimlik, Astronomy Engine ve Canvas/HYG/d3 ilk dilimi. Kaynak/lisans ve donmuş referanslar var. | Fiziksel cihaz performansı, geniş bilimsel doğrulama, kalıcı kişisel veri/senkronizasyon ve offline stratejisi |
| **5. Delivery Planning** | İlk teknik temel işi uygulanıp sınandı; kalan MVP-0/P0 için ayrıntılı backlog henüz tamamlanmadı. | FR/UJ/AC izlenebilirliği, bağımlılıklar, test planı, sürüm çıkış ölçütleri ve CONTRIBUTING.md |
| **6. MVP-0** | İlk anonim konum/zaman → harita → arama/seçim → kart/terim akışı tr/en çalışıyor. | GPS izin/ret/doğruluk akışının fiziksel cihazda kabulü, ekran okuyucu/kullanıcı görevleri ve tam performans bütçesi; bütün MVP-0 tamamlanmadı |

Bir taslağın dosya olarak bulunması aşamanın tamamlandığı anlamına gelmez. Gerekli çıktı ve doğrulama kanıtı oluştukça bu tablo güncellenir. Araştırma veya rutin uygulama seçimleri için ayrıca bir genel onay kapısı eklenmez; gerçek ürün kararları ve çözülemeyen belirsizlikler açıkça ele alınır.

## Başlangıç iş listesi

| İş | Durum | Somut çıktı / bitiş ölçütü | İz |
|---|---|---|---|
| **DISC-01** — Ürün kimliği ve kaynakların düzenlenmesi | Tamamlandı | yorungez adı, planlanan alan adı, güncel gereksinimler ve değişmemiş başlangıç arşivi | K-001–002; gereksinimler §1 |
| **DISC-02** — Benzer ürünlerin masa başı incelemesi | İlk kapsam tamamlandı | Üç resmî kaynak ve sınırlı bulgular; kullanım testiyle doğrulanmayan noktalar ayrılmış | Gereksinimler §10, ürün keşfi |
| **DISC-03** — Görev ve başarı ölçütlerinin doğrulanması | Protokol hazır; yürütülmedi | [Sekiz görev kartı ve gözlem formu](kullanici-gorevleri.md); gerçek değerlendirme, eşikler ve sonuç kaydı bekliyor | UJ-01–03, UJ-06; AC-01–06, AC-11; A-009, A-012 |
| **DOM-01** — Alan sözlüğü ve iş kuralları | Davranış modeli genişletildi; açık kararlar var | [35 sınır durumu ve yaşam döngüsü](baglam-ve-sinir-durumlari.md); ADR-0011 minimum gözlem/konum ve bağımsız kopyayı seçti; ileri çokluk/ekipman/olay, kota/import/purge/backup açık; saat politikası ADR-0005 | FR-01, FR-03–08; AC-03, AC-06–09; A-006, A-013–014 |
| **UX-01** — Harita ve bilgi kartı akışları | İlk taslak + TECH-04 çalışan tam ekran yüzeyi | [Ekran envanteri, akışlar ve üç wireframe](ux-akislari.md); gerçek görev/cihaz/erişilebilirlik değerlendirmesi henüz yok | UJ-01–03, UJ-06; AC-01–06, AC-11 |
| **UX-02** — Kişisel kayıt ve çevrimdışı akışlar | Hesap zorunlu dört kayıt türü ve hesap UI uygulandı; genel offline devam ediyor | Hızlı üyelik/giriş, doğrulama, hesaba özel kayıt, revizyon çakışması, bağlantı gereği ve genel katalog offline ekranları; KG-07–08 ve SN-P/SN-D durumları başlangıç girdisi | UJ-04–05, UJ-07; AC-07–10, AC-12 |
| **DATA-01** — Motor ve veri kaynaklarının değerlendirilmesi | İlk hesap ve parlak katalog/çizim dilimi seçildi | ADR-0003/0004/0005, HYG/d3/OpenNGC/çizim/Wikipedia lisans/hash/atıf, 144 yıldız + 72 DSO Astropy ve önceki JPL referansı; Canvas/SVG/WebGL IAB ölçümü. Fiziksel mobil/geniş katalog ve tam offline açık; PostGIS kurulmadı. | FR-02–05, FR-08–09; A-001–005, A-007–009 |
| **ARCH-01** — Mimari görünüm ve ADR'ler | İlk backend/hesap/harita sınırları uygulandı | ADR-0002/0003/0004/0005: Identity, Catalog, Astronomy, Notebook, BFF ve Worker; yerel IANA ve hesap sahibi/revizyon sınırları. Üretim backup/işletim/ileri veri akışları açık. | Gereksinimler §7; FR-06–09, FR-11–12; A-004, A-006, A-010 |
| **PLAN-01** — Uygulamaya hazır backlog | Katkı/kurulum ve bilimsel doğrulama rehberi hazır; kalan işler açık | Kabul senaryoları, bağımlılıklar, özellik bazlı test/ölçüm ve sürüm çıkış kanıtları derinleştirilecek | Gereksinimler §9–10; AC-01–14 |
| **TECH-01** — Backend host'u ve koordinat çekirdeği | Tamamlandı; sınırlı temel | [Teknik başlangıç](teknik-baslangic.md): Release build 0 uyarı/0 hata, 18 koordinat testi ve yerel HTTP kontrolü başarılı. Tam ürün kabul kriterleri geçti anlamına gelmez. | FR-01; SN-K03–04; K-009–011 |
| **FOUND-01** — Modüler kalıcılık/kimlik | Backend temeli tamamlandı | Gerçek PostgreSQL migration'ı, Redis, Identity/JWT/refresh, doğrulama/sıfırlama ve şifreli e-posta outbox; ilk aşamada 28 API/entegrasyon testi, yerel SMTP ile tr/en HTTP akışı; güncel toplam 83 API testi; Notebook kişisel kayıt modülü ve ADR-0011 eklendi. Üretim dağıtımı/backup kabulü açık. | FR-07–08; AC-08–09; K-015 |
| **FOUND-02** — Yerelleştirme/terimler | Backend ve ilk harita UI hazır; kabul kısmi | 52 kaynaklı terim, kart bağlantıları, bağlamı koruyan tr/en geçiş, klavye/ESC odak dönüşü. Ayrı sözlük/derin bağlantı/ekran okuyucu ve bütün ekranlar açık. | FR-11–12; AC-13–14; K-013–014 |
| **MVP0-01** — Dikey prototip | İlk akış uygulandı; tam çıkış açık | [Harita kanıtı](harita-ve-katalog-denemesi.md): manuel konum/UTC/canlı/arama/seçim/kart; fiziksel cihaz, izin/sensör, erişilebilirlik ve ölçüm bütçesi açık. | FR-01–05; UJ-01–03, UJ-06; AC-01–06, AC-11 |
| **TECH-04C** — Çizelge, takvim, yer adı ve ufuk altı | Yazılım ve sınırlı referans/tarayıcı doğrulaması tamamlandı | [Uygulama](gozlem-cizelgesi-ve-takvim.md); 2623 olay/1781 USNO evre kontrolü, 22 standart doğuş-batış referansı; yerel GeoNames, 330° ve saydam arazi. Geniş kaynak/cihaz kabulü açık. | FR-01–05/FR-08/FR-11–12; K-021 |
| **TECH-06** — Gözlem ve kayıtlı konum | Yazılım, migration ve sınırlı API/tarayıcı doğrulaması tamamlandı | [Uygulama/kanıt](gozlem-kayitlari-ve-kayitli-konumlar.md), ADR-0011; açık gerçek zaman girişi, kişisel beyan, bağımsız konum kopyası, haritada bağlam koruma, export v2. 120 .NET/38 istemci testi; fiziksel cihaz/üretim/ileri bağlar açık. | FR-01/FR-04/FR-06–07/FR-09/FR-11–12; UJ-03–05/UJ-07; K-026 |
| **TECH-07 / UX-02C** — Hesap menüsü ve genel PWA | Ad-soyad/ortak oturum ve genel çevrimdışı paket uygulandı | [Kanıt](hesap-menusu-ve-cevrimdisi-gokyuzu.md); 125 .NET/44 istemci, hash/başarısız paket/özel veri hariç tutma, sunucusuz yeniden açılış. Fiziksel/üretim kapsamı açık. | FR-07/FR-09/FR-11; UJ-04/UJ-07; AC-07–09/AC-12–13; K-027–028 |
| **TECH-10** — Yerel yedek/geri yükleme | Sentetik yerel prova geçti | [Kanıt](yerel-yedek-geri-yukleme.md); arşiv/iki DB/keyring/sertifika/sahiplik/revizyon/kuyruk/oturum kontrolü, 127 .NET testi. Üretim kabulü açık. | FR-06–09; AC-07–09; A-006; K-033 |

| **TECH-11B** — Hesap formu ve canlı veri durumu | Yerel paket geçti | [Kanıt ve çalışan API envanteri](canli-hesap-ve-veri-guncelligi.md); 53 istemci testi, başlık boşlukları, iki dil/320 px, canlı-simülasyon/özgün kaynak tarihleri ve genel PWA yeniden açılışı. Sürekli olay akışı/kaynak yenileme tamamlanmadı. | FR-02–05/08–09/11; K-035 |

| **TECH-11C** — Mevcut sözlüğü derinleştirme | Yerel paket geçti | [Kanıt](sozluk-ve-terim-baglantilari.md); 52 terim için ortak panel/sayfa/çapraz arama/bağlantı/odak/PWA, 55 istemci testi. Ekran okuyucu ve tüm yüzeylerin kabulü açık. | FR-09/11–12; AC-11–14; K-036 |

## Sıradaki çalışma paketi

K-032 ile deployment/HTTPS/canlı yayın ve buna bağlı fiziksel telefon oturumu beklemede. **Yerel test verisiyle DB yedek/geri yükleme provası TECH-10 ile geçti.** K-036 ile öncelik mevcut yüzeyleri derinleştirmektir. Sözlük/terim bağlantıları TECH-11C ile uygulandı; sırada kalan iki dil/erişilebilirlik, ardından kişisel kayıt yaşam döngüsü ve tekrarlanabilir performans ölçümü var. P1 ek olay kaynakları, atlas, görünürlük ve veri yenileme; P2 ekipman/ileri planlama sırası korunur. [Güncel çalışma sırası](yayin-oncesi-yerel-plan.md), [hesap/PWA ayrıntısı](kisisel-kayit-hesap-cevrimdisi-akislari.md).

**TECH-02A — İlk hesap adaptörü:** Uygulandı; [ADR-0003](adr/0003-ilk-astronomi-adaptoru-ve-dogruluk-sinirlari.md). 12 konum/dört günlük seri, 1.168 JPL karşılaştırması, iki korunmuş kutup istisnası, C#/JS eşliği, offline tekrar üretim ve iki dilli anonim API. TECH-02B/03 ilk katalog/çizim/UI ekledi; güncel terim sayısı 52 (TECH-06). TECH-02 bütünü henüz tamamlanmadı; gerçek cihaz ve geniş bilimsel doğrulama açık. [FR/UJ/AC izlenebilirliği](teslimat-izlenebilirligi.md) kalan ayrıntıları korur.

1. **TECH-02B/03:** İlk çizim/parlak katalog ve tr/en Next.js harita akışı [ADR-0004](adr/0004-ilk-harita-ve-parlak-katalog.md) ile uygulandı. Canvas/SVG/WebGL deneyi, 144 yıldız referansı, ortak kimlik/kart ve TR/EN bağlamı kanıtlı; fiziksel mobil/tam kare/ilk yükleme/bellek, ekran okuyucu ve geniş bilimsel kapsam açık.
2. **TECH-04 / FR-01–04 / UJ-01–03, UJ-06:** [Tam ekran/konum/zaman paketi](tam-ekran-harita-gelistirmesi.md) uygulandı: açılış korumaları, kullanıcı katman varsayılanları, kaynaklı çizim/DSO/Wikipedia, izinli GPS/manuel/OSM ve IANA/Temporal. TECH-04B ile fotoğraf çevre/atmosfer/yıldız ışığı/palet/dil listesi ve düz telefon pusulası yazılımı eklendi. Sırada [gerçek cihaz GPS/pusula protokolü](cihaz-konum-pusula-dogrulamasi.md); fiziksel izin/ret/doğruluk/ekran yönü/kalibrasyon ve performans kabulü var. Geliştirici testi gerçek cihaz kabulü değildir; testte kullanıcının gerçek konumu okunmadı.
3. **UX-02 / DISC-03 / DOM-01:** P0 kişisel kayıt, hesap ve çevrimdışı ekranları ayrıntılandırmak; hazır görev protokolü ve açık kararları gerçek kanıtla derinleştirmek. İlk backend'in oluşması kullanıcı araştırması veya tüm mimari kararların tamamlandığı anlamına gelmez.

Bu işler ana kapsamı değiştirmez. Motor araştırması için gerekli sorular keşifte toplanır; kanıtsız bir sağlayıcı veya teknoloji sürümü kesinleştirilmez.

## MVP-0 teknik çıkış ölçütleri

Bunlar ilk teknik prototipin doğrulama planıdır; tamamlanmış sonuçlar değildir. P0 kapsamının tamamını MVP-0'a taşımaz.

| Ölçüt | Gerekli kanıt | İz |
|---|---|---|
| Hesapsız başlangıç ve konum | Örnek konumun etiketli olması; GPS reddi sonrası geçerli manuel koordinatla keşif | AC-01–02 |
| Ortak konum/zaman bağlamı | Sabit referans senaryolarında harita ve kartın aynı girdiyi kullanması; özellik bazlı doğruluk toleranslarının raporlanması | AC-03; A-003, A-007, A-009 |
| Aynı nesneye iki giriş | Harita ve aramadan seçilen hedefin aynı kimlik, bilgi kartı ve hesap bağlamına ulaşması | AC-04 |
| Zaman modu | Canlı/simülasyon ayrımı ve tek eylemle şimdiye dönüş | AC-05 |
| Ufuk altı açıklaması | Hedefin yanlış biçimde görünür sunulmaması; bilinmeyen koşulların açık olması | AC-06, FR-05 |
| Mobil ve masaüstü etkileşim | Kaydırma/zoom/seçim, manuel yönlendirme ve panel davranışları; sensör yokluğu senaryosu | AC-11, UJ-06 |
| İki dil ve anlaşılır terimler | Aynı keşif akışının tr/en tamamlanması, bağlamı koruyan dil değişimi, klavye/dokunmayla terim açıklaması | AC-13–14, FR-11–12 |
| Harita performansı | Belirlenecek cihaz/işlem bütçesine göre kaydırma, zoom, seçim ve zaman değişimi ölçümleri; erişilebilir metinsel bilgi yaklaşımının değerlendirilmesi | Gereksinimler §8; A-009 |

## Sonraki sürümler

- **P0:** Kaynak belgedeki ilk herkese açık kullanılabilir sürüm. K-024 ile hesap zorunlu sunucu kişisel kayıtları ve genel katalog PWA/çevrimdışı davranışları dahil; AC-01–14 ilgili uçtan uca senaryolarla ele alınır.
- **P1:** Geniş katalog ve olay takvimi, hava/ışık kirliliği, gözlem pencereleri, yerel ufuk ve daha güçlü çevrimdışı işlevler.
- **P2:** İsteğe bağlı ekipman, görüş alanı simülasyonu, ileri koordinatlar ve uzman planlama.

## Değişiklik ve doğrulama kaydı

31 Ekim 2026 — TECH-04B: PRD 1.4.1/K-020/ADR-0006; kullanıcı paleti/native dil listesi, gerçek kaynaklı fotoğraf çevre/atmosfer/yıldız halesi, izin/veri/hizalama korumalı düz pusula. 43 eşli terim/cache .5; 84 .NET + 24 istemci testi ve üretim derlemesi geçti. [Uygulama/ekranlar/sınırlar](dogal-gorunum-ve-pusula.md), [yürütülmemiş fiziksel protokol](cihaz-konum-pusula-dogrulamasi.md). Eski kayıtlar kendi aşamasının kanıtıdır.

31 Ekim 2026 — TECH-04: PRD 1.4/K-019/ADR-0005; tam ekran kapalı menü/gri-bordo, katmanlar/107 DSO/85 çizim, kaynaklı Wikipedia kartı, izinli GPS ve OSM, IANA/GMT/UTC/DST ve başlangıç süre/Worker kurtarması uygulandı. 84 .NET + 19 istemci testi ve üretim derlemesi geçti; 72 DSO referansı/yerel IAB kanıtı kayıtlı. [Sonuçlar ve sınırlar](tam-ekran-harita-gelistirmesi.md). Gerçek cihaz/pusula, geleneksel olaylar/PWA/kişisel kayıt ve tüm FR/UJ/AC kalanları açık. Aşağıdaki kayıtlar tarihsel aşama sonuçlarıdır.

31 Ekim 2026 — TECH-02B/03: PRD 1.3.2, ADR-0004, 5073 yıldız/88 figür, 144 Astropy referansı, üç çizici IAB deneyi ve ilk tr/en harita/kart/terimler. 82 .NET + 9 istemci testi, Next üretim derlemesi, HTTP katalog SHA/304/fallback ve geliştirici UI kontrolleri geçti. [Kanıt/sınırlar](harita-ve-katalog-denemesi.md). Sıradaki TECH-04; fiziksel cihaz/PWA/ekran okuyucu/gerçek kullanıcı ve bütün FR/UJ/AC kalanları açık. Tarihsel kayıtlar aşağıda değiştirilmeden korunur.

31 Ekim 2026, sonraki basamak — TECH-02A: Astronomy Engine 2.1.19 ilk sınırlı hesap adaptörü, JPL referansları, port eşliği, yerel desktop hesap/boyut ölçümü ve ADR-0003. 79 test geçti (18 çekirdek/19 astronomi/42 API). İki kutup yön başarısızlığı raporda korundu; API bu bölgede azimut sunmuyor. Koşullar bilinmiyor ve geometrik merkez geçişi tanımı açık. Gmail göndereni kullanıcı yazımıyla placeholder şablonunda; gerçek gönderim kapalı. Çizim/katalog/Next.js, geleneksel doğuş-batış ve cihaz testleri sonraki işler. Önceki doğrulama kayıtları aşağıda kendi aşamalarının tarihsel kanıtıdır.

| Tarih | Yapılan iş | Kanıt / sınır |
|---|---|---|
| 30 Ekim 2026 | yorungez kimliği ve ilk dokümantasyon paketi | Güncel gereksinimler 1.1; başlangıç 1.0 arşivi; FR/UJ/AC kimlikleri korundu. Ürün keşfi ve alan sözlüğü taslak; uygulama/test/ölçüm sonucu yok. |
| 30 Ekim 2026 | İlk paket dokümantasyon kontrolü | Arşivin SHA-256 özeti başlangıçla aynı; 10 FR, 7 UJ, 12 AC kimliği korundu. O pakette 20 iç bağlantı ve 148 gereksinim referansı geçerliydi; uygulama doğrulaması yapılmış sayılmaz. |
| 30 Ekim 2026 | DISC-03 / DOM-01 / UX-01 taslakları | Sekiz görev kartı, 35 sınır durumu, 12 yüzeylik envanter ve dört temel akış; üç düzenlenebilir SVG ve PNG önizleme. Gerçek kullanıcı, çalışan prototip, bilimsel hesap ve cihaz testi henüz yok. |
| 30 Ekim 2026 | İkinci paket dokümantasyon ve görsel kontrolü | 52 iç bağlantı/görsel hedefi ve aralıklar dahil 450 gereksinim referansı geçerli. Kaynak belgenin ürün kapsamı bölümleri ve arşiv değişmedi. Üç SVG/PNG çiftinin boyutu ve dosya bütünlüğü kontrol edildi; görsel incelemede yön etiketi çakışması düzeltildi. |
| 30 Ekim 2026 | Kullanıcı önceliği ve TECH-01 | Gereksinimler 1.2: harita, hassas konum, pusula ve ücretsiz/açık kaynak altyapı yönü. İlk .NET 10 solution/API/çekirdek/test projeleri ve ADR-0001 eklendi. Release build 0 uyarı/0 hata; 18 test geçti; liveness 200/Healthy ve servis kimliği yerelde doğrulandı, kontrol süreci kapatıldı. Harita/GPS/pusula/astronomi/PostGIS henüz uygulanmadı. |

Her sonraki işte değişen dosyalar, etkilenen gereksinimler, yapılan doğrulama ve kalan açık kararlar bu planda veya ilgili iş kaydında belirtilir.

31 Ekim 2026 — Gereksinimler 1.3: FR-11–12 ve AC-13–14 eklendi; eski kimlikler korundu. FOUND-01/02 backend temeli uygulandı. Kilitli restore, Release build (0 uyarı/0 hata), 18 çekirdek + 28 gerçek PostgreSQL/Redis kullanan API testi geçti. Yerel Mailpit üzerinden tr/en gerçek HTTP kayıt/doğrulama/giriş/profil/çıkış denemesi başarılı oldu. PostGIS, harita, astronomi motoru ve frontend henüz yoktur. Başlangıç arşivi korunur. Test API süreçleri ve bu projeye ait yerel servisler kontrol sonunda durdurulur; volume'lar korunur.

31 Ekim 2026 — TECH-04C: PRD 1.5/K-021/ADR-0007. Bugün-Bu gece, kaynaklı Takvim, hedef pusulası, 330°/saydam ufuk altı ve yerel şehir-ilçe/manuel ad-yükseklik uygulandı. 93 .NET +29 istemci testi, TypeScript/üretim derlemesi geçti; 1781 USNO evresi (en çok79,946 s) ve 22 standart doğuş-batış referansı (25,48 s), tr/en/390 px tarayıcı kontrolü kayıtlı. 336 belge bağlantısı ve tüm FR/UJ/AC kimlikleri doğrulandı; başlangıç arşivi değişmedi. [Güncel kanıt/kalanlar](gozlem-cizelgesi-ve-takvim.md). Gerçek cihaz/kapsamlı erişilebilirlik/üretim yükü ve P0 işleri açık.


31 Ekim 2026 — TECH-04D/UX-02A: PRD1.6/K-022–023/ADR-0008–0009; yalnız gece, ortak özel kontroller, İstanbul örneği ve sensörsüz dürbün rehberi. İlk yerel favori/not, opsiyonel snapshot, revizyon/çakışma, JSON ve geri alınabilir çöp kutusu uygulandı. 33 istemci testi, TypeScript/üretim derlemesi ve tr/en/dar viewport/gerçek iki sekme/indirilen JSON/DST tekrar saati kontrolleri geçti. Backend değişmedi; önceki93 sonucu korundu. Fiziksel cihaz/hesap aktarımı/PWA/ek olay kaynakları açık.

31 Ekim 2026 — TECH-05/K-024/PRD1.7/ADR-0010: kullanıcı düzeltmesiyle IndexedDB kişisel kayıt kaldırıldı, Notebook modülünde PostgreSQL/sahiplik/revizyon ve iki dilli hesap UI/BFF çerez oturumu uygulandı. Alt panel geri dön eklendi. 100 .NET/35 istemci testi ve üretim derlemesi geçti. Gerçek SMTP/cihaz/gözlem-kayıtlı yer/PWA ve ek olay kaynakları açık.

31 Ekim 2026 — TECH-05B/K-025/PRD1.8: özel Gmail ortamı, gerçek SMTP TLS/AUTH tanılaması, İngilizce markalı HTML/plain mail ve varsayılan en uygulandı. 106 .NET/35 istemci testi ve üretim derlemesi geçti. Sıradaki P0 dilimi gerçek gözlem/kayıtlı konumun hesap envanterine eklenmesi; fiziksel cihaz/PWA/backup ve DATA-P1 kaynak kabulü açık.

1 Kasım 2026 — TECH-06/K-026/PRD1.9/ADR-0011: PostgreSQL hesap envanterine ayrı gözlem ve kayıtlı konum eklendi. Gerçek saat isteğe bağlı/boş başlar, kişisel beyan gerekir; simülasyon/sistem zamanı atanmaz, gelecek reddedilir. Konum kopyası eski gözlemi korur; haritada aynı an/mod/hedef/kamera. 52 terim/cache .7, 120 .NET/38 istemci testi, üretim derlemesi ve EF model/migration kontrolü geçti; TR/EN UI/çöp geri yükleme/export v2/sabit simülasyon kontrolü kayıtlı. Sonraki genel katalog PWA, fiziksel cihaz ve üretim backup/ileri model işleri açık.

1 Kasım 2026 — TECH-07/K-027–028/PRD1.10/ADR-0012–0013: ad-soyadlı hesap/menü, servis hatası ayrımı ve tek terminal başlatıcı. Genel TR/EN PWA çekirdeği, hash/aktif build ayrımı, optional görsel ve açık güncelleme. 125 .NET/44 istemci testi; Web/API kapalı yeni sekme+yenileme+takvim→Ay hesabı kanıtlı. Kişisel veriler sunucuda; fiziksel cihaz/üretim backup/ileri veri işleri açık.
