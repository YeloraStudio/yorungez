# yorungez — Teknik başlangıç ve harita önceliği

**Güncel TECH-07 / K-027–028 (1 Kasım 2026):** Menüde giriş/kayıt veya doğrulanmış oturumun ad-soyadı; kayıt için ad/soyad/e-posta/parola. Servis hatası ve çevrimdışı durum ayrıldı, ortak yerel başlatıcı eklendi. Genel katalog/terim/takvim için hash doğrulamalı PWA paketi ve yeniden açılış uygulandı; kişisel kayıt/oturum/koordinat cache'e girmez. 125 .NET/44 istemci testi; fiziksel cihaz/üretim backup kabulü açık. [Uygulama ve kanıt](hesap-menusu-ve-cevrimdisi-gokyuzu.md), [hesap ADR](adr/0012-hesap-menusu-ve-ad-soyad.md), [PWA ADR](adr/0013-genel-gokyuzu-pwa-ve-cevrimdisi-paket.md).

**Güncel K-026 / TECH-06 (1 Kasım 2026):** Hesap envanterinde not/favori yanında ayrı gözlem ve kayıtlı konum uygulandı. Gözlem açıklama + kişisel beyan ister; gerçek zaman/nesne/konum isteğe bağlıdır, simülasyon zamanı kendiliğinden bağlanmaz. Konum kopyası geçmişi korur; haritada kullanım an/mod/hedef/kamerayı korur. 120 .NET + 38 istemci testi ve üretim derlemesi geçti; 52 tr/en terim/cache .7. [Uygulama ve sınırlar](gozlem-kayitlari-ve-kayitli-konumlar.md), [ADR-0011](adr/0011-gozlem-kaydi-ve-kayitli-konumlar.md). Fiziksel cihaz, genel katalog PWA/offline ve üretim backup kabulü açık; kişisel tarayıcı kalıcılığı yoktur.

**Güncel K-025 / TECH-05B:** Gönderen `sender@example.com`; parola yalnız özel kök `.env`, Gmail STARTTLS/AUTH kontrolü başarılı (ileti gönderilmedi). İşlem e-postaları İngilizce markalı HTML + düz metin, uygulama/API varsayılan dili İngilizce; açık Türkçe seçimi korunur. [Güncel paket](eposta-ve-varsayilan-dil.md). Önceki SMTP placeholder ve iki dilde e-posta hükümleri bu kararla değişti.


**Güncel K-024 / TECH-05:** Kişisel kayıt için doğrulanmış hesap zorunlu; anonim/IndexedDB kişisel kalıcılığı kaldırıldı. Not ve favoriler kullanıcıya bağlı PostgreSQL modülünde; TR/EN kayıt/giriş/doğrulama/sıfırlama ve panel geri dönüşü bağlıdır. [Uygulama ve sınırlar](hesap-ve-sunucu-defteri.md), [ADR-0010](adr/0010-hesap-zorunlu-defter-ve-sunucu-kayitlari.md). Aşağıdaki eski paket kayıtları kendi aşamasının tarihsel kanıtıdır.


**TECH-04D:** 33 istemci testi/üretim derlemesi; ortak kontroller ve sensörsüz rehber. UX-02A yerel favori/not IndexedDB dilimi var, backend bu tur değişmedi. [Uygulama](ortak-bilesenler-ve-sensorsuz-gozlem.md), [hesap/offline devamı](kisisel-kayit-hesap-cevrimdisi-akislari.md).

**TECH-04C:** [Çizelge, takvim GET ve yer adı POST uçları](gozlem-cizelgesi-ve-takvim.md), [ADR-0007](adr/0007-gozlem-takvimi-ve-yer-adlari.md). Standart Güneş/Ay doğuş-batışının 22 bağımsız örneği geçti; geniş yükseklik/ufuk/kutup kapsamı açık. Takvim 2623 olay, 1781 evre USNO ile karşılaştırılmıştır; diğer motor olayları ayrıca etiketlidir.

**Güncelleme:** 31 Ekim 2026. **Durum:** Modüler backend ve ilk sınırlı hesap/harita/katalog akışı uygulandı. Kararlar: [ADR-0001](adr/0001-teknik-temel-ve-ilk-dikey-akis.md), [ADR-0002](adr/0002-moduler-temel-cqrs-ve-lisanslar.md), [ADR-0004](adr/0004-ilk-harita-ve-parlak-katalog.md).

## Mevcut temel

| İş | Kanıt / sınır |
|---|---|
| **TECH-01 — İlk host ve koordinat çekirdeği** | .NET 10 API, bağımsız enlem/boylam tipi; 18 geçerlilik/hassasiyet testi. Girdiyi gereksiz yuvarlamaz, NaN/sonsuz/sınır dışını reddeder; sıfır geçerlidir. Fiziksel GPS doğruluğunu garanti etmez. |
| **FOUND-01 — Modüler kalıcılık ve kimlik** | Clean Architecture, CQRS/MediatR 12.5.0, gerçek PostgreSQL/Redis, Identity/JWT/refresh, doğrulama/sıfırlama, şifreli outbox; ilk migration ve 28 API/entegrasyon testi tarihsel temelidir. Güncel 83 API testi, Notebook hesap sahibi/revizyon ve dört kayıt türü eklendi; üretim kabulü açık. |
| **FOUND-02 — Dil ve terimler** | Backend mesaj/e-postaları, hesap açıklamaları ve 52 terim tr/en; ilk haritada kart/sözlük penceresi, klavye/ESC odak dönüşü. Ayrı sözlük sayfası/ekran okuyucu açık. |
| **TECH-02B/03 — İlk harita** | 5073 yıldız/88 takımyıldız/dokuz Güneş Sistemi hedefi; Canvas/Worker/BFF, manuel konum, UTC simülasyon/canlı saat, arama/kart ve tr/en. Gerçek cihaz/PWA/sensörler açık. |

Çalıştırma ve test komutlarının güncel kaynağı [altyapı ve kimlik belgesidir](altyapi-ve-kimlik.md). Çözüm `Yorungez.slnx`, SDK seçimi `global.json`, sürümler `Directory.Packages.props` ve `packages.lock.json` dosyalarındadır. Mevcut katmanlar `Core`, `BuildingBlocks/Application`, `Modules/Identity`, `Modules/Catalog`, `Modules/Astronomy`, `Modules/Notebook` ve API'dir. Domain/Application altyapıya referans vermez; mimari test bunu denetler.

Release build 0 uyarı/0 hata; **125 .NET testi** geçti (18 çekirdek, 19 astronomi, 88 API/entegrasyon), **44 istemci testi**, Next üretim derlemesi ve TypeScript kontrolü geçti. Bu sonuçlar ürünün bütün kabul kriterlerinin veya bilimsel doğruluğunun sağlandığı anlamına gelmez. `/health/live` yalnızca host; `/health/ready` PostgreSQL şeması ve Redis kontrolüdür. Bunlar gökyüzü hesabı yapmaz. [Haritayı açma/deneme](../src/Yorungez.Web/README.md), [bilimsel ve tarayıcı kanıtı](harita-ve-katalog-denemesi.md).

## Sonraki somut sıra

**TECH-02A:** Astronomy modülü Domain/Application/Infrastructure sınırlarıyla eklendi. Dokuz hedef ve merkez/0° geometrik geçişi, 1.168 JPL örneği, C#/JS eşliği ve yerel desktop hesap ölçümü hazırdır. Kutup azimutu koruyucu sınırla sunulmaz; standart çizelge TECH-04C ile ayrı 0 m referans modeli olarak eklendi; geniş doğrulama açıktır. Yıldız/takımyıldız TECH-02B/03 ile eklendi. [Tekrarlanabilir deneme](astronomi-denemesi.md), [bütün gereksinimlerin durumu](teslimat-izlenebilirligi.md).

1. **TECH-02B / DATA-01 — Çizim/katalog denemesi:** İlk katalog/Canvas seçimi ADR-0004 ile uygulandı; 144 Astropy örneği ve Canvas/SVG/WebGL IAB ölçümleri var. Tam harita/ilk yükleme/bellek ve fiziksel mobil bütçesi ile geniş doğruluk/offline açık. İki kutup istisnası korunur.
2. **TECH-03 — İlk tr/en harita akışı:** Anonim konum-zaman-harita-arama-kart/terim akışı tarayıcıda çalışır. Cihaz/ekran okuyucu ve tam kabul işleri [deneme kaydında](harita-ve-katalog-denemesi.md) korunur; bütün MVP-0 tamamlandı değildir.
3. **TECH-04 — Tam ekran/konum/zaman ve cihaz:** [ADR-0005](adr/0005-tam-ekran-konum-ve-yerel-zaman.md) ve [uygulama kaydı](tam-ekran-harita-gelistirmesi.md): ilk açılış/Worker, yeni katmanlar, 107 DSO/85 çizim, kaynaklı kart, izinli GPS/OSM, IANA/yerel/UTC/DST yazılımı uygulandı. TECH-04B ile gerçek fotoğraf çevre/dil listesi ve izin/veri/hizalama korumalı düz pusula eklendi; sırada [fiziksel GPS/pusula protokolü](cihaz-konum-pusula-dogrulamasi.md); gerçek cihaz denemesi olmadan destek tamamlandı denmez.
4. **TECH-05 — P0 kişisel kayıt/senkronizasyon:** Yerel kayıtlar, açık onaylı aktarım, çatışma politikası, veri silme/dışa aktarma ve çevrimdışı davranış. Kurulan kimlik altyapısı bu verileri henüz saklamıyor.

## Konum ve coğrafyanın sınırı

Cihazın sunduğu koordinat, doğruluk ve ölçüm zamanı ayrı alanlardır. `0` koordinatı bilinmiyor değildir; bilinmeyen doğruluk uydurulmaz. Konum ve cihaz yönü ayrı izin/veri akışlarıdır. Pusula desteklenmese de manuel yönlendirme çalışmalıdır. [Geolocation API](https://developer.mozilla.org/en-US/docs/Web/API/Geolocation_API) güvenli bağlam/izin ister; [cihaz yönü izni](https://developer.mozilla.org/en-US/docs/Web/API/DeviceOrientationEvent/requestPermission_static) destek ve kullanıcı eylemine bağlı olabilir. Cihaz konumu tek taze yüksek doğruluk isteğiyle alınır; sürekli takip değildir. Ölçüm zamanı/metre korunur. IANA çözümü aynı kökenli BFF POST/no-store üzerinden yerel poligonlara gider; OSM yalnız kullanıcı eylemiyle açılır. Testte kullanıcının gerçek konumu okunmadı; örnek/genel şehir merkezi koordinatları kullanıldı.

PostgreSQL seçildi; PostGIS kurulmadı. Basit koordinat saklamak PostGIS gerektirmez. Gözlem alanı yakınlık/ışık kirliliği/arazi sorguları için ihtiyaç, kaynak, tip/SRID ve indeks ayrıca değerlendirilecek. Göksel hesap astronomi motorunun, çizim istemcinin, cihaz verisi tarayıcı/sensör katmanının sorumluluğudur. [Ayrıntılı özellik matrisi](bilimsel-veri-stratejisi.md).

Hassas konumlar gereksiz log/telemetriye veya herkese açık bağlantıya yazılmaz. Kullanıcının koordinat işleme onayı, ürün kullanıcılarının gizlilik ve paylaşım kontrolünün yerine geçmez. Lisans ücreti gerektirmeyen araç seçmek barındırma/alan adı/işletimin maliyetsiz olduğu anlamına gelmez; henüz canlı yayın veya alan adı bağlantısı yapılmadı.
