# TECH-10 / K-033 — Yerel yedek ve geri yükleme provası

**2 Kasım 2026.** K-032 sonrasında onaylanan ilk yerel paket uygulandı. İz: **A-006, ARCH-01, FR-06–09, UJ-04/UJ-07, AC-07–09**. Gerçek PostgreSQL arşivi, ayrı boş test veritabanı ve yeni uygulama örneğiyle kurtarma sınandı. Deployment, HTTPS, canlı yayın ve fiziksel telefon kabulü beklemede kalır.

## Tekrarlama

Bu projenin yerel PostgreSQL servisi ve özel yerel ayarları hazırken, depo kökünden:

```powershell
./scripts/Verify-Recovery.ps1 -Offline
```

`-Offline`, kurulu kilitli .NET bağımlılıklarını kullanır. İlk kurulumda bu parametreyi kaldırmak kilitli restore yapar. Varsayılan `Debug`, çalışan normal Release API dosyalarını kilitlemez. `-Configuration Release` yalnız uygun ayrı ortamda kullanılabilir. Prova normal `Verify-Backend.ps1` / çözüm testlerinin de parçasıdır; ayrı bir skip veya gizli aktivasyon bayrağı yoktur.

[Başlatıcı](../scripts/Verify-Recovery.ps1) servis açmaz/kapatmaz ve canlı veritabanı adı/connection string parametresi almaz. [Düzenek](../tests/Yorungez.Api.Tests/Recovery/LocalRecoveryEnvironment.cs), mevcut Compose PostgreSQL konteynerinin `yorungez/postgres` proje/servis etiketini ve loopback portunun özel test bağlantısıyla eşliğini doğrular. Ardından bu çalıştırmaya özgü GUID taşıyan `yorungez_recovery_<guid>_source` ve `_restored` veritabanlarını oluşturur. Başarılı CREATE ile sahipliği kaydedilmeyen hedefe dump/restore/temizlik yapılmaz; restore hedefi boş olmalıdır.

İç HTTP test sunucusu dışarıya port açmaz. SMTP göndericisi yalnız bellek içi yakalama, Redis yerine ayrı bellek cache'i kullanılır. Gerçek hesap, koordinat, SMTP ayarı, JWT sırrı veya normal Data Protection anahtarlığı kopyalanmaz. Geçici veritabanları doğrulama sonunda kaldırılır; yalnız bu çalıştırmanın oluşturduğu adlar temizlenir.

## Sınanan kurtarma

1. Gerçek migration'larla `identity` ve `notebook` şemaları oluşturulur. Üç sentetik hesap; iki farklı sahibin **aynı kayıt kimliklerini** kullanması dahil toplam yedi kayıt hazırlanır. Not/favori/gözlem/konum, ikinci revizyon, çöp kutusu, gerçek UTC gözlem zamanı ve bağımsız konum kopyası bulunur.
2. Tablo adları, sıralı bütün satırlar ve her iki migration geçmişi için içerik özeti alınır. `pg_dump --format=custom --no-owner --no-acl` ile gerçek arşiv üretilir. Bundan sonra yazılan bir kayıt, kurtarılan yedekte bulunmamalıdır.
3. Ayrı test anahtarlığı sertifikayla korunur; keyring ve parola korumalı test PFX'i yedek paketine kopyalanır. Dosya boyut/SHA-256 manifesti arşiv ve anahtar dosyalarını birlikte kapsar. Test PFX parolası yalnız işlem belleğindedir; rapor/log'a yazılmaz ve saklanmaz.
4. Bilerek kısaltılan arşiv, manifest kontrolünde SQL çalıştırılmadan reddedilir; hedefin boş kaldığı kontrol edilir. Doğru arşiv tekrar konup `pg_restore --single-transaction --exit-on-error` ile geri yüklenir. Binary akış .NET stream üzerinden taşınır; PowerShell metin yönlendirmesi kullanılmaz.
5. Uygulama hedefe ilk yazısını yapmadan önce **bütün uygulama tablo satırlarının özeti ve satır sayıları** kaynak anıyla aynı olmalıdır. Her iki migration geçmişi bulunmalı, bekleyen migration olmamalıdır.
6. Yeni uygulama, farklı dizine kopyalanmış keyring ve kopyadan yüklenen test sertifikasıyla açılır. Kaynak provider nesnesi yeniden kullanılmaz. Anahtarlık yokken veya sertifikanın özel anahtarı yokken şifreli kuyruk okunamaz; doğru yedekle bütün şifreli içerik eşleşir. Bekleyen iki ileti yalnız test yakalayıcısına işlenir; yedekten gelen doğrulama bağlantısı test hesabında çalışır.
7. Eski cookie ile oturum sürekliliği, anonim erişimin reddi ve hesaplar arası sahiplik sınırı kontrol edilir. Ayrı test hedefindeki oturumlar açıkça iptal edilip security stamp'ler yenilenir; eski cookie'ler reddedilir, aynı parola ile yeni giriş ve kayıt okuma/yazma çalışır. Eski not revizyonu çakışma verir; güncel revizyonla düzenleme ve çöpten geri alma çalışır.

Kurtarma sonunda üretilen özel `result.json` yalnız kontrol adları, tablo sayıları, içerik özeti, arşiv boyutu ve sonuç taşır. Bu turdaki [public kanıt kopyası](science/recovery-drill-qa.json) sentetik çalıştırmadan gelir; dump, PFX, keyring ve işlem bilgileri public kopyaya girmez. Özel çıktılar `.local/recovery-drills/<guid>/` altındadır. Test PFX parolası saklanmadığı için bu klasör kalıcı/elle kullanılabilir üretim yedeği olarak sunulmaz.

## Sonuç

Yerel bağımsız prova geçti; ardından tüm çözümde **127 .NET testi** geçti: 18 çekirdek, 19 astronomi, 90 API/entegrasyon. Başarılı çalıştırmada üç hesap, yedi kayıt, dört outbox satırı ve iki oturum satırı arşivden geri geldi; 17 kurtarma kontrolü uygulandı. Test veritabanları kaldırıldı. Başka bir cihaz/sunucu/işletim sistemi veya üretim yükü bu sonuçla kabul edilmiş değildir. Web ve bilimsel hesap kodu değişmedi.

## Kurtarma planının sınırları

- **Veritabanı tek başına yeterli değildir.** Keyring, aynı uygulama/purpose tanımları ve anahtarları açan sertifika özel anahtarı/parola erişimi de korunmalıdır. Prova bağımsız test sertifikası kullanır. Normal Windows geliştirme keyring'i kullanıcıya bağlı DPAPI kullanır; yalnız dosya kopyası başka makinede kurtarma kanıtı değildir. Bu değişiklik normal DPAPI veya üretim sertifika politikasını değiştirmez.
- **Yedek, alındığı anı geri getirir.** Sonraki yazılar ve oturum iptalleri kaybolabilir. Prova eski oturumların da dönebildiğini ve açık iptal/yeni giriş işlemini gösterir; canlı ortamda otomatik kurtarma komutu kurulmadı. Gerçek kurtarmada erişim kapalı tutulmalı, kuyruk göndericisi başlamamalı; oturumlar, güvenlik damgaları ve bekleyen işlem bağlantıları kontrollü ele alınmalıdır. Testin iki iletiyi yakalaması gerçek alıcılara eski iletileri yeniden gönderme yetkisi değildir.
- **Custom arşiv sıkıştırmadır, veri şifrelemesi değildir.** SHA-256 manifesti kazara bozulmayı saptar; saldırganın değiştirdiği manifesti doğrulayan imza değildir. Burada yalnız aynı testin ürettiği güvenilir arşiv yüklenir. Üretim şifreli yedek, erişim, saklama süresi, ayrı güvenli kopya ve kurtarma sırları daha sonra ele alınacak.
- **Cluster/PITR kanıtı yoktur.** Roller/ACL (`--no-owner --no-acl`), işletim sistemi, WAL/PITR, farklı sürüm ve büyük veri performansı bu provada yoktur. Redis geçici cache'tir ve kişisel kayıtların kaynağı değildir; genel kataloglar ve kaynaklı görseller Git/veri manifestlerinde ayrıca bulunur. Üretim yedek/geri yükleme kabulü açık kalır.

Kaynaklar: PostgreSQL 18 [pg_dump](https://www.postgresql.org/docs/18/app-pgdump.html) ve [pg_restore](https://www.postgresql.org/docs/18/app-pgrestore.html); ASP.NET Core [Data Protection yapılandırması](https://learn.microsoft.com/en-us/aspnet/core/security/data-protection/configuration/overview?view=aspnetcore-10.0) ve [anahtarların saklanırken korunması / DPAPI](https://learn.microsoft.com/en-us/aspnet/core/security/data-protection/implementation/key-encryption-at-rest?view=aspnetcore-10.0).

Sıradaki yerel paket: [iki dil, klavye/odak ve erişilebilirlik denetimi](yayin-oncesi-yerel-plan.md). Kota/kalıcı silme/içe aktarma, performans, P1/P2 ve fiziksel/üretim açık işleri korunur.
