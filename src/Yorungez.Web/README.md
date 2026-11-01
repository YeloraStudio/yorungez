# yorungez Web

**Güncel TECH-07 / K-027–028 (1 Kasım 2026):** Menüde giriş/kayıt veya doğrulanmış oturumun ad-soyadı; kayıt için ad/soyad/e-posta/parola. Servis hatası ve çevrimdışı durum ayrıldı, ortak yerel başlatıcı eklendi. Genel katalog/terim/takvim için hash doğrulamalı PWA paketi ve yeniden açılış uygulandı; kişisel kayıt/oturum/koordinat cache'e girmez. 125 .NET/44 istemci testi; fiziksel cihaz/üretim backup kabulü açık. [Uygulama ve kanıt](../../docs/hesap-menusu-ve-cevrimdisi-gokyuzu.md), [hesap ADR](../../docs/adr/0012-hesap-menusu-ve-ad-soyad.md), [PWA ADR](../../docs/adr/0013-genel-gokyuzu-pwa-ve-cevrimdisi-paket.md).

**Güncel K-026 / TECH-06 (1 Kasım 2026):** Hesap envanterinde not/favori yanında ayrı gözlem ve kayıtlı konum uygulandı. Gözlem açıklama + kişisel beyan ister; gerçek zaman/nesne/konum isteğe bağlıdır, simülasyon zamanı kendiliğinden bağlanmaz. Konum kopyası geçmişi korur; haritada kullanım an/mod/hedef/kamerayı korur. 120 .NET + 38 istemci testi ve üretim derlemesi geçti; 52 tr/en terim/cache .7. [Uygulama ve sınırlar](../../docs/gozlem-kayitlari-ve-kayitli-konumlar.md), [ADR-0011](../../docs/adr/0011-gozlem-kaydi-ve-kayitli-konumlar.md). Fiziksel cihaz, genel katalog PWA/offline ve üretim backup kabulü açık; kişisel tarayıcı kalıcılığı yoktur.

**Güncel K-025 / TECH-05B:** Gönderen `sender@example.com`; parola yalnız özel kök `.env`, Gmail STARTTLS/AUTH kontrolü başarılı (ileti gönderilmedi). İşlem e-postaları İngilizce markalı HTML + düz metin, uygulama/API varsayılan dili İngilizce; açık Türkçe seçimi korunur. [Güncel paket](../../docs/eposta-ve-varsayilan-dil.md). Önceki SMTP placeholder ve iki dilde e-posta hükümleri bu kararla değişti.


**Güncel K-024 / TECH-05:** Kişisel kayıt için doğrulanmış hesap zorunlu; anonim/IndexedDB kişisel kalıcılığı kaldırıldı. Not ve favoriler kullanıcıya bağlı PostgreSQL modülünde; TR/EN kayıt/giriş/doğrulama/sıfırlama ve panel geri dönüşü bağlıdır. [Uygulama ve sınırlar](../../docs/hesap-ve-sunucu-defteri.md), [ADR-0010](../../docs/adr/0010-hesap-zorunlu-defter-ve-sunucu-kayitlari.md). Aşağıdaki eski paket kayıtları kendi aşamasının tarihsel kanıtıdır.


**Önceki TECH-04D / UX-02A:** [Ortak kontroller/gece/yön rehberi](../../docs/ortak-bilesenler-ve-sensorsuz-gozlem.md), [yerel Defterim ve hesap/offline devamı](../../docs/kisisel-kayit-hesap-cevrimdisi-akislari.md). Görünen native select/date/time yok; ortak CSS/popover/grid ve draft ISO form değerleri. Bu önceki deneyin kaydıdır; güncel K-024 IndexedDB yolunu kaldırdı. Koordinat bağlamak hesap notunda açık seçimdir. 33 istemci testi/üretim derlemesi geçti; tam PWA/hesap eşitleme/cihaz kabulü açık.

**TECH-04C:** [Çizelge/takvim/saydam geniş açı ve yer adı](../../docs/gozlem-cizelgesi-ve-takvim.md), [ADR-0007](../../docs/adr/0007-gozlem-takvimi-ve-yer-adlari.md). BFF `/api/calendar` genel ETag/304; `/api/location/places` POST/no-store yerel GeoNames. 0,6°–330° stereografik görüş; Bugün/Bu gece Worker ve iki dilde kaynaklı takvim. 51 terim, 29 istemci/93 .NET testi; fiziksel cihaz/üretim yükü kabulü açık.

**Önceki TECH-04B:** [Doğal görünüm/pusula rehberi](../../docs/dogal-gorunum-ve-pusula.md). Gerçek kaynaklı çevre fotoğrafı, yön bağımlı WebGL atmosferi + Canvas yıldız ışığı, kullanıcı paleti, native dil listesi ve düz pusula aracı eklendi. O aşamada 43 terim/84 .NET/24 istemci testi. Pusula fiziksel kabulü/AR ve mobil bellek bütçesi açık. Ayrı ajan önizlemesi için süreçte `YORUNGEZ_BUILD_DIR=.next-preview` kullanılır; `.next-preview` ile `5194`, kullanıcının `.next`/`5190` sunucusundan ayrıdır. Tek çıktı klasöründe build/start eşzamanlı yapılmaz.

Next.js 16.4.3 / React 19.3.1 / TypeScript 5.9.3 / Astronomy Engine 2.1.19; sürümler `package-lock.json` içinde sabittir. Node.js 22.20.0 ve PowerShell 7 ile doğrulandı. Leaflet 1.9.4, Temporal polyfill 0.5.1 ve sunucuda geo-tz 8.1.10 eklenmiştir. Uygulama yereldir, yayınlanmış değildir.

Repo kökünden:

```powershell
# Kullanıcı deneyimini üretim derlemesinde aç:
./scripts/Start-Web.ps1 -Production
# http://127.0.0.1:5190/tr veya /en; Ctrl+C ile kapat.
# Kod geliştirirken (ilk istekte derleme daha uzun olabilir):
./scripts/Start-Web.ps1
# Önce sunucuyu kapat; aynı .next üzerinde eşzamanlı build/dev/start yok:
./scripts/Verify-Web.ps1
# Önceden kurulmuş bağımlılıklarla:
./scripts/Verify-Web.ps1 -Offline
# Çizici karşılaştırma laboratuvarı ayrıca açılabilir:
./scripts/Start-Web.ps1 -Production -EnableLab
# /tr/lab/renderers veya /en/lab/renderers
```

`Start-Web` loopback üzerinde dinler, laboratuvar varsayılan kapalıdır; kilit dosyası hash’i değişmişse `npm ci --ignore-scripts` çalıştırır. Next paketinin yerel rehberi ve bu klasörün AGENTS.md talimatları korunur. Docker veya ayrı .NET API haritanın ön koşulu değildir. Backend `scripts/Start-LocalBackend.ps1` ile ayrı çalışabilir. Web’de kullanılmayan API adresi yapılandırması kaldırıldı; `NEXT_PUBLIC_` sırlara uygun değildir.

Verinin tek kaynağı `data/catalog/` ve backend terim JSON’udur. `predev/prebuild` base/overlay/85 çizim/Sun fotoğrafı hash’lerini doğrular, yok sayılan `generated/` kopyasını hazırlar. C# aynı base/overlay dosyalarını gömer. Üretilen kopya elle düzenlenmez. `/api/catalog` doğrulanmış yerel genel veri + 52 terimin iki dilini sunar; ETag base/overlay/terim/şema sürümünü içerir. İlk kare backend veya Wikipedia çağrısı beklemez.

5073 yıldız + 9 Güneş Sistemi hedefi + 88 figür + 107 Messier eşleşmesi aynı bağlamdan hesaplanır; 85 lisanslı çizim üç yıldız bağıyla göğe yerleşir. Bilimsel çıktı Float64, yalnız piksel koordinatları Float32’dir. Canvas 2D/stereografik çizim, yumuşak fare/trackpad zoom, sürükleme, pointer/pinch ve klavye vardır. Katman varsayılanı yalnız atmosfer/temsili arazi/derin uzay açık; çizgi/ad, çizimler, iki ızgara, gece ve tam ekran kapalıdır. Arazi/atmosfer gerçek topografya/hava/görünürlük hesabı değildir.

Worker hazır sinyali, tek etkin/en yeni bekleyen iş, sıra numarası, 8 s gözetim ve aynı gerçek hesapla uyumluluk yolu kullanır. Katalog isteği 10 s ile sınırlıdır. Meşgulken canlı saat yeni hesap kuyruğu biriktirmez; hata görünür/tekrar denenebilir. Kaynak/GPS/bölge işlemleri ilk açılışı engellemez.

Tam ekran gri/bordo yüzeyin sol menüsü başlangıçta kapalıdır; kalıcı topbar/sidebar yoktur. Kısa saydam kartta gerçek Güneş arşiv fotoğrafı/Wikipedia özeti, isteğe bağlı ayrıntı/atıf/konum alanları bulunur. Mobilde odak eylemi kartı küçültür. `/api/objects/[id]` Güneşin lisanslı yerel tr/en snapshot’ını, diğer bilinen hedeflerde süre sınırlı Wikipedia/Commons bilgisini sunar. Eksik/belirsiz kaynak uydurulmaz; görsel ve metin lisansları ayrıdır.

Önceden izinli cihaz konumu tek güncel yüksek doğruluk isteğiyle alınır; yeni izin kullanıcı eylemiyle istenir. Doğruluk/metre ve ölçüm zamanı korunur, manuel seçim geç GPS yanıtını iptal eder. Koordinatlar URL/storage/log’a yazılmaz. `/api/location/time-zone` POST/no-store ve 2 KiB gövde sınırıyla koordinattan sunucudaki `geo-tz/all` kapsamlı poligonlarını sorgular; dış coğrafi API yoktur. Çoklu/çözümsüz bölge görünür UTC/elle IANA seçimi sunar. OSM haritası/döşemeleri ancak açık kullanıcı eylemiyle yüklenir; görünür atıf ve sağlayıcı cache politikası korunur, toplu/offline indirme yoktur.

Yerel IANA saat + GMT ofseti ve UTC birlikte görünür. Yerel/UTC giriş ayrı seçilebilir; seçili UTC anı dil/konum/bölge değişimiyle değişmez. Temporal boş yerel saati reddeder, çift saat için oluşum seçtirir. Bölge hazır değilken giriş UTC’dir. Ortak özel tarih girdisi canlı render’dan korunur, gönderimde gerçek form değeri okunur. 31 Ekim 2026 Balıkesir 14:24 = 11:24 UTC tarayıcıda doğrulandı. IANA/ofset verisi bakım gerektirir.

**44 istemci testi ve üretim derlemesi geçti (TECH-07).** 144 yıldız ve 72 DSO donmuş bağımsız Astropy referansı normal testte ağsız okunur. Dar viewport/IAB gerçek telefon/GPS testi değildir. Hesap UI ve dört kişisel kayıt türü uygulanmıştır. Pusula/kalibrasyon fiziksel kabulü, kamera AR, fiziksel dokunma/performans/ekran okuyucu, geniş olay/rakım/ufuk kapsamı, genel PWA/service worker/çevrimdışı yeniden açılış sınırlı IAB testlidir; üretim/fiziksel cihaz/kurulum/çok tarayıcı kabulü açıktır. Yüklenmiş sekmede hesap çalışması tam offline kabulü değildir. [Güncel kanıt/sınırlar](../../docs/tam-ekran-harita-gelistirmesi.md), [kaynak/atıf](../../data/catalog/README.md), [ADR-0005](../../docs/adr/0005-tam-ekran-konum-ve-yerel-zaman.md).

Hesap kaydı için API de açık olmalıdır. `../../scripts/Start-LocalBackend.ps1` ve `../../scripts/Start-Web.ps1` varsayılan Web portu5190/e-posta linkiyle eşleşir. Farklı Web portunda backend `-FrontendUrl` değerini aynı kökene ver. API kapalıyken anonim genel harita sürer, kişisel Defterim sunucu hatasını gösterir. Üretimde server-only `YORUNGEZ_API_ORIGIN`/`YORUNGEZ_WEB_ORIGIN` ve backend e-posta kökeni [ADR-0010](../../docs/adr/0010-hesap-zorunlu-defter-ve-sunucu-kayitlari.md) ile yapılandırılır; kişisel veri için tarayıcı fallback deposu yoktur.

TECH-07: `predev/prebuild` kaynak hash'lerini doğrulayıp genel `public/pwa/` katalog/takvim/ikon paketini üretir. Başarılı Next build sonrasında `postbuild`, o `distDir` için HTML bağımlılıkları ve SHA/byte envanterini doğrular; `yorungez-pwa/pack.json` ve `worker.js` çıktısını üretir. `/sw.js` ve `/pwa-pack.json` bunları no-store sunar. Çıktıları elle değiştirme; `.next`/`.next-preview` ayrımı korunur. Kaynak staging aynı `public/pwa/` alanını kullandığından iki build'i eşzamanlı çalıştırma. Genel veri cache'i, kişisel BFF ve hesap HTML'inden ayrı tutulur; RSC/POST/query/external hariçtir. Üretim paketine aktif distDir içindeki `yorungez-pwa/` da dahil edilmelidir. PWA geliştirme modunda kaydedilmez; gerçek kabul için `Start-LocalApp` veya `Start-Web -Production`. Sürüm değiştirmede taslak uyarısını/tek sekme kontrolünü atlama.
