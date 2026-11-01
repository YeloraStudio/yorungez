# TECH-08 — Responsive, sensör ve PWA kabul hazırlığı

**1 Kasım 2026 / K-030 / PRD 1.12.** [ADR-0015](adr/0015-responsive-sensor-ve-pwa-kabulu.md). Mevcut MVP-0/P0 planı ve FR/UJ/AC kimlikleri korunur. Fiziksel test için kullanılabilecek cihazlar belirlendi; erişilebilir HTTPS ortamı henüz yoktur.

## Uygulanan düzeltmeler

- Pusula geçerli ölçümden sonra eğim/kötü sapma bildirince eski yön hemen uygulanamaz olur; hizalama ve eski ekran değeri temizlenir. Geçerli ölçüm sonrası yeniden hizalama gerekir. Göreli/mutlak Android olay ayrımı ve izin/cleanup/8 saniye korumaları korunur.
- Özel açılır listeler gerçek görünen viewport sınırlarına göre yerleşir; VisualViewport resize/scroll ve klavye/pinch ofsetlerini hesaba katar. Dar/yatay ekranlarda kaydırma korunur.
- Çentik ve home-indicator safe-area alanları kontrollerde birlikte hesaba katılır. Mobil metin girişleri 16px, temel harita araçları 44px; kullanıcı sayfa zoom'u engellenmez. Astronomik hesap ve konum hassasiyeti CSS düzeninden bağımsız kalır.
- PWA açılışında ve sayfaya dönüşte genel bağlantı yeniden kontrol edilir; aynı andaki kontroller tek ağı paylaşır. Yalnız `online:true` işareti kabul edilir. İlk kurulumdaki geçici bekleme, sahte güncelleme bildirimi olarak kalmaz; bekleyen worker yokken ileride istemsiz yenileme isteği saklanmaz.
- UJ-07'nin eski offline not/eşitleme satırı, mevcut hesap zorunlu sunucu kayıt kuralıyla düzeltildi. Anonim/offline kişisel kayıt geri eklenmedi.

## Otomatik ve tarayıcı kanıtı

49 istemci testi, TypeScript ve üretim PWA derlemesi geçti. Testler yeni sensör bozulması, geç izin yanıtı, görünen viewport/popup sınırları, kesinti sonrası bağlantı dönüşü/tek istek ve kişisel cache dışlamasını içerir. Önceki 144 yıldız / 72 DSO Astropy, donmuş JPL, 1781 USNO evresi ve 22 doğuş-batış referans kontrolleri aynı toleranslarla geçer; yeni bilimsel doğruluk iddiası veya veri yenilemesi yoktur.

Windows IAB ve Brave ile genel İstanbul örnek konumu kullanıldı; gerçek GPS/pusula izni veya sahte sensör değeri kullanılmadı. IAB takvim paneli 320×568, 360×780, 393×852, 640×360, 780×360, 1024×768 ve 1440×900 boyutlarında yatay taşma olmadan açıldı. Özel ay seçimi ve seçenek üzerindeyken Escape'in paneli koruyup odağı tetikleyiciye döndürmesi kontrol edildi. Dar ekran hesabı/klavye/çentik için fiziksel cihaz kabulü halen gereklidir.

Jüpiter için Bu gece aralığı seçildiğinde aynı örnek konumda 2 Kasım 2026 01:26:03 UTC / 04:26:03 Europe/Istanbul bağlamı ve yaklaşık 102,8° azimut / 35,3° yükseklik rehbere taşındı; simülasyon etiketi, yaklaşık 3,5 yumruk ve bilinmeyen koşullar uyarısı korundu. Bu bir gerçek gözlem veya cihaz doğruluk ölçümü değildir.

Brave'de çekirdek ve 88/88 genel görsel hazırlandı. Yalnız ajanın 5194 önizlemesi kapatılınca sayfa yeniden açıldı; takvimden 1 Kasım 2026 20:28 UTC Son dördün seçimi Ay'ı yaklaşık 59,0° / −5,9° ve ufuk altı uyarısıyla açtı. UTC alternatifi açık, Wikipedia eksikliği görünürdü; kişisel kayıt için sunucu gerektiği kuralı korundu. Bu işlem Windows'un internetini kesmek veya fiziksel uçak modu değildir.

İlk hesap için gözlenen tekil yerel örnekler IAB 211ms, Brave 485ms idi; bunlar cihaz/dağıtım geneline yayılan bir bütçe, LCP/INP/CLS veya gerçek telefon performans ölçümü değildir. Sunum ve bilimsel hesap süresi birbirine karıştırılmaz.

Son yaşam döngüsü düzeltmesiyle temiz 5196 kökeninde `5248920dc675b7010103` paketi ilk kurulumda hazırlandı; güncelleme düğmesi yoktu. Brave'de `45fad93348c4612c0928` → `5248920dc675b7010103` açık güncellemesi sonrası bildirim temizlendi. Son paketin sunucusu kapatılıp yeniden açıldığında genel harita çalıştı; sunucu dönünce yenileme ile offline etiketi manuel kontrol eylemi olmadan kalktı. Yeni paket hazırlanmış eski görselleri varmış gibi göstermedi. 360px kayıt formunda yatay taşma yoktu ve metin girişleri 16px ölçüldü; form gönderilmedi.

Sonuçlar [makine okunur kayıtta](science/device-browser-acceptance-qa.json). Sadece workflow dosyası veya bekleyen CI sonucu geçmiş test sayılmaz.

## Görsel kanıt

[320px Türkçe takvim](ux/device-acceptance/calendar-320-tr.jpg), [393px Bu gece](ux/device-acceptance/tonight-393-tr.jpg), [393px Jüpiter rehberi](ux/device-acceptance/jupiter-393-tr.jpg), [Brave çevrimdışı görünüm](ux/device-acceptance/brave-offline-en.jpg), [Brave güncellenmiş paket](ux/device-acceptance/brave-updated-pack-en.jpg). Ekranlar genel örnek konumu ve simülasyon kullanır.

## Açık kalan kabul

Samsung Galaxy S23/Chrome ve iPhone 15/Safari üzerinde gerçek GPS doğruluğu, gerçek yön/kalibrasyon, portrait-landscape/pinch, klavye/çentik, VoiceOver/TalkBack, ana ekrana kurulum ve OS depolama temizliği kabulü yapılmadı. Telefonların erişebileceği geçerli HTTPS adresi ön koşuldur; [telefon oturumu rehberi](telefon-kabul-oturumu.md) hazırdır. Üretim backup/restore ve ek takvim türü kaynak doğrulaması sonraki planlarında kalır; bütün P0 tamamlandı denmez.

Kaynaklar: [W3C Device Orientation](https://www.w3.org/TR/orientation-event/), [Geolocation](https://www.w3.org/TR/geolocation/), [Apple viewport açıklaması](https://developer.apple.com/library/archive/documentation/AppleApplications/Reference/SafariWebContent/UsingtheViewport/UsingtheViewport.html). Bunlar platform sözleşmesidir; sahada ölçülmüş cihaz kabulü değildir.
