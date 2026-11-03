# Ubuntu + Portainer + Traefik deployment

**3 Kasım 2026 / K-041.** Bu paket Docker Standalone içindir; Swarm stack'i değildir. Kullanıcı sunucuda kendisi deploy eder. Bu hazırlık sunucuya, Portainer'a veya DNS'e değişiklik uygulamaz.

| Public origin | Container | Internal port |
|---|---|---|
| `https://yorungez.com` | web | 3000 |
| `https://api.yorungez.com` | api | 8080 |

Tarayıcı hesap/defter için Web'in aynı kökenli `/api/...` BFF rotalarını kullanır. API alan adı ayrıca doğrudan JWT istemcileri/ileriki mobil için ayrıdır. Web'e JWT/SMTP sırrı verilmez. Cookie `__Host-`, HttpOnly/Secure/host-only kalır; wildcard cookie veya geniş CORS açılmaz.

## 1. Mevcut sunucuda kontrol edilecekler

- Docker Engine + Compose v2, Git, Python 3 ve OpenSSL. Traefik Docker provider ve çalışan HTTPS entrypoint/certificate resolver mevcut olmalı.
- Traefik'in **gerçek Docker network adı**, bu network üzerindeki **container IP'si**, entrypoint ve resolver adı `.env` içine girilmeli. Bunlar kurulumunuza bağlıdır; örnek isimler kanıtlanmış mevcut ayarlar değildir. Traefik IP'si sabit tutulmalı; değişirse `TRAEFIK_IP` de güncellenmeli. Tüm proxy'lere güven veren bir ayar kullanmayın.
- `10.89.0.0/24` mevcut Docker/LAN/VPN ağlarıyla çakışmamalı. Değiştirilirse `APP_SUBNET`, `API_INTERNAL_IP`, `WEB_INTERNAL_IP` birlikte değişmeli.
- API UID **1654**, Web UID **1000** ile root olmayan kullanıcıda çalışır. Keyring/certificate host izinleri buna göre hazırlanır.
- Traefik dışındaki container portları host'a açılmaz; PostgreSQL/Redis yalnız izole database ağında. API/Web, Traefik'in mevcut external network'üne bağlanır. SMTP/Wikipedia erişimi bu external ağın outbound bağlantısını kullanır.

## 2. Kaynağı alın ve image'ları aynı Docker host üzerinde hazırlayın

```bash
git clone https://github.com/YeloraStudio/yorungez.git
cd yorungez
VERSION=$(git rev-parse --short=12 HEAD)
docker build --pull -f deploy/Dockerfile.api -t yorungez-api:$VERSION .
docker build --pull -f deploy/Dockerfile.web -t yorungez-web:$VERSION .
```

Portainer'ın seçili environment'ı bu image'ların bulunduğu daemon olmalıdır. Farklı makinede build edilirse `docker save/load` veya sizin yönettiğiniz registry üzerinden taşıyın. Bu repo otomatik image publication/deployment yapmaz. Aynı sürümün API/Web image etiketlerini birlikte kullanın; üretimde `latest` yerine commit etiketi/digest kaydedin. Base runtime image'ları major/patch tag kullanır; işletim bakımında digest sabitleme ve güncelleme sorumluluğu size aittir. PostgreSQL/Redis digest'leri mevcut doğrulanmış projeden korunmuştur.

Build bağlamı **repo kökü** olmalı. Web hash'li kaynak verileri build'de hazırlar; PWA çekirdeği/görselleri ve filesystem'den okunan `generated` katalogları runtime image'a dahildir. `.dockerignore` gerçek ortam dosyalarını/anahtarları/local çıktıları image build'inden dışlar. Hiçbir gerçek sırrı build argümanı vermeyin.

## 3. Özel sunucu yapılandırmasını bir kez oluşturun

```bash
sudo python3 deploy/initialize-production.py --directory /opt/yorungez/private
```

Bu araç kalıcı keyring dizinini, şifreli PFX'i ve yalnız placeholder içeren özel ortam şablonunu hazırlar; mevcut hedefi **üzerine yazmayı reddeder**. PFX parolasını gizli terminal isteminde siz seçersiniz (en az 32 karakter); araç parolayı ortam dosyasına yazmaz/ekrana basmaz. Parolayı kendi secret yöneticinizde koruyun. PFX, public HTTPS sertifikası değildir. Traefik HTTPS sertifikasını mevcut resolver'ıyla ayrı yönetir. Oluşturulan `/opt/yorungez/private/.env` dosyasını sunucuda özel editörünüzle doldurun:

- `API_IMAGE=yorungez-api:<VERSION>`, `WEB_IMAGE=yorungez-web:<VERSION>`.
- Gerçek `TRAEFIK_NETWORK`, `TRAEFIK_IP`, `TRAEFIK_ENTRYPOINT`, `TRAEFIK_CERTRESOLVER`.
- SMTP gönderen/kullanıcı ve **gerçek uygulama parolası**; public `sender@example.com` yalnız örnektir. Yerel proje `.env` dosyasını repo/image'a taşımayın. Google uygulama parolasını boşluksuz girin. İşlem e-postaları İngilizce/markalı kalır.
- `POSTGRES_PASSWORD`, `REDIS_PASSWORD` için ayrı ayrı `openssl rand -hex 32`, JWT için `openssl rand -hex 64` ile sunucuda değer üretip kendi özel yapılandırmanıza girin; sohbet/log/public dosyalara koymayın. `KEYRING_CERT_PASSWORD`, PFX oluştururken seçtiğiniz **aynı** parola olmalıdır. Hex değerler bağlantı dizesi/Compose ayracı sorunlarını önler; `$`, `;`, `,`, tırnak ve satır sonu gibi karakterlerin parse etkisini değerlendirin.

PFX, PFX parolası ve keyring birlikte korunmalı; her deploy'da yeniden oluşturulmaz. Kaybolmaları cookie/token/outbox içeriklerini okunamaz yapabilir. Bu dosyalar özel kalır, public repoya/sohbete kopyalanmaz. Portainer environment değerleri yetkili Portainer yöneticilerince görülebilir; bu bir secret vault iddiası değildir.

## 4. Stack ön kontrolü ve Portainer

Sunucuda sırları ekrana dökmeyen yapı kontrolü:

```bash
sudo docker compose --env-file /opt/yorungez/private/.env \
  -f deploy/compose.production.yaml config --quiet
```

Portainer → ilgili **Docker Standalone environment** → Stacks → Add stack:

1. Ad: `yorungez-production` (kalıcı volume adlarının sabit kalması için sonradan rastgele değiştirmeyin).
2. Web editor/upload ile [compose.production.yaml](compose.production.yaml) içeriğini kullanın veya Git repository yöntemiyle bu dosyayı seçin.
3. Özel `.env` değerlerini Portainer environment alanlarına **yerel olarak** aktarın. Repo içine `.env` eklemeyin. Ubuntu'daki bind-mount yolları Docker daemon host'undaki gerçek mutlak yollar olmalı.
4. API/Web local image'ları için gereksiz registry re-pull seçmeyin. Build işlemi Portainer editor içinden otomatik yapılmaz; image'lar önceki adımda hazırlanmış olmalı.
5. Son adım **Deploy the stack** işlemini siz yapacaksınız.

`migrate` bir kerelik servistir: PostgreSQL/Redis readiness sonrası iki modülün migration'larını uygular, exit 0 verir. API bu başarıdan sonra; Web API readiness sonrası başlar. Migration başarısızsa API başlamamalıdır; volume silerek geçiştirmeyin. Uygulama restart'ı otomatik schema değişikliği çalıştırmaz. Eski image'a dönüş, geri döndürülemez yeni schema değişikliğini otomatik geri almaz; sürüm/migration uyumluluğunu yayın öncesi doğrulayın.

## 5. DNS ve TLS

- `yorungez.com` ve `api.yorungez.com` A/AAAA kayıtlarını **sizin public sunucu/ingress adresinize** bağlayın. Private LAN veya localhost adresi public DNS hedefi değildir. Yanlış AAAA eklemeyin.
- Cloudflare nameserver kaydı önceki oturumda Natro'da kaydedilmişti; propagation/Active durumunu yayın anında kontrol edin.
- Traefik resolver'ın ACME challenge yöntemi ve 80/443 erişimi mevcut kurulumunuzla uyumlu olmalı. HTTP→HTTPS yönlendirmesi Traefik'te mevcut global entrypoint yönlendirmesiyle sağlanmalı; bu stack başka projelerin global ayarlarını değiştirmez.
- Cloudflare kullanılıyorsa origin'in geçerli sertifikasından sonra **Full (strict)** kullanın. Flexible'a düşürmeyin. DNS-only test veya proxy seçimi mevcut challenge/ingress düzeninize göre yapılır.
- `/api/*`, `/en/account/*`, `/tr/account/*`, `/sw.js`, `/pwa-pack.json` için HTML/yanıtları “Cache Everything” ile cache'lemeyin; origin Cache-Control/no-store korunmalı. Özel kullanıcı verileri PWA/CDN'e girmemeli.
- `www` için bu pakette router yok; ana adres `yorungez.com`. `www` gerekirse ayrı redirect/router/sertifika kararıdır.

API forwarded headers yalnız **tam adresi tanımlı Traefik ve Web** hop'larından kabul edilir; `X-Forwarded-Host` kullanılmaz. Web HTTPS scheme bilgisini kendi sabit public origin ayarından üretir, istemcinin rastgele forwarding başlıklarını kopyalamaz. API health uçları container içi HTTP probe için açık kalır; ürün uçları production HTTPS yönlendirmesini korur.

## 6. Sizin yapacağınız yayın kabulü

- `migrate` exit 0; API/Web/Postgres/Redis healthy; dışarıya DB/Redis portu açılmamış.
- Her iki domain'de geçerli TLS, yönlendirme döngüsü yok; `/health/ready` ve genel katalog erişilir.
- EN/TR harita, saat dilimi/arama/terim/takvim ve PWA güncelleme/yeniden açılış.
- Sentetik bir hesapla kayıt → **gerçek e-posta teslimi** → doğrulama → giriş → kayıt → çıkış/ikinci oturum. Parola/reset linki, cookie Secure/HttpOnly ve doğru Web origin kontrolü.
- Mobil GPS/pusula/PWA fiziksel kabulü, üretim yükü ve işletim/kurtarma kabulleri önceki planda açık kalır. Image build/smoke testi bunların yerine geçmez.

[CI container smoke testi](../scripts/Verify-Containers.sh) yalnız disposable Linux runner'da kendine ait fixture/volume/network kullanır; gerçek Portainer'a bağlanmaz. [Smoke override](compose.smoke.yaml) host test portları açar ve outbox worker'ı kapatır: **üretime uygulanmaz**.

Kaynaklar: [Portainer stack kurulumu](https://docs.portainer.io/user/docker/stacks/add), [ASP.NET Core güvenilen proxy başlıkları](https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/proxy-load-balancer?view=aspnetcore-10.0). Mevcut .NET/CQRS/mimari, lisans, bilimsellik ve aynı backend ile mobil hedefi korunur.
