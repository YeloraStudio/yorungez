# TECH-05B — Gmail, markalı e-posta ve varsayılan İngilizce

**K-025 / PRD1.8.** Kullanıcı göndereni `sender@example.com` olarak düzeltti, yerel uygulama parolasını sağladı, bütün işlem e-postalarını İngilizce ve uygulama varsayılan dilini İngilizce istedi. Türkçe arayüz/API işlev eşliği sürer; işlem e-postası dili son kullanıcı kararıyla sabit İngilizcedir. FR-07/FR-11; UJ-04; AC-08–09/AC-13. Önceki placeholder notları tarihsel durumdur.

## Yapılanlar

- Gerçek parola yalnız kökteki özel `.env` içinde `EMAIL__PASSWORD` değeridir; bu belge/örnek yapılandırma/test/önizleme parolayı içermez. `.gitignore` dışlaması ve kaynak/Web statik çıktısı taraması doğrulandı. Git push/dağıtım yapılmadı.
- Gmail `smtp.gmail.com:587`, zorunlu STARTTLS, düzeltilmiş gönderen/kullanıcı ve uygulama parolası yapılandırıldı. TLS ve SMTP kimlik doğrulaması gerçek Google bağlantısıyla başarılı oldu; bu tanılama hiçbir e-posta göndermedi.
- Doğrulama ve parola sıfırlama şablonları graphite/burgundy/sand/ivory markasıyla, belirgin işlem düğmesi, 2 saat geçerlilik, güvenlik açıklaması ve kopyalanabilir bağlantıyla hazır. Dış görsel/font/izleme yoktur. MIME `multipart/alternative` HTML + düz metin içerir; işlem URL'si HTML-encode edilir.
- Arayüz Türkçe olsa da yeni outbox iletileri ve bağlantı ekranları İngilizcedir. Önceden bekleyen eski düz metin ileti, gönderimden önce İngilizce şablona yükseltilir; token fragment'i değişmez. Şifreli outbox/retry/lease ve parola sıfırlama oturum iptali korunur.
- `/` her zaman `/en` açar. API'de dil yok/desteklenmiyor ise İngilizce; `/tr`, `Accept-Language: tr` veya ilgili BFF `lang=tr` açık seçimi Türkçeyi korur. Tarih/saat dilinden bağımsız UTC anı sözleşmesi değişmez.

## Yerel kullanım ve dağıtım

```powershell
./scripts/Start-LocalBackend.ps1
# Auto: özel EMAIL__PASSWORD varsa Gmail; yoksa Mailpit.
# Gerçek dış gönderim istemeyen test/geliştirme:
./scripts/Start-LocalBackend.ps1 -EmailMode Mailpit

# SMTP bağlantı/kimlik doğrulama kontrolü; ileti göndermez, outbox başlatmaz:
./scripts/Test-Smtp.ps1
```

Script `.env` içindeki yalnız izinli `EMAIL__*` değerlerini backend işleminin ortamına alır, süreç sonunda eski ortamı geri yükler; parolayı `appsettings.Local.json` veya Web dizinine kopyalamaz. `Initialize-LocalEnvironment.ps1` mevcut özel dosyayı korur. Gerçek API `Gmail` modunda başlatıldığında kullanıcının kayıt/kurtarma eylemleri gerçek e-posta oluşturur. Otomatik testler fake/Mailpit kullanır.

Sunucuda aynı `EMAIL__HOST/PORT/SENDER/USERNAME/PASSWORD/REQUIRETLS/RUNOUTBOXWORKER` değişkenleri backend sürecine verilir. .NET `.env` dosyasını kendiliğinden okumaz: örneğin API konteynerinin `env_file`/`--env-file` ayarı veya servis yöneticisinin ortam dosyası kullanılır. Bu deponun Compose dosyası şu anda yalnız yerel altyapıdır, hazır API dağıtımı değildir. Gerçek sır [örnek `.env`](../.env.example) veya [Gmail şablonuna](../config/smtp.gmail.example.json) yazılmaz. Üretimde `Email__FrontendBaseUrl` ve `YORUNGEZ_WEB_ORIGIN` gerçek Web HTTPS kökenine, API adresi ve DataProtection/DB/Redis ayarları sunucuya göre tanımlanır. [Oturum sözleşmesi](adr/0010-hesap-zorunlu-defter-ve-sunucu-kayitlari.md).

Önizlemeler gerçek token içermez: [doğrulama HTML](ux/emails/confirmation.html), [doğrulama görüntüsü](ux/emails/confirmation.jpg), [sıfırlama HTML](ux/emails/reset.html), [sıfırlama görüntüsü](ux/emails/reset.jpg). Yeniden üretme (Development, Release derlemesi mevcut): `dotnet run --project src/Yorungez.Api --configuration Release --no-build -- --preview-emails`.

## Kanıt ve sınırlar

106 .NET testi geçti (18 çekirdek,19 astronomi,69 API); 35 istemci testi, Release build (0 uyarı/0 hata) ve Next üretim derlemesi geçti. Yeni kontroller: TR/EN kayıt isteğinde İngilizce mail, MIME HTML/plain roundtrip, kaynaklı işlem URL'sinin kaçışları, eski outbox dil yükseltmesi ve eksik dilde İngilizce. SMTP script sözdizimi kontrol edildi. HTTP'de `/en` yönlendirmesi, varsayılan İngilizce ve açık Türkçe terms/Sun uçları 200 doğrulandı. HTML iki şablon tarayıcıda incelendi.

Gerçek bir alıcıya gönderim ve Gmail/Outlook/iOS mail istemcileri arası gelen kutusu/render/teslim edilebilirlik kabulü yapılmadı. Başarılı SMTP AUTH tek başına gelen kutusuna teslim veya üretim hazır sertifikası değildir. Gmail göndereni/alan adı teslim yapılandırması, gerçek mobil GPS/pusula, PWA/offline, üretim DB yedek/geri yükleme ve ek takvim kaynakları kalan işlerdir. Önceki bilimsel referanslar ve kutup yön sınırı değişmedi.

## Şu anki proje ve sıradaki adım

Tam ekran iki dilli gökyüzü; katalog/arama/nesne kartları, konum/UTC-IANA/simülasyon, katmanlar, Bu gece, kaynaklı Takvim ve sensörsüz yön yardımı çalışır. Hesap kaydı/giriş/doğrulama/kurtarma, güvenli Web oturumu ve PostgreSQL'de hesaba özel favori/not var. [Önceki hesap paketi](hesap-ve-sunucu-defteri.md), [bütün gereksinimler](teslimat-izlenebilirligi.md).

Bir sonraki somut P0 dilimi **gerçek gözlem kayıtları ve kayıtlı konumlar**: nottan ayrı minimum gözlem modeli, gerçekleşen gözlem zamanı, isteğe bağlı nesne/konum bağları, özel hesap sahipliği ve geçmiş konumu koruyan snapshot. Aynı PostgreSQL envanterine bağlanacak; anonim/tarayıcı kalıcılığı geri getirilmeyecek. Sonraki kabul işlerinde fiziksel GPS/pusula ve genel katalog PWA/offline sürer.

Kaynaklar: [Google Gmail SMTP/STARTTLS](https://support.google.com/mail/answer/7104828?hl=en), [MimeKit BodyBuilder](https://mimekit.net/docs/html/T_MimeKit_BodyBuilder.htm).

[Makine okunur kontrol kaydı](science/email-default-language-qa.json) ve [varsayılan İngilizce ekranı](ux/emails/default-en.jpg) bu paketin kanıtıdır. Özel parola değeri kontrol kaydına dahil edilmedi.
