# ADR-0010 — Hesap zorunlu Defterim ve sunucu kayıtları

**Sonraki K-027–028:** [ADR-0012](0012-hesap-menusu-ve-ad-soyad.md) yeni kayıtta ad-soyadı zorunlu yapar; [ADR-0013](0013-genel-gokyuzu-pwa-ve-cevrimdisi-paket.md) yalnız genel PWA cache'ini uygular. Kişisel sunucu sahipliği/özel cache yasağı korunur. Aşağıdaki ilk paket metni kendi tarihinin kanıtıdır.

**31 Ekim 2026 / K-024. Durum: uygulandı.** Kullanıcı açıkça anonim/tarayıcıda kişisel kalıcılığı reddetti. Bu karar ADR-0009/K-023'ün yerel kayıt ve hesaba aktarım yönünün yerine geçer. FR-06–07/FR-09/FR-11; UJ-04–05/UJ-07; AC-07–09/AC-12–13. Başlangıç arşivi tarihsel kalır.

## Ürün sözleşmesi

Harita, Bu gece, Takvim, arama ve terimler hesapsız çalışır. Favori, not/anı, ileride gözlem ve kayıtlı konum için hesap ve e-posta doğrulaması gerekir. Yeni kişisel kayıtlar PostgreSQL'de kullanıcıya bağlıdır. IndexedDB/localStorage, anonim JSON deposu, kalıcı tarayıcı taslağı ve çevrimdışı kişisel yazma kuyruğu yoktur. Açık sayfadaki kaydedilmemiş taslak yalnız bellektedir. JSON indirme açık kullanıcının dışa aktarma eylemidir; uygulama deposu değildir. Önceki deneyin IndexedDB'si okunmaz/aktarılmaz; mevcut veriler sessiz silinmez.

## Modül ve veri

Notebook, plandaki Personal Observatory mantıksal modülünün ilk fiziksel dilimidir; dokuzuncu bir mantıksal servis önerisi değildir. Domain/Application/Infrastructure ayrıdır; CQRS/MediatR 12.5.0 korunur. Aynı PostgreSQL sunucusunda ayrı `notebook` şeması, migration geçmişi ve `Entries` tablosu kullanılır. Başka modülün tablolarına erişmez; sahibi Identity'nin kamu sözleşmesindeki kullanıcı kimliğidir. Birincil anahtar `(UserId, Id)`; bütün okuma/yazmalarda sahibi sunucu oturumundan gelir. Gövdeyle gönderilen kullanıcı kimliğine güvenilmez. Favori hedef başına tektir. Not UUID'si/tür/revizyon/gövde/opsiyonel hedef-zaman-konum ve çöp kutusu korunur. Sistem zamanını sunucu üretir; gerçekleşmiş gözlem zamanı değildir.

Her güncelleme PostgreSQL'de beklenen revizyonla atomik olarak koşulludur. Eski sürüm 409 döner; metin bellekte korunur, yeni kopya veya diğer sürümü inceleme mümkündür. İlk oluşturma yarışında birleşik PK yinelenmeyi engeller. Başarı yalnız commit yanıtından sonra gösterilir. Ağ zaman aşımı işlemin gerçekleşmediğini kanıtlamaz; liste yenilenerek kontrol edilir. Not kimliği yeniden denemede korunur. Silme geri alınabilir çöp kutusudur; kalıcı temizleme ayrı sonraki iştir.

## Web oturumu

Next.js aynı köken BFF kullanır. Mevcut JWT access/rotating refresh API sözleşmesi korunur. Web girişi ayrıca ASP.NET DataProtection ile korunan HttpOnly/SameSite=Strict oturum çerezi alır; JS'ye JWT/refresh/parola dönmez. Üretimde `__Host-yorungez-session`, Secure ve Path=/; localhost geliştirme/testte `yorungez-session` ve isteğin HTTPS durumuna göre Secure. Sabit mutlak ömür yapılandırılmış refresh ailesi ömrünü aşmaz (varsayılan 7 gün); sessiz uzatma yoktur. Her istekte doğrulanmış hesap/security stamp/aile iptali/son kullanım kontrol edilir. Çıkış aileyi iptal eder; parola sıfırlama mevcut aileleri iptal eder. Bu Web yolu dönen refresh token'ını tarayıcıda tutmaz ve rotasyon yarışına girmez.

BFF yalnız izinli sabit uçlara gider, yalnız oturum çerezini aktarır; no-store/private, Cookie vary ve zaman sınırı vardır. Değiştiren istekler JSON + özel istek başlığı + aynı Origin gerektirir; cross-site Fetch Metadata reddedilir. API çerezli yazmalarda aynı kontrolleri yapar. Üretimde `YORUNGEZ_WEB_ORIGIN` güvenilir dış HTTPS kökenine, backend `Email:FrontendBaseUrl` aynı kökene ayarlanır; reverse proxy/istemci IP güveni dağıtım öncesi ayrıca doğrulanır. Notebook hız limiti hesaba göre bölünür. Sırlar/ham gövde/hassas koordinatlar loglanmaz.

Eski A sekmesinin B hesabına taslak yazmasını önlemek için Notebook isteği beklenen hesap başlığını taşır; oturumla uyuşmazsa 409. Liste sahibi ayrıca yanıtta doğrulanır. Panel açılışı/odak ve BroadcastChannel hesap değişimini yeniden kontrol eder; kalıcı hesap önbelleği yoktur. Hesap değişimi/çıkış eski bileşeni ve bellekteki kayıtları kaldırır. Aynı hesabın yeniden girişinde açık taslak bellekte kalabilir; yenileme sonrası kalıcılık vaadi yoktur.

## E-posta ve sınırlar

Kayıt yalnız e-posta/parola ister; doğrulama bekleme, yeniden gönderme, giriş, çıkış, unutulan parola ve sıfırlama ekranları TR/EN vardır. Mail linkinde token query yerine fragment'tir; sayfa açılışında URL'den kaldırılır, açık eylemle sunucuya iletilir. Link sayfaları cache edilmez, referrer göndermez. Gerçek Gmail ayarı placeholder ve gerçek dış gönderim kapalıdır; test fake/Mailpit ile yapılır. Doğrulama zorunluluğu bu nedenle üretim SMTP kurulmadan herkese açık hazır anlamına gelmez.

PWA genel katalog önbelleği/çevrimdışı keşif hedefi sürer; özel kayıtları çevrimdışı kalıcılaştırma ve anonim aktarım hedefi kaldırılmıştır. Fiziksel GPS/pusula, kayıtlı konum/gerçek gözlem modeli, kalıcı silme/içe aktarma, üretim işletimi/backup ve ek takvim kaynakları açıktır. [Güncel uygulama ve kanıt](../hesap-ve-sunucu-defteri.md).

Kaynaklar: [ASP.NET Core 10 cookie doğrulaması](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/cookie?view=aspnetcore-10.0), [Next.js Route Handlers](https://nextjs.org/docs/app/getting-started/route-handlers), [EF Core concurrency](https://learn.microsoft.com/en-us/ef/core/saving/concurrency).
