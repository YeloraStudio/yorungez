# OpenSky — Ürün Vizyonu, Gereksinimler ve UX Taslağı

> **Belge sürümü:** 1.0  
> **Tarih:** 28 Ekim 2026  
> **Durum:** Ürün keşfi / geliştirme öncesi referans belge  
> **Proje adı:** OpenSky (çalışma adı; marka ve alan adı uygunluğu henüz doğrulanmadı)  
> **Kapsam:** Ürün, kullanıcı deneyimi, iş kuralları, modül sınırları ve yol haritası. Bu belge bir kodlama talimatı değildir.

## 1. Ürün özeti

**OpenSky**, dünyanın herhangi bir noktasından gökyüzünü konum ve zamana göre keşfetmeyi, astronomik nesneleri öğrenmeyi, gök olaylarını takip etmeyi ve kişisel gözlem kayıtları oluşturmayı sağlayan **açık kaynak, hızlı, erişilebilir ve PWA destekli bir astronomi platformudur**.

**Temel soru:** *“Bulunduğum noktadan gökyüzünde ne var, nerede, ne zaman görülebilir ve neden?”*

Ürün, **hesap veya ekipman bilgisi gerektirmeden** kullanılabilir. Hesap açanlar ise favorilerini, kayıtlı konumlarını, notlarını ve gözlem/anı geçmişlerini cihazlar arasında saklayabilir. Kullanıcı ister çıplak gözle gözlem yapsın, ister dürbün ya da teleskop kullansın, aynı astronomi atlasından faydalanır.

**Temel deneyim:** Harita öncelikli hibrit arayüz. Gökyüzü haritası ana yüzeydir; katalog, bilgi kartları, görünürlük, takvim ve kişisel kayıtlar bu deneyimin etrafında bütünleşir.

### 1.1 Ürün ilkeleri

1. **Önce keşif:** İlk ziyarette üyelik, ekipman seçimi veya zorunlu eğitim turu yoktur.
2. **Harita merkezde:** Arayüzün ana referansı etkileşimli gökyüzü haritasıdır.
3. **Konum + zaman + bağlam:** Bütün hesaplanabilir astronomi verileri seçili gözlem noktası ve tarih/saatle ilişkilidir.
4. **Bilimsel güvenilirlik:** Hesaplanmış değer, tahmin, katalog bilgisi ve kişisel gözlem birbirinden ayrılır.
5. **Dikey büyüme:** Her yeni özellik gökyüzünü bulma, görme, anlama veya kaydetme deneyimini derinleştirir.
6. **İsteğe bağlı kişiselleştirme:** Üyelik ve ekipman profilleri temel kullanımın ön koşulu değildir.
7. **Şeffaf veri:** Kaynak, hesaplama/yenilenme zamanı ve bilinen belirsizlikler gösterilir.
8. **Hız ve süreklilik:** Harita akıcıdır; ağ kesintisinde mümkün olan temel işlevler korunur.
9. **Gizlilik:** Hassas koordinatlar ve kişisel kayıtlar varsayılan olarak özel tutulur.

### 1.2 Hedef kitle

- Astronomiyi merak eden ve hiçbir ekipmana sahip olmayan kişiler.
- Ay, gezegen, yıldız ve derin uzay gözlemine yeni başlayan amatörler.
- Dürbün veya teleskop kullanan gözlemciler.
- Öğrenciler, öğretmenler ve bilim iletişimiyle ilgilenenler.
- Kendi konumlarını, astronomi anılarını ve gözlem kayıtlarını düzenlemek isteyenler.

## 2. Ürünün sınırları

### Kapsama dahil

- Gerçek zamana duyarlı gökyüzü haritası, pusula/yön bilgisi ve tarih-saat simülasyonu.
- GPS izni veya manuel enlem-boylam ile hassas gözlem noktası seçimi.
- Gezegenler, Ay, Güneş, yıldızlar, takımyıldızlar ve derin uzay cisimleri hakkında atlas/katalog.
- Gök cisimlerinin konum, hareket, doğuş-batış ve uygun gözlem aralıklarının anlaşılır sunumu.
- Astronomik olay takvimi ve bağlama uygun keşif önerileri.
- İsteğe bağlı hesap; favoriler, notlar, anılar, gözlem kayıtları, konumlar ve senkronizasyon.
- Sonradan eklenebilecek, **tamamen isteğe bağlı** dürbün/teleskop profilleri.

### Ana kapsam dışında

Sosyal medya akışı, genel amaçlı forum, ekipman pazaryeri, reklam/alışveriş karşılaştırma sitesi, zorunlu AI asistanı ve astronomi dışı kişisel günlük. Bunlar sırf kullanıcı sayısını artırmak amacıyla projeye eklenmez.

## 3. Bilgi mimarisi ve navigasyon

| Ana bölüm | Kullanıcının amacı | Başlıca içerik |
|---|---|---|
| **Gökyüzü** | Şimdi veya seçili zamanda gökyüzünü incelemek | Canlı harita, pusula, zaman kontrolü, konum, nesne seçimi, keşif paneli |
| **Keşfet** | Bir astronomi nesnesini öğrenmek veya bulmak | Arama, katalog, sınıflandırma, ayrıntılı bilgi kartları |
| **Olaylar** | Ne zaman ne olacağını öğrenmek | Ay evreleri, yaklaşan gök olayları, uygun zaman pencereleri |
| **Defterim** | Kişisel astronomi geçmişini yönetmek | Favoriler, notlar, gözlem/anı kayıtları, kayıtlı konumlar |

**Navigasyon kuralı:** “Konumlarım” beşinci ana sekme değildir; haritadaki konum seçiciden ve Defterim içinden erişilir. **Arama** ayrı bir ana menü değil, uygulama genelinde erişilebilen ortak bir işlevdir.

### 3.1 Ana ekran — hibrit, harita öncelikli

- **Masaüstü:** Harita baskın alanı kaplar. Seçili gök cisminin bilgileri veya “Bu gece” içeriği sağdaki bağlamsal panelde görüntülenir.
- **Mobil/PWA:** Harita mümkün olduğunca geniş kalır. Arama ve konum kontrolleri kompakt; detaylar kapatılabilir, kısmen veya tamamen açılabilir bir alt panelde sunulur.
- **İlk açılış:** Uygulama konum izni istemeden çalışır; açıkça **örnek konum** olarak etiketlenen varsayılan bir noktada harita açılabilir. Kullanıcı GPS izni veya manuel koordinat seçer.
- **Bağlam sürekliliği:** Seçilen konum, tarih/saat, nesne ve harita görünümü arasında gereksiz sıfırlama yapılmaz.
- **Kullanıcı kontrolü:** Haritayı kaydırma/yakınlaştırma, bir hedefe odaklanma, katmanları açma, “Şimdiye dönme” ve konumu değiştirme kolay erişilebilir olmalıdır.

## 4. İşlevsel gereksinimler

### FR-01 — Konum ve yön

- Tarayıcı konum izni veya manuel **enlem-boylam** girme; şehir araması yardımcı seçenek olabilir.
- Manuel koordinatta geçerlilik kontrolü; GPS sonucunda mevcutsa doğruluk bilgisi.
- Konuma göre saat dilimi ve yerel tarih/saat gösterimi.
- Azimut **0–360°**, yükseklik **−90° ila +90°**; kuzey/doğu/güney/batı yönlerinin açıklanması.
- Mobil pusula destekleniyorsa sensörle hizalama; izin veya sensör yoksa manuel yönlendirme.
- Yerel ufuk engelleri, yükseklik (elevation) ve kullanıcı tanımlı balkon/dağ profili sonraki aşamada genişletilebilir.
- Tam konum paylaşımında açık onay; kayıtlı kişisel konumlar varsayılan olarak özel.

### FR-02 — Canlı gökyüzü haritası

- Tarih, saat ve gözlemci koordinatına göre gök cisimlerinin konumları.
- Güneş, Ay, gezegenler, parlak yıldızlar ve temel takımyıldızlar ilk sürümde.
- Seçme, odaklama, kaydırma, yakınlaştırma/uzaklaştırma ve arama üzerinden haritaya geçiş.
- Katmanlar: takımyıldız çizgileri/adları, yönler, ufuk, koordinat ızgaraları ve görünür etiketler.
- Gece kullanımına uygun düşük parlaklıklı görünüm; harita kontrolleri erişilebilir ve dokunmatik kullanıma uygun.
- Derin uzay kataloglarının kapsamı ve ileri seviye harita seçenekleri aşamalı genişletilir.

### FR-03 — Gök cismi atlası

Her nesnenin tekil bir kimliği ve tutarlı bir bilgi kartı bulunur. Nesne türüne göre geçerli alanlar gösterilir:

| Alan | Örnek içerik |
|---|---|
| Kimlik | Türkçe/İngilizce ad, alternatif adlar, Messier/NGC numarası |
| Sınıf | Gezegen, yıldız, açık küme, galaksi, bulutsu vb. |
| Anlık konum | Azimut, yükseklik; gerektiğinde diğer astronomik koordinatlar |
| Zaman | Doğuş, batış, uygun gözlem aralığı; hesaplanamadığı durumlar açıkça belirtilir |
| Görünürlük | Geometrik durum, tahmini gözlem koşulları ve çıplak göz beklentisi ayrı ayrı |
| Fiziksel bilgiler | Uzaklık, boyut, parlaklık, bilimsel açıklama; yalnızca nesne için anlamlı alanlar |
| Kaynak | Veri kataloğu, kaynak bağlantısı, veri güncelliği |
| Eylemler | Haritada göster, ilgili olaylara git, favorile, gözlem kaydı oluştur |

Arama Türkçe/İngilizce isimleri ve **M31 / NGC 224** gibi katalog kimliklerini desteklemelidir. Kullanıcı hedefi o anda göremese bile atlas kaydına erişebilir.

### FR-04 — Zaman ve astronomik olaylar

- **Canlı zaman** ve **simülasyon zamanı** her zaman açıkça ayırt edilir.
- Tarih/saat manuel değiştirilebilir; tek işlemle **Şimdiye dön** yapılır.
- Gök cisimlerinin seçili zaman dilimindeki hareketi ve konumu güncellenir.
- İlk sürüm: temel Güneş/Ay saatleri, Ay evresi ve yakın tarihli temel olay bilgileri.
- Sonraki sürümler: meteor yağmurları, kavuşumlar, tutulmalar, ileri tarih olayları, uygun gözlem pencereleri.
- Uzak gelecek tarihine ait hava tahmini varmış gibi davranılmaz.

### FR-05 — Görünürlük ve gözlem koşulları

**“Görünür” tek bir evet/hayır değeri değildir.** Sistem üç katmanı ayrı sunar:

1. **Geometrik görünürlük:** Nesne, seçili yer ve zamanda yerel ufkun üzerinde mi?
2. **Koşullara göre uygunluk:** Ay ışığı, astronomik karanlık, atmosfer, bulutluluk ve benzeri etkenler gözlemi nasıl etkiliyor?
3. **Gözle algılanabilirlik:** Nesne çıplak gözle veya isteğe bağlı ekipmanla pratikte seçilebilir mi? Kesin garanti verilmez.

Astronomik gece, Güneş merkezinin ufkun yaklaşık **18° altına** indiği koşulla tanımlanır; yerel ufuk, kırılma ve hesaplama varsayımları gerektiğinde belgelenir. Hava ve ışık kirliliği bilgileri dış kaynaklara bağlıdır; bulunmadığında sistem **“bilinmiyor”** gösterir, uydurma uygunluk puanı üretmez.

### FR-06 — Kişisel astronomi alanı

Dört veri kavramı ayrı tutulur:

| Kayıt | Anlamı |
|---|---|
| **Favori** | Daha sonra dönülecek gök cismi veya atlas içeriği |
| **Gözlem kaydı** | Bir zamanda gerçekten yapılan gözleme ilişkin kayıt |
| **Kayıtlı konum** | Tekrar kullanılabilen koordinat ve isteğe bağlı ad/açıklama |
| **Not / anı** | Bir gök cismi, tarih, konum veya kişisel deneyimle ilişkilendirilebilen serbest metin |

Astronomik olay (ör. Ay tutulması) ile kullanıcının bu olayı izlemesine ilişkin **kişisel gözlem** aynı kayıt türü değildir; birbirlerine bağlanabilirler.

Kayıt oluştururken minimum zorunlu alan kullanılır. Gök cismi, zaman, koordinat ve ileride ekipman eklemek isteğe bağlıdır. Kişisel içerik varsayılan olarak özel olmalıdır. Veri dışa aktarma ve silme olanağı planlanır.

### FR-07 — Anonim kullanım ve hesaplar

| İşlev | Anonim ziyaretçi | Doğrulanmış hesap |
|---|---|---|
| Harita, keşif, katalog, olaylar | Kullanabilir | Kullanabilir |
| Konum ve zaman seçimi | Kullanabilir | Kullanabilir |
| Favoriler, notlar, gözlem kaydı | Tarayıcıda yerel kayıt | Hesaba bağlı kalıcılık |
| Kayıtlı konumlar | Yerel kayıt | Hesapta kayıt ve senkronizasyon |
| Cihazlar arası senkronizasyon | Yok | Var |
| Veri dışa aktarma | Yerel veriler | Hesap verileri |

- E-posta/şifre ile kayıt, **zorunlu e-posta doğrulaması**, giriş-çıkış, şifre sıfırlama ve temel oturum güvenliği.
- Hesap açıldığında yerel verileri taşıma **açık onayla** yapılır; aynı favorinin çoğaltılması önlenir, not çakışmaları veri kaybı olmadan ele alınır.
- Anonim tarayıcı verileri önbellek temizliği veya cihaz değişikliğiyle kaybolabilir; arayüzde bu sınır anlatılır.
- Kullanıcı her zaman haritaya geri dönebilir; hesap ekranları keşif akışını gereksiz yere kesmez.

### FR-08 — Sürekli yaşayan veri sistemi

“Canlı” yaklaşımı üç ayrı mekanizma gerektirir:

- **Hesaplanan veri:** Gök cisimlerinin konumları ve zaman olayları güvenilir astronomi algoritmalarıyla seçili an için hesaplanır. Her hareket için dış API çağrısı gerekmez.
- **Yenilenen veri:** Hava koşulları ve güncellenen harici kaynaklar uygun aralıklarla alınır; önbellek ve hata toleransı kullanılır.
- **Küratörlü bilgi:** Bilimsel kataloglar ve açıklamalar kaynak, sürüm ve doğrulama geçmişiyle güncellenir. AI kaynak metnini denetimsiz değiştirmez.

Her veri alanı için kaynak, son başarıyla güncellenme zamanı, hesaplanma zamanı ve gerektiğinde **güncel / gecikmiş / erişilemiyor** durumu tanımlanmalıdır.

### FR-09 — PWA ve çevrimdışı kullanım

- Mobil/masaüstü uyum, kurulabilir PWA ve kesintisiz temel navigasyon.
- Daha önce yüklenmiş temel arayüz ve uygun önbellekli katalog verilerinin internetsiz görüntülenmesi.
- Yerel astronomik hesaplar için gerekli veri önceden mevcutsa çevrimdışı temel harita işlevleri.
- Yerel not/gözlem kayıtlarının kaybolmadan saklanması; hesap senkronizasyonunun ağ gelince güvenli devam etmesi.
- Eski hava bilgisinin canlıymış gibi gösterilmemesi.

### FR-10 — Ekipman uyumluluğu (zorunlu değil; ileri aşama)

Dürbün/teleskop bilgisi girmek hiçbir temel ekrana erişim koşulu değildir. İleride kullanıcı isterse büyütme, açıklık ve gerçek görüş alanı gibi değerleri kaydedebilir; **görüş alanı simülasyonu ve ekipmana uygun gözlem açıklamaları** kişiselleştirilebilir. Çıplak göz deneyimi daima tam işlevli kalır.

## 5. Temel kullanıcı yolculukları

| ID | Yolculuk | Tamamlanma ölçütü |
|---|---|---|
| **UJ-01** | İlk ziyaret → örnek harita → GPS veya koordinat → ilk gök cismi | Hesap ve ekipman gerekmeden keşif yapılır |
| **UJ-02** | Arama/haritadan nesne seç → bilgi kartı → konumu/zamanı incele | Harita bağlamı korunur; görünmeyen nesne de açıklanır |
| **UJ-03** | Şimdi → başka tarih/saat → hareketi incele → Şimdiye dön | Simülasyon zamanı asla gerçek zamanla karıştırılmaz |
| **UJ-04** | Anonim favori/not → kayıt → e-posta doğrulama → veriyi hesaba aktar | Veri kaybı veya sessiz otomatik paylaşım yaşanmaz |
| **UJ-05** | Gözlem/anı oluştur → isteğe bağlı nesne ve konum bağla → sakla | Minimum alanlarla kişisel kayıt oluşturulur |
| **UJ-06** | Mobilde haritayı gez → cihaz pusulasını kullan/manuel yönet → ayrıntı panelini aç | Sensör yokken de görev tamamlanır |
| **UJ-07** | İnternet kesilir → önbellekli atlası aç → not kaydet → sonra eşitle | Kullanıcı veri güncelliği ve eşitleme durumunu anlar |

**Bağlamsal durum:** Seçili konum, tarih/saat, gök cismi, harita yönü/ölçeği ve gerçek zaman-simülasyon modu tek bir tutarlı deneyim oluşturmalıdır.

## 6. Hata, boş ve sınır durumları

| Durum | Ürün davranışı |
|---|---|
| Konum izni reddedildi | Manuel koordinat ve şehir seçimi sunulur; keşif engellenmez |
| Konum yaklaşık / düşük doğruluklu | Doğruluk bilgisi veya uygun uyarı gösterilir |
| Sensör/pusula yok veya sapmalı | Manuel yönlendirme çalışır; kalibrasyon ipucu sunulur |
| Nesne ufkun altında | Durumun nedeni ve hesaplanabiliyorsa sonraki uygun zaman gösterilir |
| Harici hava kaynağı çalışmıyor | Astronomik hesaplar devam eder; hava durumu “bilinmiyor” olur |
| Katalog bilgisi eksik | Bilinmeyen alan boş/uygun etiketle gösterilir, uydurulmaz |
| İnternet kesildi | Desteklenen yerel işlevler çalışır; senkronizasyon bekler |
| İleri tarih seçildi | Astronomik hesaplar yapılır; hava tahmini kapsamadığı tarih için verilmez |
| Kullanıcı konumu değiştirir | Seçili zaman ve hedef mümkün olduğunca korunur; konuma bağlı veriler yeniden hesaplanır |
| Tam koordinat bağlantıyla paylaşılacak | Gizlilik uyarısı ve isteğe bağlı yaklaşık konum paylaşımı sunulur |

## 7. Teknoloji ve mantıksal modüller

**Kararlaştırılan yön:** Next.js + TypeScript frontend, **PWA**, ASP.NET Core tabanlı **modüler monolit backend**; Python yalnızca gerektiği veri işleme/bilimsel analiz işlerinde. PostgreSQL ve gerekirse PostGIS önerilen kalıcılık altyapısıdır. Kod ve dosya yapısı bu belgenin kapsamında değildir.

| Mantıksal modül | Sorumluluk |
|---|---|
| **Astronomy Core** | Zaman/koordinat dönüşümü, göksel konum ve efemeris hesapları |
| **Sky Explorer** | Harita deneyimi, yön, katmanlar, seçili hedef ve zaman kontrolü |
| **Celestial Catalog** | Nesne kimlikleri, sınıflandırma, adlar, açıklamalar, kaynaklı içerik |
| **Astronomical Events** | Hesaplanmış veya kataloglanmış gök olayları ve takvim |
| **Geo & Visibility** | Gözlemci konumu, saat dilimi, ufuk ve görünürlük kuralları |
| **Identity & Access** | Kayıt, doğrulama, oturum ve hesap yaşam döngüsü |
| **Personal Observatory** | Favoriler, notlar, gözlem/anı kayıtları, kayıtlı yerler |
| **Data Integration** | Harici kaynak envanteri, içeri alma, yenileme, kaynak sürümü, sağlık kontrolleri |

**Önemli ayrım:** Bu tablo zorunlu olarak sekiz ayrı deploy edilecek servis anlamına gelmez. Modüler monolitte modüller tek uygulama içinde açık sınırlar ve sorumluluklarla çalışır.

### 7.1 Dış kaynak değerlendirme listesi

Bunlar **onaylanmış nihai bağımlılıklar değil, doğrulanacak adaylardır**:

- **Astronomy Engine:** Gök cismi pozisyonları ve astronomik olay hesapları.
- **NASA JPL Horizons:** Hassas efemerislerle doğrulama/karşılaştırma.
- **OpenNGC ve diğer astronomik kataloglar:** Derin uzay nesnelerinin kimlik ve nitelikleri.
- **Open-Meteo veya eşdeğer kaynaklar:** İsteğe bağlı hava koşulları.
- **Mevcut açık kaynak gökyüzü motorları / görselleştirme kütüphaneleri:** Harita çekirdeği için yeniden kullanım değerlendirmesi.

Her aday için **lisans, veri kullanım hakkı, atıf zorunluluğu, ticari kullanım koşulları, sürüm bakımı, API sınırları, doğruluk, performans ve çevrimdışı uygunluk** kontrol edilmelidir.

## 8. Fonksiyonel olmayan gereksinimler

| Alan | Başlangıç hedefi |
|---|---|
| **Web performansı** | Core Web Vitals hedefleri: LCP ≤ 2,5 sn, INP ≤ 200 ms, CLS ≤ 0,1; gerçek cihaz testleriyle ölçüm |
| **Harita performansı** | Orta sınıf mobil cihazda akıcı kaydırma, zoom, hedef seçimi ve zaman geçişi; ölçülebilir performans bütçesi |
| **Doğruluk** | Astronomik hesaplar bağımsız güvenilir referanslarla karşılaştırılır; toleranslar özellik bazında tanımlanır |
| **Güvenilirlik** | Harici kaynak hataları ana haritayı kullanılmaz hâle getirmez; veri güncelliği görünür |
| **Güvenlik** | E-posta doğrulama, güvenli kimlik doğrulama, hız sınırlama, güvenli şifre sıfırlama |
| **Gizlilik** | Konum izni açık rızaya dayanır; kayıtlı koordinatlar/notlar varsayılan olarak özeldir; veri silme/dışa aktarma |
| **Erişilebilirlik** | WCAG 2.2 AA hedefi, klavye kullanımı, dokunmatik hedefler ve haritaya eşdeğer metinsel bilgi |
| **Yerelleştirme** | Türkçe ve İngilizce; zaman, ondalık biçimi ve saat dilimi tutarlılığı |
| **PWA** | Kurulabilirlik, sürüm/önbellek yönetimi, sınırlı çevrimdışı kullanım ve senkronizasyon durumu |
| **Gözlemlenebilirlik** | API ve güncelleme işleri için hata, gecikme, kaynak başarısı ve performans izleme |

Bu değerler **hedef** niteliğindedir; tamamlandığına dair ölçüm veya garanti değildir.

## 9. Sürümleme ve önceliklendirme

### MVP-0 — Dikey prototip (ilk teknik doğrulama)

- Bir gözlem konumu ve seçili tarih/saatten çalışan harita.
- Temel gök cismi arama/seçme, bilgi kartı ve konum hesabı.
- Mobil/masaüstü temel etkileşim ve gerçek zaman-simülasyon ayrımı.

**Amaç:** Harita çekirdeğinin doğruluğunu, kullanılabilirliğini ve performansını kullanıcı hesabı gibi ek karmaşıklıklardan önce göstermek.

### P0 — İlk herkese açık kullanılabilir sürüm

- GPS izni veya manuel koordinat; açıkça etiketli örnek konum.
- Canlı harita, pusula için cihaz destekli/manuel yön, tarih-saat kontrolü.
- Güneş, Ay, gezegenler, temel yıldızlar ve takımyıldızlar.
- Nesne arama, temel bilimsel bilgi kartları, haritada odaklanma.
- Basit geometrik görünürlük ve temel Ay/Güneş bilgileri.
- E-posta/şifre ile isteğe bağlı kayıt, giriş, **e-posta doğrulama**.
- Yerel ve hesap bağlantılı favoriler, notlar, gözlem kayıtları ve kayıtlı konumlar.
- Anonim verileri açık onayla hesaba taşıma.
- Kurulabilir PWA, temel önbellek/çevrimdışı durumlar, kaynak/güncellik bilgileri.

### P1 — Astronomi derinliği

- Geniş Messier/NGC ve yıldız katalogları; gelişmiş arama/filtreleme.
- Astronomik olay takviminin kapsamlı hâli ve gözlem zaman pencereleri.
- Hava koşulları, Ay ışığı, ışık kirliliği ve gelişmiş uygunluk değerlendirmesi.
- Yerel ufuk engelleri, balkon ve arazi profilleri.
- Daha ayrıntılı bilimsel içerik, harita katmanları ve gözlem geçmişi analizi.
- Daha güçlü çevrimdışı katalog ve kişisel veri senkronizasyonu.

### P2 — İsteğe bağlı uzmanlaşma

- Dürbün/teleskop profilleri ve görüş alanı simülasyonu.
- Gelişmiş koordinat sistemleri, projeksiyonlar ve astronomik simülasyonlar.
- İleri gözlem planlama ve gelişmiş analitik.

**Öncelik ilkesi:** P0/P1/P2 takvim taahhüdü değil, kapsam ve bağımlılık sıralamasıdır. Yeni özellik haritanın astronomik keşif amacını güçlendirmiyorsa ertelenir veya reddedilir.

## 10. Geliştirme öncesi dokümantasyon yol haritası

| Aşama | Amaç | Çıktı |
|---|---|---|
| **Product Discovery** | Değer önerisi, hedef kitle, kapsam/sınırlar, benzer ürün analizi | Vision, PRD, başarı ölçütleri |
| **Domain Discovery** | Gök cismi, konum, zaman, görünürlük, olay ve kişisel kayıtların tanımlanması | Domain glossary, iş kuralları |
| **UX / Information Architecture** | Sayfalar, paneller, arama, ilk kullanım ve hesap geçişleri | Sitemap, screen inventory, user journeys, wireframes |
| **Architecture & Data Strategy** | Modül sınırları, veri kaynakları, lisans ve güncelleme stratejisi | Architecture overview, veri envanteri, ADR'ler |
| **Delivery Planning** | Küçük, test edilebilir işler, test planları ve sürüm sınırları | Backlog, kabul kriterleri, release plan, CONTRIBUTING.md |

### 10.1 İlk kabul kriterleri

- **AC-01:** Giriş yapmadan harita kullanılabiliyor.
- **AC-02:** Konum izni reddedildiğinde manuel koordinatla devam edilebiliyor.
- **AC-03:** Konum/tarih/saat değişince astronomik pozisyonlar tutarlı güncelleniyor.
- **AC-04:** Nesne haritadan da aramadan da seçilebiliyor; aynı bilgiye ulaşılabiliyor.
- **AC-05:** Gerçek zaman ve simülasyon açıkça ayrılıyor; tek eylemle şimdiye dönülüyor.
- **AC-06:** Nesne ufkun altındaysa yanlış şekilde “görünür” denmiyor.
- **AC-07:** Anonim favori/notlar hesap oluşturma sırasında kaybolmuyor.
- **AC-08:** E-posta doğrulaması olmadan doğrulanmış hesap işlevleri aktifleşmiyor.
- **AC-09:** Hassas konum ve kişisel notlar kullanıcının izni dışında yayımlanmıyor.
- **AC-10:** Harici veri kaynağı bozulduğunda harita mümkünse çalışıyor; son veri zamanı anlaşılıyor.
- **AC-11:** Mobilde pusula/sensör desteği olmadığında harita manuel kontrol ediliyor.
- **AC-12:** PWA çevrimdışı modunda desteklenen işlevler ve güncellik sınırları açıkça belirtiliyor.

## 11. Başlıca riskler ve açık kararlar

**Riskler:** Harita motorunun geliştirme maliyeti; farklı cihazlarda sensör doğruluğu; büyük kataloglarda performans; üçüncü taraf API kotası/lisansları; hassas koordinatların gizliliği; kişisel yerel kayıtların hesaba taşınmasında çakışmalar; hava koşullarını kesin astronomik görünürlük gibi sunma riski.

**Henüz kesinleştirilmemiş kararlar:**

- Açık kaynak **kod lisansı** ve projede kullanılan veri/kütüphanelerin lisans uyumu.
- Gökyüzü görselleştirmesinde mevcut motoru kullanma, uyarlama veya ayrı katman geliştirme kararı.
- Astronomi kataloglarının kesin kapsamı, kalite kontrolleri ve güncelleme periyotları.
- Anonim kayıtlar için yerel saklama/senkronizasyon sınırları ve veri çatışması politikası.
- İlk sürümde konum yüksekliği ve gerçek yerel ufuk engellerinin kapsamı.
- Marka/alan adı uygunluğu ve dağıtım/işletim maliyeti.

Bu maddeler **alınmış kararlar gibi sunulmamalı**; ADR veya ürün kararıyla kesinleştirilmelidir.

## 12. Bu belgede yapılan temizlik ve güncelleme

- Yinelenen vizyon, misyon, navigasyon ve UX kararları tek bir güncel tanımda birleştirildi.
- Kişisel veya temsili **enlem-boylam, 122° azimut ve 4,4° dürbün görüş alanı** varsayılan proje gereksinimlerinden çıkarıldı. Bunlar yalnızca kullanıcı tarafından seçilebilecek girdilerin örnekleriydi.
- Ekipman merkezli tasarım kaldırıldı; ekipman yalnızca **isteğe bağlı P2 genişleme** olarak korundu.
- “Konumlarım” ayrı ana menü olmaktan çıkarıldı; konum seçici ve **Defterim** altında birleştirildi.
- Anonim kullanım ile doğrulanmış hesap/senkronizasyon farkları netleştirildi.
- Astronomik olay ile **kişisel gözlem/anı** kayıtları ayrıştırıldı.
- “Canlı uygulama” söylemi; hesaplanan astronomik veri, otomatik yenilenen dış veri ve kaynaklı bilgi deposu olarak tanımlandı.
- Görünürlük kavramı geometrik görünürlük, çevresel uygunluk ve çıplak göz/ekipmanla algılanabilirlik şeklinde ayrıştırıldı.
- Harita öncelikli hibrit UX, mobil alt panel, zaman modu ve kullanıcı yolculukları güncel kararlara eklendi.
- Nihai olmayan teknoloji/katalog seçimi ve ölçülmemiş performans değerleri **öneri veya hedef** olarak etiketlendi.

---

**Kısa ürün pusulası:** OpenSky'ın görevi kullanıcıya bir astronomi paneli göstermek değil; **seçtiği konum ve zamanda gökyüzünü keşfetme, anlama ve kişisel deneyimini kaydetme olanağı vermek**. Her yeni karar bu cümleye göre değerlendirilmelidir.
