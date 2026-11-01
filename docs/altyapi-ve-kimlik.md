# yorungez — Yerel altyapı ve kimlik temeli

**Güncel K-025 / TECH-05B:** Gönderen `sender@example.com`; parola yalnız özel kök `.env`, Gmail STARTTLS/AUTH kontrolü başarılı (ileti gönderilmedi). İşlem e-postaları İngilizce markalı HTML + düz metin, uygulama/API varsayılan dili İngilizce; açık Türkçe seçimi korunur. [Güncel paket](eposta-ve-varsayilan-dil.md). Önceki SMTP placeholder ve iki dilde e-posta hükümleri bu kararla değişti.


**Güncel K-024 / TECH-05:** Kişisel kayıt için doğrulanmış hesap zorunlu; anonim/IndexedDB kişisel kalıcılığı kaldırıldı. Not ve favoriler kullanıcıya bağlı PostgreSQL modülünde; TR/EN kayıt/giriş/doğrulama/sıfırlama ve panel geri dönüşü bağlıdır. [Uygulama ve sınırlar](hesap-ve-sunucu-defteri.md), [ADR-0010](adr/0010-hesap-zorunlu-defter-ve-sunucu-kayitlari.md). Aşağıdaki eski paket kayıtları kendi aşamasının tarihsel kanıtıdır.


**Güncel ek — TECH-04:** Anonim `GET /api/v1/catalog/overlays` 107 DSO/85 çizim/kaynak/hash ve ETag/304 sunar; terimler 39’dur. Web BFF ilk karede backend’e bağlı değildir; konum IANA çözümü POST/no-store ile yerel poligonlara gider. Güncel toplam 84 .NET testi (18/19/47), 19 istemci testi ve üretim derlemesi geçti. Aşağıdaki ilk kimlik doğrulama kayıtları tarihsel kanıttır; SMTP placeholder/gerçek gönderim kapalı kararı korunur. [Güncel paket](tam-ekran-harita-gelistirmesi.md).

**Tarih:** 31 Ekim 2026. **İz:** FR-07–08, FR-11–12; AC-08–09, AC-13–14. [ADR-0002](adr/0002-moduler-temel-cqrs-ve-lisanslar.md) uygulamasıdır. İlk anonim frontend/harita [ADR-0004](adr/0004-ilk-harita-ve-parlak-katalog.md) ile eklendi; hesap ekranları ve P0 senkronizasyonu henüz yoktur.

## Yerel çalıştırma

Ön koşul: PowerShell 7, `global.json` ile uyumlu .NET 10 SDK ve çalışan Docker Compose. Proje kökünde:

```powershell
./scripts/Start-LocalBackend.ps1
```

Script özel `.env` ve `src/Yorungez.Api/appsettings.Local.json` dosyalarını ilk çalıştırmada rastgele sırlarla oluşturur; mevcut dosyaları değiştirmez. Bunlar `.gitignore` kapsamındadır. İlk yapılandırmada varsayılan port doluysa boş yerel port seçilir. Port kontrolü ile Docker'ın bağlanması arasında başka süreç portu alabilir; başlatma başarısızsa `.env` ve yerel JSON'daki ilgili portu birlikte düzenlemek gerekir. Başka projelerin süreçleri kapatılmaz. Yapılandırma dosyaları ekrana veya issue'ya yapıştırılmaz.

Compose yalnızca `yorungez` projesine ait PostgreSQL 18.6, Redis 8.10.3 ve Mailpit v1.32.0 servislerini başlatır. İmajlar içerik özetiyle sabittir. Portlar `127.0.0.1` ile sınırlıdır; gerçek portlar `.env` içindedir. Mailpit yerel SMTP yakalayıcısıdır, gerçek alıcılara e-posta iletmez. Kullanıcı hesabı oluşturmak için çalışan gerçek e-posta sağlayıcısı üretimde ayrıca yapılandırılacaktır.

Başlatma script'i kilitli paket restore, Release build ve açık `--migrate` komutundan sonra API'yi `http://127.0.0.1:5187` üzerinde çalıştırır. `-Url` ile adres değiştirilebilir. Migration normal API açılışında otomatik uygulanmaz; yerel script bu işlemi açıkça yapar. Üretim migration'ı ayrı dağıtım adımı ve ayrı yetkili kimlik gerektirir.

```powershell
./scripts/Verify-Backend.ps1
docker compose stop
```

Doğrulama script'i gerçek yerel servisleri başlatır ve testleri çalıştırır. Testler her fixture için rastgele `yorungez_test_<GUID>` veritabanı oluşturup yalnızca kendi veritabanını siler; yalnızca localhost bağlantısına izin verir. E-postalar entegrasyon testinde yakalanan sahte taşıyıcıya gider. Test için `YORUNGEZ_TEST_POSTGRES` bağlantı değişkeni kullanılabilir; yapılandırma yine yerel JSON'daki Redis'i kullanır. Test kullanıcısının veritabanı oluşturma hakkı gerekir; bu yerel geliştirme yetkisi üretim uygulama rolüne verilmez.

API Ctrl+C ile kapanır. `docker compose stop` yalnızca bu projenin servislerini durdurur, verileri silmez. Test/başlatma scriptleri hata incelemesi ve tekrar kullanım için servisleri açık bırakır. Veritabanı/Redis volume'ları korunur; otomatik `down -v` yapılmaz.

## HTTP sözleşmesi

| Uç | Davranış |
|---|---|
| `GET /health/live` | Host canlılığı; bağımlılıklardan bağımsız |
| `GET /health/ready` | PostgreSQL bağlantısı, migration durumu ve hesap tablosu; Redis yaz/oku kontrolü |
| `GET /api/v1/status` | Servis/sürüm aşaması ve seçili dil |
| `GET /api/v1/terms/?q=...`, `/{id}` | Anonim iki dilli terim arama/ayrıntı |
| `POST /api/v1/auth/register` | `{email,password}`; genel 202, doğrulama e-postası kuyruğa alınır |
| `POST /api/v1/auth/confirm-email` | `{userId,token}`; doğrulama |
| `POST /api/v1/auth/login` | `{email,password}`; doğrulanmış hesap için JWT/refresh çifti |
| `POST /api/v1/auth/refresh` | `{refreshToken}`; eski token tek kullanımla tüketilir, yeni çift döner |
| `POST /api/v1/auth/logout` | Bearer JWT gerekir; o oturum ailesini iptal eder |
| `GET /api/v1/auth/me` | Bearer JWT gerekir; yalnızca mevcut hesabın profili |
| `POST /api/v1/auth/resend-confirmation` | `{email}`; genel 202 |
| `POST /api/v1/auth/forgot-password` | `{email}`; genel 202 |
| `POST /api/v1/auth/reset-password` | `{userId,token,password}`; önceki oturumları iptal eder |

`Accept-Language: tr` veya `en` kullanılır. Hata yanıtları `application/problem+json`, sabit `code`, çevrilmiş `title/detail` ve izleme kimliği taşır; girilen şifre/token/e-posta hata metnine geri yazılmaz. Kimlik yanıtları önbelleğe alınmamalıdır; uygulanan endpoint'ler `Cache-Control: no-store` döndürür. Redis kapalıysa sözlük kaynak dosyadan çalışır, readiness `Degraded`/200 olur. Zorunlu PostgreSQL hazır değilse readiness başarısızdır; liveness çalışabilir. Health astronomik doğruluk veya dış katalog güncelliği kanıtı değildir.

## Kimlik ve sırların yaşam döngüsü

- ASP.NET Core Identity kullanıcı/parola saklama ve doğrulama token sağlayıcısını yönetir. Parola 15–128 karakter; zorunlu karakter bileşimi yoktur. PBKDF2 maliyeti 210.000 iterasyondur. Yanlış giriş için 5 denemede 15 dakika hesap kilidi vardır. E-posta doğrulanmadan girişle hesap işlevleri açılamaz.
- Access token gerçek HS256 JWT'dir; varsayılan 10 dakika. Issuer, audience, imza, süre ve algoritma doğrulanır; 15 saniye saat toleransı vardır. İmzalama anahtarı en az 64 UTF-8 bayt olmalı; yerel script rastgele üretir. JWT'de e-posta/GPS bulunmaz. [Identity'nin yerleşik bearer token'ı JWT değildir](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/identity-api-authorization?view=aspnetcore-10.0); burada ayrı JWT üreticisi bu nedenle kullanılır.
- Refresh token rastgele 48 bayttan üretilir, varsayılan 7 gün geçerlidir. Ham token DB'ye yazılmaz; SHA-256 özeti ve oturum ailesi tutulur. Tüketilen tokenın tekrar kullanımı aileyi iptal eder. Güncelleme concurrency sürümüyle iki eşzamanlı başarılı yenilemeyi önler. Ailedeki tek bir iptal kaydı bile bütün aileyi geçersiz kılar; çıkışla eşzamanlı geç kaydedilmiş çocuk token aileyi yeniden açamaz. İptal kayıtları, ailenin bütün tokenları kullanım dışına çıkmadan tek tek temizlenmemelidir; temizlik aile bazında tasarlanacaktır.
- Her korumalı istekte kullanıcı güvenlik damgası ve oturum ailesi PostgreSQL'den kontrol edilir. Çıkış ve parola sıfırlama önceki access token'ı da geçersiz kılar. Bu tercih iptal doğruluğunu artırır, korumalı isteklere DB okuması ekler; ölçüm yapılmadan yüksek trafik performansı iddia edilmez. Anonim harita bu kontrole bağımlı tutulmaz.
- Doğrulama/sıfırlama bağlantıları 2 saat geçerlidir. Mail bağlantısında token URL fragment'ındadır; sunucu query'sine taşınmaz. Hedef `/tr|en/account/confirm-email|reset-password` sayfaları henüz yoktur. Frontend bunları okuyup tokenı POST ile API'ye iletecek; şu anda uçlar HTTP/test istemcisiyle doğrulanmıştır.
- Kayıt ve şifreli e-posta outbox kaydı aynı PostgreSQL transaction'ındadır. Alıcı, konu ve tokenlı gövde Data Protection ile korunur. İşçi 5 saniyede bir çalışır; lease ve tekrar deneme kullanır, en çok 10 deneme yapar. Teslimat **en az bir kez** yaklaşımıdır: SMTP kabulü ile DB işaretlemesi arasında kesinti yinelenen e-posta üretebilir. Teslim edilemeyen kuyruk için izleme/işletim aracı sonraki iştir. Yeniden gönderim ve sıfırlama isteklerinde kullanıcı/tür başına 1 dakika bekleme vardır.
- Anahtar halkası kalıcıdır; yerel Windows geliştirmesinde DPAPI, üretimde sertifika ile korunur. Test anahtarları geçicidir. Anahtar halkası kaybı bekleyen postaları çözülemez ve bağlantıları geçersiz kılabilir; yedekleme/döndürme üretim işletiminin parçasıdır.

## Üretime geçmeden tamamlanacaklar

**SMTP tercihi (31 Ekim 2026):** Kullanıcı göndereni `sender@example.com` olarak belirledi; yazım aynen korunur. [Gmail şablonu](../config/smtp.gmail.example.json) `smtp.gmail.com:587`, STARTTLS, aynı kullanıcı adı ve parola placeholder'ı içerir. Şablon otomatik yüklenmez, `RunOutboxWorker=false` tutar. Yerel ayarlar Mailpit kaldı; Gmail bağlantısı/gönderimi yapılmadı. Parola sonradan özel yerel ayara veya `Email__Password` gibi süreç ortam sırrına konacak; paylaşılan şablona yazılmayacak. Gerçek frontend URL'si ve işçi etkinliği hazır olduğunda yapılandırılacak. [Google SMTP ayarları](https://support.google.com/a/answer/176600?hl=en).

Henüz dağıtım, alan adı, gerçek SMTP, hesap frontend/BFF veya üretim yük testi yapılmadı; anonim harita BFF’si yerelde çalışır. Üretimde HTTPS, SMTP TLS, güvenilir frontend URL'si, özel sertifika/kalıcı anahtar halkası, sır yöneticisi, yedek/geri yükleme ve en az yetkili PostgreSQL/Redis erişimi yapılandırılacak. Geliştirme compose'u bu üretim ayarlarının yerine geçmez.

IP hız sınırı varsayılan 20 kimlik isteği/dakikadır ve süreç başınadır; tüm deployment'larda ortak Redis hız limiti henüz yoktur. Ters proxy adres güveni, çoklu instance senaryoları, genel abuse/load denemesi ve güvenlik gözden geçirmesi dağıtımla ele alınacak. Mevcut BFF genel katalog/39 terim, kaynaklı nesne bilgisi ve yerel poligonlarla IANA çözümlemesi içindir; kimlik için BFF ve güvenli HttpOnly/Secure cookie tasarımı hesap frontend'iyle uygulanacak. Tarayıcıya token depolayan UI henüz eklenmedi. Hesap silme, kişisel veri saklama süresi, süresi dolmuş oturum/outbox temizliği ve senkronizasyon P0 işleridir.

## Doğrulama kaydı

31 Ekim 2026: Release build 0 uyarı/0 hata; 18 çekirdek + 28 API/entegrasyon testi geçti. Gerçek PostgreSQL migration'ı, Redis cache/fallback, kimlik akışları, refresh yarışı/tekrar kullanımı, çıkış/yenileme yarışı ve geç çocuk oturum, sıfırlama iptali, yanlış JWT güveni/süresi ve outbox hata/yeniden denemesi sınandı. Yerel Mailpit ile tr/en gerçek HTTP kayıt → e-posta → doğrulama → giriş → profil → çıkış akışı da geçti; gerçek alıcılara e-posta gönderilmedi. `dotnet list Yorungez.slnx package --vulnerable --include-transitive` kontrolünde kullanılan güncel NuGet kaynağı bilinen zafiyet raporlamadı; bu, tüm uygulama için güvenlik garantisi değildir. Bunlar ürünün tüm AC'lerinin geçtiği, frontend'in tamamlandığı veya bilimsel sonuçların doğrulandığı anlamına gelmez.

## TECH-05 — Web oturumu ve hesap defteri

JWT/rotating refresh uçları korunur. Web BFF için `POST /api/v1/session/login` doğrulanmış hesaba korunan HttpOnly çerez ve profil döndürür; token çifti JS'ye dönmez. `GET /api/v1/auth/me` ve `POST /api/v1/auth/logout` çerez veya mevcut Bearer ile çalışır. Notebook `GET/POST /api/v1/notebook/` oturum gerektirir; beklenen hesap başlığı, revizyon ve özel sahiplik denetimi uygulanır. [Tam sözleşme](adr/0010-hesap-zorunlu-defter-ve-sunucu-kayitlari.md).

Web `api/account/*` ve `api/notebook` aynı köken BFF yollarıdır. Anonim kişisel kalıcılık/IndexedDB yoktur; hesap servisi erişilemiyorsa kişisel kayıt açılamaz/yazılamaz. Harita genel gömülü katalogla keşfe devam eder. Yeni Notebook migration'ı standart `--migrate` akışına dahildir; aynı PostgreSQL'de ayrı `notebook` şeması ve geçmiş tablosu kullanır. Notebook plandaki Personal Observatory modülünün ilk dilimidir.

`Start-LocalBackend.ps1` artık e-posta linkini varsayılan Web adresi `http://127.0.0.1:5190` olarak süreç kapsamında ayarlar; farklı portta `-FrontendUrl` verilir, mevcut özel dosya/sırlar değiştirilmez. Yerel doğrulama iletisi Mailpit (`http://127.0.0.1:8029`) üzerinden açılır. Üretimde `YORUNGEZ_WEB_ORIGIN` ve backend `Email:FrontendBaseUrl` aynı güvenilir HTTPS kökenidir. Çerez Secure/Strict, kalıcı DataProtection anahtarları, güvenilir proxy/IP sınırı ve gerçek SMTP dağıtım öncesi doğrulanmalıdır. Gmail app password hâlâ placeholder; gerçek dış gönderim açılmadı.
