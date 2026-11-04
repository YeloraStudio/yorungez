# Stellarium Mobile ve SkyView Lite — Yorungez için karşılaştırmalı araştırma

**Araştırma tarihi:** 4 Kasım 2026. **Proje temeli:** `07bdc3a` / K-047.

Bu belge kullanıcının verdiği iki Android uygulamasını, resmî mağaza kayıtları, üretici özellik/yardım sayfaları, gizlilik metinleri ve platform belgeleri üzerinden inceler. Android paketleri `com.noctuasoftware.stellarium_free` ve `com.t11.skyviewfree` esas alınmıştır; Plus/ücretli sürüm ve iOS farkları ayrıca belirtilir. Rakipler fiziksel telefonda çalıştırılmadı; gecikme, yön hatası, enerji ve görsel kalite için ölçülmüş üstünlük iddiası yoktur.

**Değerlendirmem:** Stellarium geniş ve ayrıntılı bir gözlem atlası için; SkyView hedefi seçip telefonu o yöne götürme deneyimi için yararlı referanslardır. Yorungez'ın mevcut yönü, kaynaklı bilimsel içerik ile anlaşılır saha rehberliğini bir araya getirmektir. Aşağıdaki öneriler ürün kararı veya uygulanmış özellik değildir; mevcut FR/UJ/AC kapsamını değiştirmez.

## 1. Ürünlerin kapsamı ve sürüm ayrımı

### Stellarium

Android kaydı 22 Ekim 2026 güncellemesini, 10 milyon üzeri indirmeyi ve uygulama içi yükseltmeyi gösteriyor. Üretici, Plus için Gaia DR3'ten 1,81 milyarı aşan yıldız ve milyonlarca derin uzay kaydı bildiriyor. Temel/Plus sönüklük sınırı Android açıklamasında 10/22 kadir. Bunlar üretici beyanlarıdır; cihazda tamamının yüklü olması veya çıplak gözle görülmesi anlamına gelmez. [Android mağaza kaydı](https://play.google.com/store/apps/details?id=com.noctuasoftware.stellarium_free&hl=en).

Resmî ürün tablosu 3B görünüm, gözlem takvimi, oküler görünümü ve teleskop kontrolünü Plus altında ayırıyor. Çevrimdışı set için 3 milyon yıldız/2,3 milyon DSO yazıyor; yüksek çözünürlüklü çevrimiçi atlas bundan ayrıdır. Gerçekçi atmosfer, kırılma ve farklı gökyüzü kültürleri de açıklanıyor. [Ürün ve sürüm tablosu](https://stellariumlabs.com/stellarium-mobile-plus/).

Kamera AR modu resmî ana sayfada 1.14.0 yeniliği olarak yer alıyor; bu başlık güncel kurulu sürüm numarası diye alınmamalı. [AR duyurusu](https://stellariumlabs.com/).

**Güçlü yön yorumu:** Küçük bir gökyüzü rehberinden ayrıntılı incelemeye geçiş aynı ürün ailesinde sağlanıyor. Bizim için asıl ders, nesne kimliği, yakınlaştırma ve kaynaklı açıklamanın birbiriyle tutarlı kalmasıdır. Milyarlarca kayıtla hemen rekabet etmek mevcut Web kabulünün önüne geçirilmemelidir.

### SkyView Lite ve ücretli SkyView

Lite'ın Android kaydı kamera AR, arama, zaman yolculuğu, gök yolu ve çevrimdışı kullanım sunuyor; 4 Ekim 2025 güncellemesi NOAA'nın yüksek çözünürlüklü 2025 manyetik modeli ve elle pusula düzeltmesini açıklıyor. [SkyView Lite Android](https://play.google.com/store/apps/details?id=com.t11.skyviewfree&hl=en).

Ücretli Android uygulaması ayrı pakettir: `com.t11.skyview`. Mağaza 88 takımyıldız, daha geniş nesne/bilgi kapsamı ve nesne yollarını listeliyor; erişilen sayfada fiyat **4,99 ABD doları**. Bu Türkiye fiyatı değildir. [Ücretli Android kaydı](https://play.google.com/store/apps/details?id=com.t11.skyview).

Üreticinin iPhone ürün sayfasında hedefe götüren ok, 24 saatlik yol, parlaklık/gezegen boyutu kontrolleri ve yaklaşan gözlem listeleri anlatılıyor. Bunlar tüm Lite/Android özellikleriyle eşit kabul edilmedi. [SkyView ürün deneyimi](https://www.terminaleleven.com/skyview/iphone/).

**Güçlü yön yorumu:** Kullanıcının ilk sorusu olan “Nereye bakacağım?” için az adımlı bir yol kuruyor. Yorungez'ın araçlarını uzun teknik açıklamalara gömmek yerine hedef, yön, yükseklik ve yeniden hizalama çevresinde sadeleştirmek daha değerli olur.

## 2. Özellik karşılaştırması

Tablo kaynakların kısa sentezidir; “belirsiz” eksik özelliğin kanıtı değildir.

| Alan | Stellarium Mobile ailesi | SkyView ailesi | Yorungez'ın mevcut durumu / açık fark |
|---|---|---|---|
| Telefonu çevirerek keşif | Sensör modu; kamera AR de var | Kamera AR merkezli kullanım | K-047 takip/kamera uygulandı; fiziksel doğruluk kabulü açık |
| Katalog derinliği | Plus'ta çok geniş | Lite sınırlı, ücretli daha geniş; kesin güncel sayılar belirsiz | 5073 yıldız, 88 takımyıldız, 107 Messier eşleşmesi; kapsam büyümesi açık |
| Gerçekçi gökyüzü | Atmosfer/kırılma, Samanyolu/DSO görüntüleri | Kamera veya yıldız arka planı | Fotoğraf arazi/atmosfer; bilimsel Samanyolu görüntü katmanı henüz yok |
| Hedef bulma | Sensörlü harita ve gözlem araçları | Arama → yön oku → hedef | Arama/odak/yön rehberi var; takip ekranında hedefe yönlendirme derinleştirilebilir |
| Bu gece / olaylar | Plus gözlem takvimi/planlama | Sightings; platform/sürüm farkı var | Gece çizelgesi ve doğrulanmış dar olay kapsamı var; daha fazla olay açık |
| Nesnenin izleyeceği yol | Gözlem/transit araçları | Açıkça sunulan günlük Sky Paths | Sürekli hedef yolu ayrı ürün özelliği olarak tamamlanmış değil |
| Çevrimdışı | Azaltılmış atlas | Temel kullanım beyanı | Genel PWA paketi var; kişisel kayıtlar hesapla sunucuda |
| Ekipman | Plus oküler ve belirli teleskop bağlantıları | Space Navigator desteği; aynı kontrol protokolü sayılmaz | İsteğe bağlı FR-10/P2; henüz uygulanmadı |
| Dil | iOS listesinde Türkçe dahil 22 dil | iOS listesinde İngilizce | EN varsayılan + TR; hesap tercihi ortak backend'de |

Rakip sütunları için: [Stellarium sürüm tablosu](https://stellariumlabs.com/stellarium-mobile-plus/), [SkyView ürün sayfası](https://www.terminaleleven.com/skyview/iphone/), [SkyView Lite mağazası](https://play.google.com/store/apps/details?id=com.t11.skyviewfree&hl=en), [Stellarium iOS](https://apps.apple.com/us/app/stellarium-mobile-star-map/id1458716890), [SkyView Lite iOS](https://apps.apple.com/us/app/skyview-lite/id413936865). Yorungez sütunu [mevcut kapsam envanteri](web-tamamlama-ve-ortak-backend-mobil-hedef.md), [telefon takibi](phone-sky-tracking.md) ve [dil tercihi](account-language-preference.md) ile karşılaştırıldı. 2 Kasım envanterindeki kamera/yayın durumu tarihsel kayıttır; sonraki K-042/K-047 önceliklidir.

## 3. Sensör doğruluğu: kullanıcının istediği deneyim

“Telefonu Ay'a tutunca Ay ekranda doğru yerde olsun” hedefini dört ayrı doğrulama katmanında ele almak gerekir:

1. **Göksel hesap:** UTC anı ve gözlemci konumuna göre hedefin doğrultusu doğru mu?
2. **Telefon pozu:** Arka optik eksenin yönü, eğimi ve ekran dönüşü doğru mu?
3. **Kuzey/hizalama:** Manyetik, gerçek veya göreli referans hangisi; düzeltme hangi aşamada uygulanıyor?
4. **Kamera projeksiyonu:** Optik görüş açısı, kırpma, lens seçimi ve görüntü merkezi çizimle uyuşuyor mu?

Birinci katmanın bilimsel testi diğer üçünün kabulü yerine geçmez. Kamera görüntüsünün üzerine hesaplanan gök küresini çizmek de görüntüden Ay tanıma ya da yıldızlarla otomatik astrometrik çözümleme yapıldığını kanıtlamaz. İncelenen kaynaklar bu iki rakibin güncel görüntü tanıma/sensör füzyon algoritmalarını tam olarak açıklamıyor.

Stellarium yardım sayfası sensör modunda arka yüzü göğe çevirmeyi, pusula donanımını ve mıknatıslı kılıf/metal etkisini ele alıyor. SkyView yardımı da çevresel manyetik etki ve yeniden kalibrasyon ihtiyacını kabul ediyor. Native olmak bu etkileri ortadan kaldırmıyor. [Stellarium sensör yardımı](https://stellariumlabs.com/blog/faq/), [SkyView sensör yardımı](https://terminaleleven.com/help/).

SkyView'ın 2025 güncellemesinde model düzeltmesiyle manuel düzeltmenin birlikte bulunması, bizim hizalama yolumuz açısından anlamlıdır. NOAA WMM2025'in dönemi 2025–2030'dur; kullanılabilirlik sonu 31 Aralık 2029 olarak açıklanır. WMMHR2025 ayrı, daha ayrıntılı modeldir. Birini seçersek sürüm, tarih/yükseklik sözleşmesi, test değerleri ve modelin belirsizliği izlenmelidir. [NOAA WMM](https://www.ncei.noaa.gov/products/world-magnetic-model), [WMMHR](https://www.ncei.noaa.gov/products/world-magnetic-model-high-resolution).

**Mühendislik çıkarımı:** Referans manyetik ise modelden bulunan sapma gerçek kuzeye dönüşümde kullanılabilir. OS zaten gerçek kuzey veriyorsa aynı düzeltme yeniden eklenmemelidir. Bilinmeyen referansa sessiz otomatik düzeltme uygulamak doğru değildir. Apple `magneticHeading` ve `trueHeading` alanlarını ayırır; geçerli gerçek yön için konum güncellemeleri ister. Android'in game rotation vector'ü kuzeye bağlı değildir ve sürüklenebilir. [Apple CLHeading](https://developer.apple.com/documentation/corelocation/clheading), [Android yön sensörleri](https://developer.android.com/develop/sensors-and-location/sensors/sensors_position).

PWA'da yön verisine erişim standartta vardır; güvenli bağlam, kullanıcı izni ve uygulayıcı desteği önemlidir. Bu standart bütün mevcut tarayıcılarda aynı API/kalite sözünü vermez. [W3C yön/hareket belirtimi](https://www.w3.org/TR/orientation-event/).

Yorungez şu anda arka eksen/eğim/roll takibi, açık referansla yatay hizalama ve isteğe bağlı yerel kamera kullanıyor. WMM, otomatik optik kalibrasyon ve fiziksel doğruluk ölçümü tamamlanmadı. Sabit başlangıç FOV'u ve kullanıcı zoom'u hassas lens modeli değildir. [K-047 sözleşmesi](phone-sky-tracking.md).

## 4. Bilimsel içerik, canlılık ve görsel kalite

Benim değerlendirmemde “canlı” için üç ayrı gösterge gerekir: **hesabın anı**, **kataloğun sürümü**, **değişken dış verinin son başarılı alımı**. Her kareyi sunucudan almak veya bütün yıldızları sürekli bir API'den istemek doğruluğun koşulu değildir. Kaynaklı katalog üstünde yerel, zamana bağlı hesap; hızlı ve çevrimdışı kullanım için Yorungez'ın mevcut yaklaşımıyla uyumludur.

Stellarium FAQ'sı internet varken açılışta uydu/kuyrukluyıldız verisinin yenilendiğini bildiriyor. Bu, bütün gökyüzünün canlı kamerayla aktarıldığı anlamına gelmez. “Bilinen bütün yıldızlar” gibi pazarlama ifadelerini de evrenin eksiksiz envanteri olarak sunmamalıyız. [Stellarium veri yenilemesi](https://stellariumlabs.com/blog/faq/).

Yorungez'ın geliştirme önerileri:

- Önce eksik Messier kimliklerini, gerçek fotoğraf/kaynak ve türe uygun fiziksel alanları tamamlamak; katalog büyütürken aynı nesnenin iki farklı kimlikle tutarsız görünmesini önlemek. **FR-03.**
- Samanyolu için gök koordinatlarına kayıtlı, lisanslı görüntü katmanı araştırmak. HiPS/HEALPix çok çözünürlüklü döşeme yaklaşımı bu iş için adaydır; dekoratif 8K arka plan aynı şey değildir. HiPS 2.0 erişilen belge bir çalışma taslağıdır; uygulama kararı için öneri sürümü ayrıca sabitlenmelidir. [IVOA HiPS](https://www.ivoa.net/Documents/HiPS/20260501/WD-HiPS-2.0-20260501.html). **FR-02/03/08.**
- Uydu eklenirse yörünge verisi ve gözlenebilir geçiş hesabını ayrı kaynaklandırmak. CelesTrak GP verisini TLE yanında OMM biçimlerinde de sağlıyor; yeni tasarım tek eski metin biçimine kilitlenmemeli. Bu araştırmada uydu özelliği uygulanmadı. [CelesTrak GP biçimleri](https://celestrak.org/NORAD/documentation/gp-data-formats.php). **FR-04/08, mevcut öncelik sırasıyla.**
- Ufuk üstünde olmak, karanlık olmak ve nesneyi gerçekten görebilmek ayrı gösterilmeli. Bulut/ışık kirliliği/engel verisi yokken kesin görünürlük sözü veya uydurma kalite puanı verilmemeli. **FR-05.**

SkyView Lite iOS sürüm geçmişi kamera kapalı yıldız fonunun 8K'ya çıkarıldığını belirtiyor. Bu, aynı çözünürlükte arazi, canlı kamera keskinliği veya astronomik doğruluk kanıtı değildir. [iOS sürüm geçmişi](https://apps.apple.com/us/app/skyview-lite/id413936865). Bizim 4K fotoğraf arazinin 8K yapılması ayrıca özgün kaynak/GPU/bellek konusudur; [mevcut sınırlar](yerel-4k-panorama.md) sürer.

## 5. Gizlilik ve ticari model

**SkyView Lite:** 30 Nisan 2024 tarihli resmî politika, hassas konum, yakın Wi-Fi/BLE sinyalleri ve reklam kimliklerinin Outlogic dahil iş ortaklarıyla paylaşılmasını; uygulama arka plandayken de veri kullanımını açıklıyor. Uygulama içi reddetme seçeneği belirtiliyor. “Veri toplamıyoruz” üst cümlesi, aynı metindeki ayrıntılı paylaşım hükmünü yok saymak için kullanılamaz. Bu politika incelemesidir; güncel cihaz ağ trafiğinin adli analizi değildir. [Lite gizlilik politikası](https://terminaleleven.github.io/free/).

**Ücretli SkyView:** Ayrı politika konum hesabının cihazda yapıldığını ve konumun iletilmediğini söylüyor; analiz hizmetleri de anılıyor. Lite hakkındaki sonucu ücretli sürüme taşımamak gerekir. [Ücretli sürüm politikası](https://terminaleleven.github.io/paid/).

**Stellarium:** 3 Kasım 2026 politikası kamera/sensörlerin yerelde işlendiğini, hava isteğinde yaklaşık 25 km'lik konum ızgarası kullanıldığını ve Android'de Firebase Analytics/Remote Config bulunduğunu açıklıyor. iOS için kullanım istatistiği göndermediğini söylüyor; web hesabındaki gözlem/yer eşitlemesi ayrı açıklanıyor. Dolayısıyla tek bir “hiç veri yok” etiketi doğru olmaz. [Stellarium gizliliği](https://stellariumlabs.com/privacy-policy/).

**Yorungez için sonuç:** Konumun hesapta saklanması kullanıcının açık kayıt eylemine bağlı kalmalı; kamera/sensör akışı yerel kalmalı. Hesap ve kişisel envanter sunucudadır; genel offline katalogla karıştırılmaz. Rakiplerdeki yerel kişisel liste davranışı bizim mevcut hesap zorunluluğunu değiştirmez.

Stellarium güncel şartları reklamsız ücretsiz kurulum yanında platforma göre ücretli sürüm, tek seferlik yükseltme veya aylık abonelik açıklıyor. Google/Apple satın alımları birbirine taşınmıyor. [Ticari şartlar](https://stellariumlabs.com/terms-of-use/). SkyView Lite iOS'ta ek paketler, ayrıca ayrı ücretli uygulama var; erişilen ABD iOS kaydında ücretli sürüm **2,99 dolar**. [Lite paketleri](https://apps.apple.com/us/app/skyview-lite/id413936865), [ücretli iOS](https://apps.apple.com/us/app/skyview/id404990064). Bu araştırma Yorungez için ücretlendirme politikası seçmez.

## 6. UX ve kaynakların güncellik sınırı

Önerdiğim Yorungez saha akışı: **hedef seç → şu anki gözlem durumunu anla → konum/yön izinlerini gerektiğinde ver → kısa hizalama → yön oku ve yükseklikle bul → sade bilgi kartını aç**. Kamera ayrı, isteğe bağlı kontrol olarak kalır. Teknik tanı listesi ayrıntıya taşınırken başlat/durdur ve yeniden hizalama görünür olmalıdır. Bu tasarım önerisidir; rakip ekranlarında ölçülmüş görev testi değildir.

Kaynak çelişkilerini özellikle kaydettim:

- Stellarium iOS açıklaması hâlâ Gaia DR2, 8 kadir ve 2 milyon offline yıldız yazarken Android/ürün sayfası farklı sayılar veriyor. Bu nedenle Plus/temel özelliklerini platform belirtmeden birleştirmedim. [iOS açıklaması](https://apps.apple.com/us/app/stellarium-mobile-star-map/id1458716890).
- SkyView yardım sayfasındaki “Free = 15 takımyıldız/iki uydu” anlatımı eski arayüz ve App Store yükseltmesine atıf yapıyor; güncel Lite'ın kesin nesne sınırı diye kabul edilmedi. [Üretici FAQ](https://terminaleleven.com/help/).
- SkyView ürün sayfasındaki iOS 8 widget anlatımı da eski; güncel widget desteği fiziksel cihazda doğrulanmadan öneri standardı yapılmadı. [Ürün sayfası](https://www.terminaleleven.com/skyview/iphone/).
- SkyView Android'deki 3 Ağustos 2025 Ay hizası şikâyeti manyetik model güncellemesinden önce. Güncel sürümün aynı hatayı taşıdığını kanıtlamaz. Stellarium yorumlarında da hem olumlu kullanım hem yön/zoom karışıklığı var. Görünen az sayıda yorum temsilî örneklem veya performans ölçümü değildir. [SkyView yorumları](https://play.google.com/store/apps/details?id=com.t11.skyviewfree&hl=en), [Stellarium yorumları](https://play.google.com/store/apps/details?id=com.noctuasoftware.stellarium_free&hl=en).

Dil listelerinde Stellarium iOS Türkçeyi içeriyor; SkyView Lite iOS İngilizce listeliyor. Android dil eşliğini bu bilgiden türetmedim. İki iOS kaydı da geliştiricinin erişilebilirlik özelliklerini belirtmediğini söylüyor; bu, erişilebilirlik olmadığı kanıtı değildir. [Stellarium iOS bilgisi](https://apps.apple.com/us/app/stellarium-mobile-star-map/id1458716890), [SkyView Lite iOS bilgisi](https://apps.apple.com/us/app/skyview-lite/id413936865).

Mağaza puan/yorum sayıları bölge ve sayfa bölümlerine göre farklı göründüğü için kalite sıralaması olarak kullanılmadı. İki ücretsiz Android kaydı da 10 milyon üzeri indirme gösteriyor; bu sayı bilimsel doğruluk veya aktif kullanıcı sayısı değildir.

## 7. Açık kaynak ve mimari açısından alınabilecekler

Stellarium masaüstü, Web Engine ve mevcut mobil mağaza uygulaması aynı lisans nesnesi değildir. Web Engine deposunda AGPL-3.0 bulunuyor; özgün Yorungez kodu Apache-2.0. Resmî mobil kullanım şartları uygulama/veri/görseller için ayrıca izin sınırı koyuyor. “Stellarium açık kaynak” diyerek mobil varlıklarını veya motorunu Apache-2.0 kabul etmiyoruz. [Web Engine lisansı](https://github.com/Stellarium/stellarium-web-engine/blob/master/LICENSE-AGPL-3.0.txt), [ürün şartları](https://stellariumlabs.com/terms-of-use/), [Yorungez lisans kararı](adr/0014-acik-kaynak-yayin-ve-apache-2.md).

Bu araştırma SkyView'ın bütün kaynak kodunu, backend tasarımını veya tam efemeris yöntemini doğrulamadı. Stellarium'ın açık Web Engine iç yapısı da mobil mağaza sürümünün birebir mimarisini kanıtlamaz. Render/füzyon dilleri, işlem başına enerji ve sunucu maliyetleri hakkında tahminler gerçek gibi sunulmadı.

Ortak backend hedefimiz korunur: hesap, dil, not/favori/gözlem ve içerik kimlikleri mevcut .NET API'de paylaşılır. Her sensör karesini API'ye göndermek önerilmiyor. Native istemcide Android/iOS sensör ve kamera adaptörleri; ortak bilimsel referanslarla yerel hesap/render eşliği gerekir. Framework seçimi için önce telefon takibi prototipinde sensör, lens metadata'sı, düşük gecikmeli çizim ve yaşam döngüsü ölçülmelidir. Bu belge MAUI/Flutter/React Native veya ayrı Swift/Kotlin seçimi yapmaz.

## 8. Mevcut plana bağlı önerilen çalışma sırası

| Öncelik | Somut iş | Mevcut iz | Tamamlanma kanıtı |
|---|---|---|---|
| 1 | S23/iPhone üzerinde yeni takibin gerçek yön, eğim, yatay ekran ve izin testleri | FR-01/02, UJ-06, K-047 | Her cihaz için merkez/kenar sapması, yeniden hizalama, kesinti ve geri dönüş sonuçları |
| 2 | Hedefe ulaşma akışını sadeleştirme; takipte kısa yön/yükseklik ve yeniden hizalama | FR-01/03/11 | EN/TR aynı hedef bulma görevini tamamlama; uzun tanıyı açmadan kullanılabilme |
| 3 | Referansı belirli heading için WMM/WMMHR değerlendirmesi; FOV/kırpma kalibrasyonunu ayrı prototipleme | FR-01/02, K-047 açık işleri | NOAA sabit testleri, çift sapma düzeltmesi olmaması; merkez ve kenarda bağımsız fiziksel ölçüm |
| 4 | Katalog/görsel ve gece planlama derinliği; kaynak bazında güncelleme | FR-03/04/05/08 | Kimlik/lisans/kaynak eşliği, bağımsız hesap referansları ve bayat veri davranışı |
| 5 | Web kabulünün ardından ortak mobil API sözleşmesi ve native render/sensör prototipi | K-039, FR-07/09/11 | Aynı hesabın veri/dil eşliği, güvenli mobil oturum, cihaz kabulü ve bilimsel port eşliği |

Ekipman/teleskop kontrolü ve çok geniş atlas mevcut ileri kapsamlarında kalır. Bildirim, widget, satın alma, yeni sosyal paylaşım akışı ve kişisel offline veri deposu bu araştırmayla teslimat kapsamına alınmadı.

## 9. Adil fiziksel karşılaştırma protokolü

Henüz çalıştırılmadı. Aynı S23 ve iPhone 15 üzerinde, kurulu sürüm ve Lite/Plus/paket durumu kaydedilerek uygulanmalı:

1. Aynı gözlem noktası ve UTC anı; önce sensörsüz haritada koordinat/ufuk karşılaştırması. Rakip haritası tek bilimsel gerçek kaynak yapılmaz.
2. Ufuk üstü Ay ve birbirinden ayrık parlak yıldız/gezegenlerle ilk yön hatası; hizalama sonrası merkez, kenar ve farklı yüksekliklerde hata. Güneş optik kalibrasyon hedefi yapılmaz.
3. Dört ana yön, 359°→0° geçişi, dikey/yatay ekran, yavaş/hızlı dönüş ve birkaç dakika sonra sürüklenme. Aynı hedefe dönerek tekrarlanabilirlik kontrolü.
4. Kamera açık/kapalı; ana/alternatif arka lens, zoom/kırpma ve yeniden boyutlanmada örtüşme. Ölçülemeyen FOV “doğru” varsayılmaz.
5. Soğuk açılış, sensör hazır olma ve hedefi bulma süreleri; kare zamanı, kayıp kare, pil/ısınma. Cihaz ve koşul belirtmeden performans puanı verilmez.
6. Önceden paket indirilmiş/indirilmemiş uçak modu; izin reddi/sonradan verme; arka plana alma/dönüş; kamera göstergesinin kapanması. PWA ve native sonuçları ayrı tutulur.
7. Başlangıç kullanıcı görevi: “Jüpiter'i bul, hangi yöne/ne kadar yukarı bakacağını anlat, bilgi kartını oku.” Tamamlama ve yanlış yönlendirme kaydedilir; az kişiyle yapılan sonuçlar dünya geneline genellenmez.

Açısal merkez hatası için gerçek referans ve raporlanan birim yön vektörleri arasında `acos(clamp(dot(u,v), -1, 1))` kullanılabilir. Örnek sayısı, medyan, üst yüzdelik ve en kötü durum birlikte raporlanmalı; kabul eşiği kullanıcıyla ürün hedefi olarak belirlenmeli, rakip iddiasından uydurulmamalıdır. Ham kamera/konum/sensör kayıtlarını paylaşmak bu protokolün zorunlu parçası değildir.

## 10. Araştırmanın sonucu ve sınırı

Yorungez'ın gelişimi için en yüksek değer, katalog sayısını büyütmeden önce **telefonun gösterdiği yönü fiziksel olarak doğrulamak**, kullanıcıyı hedefe kısa bir akışla ulaştırmak ve kaynaklı nesne/görünürlük bilgisini derinleştirmektir. PWA üzerinden takip mümkündür; native istemci daha doğrudan platform adaptörleri sağlar, fakat cihaz/manyetik/lens hatalarının kendiliğinden çözümü değildir. Aynı backend hedefi bu ayrımla uyumludur.

Araştırma sonucunda yalnız bu rapor ve belge dizini güncellendi. Ürün kodu, hesap/veri politikası, kapsam, otomatik dağıtım ve uygulama sürümü değişmedi. Mağaza fiyatları/sürümleri zamanla değişebilir; bu belge tarihli bir kaynak incelemesidir.
