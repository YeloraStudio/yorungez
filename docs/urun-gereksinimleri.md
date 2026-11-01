# yorungez — Ürün Vizyonu, Gereksinimler ve UX Taslağı

**K-029 / açık kaynak yayın (1 Kasım 2026):** Özgün kod ve özgün proje belgeleri Apache-2.0; üçüncü taraf veri/görseller kendi lisanslarında. Public kaynak hedefi `YeloraStudio/yorungez`; gerçek ortam/SMTP/Portainer/veritabanı verileri özel kalır. Public metinlerde `sender@example.com` redakte örnektir, gerçek gönderen özel yapılandırmadadır; tarihsel SMTP başarı kaydı örnek hesabın kullanıldığı anlamına gelmez. [Karar](adr/0014-acik-kaynak-yayin-ve-apache-2.md), [yayın incelemesi](open-source-publication.md). Önceki ürün planı ve açık kabul işleri korunur.

**Güncel TECH-07 / K-027–028 (1 Kasım 2026):** Menüde giriş/kayıt veya doğrulanmış oturumun ad-soyadı; kayıt için ad/soyad/e-posta/parola. Servis hatası ve çevrimdışı durum ayrıldı, ortak yerel başlatıcı eklendi. Genel katalog/terim/takvim için hash doğrulamalı PWA paketi ve yeniden açılış uygulandı; kişisel kayıt/oturum/koordinat cache'e girmez. 125 .NET/44 istemci testi; fiziksel cihaz/üretim backup kabulü açık. [Uygulama ve kanıt](hesap-menusu-ve-cevrimdisi-gokyuzu.md), [hesap ADR](adr/0012-hesap-menusu-ve-ad-soyad.md), [PWA ADR](adr/0013-genel-gokyuzu-pwa-ve-cevrimdisi-paket.md).

**Güncel K-026 / TECH-06 (1 Kasım 2026):** Hesap envanterinde not/favori yanında ayrı gözlem ve kayıtlı konum uygulandı. Gözlem açıklama + kişisel beyan ister; gerçek zaman/nesne/konum isteğe bağlıdır, simülasyon zamanı kendiliğinden bağlanmaz. Konum kopyası geçmişi korur; haritada kullanım an/mod/hedef/kamerayı korur. 120 .NET + 38 istemci testi ve üretim derlemesi geçti; 52 tr/en terim/cache .7. [Uygulama ve sınırlar](gozlem-kayitlari-ve-kayitli-konumlar.md), [ADR-0011](adr/0011-gozlem-kaydi-ve-kayitli-konumlar.md). Fiziksel cihaz, genel katalog PWA/offline ve üretim backup kabulü açık; kişisel tarayıcı kalıcılığı yoktur.

**1.8 / K-025:** Varsayılan dil İngilizce; açık Türkçe seçimi ve UI/API eşliği korunur. Bütün işlem e-postaları kullanıcı kararıyla İngilizce markalı HTML/plain; Gmail sırrı özel `.env` içinde, SMTP TLS/AUTH kontrolü başarılı. [Uygulama](eposta-ve-varsayilan-dil.md). FR/UJ/AC kimlikleri ve diğer P0/P1/P2 hedefleri korunur.

**1.7 / K-024:** Kullanıcı düzeltmesi: kişisel kayıt yalnız doğrulanmış hesapla sunucuda; anonim/tarayıcı kalıcılığı ve yerelden aktarım kaldırıldı. TR/EN hesap ekranları, PostgreSQL Defterim ve panel geri dönüşü [uygulandı](hesap-ve-sunucu-defteri.md). FR/UJ/AC kimlikleri korunur; AC-07 ve UJ-04 yeni hesap zorunluluğuna göre güncellendi.

**1.6 / K-022–023:** Bugün modu kaldırıldı; yalnız Bu gece, sunset–sunrise kesişimi ve kutup durumları. Tüm görünür select/date/time alanları ortak özel bileşen; native dil listesi kararı değişti. Sensörsüz hedef yönü/yüksekliği ve dürbün brief'i eklendi; yerel favori/not ilk P0 dilimi başladı. [Güncel uygulama](ortak-bilesenler-ve-sensorsuz-gozlem.md), [UX-02](kisisel-kayit-hesap-cevrimdisi-akislari.md). Önceki kimlikler ve bütün hedefler korunur.

**1.5 / K-021 güncel ek:** [Bugün/Bu gece, Takvim ve konum/ufuk altı paketi](gozlem-cizelgesi-ve-takvim.md). Menüde gereksiz Keşfet düğmesi kaldırıldı; atlas ve ortak arama FR-03 olarak sürer. Standart çizelge 0 m deniz seviyesi referansı/34′ kırılma/üst kenar kullanır; harita hava kırılmasız merkez hesabı ayrıdır. Hedef arazi altında/aşağı bakışta fotoğraf saydamlaşır; 0,6°–330° stereografik görünüm yönleri değiştirmez. Takvim küresel anı yerel/UTC gösterir, gözlenebilirlik garantisi değildir.

**31 Ekim görünüm ek kararı:** Beğenilen tam ekran yerleşim korunur. UI kaynak paleti #3C3F43/#9EA1A6/#8B2333/#C9B6A6/#F7F1E6; dil seçimi sol menüde açılır liste. Görsel gökyüzü/çevre daha doğal, kaynaklı fotoğraf ve kadir sıralı ışıkla sunulur; fotoğraf yerel topografya, görsel atmosfer gözlem koşulu değildir. Pusulada kaynak/kuzey belirsizliği, izin/hizalama ve fiziksel kabul ayrılır. [Güncel paket](dogal-gorunum-ve-pusula.md).

> **Belge sürümü:** 1.11
> **Tarih:** 1 Kasım 2026
> **Durum:** Güncel ürün referansı; modüler backend ve ilk tr/en harita akışı uygulandı, kabul kapsamı kısmi
> **Proje adı:** yorungez (yörünge + gezmek; ad kullanıcı tarafından kesinleştirildi)  
> **Planlanan alan adı:** yorungez.com (satın alma bekliyor)  
> **Başlangıç kaynağı:** [Değiştirilmeden saklanan 1.0 belgesi](arsiv/OpenSky_Proje_Gereksinimleri_UX_v1.md)  
> **Kapsam:** Ürün, kullanıcı deneyimi, iş kuralları, modül sınırları ve yol haritası. Bu belge bir kodlama talimatı değildir.

## 1. Ürün özeti

**yorungez**, dünyanın herhangi bir noktasından gökyüzünü konum ve zamana göre keşfetmeyi, astronomik nesneleri öğrenmeyi, gök olaylarını takip etmeyi ve kişisel gözlem kayıtları oluşturmayı sağlayan **açık kaynak, hızlı, erişilebilir ve PWA destekli bir astronomi platformudur**.

**Temel soru:** *“Bulunduğum noktadan gökyüzünde ne var, nerede, ne zaman görülebilir ve neden?”*

Ürün, **hesap veya ekipman bilgisi gerektirmeden** kullanılabilir. Hesap açanlar ise favorilerini, kayıtlı konumlarını, notlarını ve gözlem/anı geçmişlerini cihazlar arasında saklayabilir. Kullanıcı ister çıplak gözle gözlem yapsın, ister dürbün ya da teleskop kullansın, aynı astronomi atlasından faydalanır.

**Temel deneyim:** Tam ekran gökyüzü haritası; başlangıçta kapalı sol menü, saydam/yüzen nesne kartı ve kontroller. Kalıcı topbar/sidebar yoktur; arayüz gri-bordo tonlarındadır. Katalog, görünürlük, takvim ve kişisel kayıtlar haritanın etrafında bütünleşir.

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

### 1.3 Kullanıcının teyit ettiği teknik öncelik

30 Ekim 2026 tarihli yönlendirmeye göre **harita ürünün en önemli ve doğruluğa en duyarlı parçasıdır**. Cihaz konumu/GPS, hassas enlem-boylam ve gözlem bağlamı ürün kapsamında işlenecek; pusula ve keşfi destekleyen araçlar harita deneyimini güçlendirecek.

Lisans ücreti gerektirmeyen açık kaynak seçenekler önceliklidir; gerçek mekânsal veri ihtiyacı oluşursa **PostGIS gibi çözümler değerlendirilebilir**. Bu yön, PostGIS'in seçilmiş veya kurulmuş olduğu anlamına gelmez. Kaynak hassasiyeti ile ölçüm doğruluğu ayrılır; konum izni, özel kayıtlar ve açık paylaşım kuralları korunur. İlk teknik temel ve harita akışının sırası [teknik başlangıç planında](teknik-baslangic.md) izlenir.

Kullanıcının sonraki yönlendirmesiyle PostgreSQL ve Redis altyapısı, C#/.NET 10, Clean Architecture, CQRS ve lisans ücreti gerektirmeyen MediatR sürümü kesinleşti. Türkçe ve İngilizce bütün ürün yüzeyleri için eşit kapsamda zorunludur; terimler ve kısaltmalar açıklamalarıyla saklanıp erişilebilir olacaktır. Ayrıntılar [ADR-0002](adr/0002-moduler-temel-cqrs-ve-lisanslar.md), [yerelleştirme sözleşmesi](yerellestirme-ve-terimler.md) ve [bilimsel veri stratejisindedir](bilimsel-veri-stratejisi.md).

Canlı gökyüzü, gezegen/yıldız/takımyıldız konumları, doğuş-batış-görünürlük hesapları ve basit koordinat saklama PostGIS gerektirmez. Dünya üzerindeki gözlem noktaları, ışık kirliliği ve ileri arazi/engel analizleri ayrı sonraki aşamadır; PostGIS bu ihtiyaçla değerlendirilir.

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
| **Bu gece** | Seçili yerde ne zaman hangi hedefin ufuk üstünde olduğunu öğrenmek | Saat çizelgesi, Güneş batışı/doğuşu, hedefe ve zamana geçiş, pusula yardımı |
| **Takvim** | Ne zaman hangi astronomik olayın olacağını öğrenmek | Ay/yıl, kaynaklı evreler ve hesaplanan olaylar, yerel/UTC, haritaya geçiş |
| **Defterim** | Kişisel astronomi geçmişini yönetmek | Favoriler, notlar, gözlem/anı kayıtları, kayıtlı konumlar |

**Navigasyon kuralı:** “Konumlarım” beşinci ana sekme değildir; haritadaki konum seçiciden ve Defterim içinden erişilir. **Arama** ayrı bir ana menü değil, uygulama genelinde erişilebilen ortak bir işlevdir.

### 3.1 Ana ekran — tam ekran, harita öncelikli

- **Masaüstü:** Harita bütün yüzeyi kaplar. Sol açılır menü varsayılan kapalıdır; arama/konum/zaman/katmanlar yüzer, nesne bilgileri kapatılabilir saydam kartta özetlenir. Kalıcı topbar veya sidebar kullanılmaz.
- **Mobil/PWA:** Aynı tam ekran yüzey ve kapalı menü korunur; kart ve kontroller küçük ekranda üst üste binmeden erişilebilir olmalıdır. Kartın ayrıntıları isteğe bağlı açılır, kendi içinde kaydırılabilir.
- **İlk açılış:** Bu siteye konum izni zaten verilmişse güncel cihaz konumu kullanılır. Yeni izin kullanıcı eylemiyle istenir. İzin/hizmet yokluğunda açıkça **örnek konum** etiketli başlangıç ve manuel koordinat/harita noktası seçimi çalışır; konum beklemek gökyüzünün açılmasını engellemez.
- **Bağlam sürekliliği:** Seçilen konum, tarih/saat, nesne ve harita görünümü arasında gereksiz sıfırlama yapılmaz.
- **Kullanıcı kontrolü:** Haritayı kaydırma/yakınlaştırma, bir hedefe odaklanma, katmanları açma, “Şimdiye dönme” ve konumu değiştirme kolay erişilebilir olmalıdır.

## 4. İşlevsel gereksinimler

### FR-01 — Konum ve yön

- Tarayıcı konum izni veya manuel **enlem-boylam** girme; şehir/ilçe araması ve isteğe bağlı konum adı/yükseklik yardımcı seçeneklerdir. GeoNames yakın yer noktası kesin adres/ilçe sınırı değildir.
- Manuel koordinatta geçerlilik kontrolü; GPS sonucunda mevcutsa doğruluk bilgisi.
- Yüksek doğruluk isteği, metre cinsinden bildirilen belirsizlik ve ölçüm zamanı ayrı tutulur. Haritada nokta seçimi GPS donanımının hassasiyetini artırmış gibi sunulmaz; harici Dünya haritası açık kullanıcı eylemiyle yüklenir.
- Cihazdan alınan veya elle girilen koordinatlar gereksiz yuvarlama ya da sessiz kırpma ile değiştirilmez; kaynak doğruluğu ayrıca gösterilir.
- Konuma göre saat dilimi ve yerel tarih/saat gösterimi.
- Azimut **0–360°**, yükseklik **−90° ila +90°**; kuzey/doğu/güney/batı yönlerinin açıklanması.
- Mobil pusula destekleniyorsa sensörle hizalama; izin veya sensör yoksa manuel yönlendirme.
- Yerel ufuk engelleri, yükseklik (elevation) ve kullanıcı tanımlı balkon/dağ profili sonraki aşamada genişletilebilir.
- Tam konum paylaşımında açık onay; kayıtlı kişisel konumlar varsayılan olarak özel.

### FR-02 — Canlı gökyüzü haritası

- Tarih, saat ve gözlemci koordinatına göre gök cisimlerinin konumları.
- Güneş, Ay, gezegenler, parlak yıldızlar ve temel takımyıldızlar ilk sürümde.
- Seçme, odaklama, kaydırma, yakınlaştırma/uzaklaştırma ve arama üzerinden haritaya geçiş.
- Katmanlar: takımyıldız çizgi/adları, takımyıldız çizimleri, atmosfer, temsili açık arazi, azimutal ızgara, ekvatoral ızgara, derin uzay cisimleri, gece görünümü ve tarayıcı tam ekranı; kolay erişilebilir aç/kapat kontrolleri.
- Başlangıçta **atmosfer, arazi ve derin uzay açık**, diğer katmanlar/gece/tam ekran kapalıdır. Arazi/atmosfer simülasyonu gerçek topografya, hava veya ölçülmüş gözlem koşulu değildir ve göksel hesabı değiştirmez.
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

Kaynaklı gerçek fotoğraf ve kısa Wikipedia açıklaması saydam kartta sunulur; ayrıntılar isteğe bağlı açılır. Fotoğrafın arşiv niteliği, üretici/lisansı ve makale revizyon/kaynağı korunur. Ansiklopedi içeriği hesaplanan konumun veya katalog verisinin yerine geçmez; kaynak hatası ana haritayı engellemez. Güneş/Sun bu akışın ilk tam kaynaklı örneğidir.

### FR-04 — Zaman ve astronomik olaylar

- **Canlı zaman** ve **simülasyon zamanı** her zaman açıkça ayırt edilir.
- Tarih/saat manuel değiştirilebilir; tek işlemle **Şimdiye dön** yapılır.
- Konumun IANA bölgesindeki yerel saat ve GMT ofseti önde, aynı anın UTC karşılığı birlikte gösterilir. Yerel/UTC giriş ayrıdır; dil/konum/saat dilimi değişimi seçili UTC anını değiştirmez. Yaz/kış saati boşluğu reddedilir, tekrarlanan saat için ilk/ikinci oluşum açıkça seçilir. Bölge bulunamadığında veya sınırda birden fazla bölge varsa belirsizlik gizlenmez.
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

Kayıt oluştururken minimum zorunlu alan kullanılır. Gözlemde açıklama ve gerçekten yapılmış gözleme ilişkin kişisel beyan gerekir; bu bağımsız bilimsel doğrulama değildir. Gök cismi, gerçek gözlem zamanı, koordinat ve ileride ekipman eklemek isteğe bağlıdır. Harita/sistem zamanı gerçek gözlem anı olarak otomatik atanmaz; gelecek gözlem reddedilir. Kayıtlı konumun bağımsız kopyası gözlem geçmişini korur; yerin sonraki değişimi geçmişi değiştirmez. Kişisel içerik varsayılan olarak özel olmalıdır. Veri dışa aktarma ve silme olanağı planlanır.

### FR-07 — Anonim kullanım ve hesaplar

| İşlev | Anonim ziyaretçi | Doğrulanmış hesap |
|---|---|---|
| Harita, keşif, katalog, olaylar | Kullanabilir | Kullanabilir |
| Konum ve zaman seçimi | Kullanabilir | Kullanabilir |
| Favoriler, notlar, gözlem kaydı | Kayıt/giriş gerekir; kalıcı kayıt yok | PostgreSQL’de hesaba bağlı kalıcılık |
| Kayıtlı konumlar | Geçici harita konumu kullanılabilir; kişisel saklama yok | PostgreSQL’de özel kayıt, düzenleme ve haritada yeniden kullanım |
| Cihazlar arası senkronizasyon | Yok | Var |
| Veri dışa aktarma | Kalıcı kişisel veri yok | Hesap verilerini açık indirme |

- Ad/soyad/e-posta/şifre ile kayıt, **zorunlu e-posta doğrulaması**, giriş-çıkış, şifre sıfırlama ve temel oturum güvenliği.
- Kişisel kayıt için önce hesap/e-posta doğrulama/giriş gerekir. Aynı hesaptaki favori çoğaltılmaz; not revizyonu uyuşmazsa diğer sürüm ezilmez.
- Tarayıcıya kişisel veri kalıcılaştırılmaz. Kaydedilmemiş açık sayfa taslağı bellektedir; yenileme/çıkış sınırı görünürdür. Hesap kaydı başka girişten sunucudan alınır.
- Menüde oturumsuz giriş/kayıt, oturumlu ad-soyad ve hesap erişimi görünürdür. Eski hesap isimleri uydurulmaz; profil tamamlama sunulur.
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
- Çevrimdışında kişisel yazma yapılmaz; bağlantı gereği açıkça gösterilir. Sunucu onayı olmadan kaydedildi denmez; genel katalog çevrimdışı keşfi ayrı hedeftir.
- Eski hava bilgisinin canlıymış gibi gösterilmemesi.

### FR-10 — Ekipman uyumluluğu (zorunlu değil; ileri aşama)

Dürbün/teleskop bilgisi girmek hiçbir temel ekrana erişim koşulu değildir. İleride kullanıcı isterse büyütme, açıklık ve gerçek görüş alanı gibi değerleri kaydedebilir; **görüş alanı simülasyonu ve ekipmana uygun gözlem açıklamaları** kişiselleştirilebilir. Çıplak göz deneyimi daima tam işlevli kalır.

### FR-11 — Tam Türkçe ve İngilizce deneyim

- Backend yanıtları, frontend UI/UX, menüler, hata/boş durumlar, erişilebilir adlar ve küratörlü açıklamalar Türkçe ve İngilizcede aynı işlev kapsamını sunar. Varsayılan İngilizcedir; açık Türkçe seçimi korunur. İşlem e-postaları K-025 kullanıcı kararıyla her zaman İngilizce gönderilir.
- Dil değişimi seçili konumu, zamanı ve nesneyi kaybettirmez; dil değişmesi astronomik sonucu değiştirmez.
- Tarih/sayı biçimleri seçili dile uygundur. API sayıları kültürden bağımsız JSON sayıları, anlar UTC/ofsetli standart biçimdedir; saat dilimi dil ile eşitlenmez.
- Eksik çeviri sessizce diğer dilde gösterilerek tamamlanmış sayılmaz. Yeni diller eklenebilir; ilk teslimat tr/en eşli ilerler.
- Kullanıcı notları ve kaynakların özgün özel adları kendiliğinden çevrilmez; kullanıcı içeriği ile ürün çevirileri ayrılır.

### FR-12 — Erişilebilir terimler ve kısaltmalar

- Bilimsel terimin/teknik kısaltmanın sabit kimliği, açılımı, sade Türkçe/İngilizce tanımı, alternatif adları, kategorisi ve kaynakları saklanır.
- Sözlük giriş yapmadan aranabilir; nesne kartları ve ilgili kontrollerden açıklamaya ulaşılır. Açıklama yalnızca fareyle üzerine gelmeye bağlı olmaz; klavye, dokunma ve ekran okuyucu kullanımı gözetilir.
- Azimut, yükseklik, efemeris ve UTC gibi keşif terimleriyle FITS/ADQL gibi veri terimleri aynı tanım düzenini kullanabilir; kullanıcıya gereksiz teknik ayrıntı dayatılmaz.
- Backend ve harita kartından erişilen iki dilli sözlük penceresi hazırdır (39 terim). Ayrı sözlük sayfası/derin bağlantılar, ekran okuyucu ve bütün ürün yüzeyleri için kabul açık kalır.

## 5. Temel kullanıcı yolculukları

| ID | Yolculuk | Tamamlanma ölçütü |
|---|---|---|
| **UJ-01** | İlk ziyaret → örnek harita → GPS veya koordinat → ilk gök cismi | Hesap ve ekipman gerekmeden keşif yapılır |
| **UJ-02** | Arama/haritadan nesne seç → bilgi kartı → konumu/zamanı incele | Harita bağlamı korunur; görünmeyen nesne de açıklanır |
| **UJ-03** | Şimdi → başka tarih/saat → hareketi incele → Şimdiye dön | Simülasyon zamanı asla gerçek zamanla karıştırılmaz |
| **UJ-04** | Kaydetme isteği → hızlı kayıt/giriş → e-posta doğrulama → hesaba kaydet | Anonim kalıcı veri oluşmaz; hesap kaydı özel kalır, revizyonla korunur |
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
| İnternet kesildi | Desteklenen katalog/hesaplama sürer; kişisel kayıt için bağlantı gerekir |
| İleri tarih seçildi | Astronomik hesaplar yapılır; hava tahmini kapsamadığı tarih için verilmez |
| Kullanıcı konumu değiştirir | Seçili zaman ve hedef mümkün olduğunca korunur; konuma bağlı veriler yeniden hesaplanır |
| Tam koordinat bağlantıyla paylaşılacak | Gizlilik uyarısı ve isteğe bağlı yaklaşık konum paylaşımı sunulur |

## 7. Teknoloji ve mantıksal modüller

**Kararlaştırılan yön:** Next.js + TypeScript frontend, **PWA**, C#/.NET 10 ve ASP.NET Core tabanlı **modüler monolit**, **Clean Architecture**, **CQRS**, **MediatR 12.5.0**, **PostgreSQL** ve **Redis**. Kimlik temeli JWT access token, döndürülen refresh token ve e-posta doğrulamasını içerir. Python gerektiği veri işleme/bilimsel analiz işlerinde kullanılabilir. PostGIS çekirdek astronomi bağımlılığı değildir; gerçek mekânsal analiz ihtiyacıyla sonraki aşamada ele alınır. Sürüm/lisans ve kod sınırları ADR-0002'de kayıtlıdır.

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

### 7.1 İlk hesap adaptörü ve dış kaynak değerlendirme listesi

İlk sınırlı hesap adaptörü Astronomy Engine 2.1.19 [ADR-0003](adr/0003-ilk-astronomi-adaptoru-ve-dogruluk-sinirlari.md); ilk Canvas 2D harita/HYG 4.1 yıldız/d3-celestial takımyıldız verisi [ADR-0004](adr/0004-ilk-harita-ve-parlak-katalog.md) ile uygulandı. Bağımsız örnek doğrulama, kutup yön sınırı ve teknik ilk tarih aralığı açıktır; bütün olay modelleri, geniş katalog veya gerçek cihaz kabulü tamamlanmış değildir. [İzlenebilirlik tablosu](teslimat-izlenebilirligi.md) bütün FR/UJ/AC kalanlarını tutar. Diğer araç ve veriler nihai seçilmiş bağımlılıklar değildir:

- **Astronomy Engine:** İlk Güneş Sistemi hesap adaptöründe seçildi; daha geniş hedef/zaman/ufuk ve olay doğrulaması sürüyor.
- **NASA JPL Horizons:** Hassas efemerislerle doğrulama/karşılaştırma.
- **OpenNGC ve diğer astronomik kataloglar:** Derin uzay nesnelerinin kimlik ve nitelikleri.
- **Open-Meteo veya eşdeğer kaynaklar:** İsteğe bağlı hava koşulları.
- **Mevcut açık kaynak gökyüzü motorları / görselleştirme kütüphaneleri:** Harita çekirdeği için yeniden kullanım değerlendirmesi.
- **Astropy, Skyfield, Stellarium Web Engine, Aladin Lite:** Hesap/doğrulama, planetaryum çizimi ve astronomik görüntüleme rolleri ayrı adaylardır; hepsini kurma kararı değildir. [Bilimsel veri stratejisi](bilimsel-veri-stratejisi.md).

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
| **Yerelleştirme** | FR-11: bütün ürün yüzeylerinde tam Türkçe/İngilizce işlev eşliği; zaman, sayı ve saat dilimi tutarlılığı |
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
- Doğrulanmış hesaba bağlı favoriler, notlar, gözlem kayıtları ve kayıtlı konumlar.
- Kişisel kayıtta üyelik zorunluluğu ve hesaplar arası erişim ayrımı.
- Kurulabilir PWA, temel önbellek/çevrimdışı durumlar, kaynak/güncellik bilgileri.

### P1 — Astronomi derinliği

- Geniş Messier/NGC ve yıldız katalogları; gelişmiş arama/filtreleme.
- Astronomik olay takviminin kapsamlı hâli ve gözlem zaman pencereleri.
- Hava koşulları, Ay ışığı, ışık kirliliği ve gelişmiş uygunluk değerlendirmesi.
- Yerel ufuk engelleri, balkon ve arazi profilleri.
- Daha ayrıntılı bilimsel içerik, harita katmanları ve gözlem geçmişi analizi.
- Daha güçlü çevrimdışı genel katalog; kişisel kayıtlara çevrimiçi hesap erişimi.

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
- **AC-07:** Anonim kişisel kayıt reddedilir; doğrulanmış hesap kayıtlarına başka girişten erişilir, başka hesap erişemez ve çakışan düzenleme veri ezmez.
- **AC-08:** E-posta doğrulaması olmadan doğrulanmış hesap işlevleri aktifleşmiyor.
- **AC-09:** Hassas konum ve kişisel notlar kullanıcının izni dışında yayımlanmıyor.
- **AC-10:** Harici veri kaynağı bozulduğunda harita mümkünse çalışıyor; son veri zamanı anlaşılıyor.
- **AC-11:** Mobilde pusula/sensör desteği olmadığında harita manuel kontrol ediliyor.
- **AC-12:** PWA çevrimdışı modunda desteklenen işlevler ve güncellik sınırları açıkça belirtiliyor.
- **AC-13:** Her teslim edilen kullanıcı akışı Türkçe ve İngilizcede aynı işlevlerle tamamlanıyor; UI/erişilebilir metinler, API hata/başarı mesajları ve e-postalar birlikte doğrulanıyor. Backend testleri frontend tamamlandı anlamına gelmiyor.
- **AC-14:** Kullanıcı terim/kısaltmanın sade açıklamasına hesap açmadan iki dilde erişebiliyor; ilgili ekrandan klavye ve dokunmayla ulaşabiliyor, kaynak bağlantısını görebiliyor.

## 11. Başlıca riskler ve açık kararlar

**Riskler:** Harita motorunun geliştirme maliyeti; farklı cihazlarda sensör doğruluğu; büyük kataloglarda performans; üçüncü taraf API kotası/lisansları; hassas koordinatların gizliliği; kişisel sunucu kayıtlarında eşzamanlı düzenleme çakışmaları; hava koşullarını kesin astronomik görünürlük gibi sunma riski.

**Henüz kesinleştirilmemiş kararlar:**

- Açık kaynak **kod lisansı** ve projede kullanılan veri/kütüphanelerin lisans uyumu.
- Gökyüzü görselleştirmesinde mevcut motoru kullanma, uyarlama veya ayrı katman geliştirme kararı.
- Astronomi kataloglarının kesin kapsamı, kalite kontrolleri ve güncelleme periyotları.
- Hesap kaydı kota/kalıcı silme/içe aktarma ve veritabanı yedek-geri yükleme kabulü; anonim saklama K-024 ile kapsam dışı.
- İlk sürümde konum yüksekliği ve gerçek yerel ufuk engellerinin kapsamı.
- yorungez.com alan adının satın alınması, marka uygunluğu araştırması ve dağıtım/işletim maliyeti.

Bu maddeler **alınmış kararlar gibi sunulmamalı**; ADR veya ürün kararıyla kesinleştirilmelidir.

## 12. Bu belgede yapılan temizlik ve güncelleme

- **1.10 — 1 Kasım 2026:** K-027–028/ADR-0012–0013; hesap menüsü/ad-soyad, servis/çevrimdışı hata ayrımı, ortak yerel başlatıcı ve yalnız genel veriye ait sürümlü PWA/çevrimdışı açılış. 125 .NET/44 istemci testi; bütün kimlikler ve açık fiziksel/üretim sınırları korunur.
- **1.9 — 1 Kasım 2026:** K-026/ADR-0011; hesapta ayrı gözlem/kayıtlı konum, açık gerçek zaman girişi, geçmişi koruyan konum kopyası; 52 terim. 120 .NET/38 istemci testi ve üretim derlemesi. Bütün kimlikler ve kalan kapsam korunur.
- **1.7 — 31 Ekim 2026:** K-024/ADR-0010; anonim kişisel kalıcılık yerine hesap zorunlu PostgreSQL, TR/EN hesap akışları ve panel geri dön düğmesi. UJ-04/AC-07 anlamı güncellendi; kimlikler ve diğer hedefler korundu.
- **1.6 — 31 Ekim 2026:** K-022–023/ADR-0008–0009; yalnız gece çizelgesi, ortak özel kontroller ve sensörsüz gözlem; yerel favori/not ilk dilimi ve UX-02 hesap/çevrimdışı devamı. Önceki backend/bilimsel kaynaklar, FR/UJ/AC ve sürüm hedefleri korunur.

- **1.5 — 31 Ekim 2026:** K-021/ADR-0007 ile Bugün-Bu gece çizelgesi ve Takvim, hedef/saat/UTC navigasyonu, pusula yardımı, saydam ufuk altı arazi, 330° zoom ve yerel yer adı/manuel yükseklik. Keşfet menü düğmesi kaldırıldı; atlas kapsamı ve bütün FR/UJ/AC/P0/P1/P2 korundu. 51 eşli terim, 2623 olay ve 1781 bağımsız USNO evre kontrolü.

- **1.4.1 — 31 Ekim 2026:** Kullanıcı paleti #3C3F43/#9EA1A6/#8B2333/#C9B6A6/#F7F1E6, sol menüde native dil listesi; kaynaklı gerçek fotoğraf çevre/daha doğal yıldız ve atmosfer. Mevcut pusula basamağının düz telefon/ayrı izin/açık gerçek yön hizalaması/süre-temizlik yazılımı, 43 eşli terim ve fiziksel cihaz protokolü. Yerel gerçek topoğrafya/kalibre fotometri/otomatik AR iddiası yok; kapsam ve kimlikler korunur.
- **1.4 — 31 Ekim 2026:** Kullanıcı düzeltmeleri K-019/ADR-0005: tam ekran/kapalı sol menü/gri-bordo saydam kart, varsayılan üç katman ve diğer anahtarlar, kaynaklı çizimler/DSO/Wikipedia fotoğrafı, izinli GPS/OSM, konuma göre IANA/GMT/UTC/DST ve süre sınırlı açılış. 39 eşli terim; önceki FR/UJ/AC ve P0/P1/P2 hedefleri korunur. Uygulananlar ve gerçek cihaz/bilimsel kabul sınırları TECH-04 kaydındadır.
- **1.3.2 — 31 Ekim 2026:** TECH-02B/03 ilk Canvas/HYG/d3 harita/arama/kart/terim akışı tr/en uygulandı; ADR-0004 ve sayısal/tarayıcı kanıtı eklendi. FR/UJ/AC kimlikleri, kişisel veri/PWA/P1/P2 ve açık kabul sınırları korunur.
- **1.3.1 — 31 Ekim 2026:** TECH-02A ilk hesap adaptörü, örnek referans doğrulaması ve açık model sınırları kaydedildi; bütün FR/UJ/AC kimlikleri/sürüm kapsamı korundu. TECH-02B çizim/katalog, frontend/cihaz ve diğer açık işler izlenebilirlik tablosunda; ilk hesap bütün harita veya doğuş-batış teslimatı değildir.
- **1.3 — 31 Ekim 2026:** Kullanıcının tr/en tam kapsam, açıklamalı terimler, .NET 10/Clean Architecture/CQRS/MediatR/PostgreSQL/Redis ve JWT/e-posta doğrulama kararları kaydedildi. FR-11–12 ve AC-13–14 eklendi; mevcut kimlikler ve MVP-0/P0/P1/P2 sınırları korundu. PostGIS ile astronomi hesaplarının rolleri ayrıldı. Uygulanan backend temeli bütün ürünün tamamlandığı anlamına gelmez.
- **1.2 — 30 Ekim 2026:** Kullanıcının harita önceliği, hassas konum verilerini işleme kapsamı, pusula/yardımcı araçlar ve lisans ücreti gerektirmeyen altyapı yönü kaydedildi. PostGIS koşullu değerlendirme olarak korundu; mevcut FR/UJ/AC kimlikleri ve MVP-0/P0/P1/P2 sınırları değişmedi.
- **1.1 — 30 Ekim 2026:** Kullanıcının seçtiği **yorungez** adı ve planlanan **yorungez.com** alan adı kaydedildi. İşlevsel kapsam, sürüm öncelikleri ve gereksinim kimlikleri korundu.

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

**Kısa ürün pusulası:** yorungez'in görevi kullanıcıya bir astronomi paneli göstermek değil; **seçtiği konum ve zamanda gökyüzünü keşfetme, anlama ve kişisel deneyimini kaydetme olanağı vermek**. Her yeni karar bu cümleye göre değerlendirilmelidir.

- **1.8 — 31 Ekim 2026:** K-025; gerçek Gmail özel ortam yapılandırması, İngilizce markalı e-posta ve varsayılan İngilizce. Türkçe açık seçim/UI/API kapsamı ve bilimsel/veri hedefleri korunur.
