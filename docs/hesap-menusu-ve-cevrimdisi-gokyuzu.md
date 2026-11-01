# TECH-07 — Hesap menüsü, ad-soyad ve çevrimdışı gökyüzü

**1 Kasım 2026 / K-027–028 / PRD 1.10.** [Hesap ADR'si](adr/0012-hesap-menusu-ve-ad-soyad.md), [genel PWA ADR'si](adr/0013-genel-gokyuzu-pwa-ve-cevrimdisi-paket.md). FR/UJ/AC kimlikleri ve önceki bilimsel sınırlar korunur.

## Düzeltilen hesap akışı

Hesap erişim hatasında yerel API/altyapı kapalıydı; arayüz bütün servis hatalarını internet bağlantısı sorunu gibi gösteriyordu. Oturumsuz `me` kontrolü artık .NET'e gerek duymadan 401 verir. Hesap servisi erişim sorunu, çevrimdışı tarayıcı ve giriş yapılmamış durumları ayrıldı. Giriş/kayıt formu servis hatası yüzünden gizlenmez; gerçek gönderim yine çalışan backend gerektirir.

Menünün marka alanının altında oturumsuz **Giriş yap / Kayıt ol**, oturumlu **ad-soyad, e-posta, hesabım/defterim ve çıkış** bulunur. Menü ve Defterim ortak oturum durumuyla güncellenir. Kayıtta ad, soyad, e-posta ve parola alınır. Her isim 1–100 karakter, Unicode ve kontrol karaktersizdir; sunucu doğrular. Eski hesaplara ad uydurulmaz, giriş sonrası tamamlatılır. Profil yazma aynı oturum sahibine kapsamlanır, başka sekmede hesap değişimi korunur. Migration `20261101084830_AccountNames` uygulandı, EF model farkı yok.

Yerelde bütün uygulamayı bir terminalde başlat:

```powershell
./scripts/Start-LocalApp.ps1
# http://127.0.0.1:5190/en veya /tr — terminali açık tut
# Otomatik QA için gerçek Gmail yerine:
./scripts/Start-LocalApp.ps1 -EmailMode Mailpit
# Ayrı terminalde yalnız bu başlatıcının süreçlerini durdur:
./scripts/Stop-LocalApp.ps1
# İstenirse bu Compose projesinin servislerini de durdur; volume silmez:
./scripts/Stop-LocalApp.ps1 -StopInfrastructure
```

Docker Desktop çalışmalıdır. Dolu portta mevcut hizmet durdurulmaz. Hazır olma denetimi gerçek loopback TCP/HTTP ile yapılır; süreç sahipliği PID ve UTC oluşturma anıyla denetlenir. Tekil backend/Web scriptleri korunur. `Auto` özel `.env` Gmail ortamını kullanır; testler fake/Mailpit kullanır. Gerçek alıcıya test e-postası gönderilmedi.

## PWA ve çevrimdışı açılış

Menüde **Uygulama ve çevrimdışı** paneli vardır. Genel paket hazırlanma/hata/hazır durumu, sürüm/boyut ve isteğe bağlı görseller gösterilir. Manifest/ikonlarla tarayıcıdan uygulama olarak kurulum yolu sunulur. Fiziksel kurulum kabulü ayrıca yapılacaktır.

Çekirdek TR/EN HTML, JS/CSS/font/Worker, aynı bilimsel katalog ve 52 terim ile 2623 takvim olayını kapsar: mevcut build 51 dosya, yaklaşık 4,2 MiB. Panorama/çizim/Güneş fotoğrafları 88 dosya ve yaklaşık 12,7 MiB'dır. Eksik fotoğraf/çizim temel hesabı engellemez; tamamı açık eylemle hazırlanır. Kaynak atıfları korunur. Dosyalar kaynak hash'lerinden ve build SHA-256 envanterinden doğrulanır; üretim derlemesi gerçek HTML bağımlılıklarını denetler.

Kişisel kayıtlar, ad-soyad/e-posta, oturum, koordinat sorgusu, hesap sayfası ve POST yanıtları genel cache'e alınmaz. Offline kişisel yazma kuyruğu yoktur. Kullanıcı taslağı açık sayfa belleğindedir; yenilemede kalıcılık vaadi yoktur. Yeni sürüm, taslaklar kaydedilip diğer sekmeler kapatıldıktan sonra açık kullanıcı eylemiyle etkinleşir. Başarısız yeni paket önceki paketi değiştirmez. Tarayıcının cache'i temizleyebilmesi ve ilk ziyaretin bağlantı gerektirmesi açıklanır.

Wikipedia, yer adı/coğrafi saat dilimi sorgusu ve OSM döşemeleri offline sayılmaz. UTC/elle IANA ve manuel koordinat çalışır; konumun otomatik bölgesi bilinmiyorsa UTC görünürdür. Örnek konum GPS konumu gibi etiketlenmez.

## Doğrulama

125 .NET testi (18 çekirdek, 19 astronomi, 88 API/gerçek PostgreSQL–Redis), 44 istemci testi ve üretim derlemesi geçti. Yeni kontroller ad-soyad zorunluluğu/kontrol karakteri, Unicode ve trim, profil sahipliği/hesap değişimi, backend'siz anonim oturum kapısı, cache dışı kişisel API/POST/RSC/sorgu, başarısız/private yanıtlı paket, kodlanmış dil dosyası ve çok sekmeli güncelleme engelini kapsar.

IAB geliştirici kabulünde mevcut sentetik hesapla giriş, isim tamamlama, eski kayıtların korunması ve menüde **Public Observer** gösterimi doğrulandı. Ad-soyadlı kayıt formu ve iki dil kontrol edildi. Web/API süreçleri durdurulduktan sonra yeni sekmede Türkçe harita yeniden açıldı ve yenilendi; takvimden 1 Kasım 2026 20:28 UTC Son dördün seçimi Ay hesabına/haritaya geçti. DOM yük durumu `ready`; Ay azimut 59,0°/yükseklik −5,9° ve ufuk altı etiketi korunur. Bu eylem kullanıcının gerçek gözlem yaptığına kanıt değildir. Eksik Wikipedia açıklaması dürüstçe bildirildi; hesap kayıtları sunucusuz gösterilmedi.

[Kayıt formu](ux/pwa-account/register-en.png), [ad-soyadlı menü](ux/pwa-account/signed-in-menu-en.png), [sunucular kapalıyken çalışan harita](ux/pwa-account/offline-map-tr.png). İsteğe bağlı genel görseller 88/88 hazırlandı, bağlantı geri dönüşü ve yeni sürümün açık güncelleme/yeniden açılması da kontrol edildi ([güncelleme ekranı](ux/pwa-account/update-ready-tr.png)). Eski worker temizliğinin gelecekteki bekleyen paketi silmemesi ek otomatik testle doğrulandı; temizleme yalnız kurulumda kaydedilen önceki paketlere yeni worker etkinleşince uygulanır. Son düzeltilmiş paket normal `/en` adresinde hazır olarak açıldı ([son paket ekranı](ux/pwa-account/final-pack-en.png)). Çıkış menüyü giriş/kayıt durumuna döndürdü; Türkçe ad-soyad formu doğrulandı. Ayrıntılar [makine okunur kayıtta](science/account-pwa-qa.json).

Bu test Windows internetini kesme veya fiziksel telefon/ekran okuyucu/kurulum/kalıcı depolama garantisi değildir. Tarayıcıda kullanıcı cache'i silerse yeniden hazırlamak gerekir. Özel verinin üretim yedek/geri yüklemesi, kota/import/kalıcı silme, gerçek posta istemcisi teslimi, fiziksel GPS/pusula ve ek meteor/asteroit/Ay–yıldız/tutulma kaynak doğrulaması açık kalır. Astronomi algoritmaları ve önceki kutup yön istisnaları değiştirilmedi; tüm MVP-0/P0 tamamlandı denmez.

## Sıradaki çalışma

Gerçek cihaz GPS/pusula/ekran okuyucu kabulü [mevcut protokolle](cihaz-konum-pusula-dogrulamasi.md) yürütülecek. Yazılım tarafında kişisel PostgreSQL verisinin **yedek/geri yükleme provası ve işletim kontrolleri**, ardından kota/import/kalıcı temizleme ve kaynaklı ek takvim türleri izlenecek. Genel offline ve hesap kabulünün fiziksel cihaz/çok tarayıcı kapsamı genişletilecek.

Son teslim: API readiness 200, Web 200, anonim hesap kontrolü 401/no-store-private; uygulama özel Gmail ortamını kullanan `Auto` başlatıcıyla açık bırakıldı. Sentetik QA hesabından çıkıldı. 562 yerel bağlantı ve bütün 12 FR/7 UJ/14 AC kimliği doğrulandı; başlangıç arşivinin SHA-256 özeti aynı. Deneme e-postaları gerçek alıcılara gönderilmedi.
