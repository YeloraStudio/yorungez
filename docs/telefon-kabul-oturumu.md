# Telefon kabul oturumu — S23 / iPhone 15

**K-032 / 2 Kasım 2026:** Kullanıcı deployment/HTTPS ve canlı yayını erteledi. Bu oturum, kullanıcı ortam hazır olduğunu bildirene kadar beklemede; domain/alt alan adı/tünel kurulumu kendiliğinden başlatılmaz. Yerel geliştirme [ayrı iş sırasıyla](yayin-oncesi-yerel-plan.md) devam eder.

**Durum: hazırlanmış protokol; fiziksel oturum yürütülmedi.** Mevcut [DV-01–12 protokolünün](cihaz-konum-pusula-dogrulamasi.md) cihaz bazlı uygulama kartıdır. Masaüstü viewport veya sentetik sensör sonucu telefon kabulü olarak işaretlenmez.

## Ortam ön koşulu

Her iki telefonun açabileceği, geçerli sertifikalı bir HTTPS test kökeni gerekir. Şu anda hazır adres yoktur. Bilgisayardaki `127.0.0.1` adresi telefonda bilgisayarı göstermez; LAN HTTP veya atlanmış sertifika uyarısı sensör/PWA kabulü için kullanılmaz. Bu belge public deploy, tünel, router portu veya yeni sunucu erişimi açmaz. Uygun ortam hazırlanırken gerçek sırlar GitHub'a veya istemciye konmaz; test hesabı ve posta yakalama kullanılır.

Test URL'si, Web/BFF kökeni, API'nin beklediği Web kökeni ve e-posta dönüş adresi aynı ortamla tutarlı olmalıdır. Altyapı/SMTP portları public açılmaz. HTTPS hazır olunca bu adres buraya canlı sır/erişim bilgisi yazılarak değil, oturumda doğrulanarak kullanılır.

## Cihaz matrisi

| Cihaz | Tarayıcı | OS/tarayıcı sürümü | Sonuç |
|---|---|---|---|
| Samsung Galaxy S23 | Chrome | Oturumda kaydedilecek | Bekliyor |
| iPhone 15 | Safari | Oturumda kaydedilecek | Bekliyor |

Chrome/Brave/Edge masaüstü sonuçları ayrı tutulur; kurulu olması test edildiği anlamına gelmez. Bilgisayarda IAB ve Brave yazılım kontrolleri [TECH-08'de](responsive-cihaz-ve-pwa-kabulu.md) kayıtlıdır.

## Kısa uygulama sırası

1. Yeni ziyarette İngilizce örnek konum ve kapalı pusula/menü, üç varsayılan katman; izin istemeden harita (DV-01).
2. Önce Türkçe/İngilizce arama, takvim ve Bu gece; geri dönüş; tarih/ay/yıl seçimi. Dikey/yatay görünüm, ekran çentiği, açık klavye ve metin büyütmede kontrollerin erişilebilirliğini kontrol et (DV-06/11/12).
3. Konuma izin ver: doğruluk aralığı ve ölçüm zamanı görülsün. Reddet/kapat/zaman aşımı ve manuel seçim çalışsın; geç GPS yanıtı elle seçimi değiştirmesin. Kesin koordinatı rapora yazma (DV-02–05).
4. Jüpiter gibi bir hedefi Bu gece'den seç. UTC/yerel saat, gerçek kuzeye göre yön ve ufuktan yükseklik aynı bağlamda olsun. Simülasyon/ufuk altı/koşullar bilinmiyor uyarılarını kontrol et; hedefin gerçekten görüldüğü iddiasını otomatik kabul etme.
5. Telefon pusulasını açık eylemle başlat. Düz telefonu bilinen gerçek yönle hizala; dört yön, 359°→0°, yatay/dikey ekran, eğim/metal/kötü sapma, sekiz saniye veri yokluğu ve kapat/gizle senaryolarını uygula. Geçersiz ölçümde önceki yön uygulanamamalı, yeniden hizalama istenmeli (DV-07–10).
6. Genel paket hazır olunca kurulum yap: Android'de tarayıcının kurulum menüsü; iPhone'da Safari Paylaş → Ana Ekrana Ekle. Kurulumu gerçek işletim sistemi yüzeyinde doğrula; ikon görmek tek başına offline kabulü değildir. TECH-09 resimli uygulama/Apple simgesi ve Android maskable amblemini ana ekran/işletim sistemi maskesi/splash/güncellemede kontrol et; kesilmiş kritik şekil veya dış krem mockup çerçevesi olmamalı.
7. Genel görselleri istersen hazırla; bağlantıyı kesip uygulamayı yeniden aç. Genel harita/terimler/takvim çalışsın, Wikipedia/yer adı/otomatik saat dilimi sınırı ve UTC/manuel alternatif açık olsun. Kişisel kayıt yazımı bağlantı istesin; anonim tarayıcıya kaydetme olmamalı.
8. Bağlantıyı geri getirip uygulamaya dön; offline etiketi bağlantı kontrolüyle kalksın. Yeni build olduğunda taslakları koruyarak açık güncelleme yap; ikinci sekme varsa engel bildirilsin. Kurulum, güncelleme ve tarayıcı depolama temizliği ayrı sonuçlardır.

## Rapor sınırı

Yalnız cihaz/OS/tarayıcı sürümü, DV kimliği, dil, geçti/kaldı/denenemedi, süre ve yuvarlanmış hata aralığı kaydedilir. Kesin GPS, ev/adres, sensör akışı, parola/token, gerçek hesap veya kişisel ekran görüntüsü paylaşılmaz. Donanım hata eşiği gerçek bir referans/ölçümle belirlenir; rastgele yüzde doğruluk veya kalibre edilmemiş puan üretilmez. VoiceOver/TalkBack ve gerçek telefon performansı ayrıca kaydedilir.
