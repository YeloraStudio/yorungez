# ADR-0006 — Fotoğraf çevre katmanı ve pusula sınırı

**31 Ekim 2026. Durum:** Yazılım uygulandı; fiziksel cihaz/performance kabulü açık. **İz:** K-020, FR-01–03/08–09/11–12; UJ-06; AC-03/09/11/13–14. [Uygulama, kaynaklar ve testler](../dogal-gorunum-ve-pusula.md).

Kullanıcının beş renk kodu UI kaynağıdır; tam ekran/kapalı menü yerleşimi korunur, dil seçimi sol menüde native listedir. Göğün doğal rengi UI paletinden bağımsızdır.

Gerçek fotoğraf çevre için kaynaklı Stara Lesna şeffaf panoraması seçildi. Orijinal PNG/atıf/hash ve kaynak readme/listedeki ayrı CC kayıtları korunur. Yalnız veri/görsel alındı; Stellarium motoru alınmadı. Aynı stereografik ENU ışınlarını kullanan iki WebGL sahne geçişi fotoğraf/atmosferi çizer; mevcut Canvas yıldız ve Astronomy Engine/Worker hesapları korunur. Fotoğraf Güneş yüksekliğine göre kararır; gerçek yerel arazi/koşul/ufuk verisi değildir. Kadir sıralı yıldız çekirdeği/hale ekran transferidir; kalibre fotometri değildir. WebGL uyumsuzluğu/kaybında açıklamalı sade harita vardır. Fotoğraf ilk astronomi karesini bekletmez; 12,37 MB ağ maliyeti ve fiziksel mobil bellek bütçesi açıktır.

İlk pusula aracı düz telefonun ekran üst kenarının yönünü okur. İzin kullanıcı eylemidir; mutlak kaynak yoksa göreli alpha kuzey olarak kullanılmaz. Eğim/kötü cihaz sapması/süresi geçmiş veri reddedilir. Manyetik/belirsiz sensör kuzeyini gerçek kuzey diye uygulamak yerine bilinen gerçek yönle açık oturum hizalaması gerekir. Sadece kamera azimutu uygulanır; astronomik konum/an değişmez. WMM/deklinasyon veya kamera AR takibi eklenmedi. İptal/gizleme/kapanış dinleyicileri durdurur; GPS izni ayrı kalır. [Gerçek cihaz protokolü](../cihaz-konum-pusula-dogrulamasi.md) yürütülmeden fiziksel destek tamamlandı değildir.

43 kaynaklı tr/en terim ve cache `.5`; 84 .NET + 24 istemci testi/üretim derlemesi kanıtlıdır. Testler doğruluk/kalibrasyon/performans sertifikası değildir; kutup azimut koruması, bağımsız referanslar, P0/P1/P2 ve bütün eski hedefler korunur.
