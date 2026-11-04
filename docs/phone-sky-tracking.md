# Telefonla gökyüzü takibi — K-047 / 4 Kasım 2026

Kullanıcı hedefi: telefonu gökyüzündeki gerçek cisme çevirirken harita aynı doğrultuyu canlı izlesin; iOS/Android PWA ve isteğe bağlı kamera. S23 görüntüsünde sensör izni/verisi vardı; önceki araç düz telefon pusulası ve tek seferlik yön uygulamasıydı. Bu araç ayrıca korunur; yeni takip onun yerine arka kamera eksenini kullanır.

## Uygulama sözleşmesi

- Haritadaki Telefonla gökyüzü / Point at the sky düğmesi, yan menü ve eski pusula ekranından erişilir. Kapalı başlar; açmak izin istemez, Başlat kullanıcı eylemi orientation iznini senkron başlatır. iOS requestPermission(true) varsa kullanılır; Android absolute ve ordinary orientation olayları dinlenir.
- Canlı mod, açıkça seçilmiş manuel/device konum ve aynı koordinat/yükseklikte en fazla 10 saniye eski hesap gerekir. Örnek İstanbul otomatik fiziksel konum sayılmaz. Konum/simülasyon değişimi takibi durdurur. Mevcut konum ölçümünü kullanır; yürürken sürekli GPS watch eklenmedi.
- W3C Z-X'-Y'' matrisi cihazın -Z arka kamera eksenini ENU'ya çevirir. Ekran dönüşü up vektörüne uygulanır; azimut, yükseklik ve roll ortak Canvas/WebGL projeksiyonuna gider. Düz telefon beta/gamma sınırı bu modda kullanılmaz.
- İlk geçerli veri tek başına kuzeye güvenmek için kullanılmaz. Gerçek gökyüzünde bulunan seçili, ufuk üstündeki noktasal hedef veya haritanın merkezindeki bilinen gerçek yönle açık hizalama gerekir. Güneş kalibrasyon hedefi yapılmaz. Göreli veri de ancak böyle bir gerçek referanstan sonra kullanılabilir; referans cihazı değişirse hizalama iptal edilir, absolute veriden sonra relative companion göz ardı edilir.
- Hizalama yatay yaw ofsetidir; yükseklik yerçekimi/sensöründen gelir. Hedef ile ölçülen eğim farkı 15 dereceden fazla veya tepe/dibe 5 dereceden yakınsa hizalama reddedilir. Bu eşikler doğruluk garantisi değildir. Telefonu gerçekten hedefe çevirmeden yalnız haritada hedef seçmek kalibrasyon değildir. Göreli jiroskop sürüklenmesi ve manyetik etkiler nedeniyle yeniden hizalama gerekebilir.
- Sensör→harita güncellemesi en fazla yaklaşık 30 Hz; haritanın ilave sürükleme animasyonu takipte atlanır. Manuel yön sürüklemesi, odakla komutu veya reset takibi durdurur; zoom kullanılabilir. Ekranda belirgin Durdur ve ayarlara dönüş bulunur.
- 8 saniye veri yokluğu, kullanılamaz veri, sayfanın gizlenmesi, pagehide, iptal ve unmount hizalamayı/kamerayı temizler. Geç dönen sensör/kamera izni durdurulmuş oturumu başlatamaz. Yeniden açılışta kullanıcı yeniden başlatır.

## İsteğe bağlı arka kamera

Takip hizalandıktan sonra ayrı kullanıcı eylemi ve getUserMedia izni gerekir. Yalnız environment kamerayı ister; ön kameraya sessiz fallback yok. Dönen track getSettings().facingMode ile doğrulanır; doğrulanamazsa görüntülenmeden kapatılır. audio=false ve microphone=() korunur. Permissions-Policy kamerayı/sensörleri sadece self için açar; bu başlık tarayıcı izni yerine geçmez.

Video yalnız yerel MediaStream/srcObject ile görüntülenir. Ses, MediaRecorder, kare yükleme veya sensör/GPS/video loglama yoktur. Kamera kapanınca, takip durunca, sensör bozulunca veya sayfa gizlenince bütün track'ler durdurulur; geç gelen stream de kapatılır.

Kamera kaplamasında fotoğraf arazi/atmosfer gizlenir, roll destekli perspektif projeksiyon kullanılır. Başlangıç uzun-eksen FOV 60 derece, zoom ile ayarlanabilir. Kamera intrinsics/distorsiyon/cover kırpması otomatik ölçülmez; kenar eşleştirmesi yaklaşık olarak etiketlenir. Ufuk altındaki cisimler video üzerinde gösterilmez; normal haritanın saydam araziyle inceleme özelliği sürer. Görüntü tanıma, otomatik Ay tanıma veya hassas astrometrik AR yapıldığı iddia edilmez.

## Kanıt ve açık kabul

75 istemci testi: W3C ana yön/eğim örnekleri; bağımsız matris bileşimiyle arka eksen ve ekran yukarısı; roll/perspektif projeksiyon tersi, kutuplar, 360 geçişi, kaynak değişimi, açık kalibrasyon, izin reddi, stale/iptal ve geç kamera stream temizliği. Tip kontrolü ve production/PWA derlemesi geçti; public CI ve canlı smoke kontrolleri ayrıca izlenir.

Yerel masaüstü ve 390 px TR/EN UI kontrolü: örnek konumda engel, manuel sentetik gözlem konumu, başlat/durdur, sensörsüz ortamda 8 saniye sonrası güvenli kapanış. Gerçek kamera veya fiziksel S23/iPhone yön doğruluğu bu kontrollerde test edilmedi. Tüm tarayıcı/cihazlarda aynı sensör/kamera erişimi garanti edilmez; engellenen ortamda açıklama ve manuel harita kalır.

## Fiziksel S23 / iPhone 15 kabulü

1. Güncel HTTPS sürümünü Chrome/Brave (S23), Safari ve Ana Ekran PWA (iPhone) üzerinde aç. Saat otomatik/güncel olsun; canlı modda kendi konumunu seç, bildirilen GPS hata payını kontrol et.
2. Telefonla gökyüzü → Başlat; yalnız tarayıcının istediği yön/hareket izinlerini ver. Telefonu düz tutmak gerekmez. Tarayıcı sensörü engelliyorsa genel korumaları topluca kapatmadan site iznini incele.
3. Gerçekten gördüğün ufuk üstü Ay veya parlak bir yıldız/gezegeni seç. Güneş'e optik araçla bakma. Arka kamerayı hedefe yöneltip Hizala ve izle de. Merkez sapmasını kaydet; kuzey/east dönüşü, yukarı/aşağı ve ekranı yataya alma sırasında takip yönünü doğrula. Hatalı gerçek referansla hizalama yapılamayacağından açık arazide bilinen bir yön alternatiftir.
4. Kamera isteğe bağlıdır; açılırsa merkez/kenar farkını ve zoom ihtiyacını gözle. Kameranın açılması hassas lens kalibrasyonu değildir. Sayfayı gizle/geri gel, Durdur, izin reddi, arka kamera bulunmaması ve kaynak/veri kaybında kamera göstergesinin kapanmasını doğrula.
5. iPhone/S23 için ayrı merkez sapması, gecikme, FPS/ısınma ve izin sonuçları alınmadan fiziksel kabul tamamlanmış sayılmaz. Ham sensör akışı, koordinat, görüntü veya cihaz kimliği göndermek gerekmez.

## Birincil kaynaklar

- [W3C Device Orientation: koordinatlar, arka ekran vektörü ve matris](https://www.w3.org/TR/orientation-event/)
- [Screen Orientation: ekranın karşı-saat yönündeki açısı](https://www.w3.org/TR/screen-orientation/)
- [getUserMedia: izin, güvenilir köken ve kamera kısıtları](https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia)

Yeni mobil uygulama aynı astronomi/hesap API'sini kullanabilir; sensör yönlendirme ve kamera adaptörü platforma özgü kalır. Native ARKit/ARCore/VIO ve lens kalibrasyonu ayrı ileri aşamadır; PWA takip kabulünün yerine geçmez.
