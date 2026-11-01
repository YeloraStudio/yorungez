# ADR-0005 — Tam ekran harita, izinli konum ve yerel/UTC zaman

**1 Kasım 2026 güncellemesi:** A-001 özgün kod lisansı kullanıcı seçimiyle Apache-2.0 olarak kapandı. Aşağıdaki açık lisans ifadeleri tarihsel aşamayı anlatır; üçüncü taraf lisansları değişmez. [ADR-0014](0014-acik-kaynak-yayin-ve-apache-2.md).

**Sonraki aşama notu:** Bu paketin 39 terim/19 istemci testi ve ilk temsili arazi kanıtı tarihsel olarak korunur. Kullanıcı paleti/dil listesi/doğal fotoğraf çevre ve düz pusula, 43 terim/24 istemci testi [TECH-04B kaydındadır](../dogal-gorunum-ve-pusula.md). Fiziksel cihaz kabulü açık kalır.

**31 Ekim 2026. Durum:** Kullanıcının düzeltmesi doğrultusunda uygulandı; cihaz/erişilebilirlik ve üretim işletimi açık. **İz:** K-019; FR-01–05/08–09/11–12; UJ-01–03/06; AC-01–06/09–14; A-002/005/007/009/014. [Uygulama ve kanıt kaydı](../tam-ekran-harita-gelistirmesi.md).

## Karar

Kalıcı üst/yan panel yaklaşımının yerine tam ekran harita, başlangıçta kapalı sol menü, yüzen kontroller ve saydam nesne kartı geldi. Dört ana bölüm ve bütün eski gereksinim kimlikleri korunur. Tema gri/bordo; gökyüzünün gündüz/gece rengi atmosfer simülasyonuna bağlıdır. Varsayılan atmosfer/arazi/derin uzay açık; takımyıldızlar/çizimler/iki ızgara/gece/tarayıcı tam ekranı kapalıdır. Arazi temsili açık alandır; gerçek konumdan üretilmiş topoğrafya/engeller değildir. Görsel katmanlar hesapları değiştirmez.

Başlangıç katalog kaynağı derlemede hash doğrulanan yerel pakettir; Identity/API veya dış servis ilk kareyi bekletmez. İstemci isteği 10 s ile sınırlı ve şema kontrollüdür. Worker hazır sinyali, bir etkin/en yeni bekleyen hesap ve 8 s gözetim kullanır; arıza halinde aynı gerçek hesap adaptörüyle ana iş parçacığında uyumluluk yolu denenir. Canlı saat meşgul işçiye iş yığmaz; eski bağlam sonucu yeni bağlamı değiştirmez. Bekleme/hata ve yeniden deneme görünürdür. Dış ansiklopedi veya konum isteği ana harita açılışına bağlanmaz.

Konum izni zaten verilmişse taze, yüksek doğruluk isteyen tek cihaz ölçümü alınır; yeni izin kullanıcı eylemiyle istenir. Sürekli hareket takibi yapılmaz. İzin değişimi izlenir; ret/ulaşılamama/süre aşımı/manuel alternatif ayrıdır. Doğruluk metre ve ölçüm zamanı korunur; yüksek ondalık basamak GPS kesinliği değildir. Manuel seçim geç gelen cihaz yanıtını iptal eder. Bilinmeyen/ellipsoidal cihaz yüksekliği doğrulanmış deniz seviyesi yüksekliği diye kullanılmaz; hesapta açık 0 m varsayımı korunur.

Harita nokta seçimi için Leaflet 1.9.4 (BSD-2-Clause) + OpenStreetMap seçildi; Google API/anahtar zorunluluğu eklenmedi. Döşemeler yalnızca kullanıcı haritayı açınca istenir, atıf ve HTTP cache korunur; bulk/offline indirme yoktur. [OSM kullanım politikası](https://operations.osmfoundation.org/policies/tiles/). Bu ücretsiz topluluk hizmetinin üretim ölçeği/SLA garantisi yoktur; A-010 sağlayıcı/işletim işi açık kalır. Harita seçimi GPS hata payını iyileştirmez.

Saat dilimi için kayıplı istemci tahmini yerine sunucuda `geo-tz/all` 8.1.10 kapsamlı poligon verisi kullanılır. Koordinat yalnızca aynı origin Yorungez BFF'sine POST/no-store gövdesinde gider, harici geocoding servisine otomatik gönderilmez. Sınırda birden fazla bölge varsa açık seçim gerekir. UTC anı tek hesap girdisidir; IANA bölgesi, GMT ofseti ve yerel saat gösterimdir. Temporal polyfill 0.5.1 (ISC) DST boşluklarını reddeder, çift saatlerde oluşum seçtirir; bölge hazır değilken giriş açıkça UTC'dir. Canlı yeniden çizim native tarih alanını eski değerine döndüremez. Politika/bölge değişiminde UTC anı korunur. Gelecekteki saat dilimi mevzuatı/dataset güncellemesi ve gerçek cihaz testleri bakım konusudur.

OpenNGC'nin CC BY-SA 4.0 verisinden 107 Messier eşleşmesi eklendi; M40/M45/M102 bu kaynak diliminde yoktur. Tam katalog değildir. Johan Meuris/Stellarium Western'den 85 özgün Free Art License çizimi değiştirilmeden paketlendi; üç yıldız ankrajı ve küresel örgüyle çizilir. Pupa/Yılan/Yelken için bu revizyonda çizim yoktur. Stellarium çalışma zamanı/AGPL motor kodu alınmadı. [Ayrı veri/atıf kaydı](../../data/catalog/README.md); lisanslar koddan ayrı korunur, A-001 kod lisansı açık kalır.

Güneş için tr/en Wikipedia revizyon/alıntı özeti ve Commons'tan gerçek, lisanslı arşiv fotoğrafı paketlendi. Diğer bilinen kimlikler kaynak makalesini isteğe bağlı alabilir; belirsiz/olmayan makale veya lisansı belirlenemeyen görsel uydurulmaz. Kısa özet, ayrıntı açma, kaynak/revizyon/üretici/lisans ve alınma tarihi vardır. Gözlemciye göre RA/Dec/uzaklık hesaplanır; ansiklopedi astrometrik hesabın yerine geçmez. Makale isteği süre/sayı/cache sınırlarıyla ana haritadan ayrıdır.

## Kanıt ve açık işler

84 .NET + 19 istemci testi, üretim derlemesi, gerçek yerel Kestrel/DB/Redis ve IAB geliştirici akışları geçti. 72 bağımsız DSO örneğinde en büyük fark 0,427525 yay dakikası; deneme hedefi 1 yay dakikası. 144 yıldız ve önceki JPL sınırları/iki kutup istisnası korunur. Bu örnekler bütün hedef/tarih/konumların doğruluk sertifikası değildir.

Gerçek telefon GPS/doğruluk/izin, pusula/kalibrasyon, fiziksel pinch, ekran okuyucu, tam mobil performans/bellek ve kullanıcı görevleri açık. PWA, offline yeniden açılış, hesap ekranları, kişisel kayıt/açık onaylı aktarım/senkronizasyon, geleneksel doğuş-batış/evre/koşul modeli eski planın parçası olarak sürer. Gmail placeholder kapalıdır; PostGIS kurulmadı. Bu değişiklikler tüm MVP-0/P0 kabulü anlamına gelmez.
