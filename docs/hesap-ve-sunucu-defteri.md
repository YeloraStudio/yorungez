# TECH-05 — Hesap ve sunucuda Defterim

**K-024 / PRD 1.7, 31 Ekim 2026.** Son kullanıcı düzeltmesi uygulanır: kişisel kayıt için üyelik zorunlu, tarayıcıda kalıcılık yok. [ADR-0010](adr/0010-hesap-zorunlu-defter-ve-sunucu-kayitlari.md), [güncel UX-02](kisisel-kayit-hesap-cevrimdisi-akislari.md). FR-06–07/FR-09/FR-11; UJ-04–05/UJ-07; AC-07–09/AC-12–13.

- Anonim Defterim, kayıt/giriş ekranı açar; e-posta/parola ile basit kayıt ve zorunlu doğrulama. Yeniden gönderme, unutulan parola, link işlemleri ve çıkış iki dilde bağlıdır.
- Notebook ayrı Clean Architecture/CQRS modülüdür. `notebook.Entries` PostgreSQL tablosu ve migration uygulandı. Sorgular/yazmalar oturum sahibine sınırlandırılır; diğer hesap aynı ID'yi kullansa da ayrı veridir.
- Favori/not, ayrı kapalı başlayan hedef/an/koordinat seçimleri, tarihsel snapshot, sunucu zamanı, revizyon ve geri alınabilir çöp kutusu korunur. Yeni kopya bağları korur. Kullanıcı metni çevrilmez ve HTML çalıştırılmaz.
- Tarayıcı veritabanına yeni kişisel okuma/yazma yoktur; açık sayfanın taslağı bellektedir. Kişisel ağ kesintisi kaydetme başarısı gibi gösterilmez; otomatik offline kuyruk yoktur. Eski deney IndexedDB'si kullanılmaz veya sessiz taşınmaz/silinmez.
- Oturum korunan HttpOnly çerezidir; üretimde Secure, SameSite Strict, hesap doğrulaması/aile iptali. JWT/refresh API temeli korunur. BFF yalnız sabit API yollarını ve gereken çerezi aktarır; no-store, Origin/JSON/özel başlık kontrolleri vardır.
- Menü altındaki Takvim, Bu gece ve diğer panellerde “Menüye geri dön” ok düğmesi vardır; X haritaya kapatır. Panel başlığına odak geçer. Özel dropdown/tarih bileşenleri korunur.

## Doğrulama

100 .NET testi geçti: 18 çekirdek, 19 astronomi, 63 gerçek PostgreSQL/Redis API testi. Yeni 7 hesap/defter senaryosu: anonim ret/doğrulama, kullanıcı ayrımı/farklı girişten erişim/gerçek tablo kontrolü, eşzamanlı revizyon/çöp kutusu/restore, TR/EN geçersiz veri, CSRF ve çıkış. 35 istemci testi geçti; BFF köken/başlık/çerez/cache/kesinti kontrolleri dahildir. Next üretim derlemesi/TypeScript geçti. Önceki 144 yıldız/72 DSO ve donmuş bilimsel veri kontrolleri korunur; yeni astronomik doğruluk iddiası yoktur.

Geliştirici tarayıcı kanıtı ve sınırları bu paket sonunda kaydedilir. Dar viewport fiziksel mobil cihaz/ekran okuyucu kabulü değildir. Gerçek dış Gmail gönderimi yapılmaz; yerel Mailpit/fake kullanılır.

## Çalıştırma ve kalanlar

Backend migration: `dotnet run --project src/Yorungez.Api -- --migrate` (Development ortamı/özel yerel ayarlarla). Standart [yerel başlangıç](altyapi-ve-kimlik.md) hem Identity hem Notebook migration'ını uygular. Web varsayılan API kökeni `http://127.0.0.1:5187`; özel değer `YORUNGEZ_API_ORIGIN`. Üretim BFF için güvenilir `YORUNGEZ_WEB_ORIGIN` ve backend e-posta link kökeni aynı HTTPS kökeni olmalıdır. SMTP göndereni `sender@example.com` placeholder şablonunda korunur; Gmail gerçek gönderimi henüz açılmaz.

Sıradaki P0 dilimi: gerçek gözlem/kayıtlı konumun minimum modeli ve hesap envanterine eklenmesi; kalıcı silme/hesap yönetimi/veritabanı yedek ve geri yükleme kabulü. Fiziksel GPS/pusula/erişilebilirlik, genel katalog PWA/offline ve ek takvim olaylarının kaynak/doğrulaması açık kalır. Bütün gereksinimler [izlenebilirlikte](teslimat-izlenebilirligi.md) sürer.

Geliştirici tarayıcı kanıtı: [TR hesap envanteri](ux/accounts/notebook-tr.jpg), [EN envanter](ux/accounts/notebook-en.jpg), [TR giriş](ux/accounts/login-tr.jpg), [EN giriş](ux/accounts/login-en.jpg), [Takvim geri dön](ux/accounts/calendar-back-tr.jpg), [Bu gece geri dön](ux/accounts/tonight-back-tr.jpg). Yerel Mailpit kayıt/doğrulama/giriş, not/favori, yenileme/yeniden giriş ve dil değişimi geçti; çıkış özel kayıt bileşenini kaldırdı. [Makine okunur gözlemler/sınırlar](science/account-notebook-browser-qa.json). Viewport override bu oturumda gerçek ölçüyü değiştirmedi; görüntüler masaüstüdür, yeni mobil kabulü iddia edilmez. Önceki fiziksel cihaz sınırları sürer. Son derlemede doğrulama sayfası no-store/private + no-referrer ve çapraz köken yazma 403/no-store HTTP ile doğrulandı.
