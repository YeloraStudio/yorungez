# yorungez — Gözlem çizelgesi, takvim ve ufuk altı keşfi

**Sonraki güncel karar:** [TECH-04D](ortak-bilesenler-ve-sensorsuz-gozlem.md) ile Bugün kaldırıldı, yalnız gece kaldı; native kontroller yerini ortak özel bileşenlere bıraktı. Aşağıdaki TECH-04C sayıları/ekranları kendi aşamasının tarihsel kanıtıdır.

**TECH-04C / 31 Ekim 2026 / K-021.** Kullanıcının yeni düzeltmeleri uygulandı. PRD 1.5; FR-01–05, FR-08, FR-11–12; UJ-01–03/UJ-06; AC-02–06/AC-09–11/AC-13–14. Önceki hedefler ve P0/P1/P2 korunur; tam MVP-0 kabulü değildir.

## Teslim edilen davranış

- Sol menü: Gökyüzü, **Bugün / Bu gece**, **Takvim**, Defterim (henüz uygulanmadı). Sadece aramaya odaklanan Keşfet kaldırıldı; arama ve FR-03 atlas kapsamı korunur. Palet, kapalı menü, tam ekran, dil listesi ve üç varsayılan katman aynı kalır.
- Bugün yerel gece yarısından sonraki gece yarısına; Bu gece yerel öğleden sonraki öğlene hesaplanır. Güneş batıp doğuyorsa çevresi saatlere yuvarlanmış akşam–sabah penceresi gösterilir. Sekiz hedefin ufuk üstü aralıkları, gün batımı/doğumu, seçili yer ve IANA bölgesi görünür. DST günleri 23/25 saat olabilir.
- Çubuğa tıklamak seçilen kesrin **UTC anını**, hedef kimliğini ve simülasyon modunu haritaya taşır. Klavye Enter, seçilen aralığın içindeki örnek yüksek konumu seçer; ikinci aralık ilkine atlamaz. Bu örnek kesin meridyen geçişi veya en iyi gözlem garantisi değildir.
- Kartta **Yön bul · Pusula**: hedefin gerçek kuzeye göre azimutu ve yüksekliği, ufuk altı açıklaması. Fiziksel sensör ayrıca izin/açık hizalama gerektirir; göreli alpha kuzey değildir. abs(enlem)>=89 azimut koruması sürer.
- Aranan/hedeflenen cisim fotoğraf arazinin arkasındaysa arazi en fazla %12 opak kalır. Aşağı bakış +5°…−15° arasında kademeli olarak %10 opaklığa iner. Cisimler/ızgaralar ve seçim çalışır; **merkezi ufkun altında** açıklaması korunur. Çizimde görünmesi gerçek gözlenebilirlik değildir.
- Stereografik zoom **0,6°…330°**; Tüm göğe bak 240°/zenit kısayolu. Arka yarıküre gösterilir, matematiksel antipod sonlu piksele zorlanmaz. Ufuk ve panorama geniş açıda dairesel kıvrılır. CPU uyumluluk yolu aynı ters ışını örnekler; fotoğraf/GPU veya fiziksel performans eşliği iddia edilmez.
- Manuel konum: şehir/ilçe araması, isteğe bağlı ad, enlem/boylam ve yükseklik. Seçilen şehir merkezi kullanıcı tarafından hassaslaştırılır. İsimsiz cihaz/manuel koordinat için yerel katalogdan en yakın yer **yakınında** etiketiyle bulunur; kesin ilçe sınırı/adres tespiti veya GPS iyileşmesi değildir. Cihaz belirsizliği ve ölçüm zamanı korunur, GPS yüksekliği sessizce kullanılmaz.
- Takvim: 2000–2035, ay/yıl seçimi; yerel saat + UTC, kaynak/hesap ayrımı, olaya tıklayarak aynı anda aynı hedefe gitme. Konum korunur. Konum bölgesi yüklenirken planlayıcının ilk günü/ayı yanlışlıkla UTC'den seçilmez; ana harita bekletilmez.

## Bilimsel model ve veri kökeni

Çizelge **Astronomy Engine 2.1.19 SearchRiseSet** kullanır: standart 34′ kırılma, Güneş/Ay üst kenarı. Mevcut harita ve `/horizon-crossings` API'sindeki **hava kırılmasız merkez/0° geçişi ayrı sözleşmedir**. Aynı isimle eşit kabul edilmez.

Harita yüksekliği önceki elipsoidal model sözleşmesini korur. Motorun doğuş-batış atmosfer hesabı deniz seviyesi yüksekliği ister. Geoit dönüşümü kurulmadığından çizelge **deniz seviyesinde 0 m referans** olarak açıkça sunulur; manuel elipsoidal yükseklik bu çizelgeye uygulanmaz. Yerel ufuk, göz yüksekliği/ufuk alçalması, bulut/ışık kirliliği ve algılanabilirlik değerlendirilmez. Yüksek rakım/özel ufuk ve datum dönüşümü A-007/P1 işidir. [Sabit motor kaynağı](https://github.com/cosinekitty/astronomy/blob/v2.1.19/source/js/astronomy.ts).

[Olay kataloğu](../data/events/README.md): **2623 kayıt**; **1781 USNO birincil Ay evresi**, diğer 842 kayıt motorla hesaplanan mevsimler, dış gezegen karşı konumları, Merkür/Venüs alt/üst kavuşumları ve en büyük uzanımları. Ay evrelerinde gösterilen zaman USNO'nun UT dakika değeridir; UTC dakika hassasiyetinde yorumlanır. Motorun ayrı sonucu ve farkı saklanır. Gezegen/mevsim olayları kaynaklı hesaplamadır, bağımsız zaman sertifikası değildir. Örnekte 3 Ekim 2026 son dördün **13:25 UTC / 16:25 Europe/Istanbul**.

[GeoNames kataloğu](../data/places/README.md): **237831 nokta**, 6.528.136 bayt gzip; dünya cities500 ve Türkiye ADM2 ilçe noktaları. CC BY 4.0 kaynak/hash/atıf saklanır. Verinin tamamı sunucuda tembel yüklenir; tarayıcıya tüm katalog gönderilmez. Koordinatlar dış geocoding servisine otomatik gitmez. Soğuk yüklemenin RAM/CPU maliyeti vardır; üretim eşzamanlı yük bütçesi ölçülmedi. Mevcut PostGIS kararı değişmedi.

## Uçlar ve yaşam döngüsü

- BFF: `GET /api/calendar?year=2026&month=10`; .NET CQRS: `GET /api/v1/events/calendar?year=2026&month=10`. Genel veri, SHA/ay ETag ve 304; yerel ay sınırı için ±2 UTC gün kapsanır, UI IANA ayına filtreler.
- BFF: `POST /api/location/places`; .NET: `POST /api/v1/locations/places`. Ad sorgusu veya enlem/boylam, sınırlandırılmış girdi, `no-store`. API hız sınırı ve tr/en hata dilini korur. İstemci eski istekleri iptal eder; koordinatlar URL/kalıcı depoya yazılmaz.
- C# gömülü kaynak ve Web `generated/` aynı kök dosyanın SHA'sını doğrular. Normal derleme/test ağdan veri çekmez. Açık yenileme komutları veri README'lerindedir. Harita başlangıcı plan/veri servislerini beklemez. Plan Worker 12 s, takvim/yer sorgusu 10 s süre aşımı ve tekrar deneme; kapanışta iptal/temizlik.
- Toplam **51 eşli tr/en terim**, içerik sürümü `2026-10-31.6`; önceki 43 kimlik korunur. Yeni sekiz terim: doğuş/batış, Ay evresi, karşı konum, kavuşum, uzanım, ekinoks, gündönümü, alacakaranlık.

## Doğrulama ve kanıt sınırı

**93 .NET testi** (18 çekirdek +19 astronomi +56 API/entegrasyon) gerçek PostgreSQL/Redis ile geçti. **29 istemci testi**, TypeScript ve Next üretim derlemesi geçti. Çizelge aralığı, DST 23/25 saat, kutup günü, ikinci aralıkta klavye seçimi, geniş açı/antipod, saydamlık, yerel ad/mahremiyet ve takvim kaynağı kapsanır.

- [1781 Ay evresi karşılaştırması](science/calendar-reference-report.json): 120 s eşik, en büyük fark **79,946 s**.
- [22 Güneş/Ay doğuş-batış karşılaştırması](science/observing-reference-report.json): altı konum/tarih dosyası, 180 s eşik, en büyük fark **25,48 s**. [Donmuş USNO referansları](../tests/ReferenceData/Observing/README.md). Bu örnekler bütün gezegen/konum/rakım doğrulaması değildir.
- Önceki 144 yıldız ve 72 DSO bağımsız Astropy örneği geçti; 1168 JPL örneğindeki **iki ham kutup yön başarısızlığı** ve API koruması korunur. Yeni başarılar bu istisnaları silmez.
- [Tarayıcı deneme kaydı](science/planning-browser-qa.json), [Bu gece](ux/planning/tonight-tr.jpg), [Takvim](ux/planning/calendar-tr.jpg), [ufuk altı](ux/planning/below-horizon-tr.jpg), [330°/nadir](ux/planning/wide-nadir-tr.jpg), [240° gece](ux/planning/wide-night-tr.jpg), [pusula hedefi](ux/planning/compass-target-tr.jpg), [dar Türkçe çizelge](ux/planning/mobile-tonight-tr.jpg), [dar İngilizce takvim](ux/planning/mobile-calendar-en.jpg). IAB/dar viewport gerçek telefon veya ekran okuyucu kabulü değildir.

Stellarium Web kullanıcının isteğiyle tarayıcıdan incelendi: Balıkesir örnek konumu, Bu gece çubukları/tıklama, takvim ve geniş açı. Kod, takvim metinleri veya yeni görseller kopyalanmadı. USNO ve GeoNames ayrı birincil kaynaklar olarak arşivlendi.

## Kalan işler ve sıra

Fiziksel GPS/pusula/ekran yönü/erişilebilirlik ve gerçek mobil bütçe [cihaz protokolü](cihaz-konum-pusula-dogrulamasi.md) ile yürütülecek. Aynı sırada UX-02 kişisel kayıt/hesap/çevrimdışı akışlarının minimum alanları ve kayıpsız aktarım sözleşmesi hazırlanacak; PWA, service worker, kişisel kayıtlar ve gerçek SMTP henüz yok. P1'de meteor yağmurları, asteroitler, Ay–yıldız yakınlaşmaları/tutulmalar için kaynak/lisans ve bağımsız doğrulama eklenir; mevcut takvim bütün örnek türleri kapsıyor denmez. [Bütün FR/UJ/AC kalanları](teslimat-izlenebilirligi.md) korunur.
