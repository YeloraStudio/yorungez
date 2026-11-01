# yorungez — Keşif bağlamı ve sınır durumları

**Güncel TECH-07 / K-027–028 (1 Kasım 2026):** Menüde giriş/kayıt veya doğrulanmış oturumun ad-soyadı; kayıt için ad/soyad/e-posta/parola. Servis hatası ve çevrimdışı durum ayrıldı, ortak yerel başlatıcı eklendi. Genel katalog/terim/takvim için hash doğrulamalı PWA paketi ve yeniden açılış uygulandı; kişisel kayıt/oturum/koordinat cache'e girmez. 125 .NET/44 istemci testi; fiziksel cihaz/üretim backup kabulü açık. [Uygulama ve kanıt](hesap-menusu-ve-cevrimdisi-gokyuzu.md), [hesap ADR](adr/0012-hesap-menusu-ve-ad-soyad.md), [PWA ADR](adr/0013-genel-gokyuzu-pwa-ve-cevrimdisi-paket.md).

**Güncel K-026 / TECH-06 (1 Kasım 2026):** Hesap envanterinde not/favori yanında ayrı gözlem ve kayıtlı konum uygulandı. Gözlem açıklama + kişisel beyan ister; gerçek zaman/nesne/konum isteğe bağlıdır, simülasyon zamanı kendiliğinden bağlanmaz. Konum kopyası geçmişi korur; haritada kullanım an/mod/hedef/kamerayı korur. 120 .NET + 38 istemci testi ve üretim derlemesi geçti; 52 tr/en terim/cache .7. [Uygulama ve sınırlar](gozlem-kayitlari-ve-kayitli-konumlar.md), [ADR-0011](adr/0011-gozlem-kaydi-ve-kayitli-konumlar.md). Fiziksel cihaz, genel katalog PWA/offline ve üretim backup kabulü açık; kişisel tarayıcı kalıcılığı yoktur.

**Güncel K-024 / TECH-05:** Kişisel kayıt için doğrulanmış hesap zorunlu; anonim/IndexedDB kişisel kalıcılığı kaldırıldı. Not ve favoriler kullanıcıya bağlı PostgreSQL modülünde; TR/EN kayıt/giriş/doğrulama/sıfırlama ve panel geri dönüşü bağlıdır. [Uygulama ve sınırlar](hesap-ve-sunucu-defteri.md), [ADR-0010](adr/0010-hesap-zorunlu-defter-ve-sunucu-kayitlari.md). Aşağıdaki eski paket kayıtları kendi aşamasının tarihsel kanıtıdır.


**Önceki TECH-04D / UX-02A:** Gece kesişimi/polar gündüz-gece ve sensörsüz brief; SN-P01/04/05/06 için yerel favori/not, opsiyonel snapshot, revizyon, hata/taslak/JSON ve geri alınabilir çöp kutusu [uygulandı](ortak-bilesenler-ve-sensorsuz-gozlem.md). SN-P02/03 hesap/aktarım ve SN-D tam offline/sürüm cache işleri [UX-02](kisisel-kayit-hesap-cevrimdisi-akislari.md) içinde açık. Gerçek kota/cihaz/ekran okuyucu kabulü değildir.

**TECH-04C:** SN-G01 için fotoğrafı saydamlaştırarak ufuk altı nesne keşfi; negatif yükseklik/uyarı korunur. Aşağı bakışta da saydamlık; 330°/nadir ve antipod sınırı. SN-Z01/09: çizelge/takvim aynı UTC + hedefle simülasyona geçer; yerel gün/ay IANA ile hesaplanır, DST 23/25 saat testli. SN-K02/06: yerel şehir/ilçe/manuel ad ve koordinat; yakın nokta kesin adres değildir. [Kanıt/sınırlar](gozlem-cizelgesi-ve-takvim.md).

**TECH-04B sensör durumu:** Düz pusula için ayrı izin/ret/destek/8 s veri yokluğu-eski veri/gerçek yönle hizalama/iptal-temizlik yazılımı eklendi. [Protokol](cihaz-konum-pusula-dogrulamasi.md) fiziksel cihazda henüz yürütülmedi. Ana harita/UTC bağlamı korunur; göreli yön kuzey diye sunulmaz.

**31 Ekim uygulama notu:** Süre sınırlı katalog/Worker kurtarma, kaynak kartı hata/yeniden deneme, izinli tek GPS ölçümü/manuel geç yanıt koruması ve yerel/UTC sınırları [TECH-04 kaydında](tam-ekran-harita-gelistirmesi.md) doğrulandı. Aşağıdaki 35 durumun tamamı uçtan uca kabul edilmiş değildir; kişisel kayıt/offline/pusula ve gerçek cihaz işleri sürer.

**Tarih:** 30 Ekim 2026  
**Durum:** Domain/UX davranış taslağı; kişisel kayıt şeması ve açık UX politikaları kesinleşmedi. İlk sınırlı hesap sözleşmesi [ADR-0003](adr/0003-ilk-astronomi-adaptoru-ve-dogruluk-sinirlari.md) ile uygulandı; bu matrisin bütün UI davranışları henüz uygulanmadı.
**İş:** DOM-01. Kaynaklar: [alan sözlüğü](alan-sozlugu.md), [gereksinimler](urun-gereksinimleri.md), [açık kararlar](kararlar.md).

## Keşif bağlamının sınırı

| Bileşen | Anlamı | Değişiklikte korunacak kural |
|---|---|---|
| Konum | Enlem/boylam, örnek/manuel/GPS kaynağı, varsa doğruluk; saat dilimi çözümlemesi | Örnek konum gerçek kullanıcı konumu gibi sunulmaz; gizli paylaşım yapılmaz |
| Seçili an | Astronomik hesabın değerlendirildiği an; yerel tarih/saat ve saat dilimiyle tutarlı gösterim | Yerel saat metni tek başına hesap girdisi sayılmaz; yorumlanamayan giriş sessizce başka bir ana çevrilmez |
| Zaman modu | Canlı veya simülasyon | Simülasyona geçiş ve şimdiye dönüş görünürdür |
| Seçili nesne | Atlas ve haritanın kullandığı tekil kimlik | Arama ve harita aynı kimliğe ulaşır; konum/zaman değişikliği seçimi gereksiz yere silmez |
| Harita görünümü | Yön, ölçek, katmanlar ve odak | Konum seçme gibi işlemler görünümü gereksiz sıfırlamaz; açık “hedefe odaklan” eylemi görünümü değiştirebilir |
| Hesap/veri sonucu | Hangi konum/an/nesne ve varsayımla üretildiği bilinen çıktı | Yeni bağlamın yanında eski sonuç etiketsiz kalmaz; geciken eski yanıt yeni bağlamı ezmez |

Bu alanlar mantıksal bir modeldir; veri tipleri, kalıcı tablo veya istemci durum kütüphanesi seçimi değildir.

## Değişikliklerin uygulanması

1. Konum veya zaman düzenleyicisi bir giriş taslağı tutar. Kullanıcı düzenlerken harita son geçerli bağlamı korur.
2. Geçerlilik kontrolü alanın yanında açıklanır. İptal mevcut bağlamı değiştirmez; hatalı giriş otomatik düzeltilmiş gibi uygulanmaz.
3. Geçerli seçim uygulandığında harita, kart ve konuma/zamana bağlı olaylar aynı yeni bağlamı kullanır. Yeni sonuç yoksa hesap bekleniyor veya hesaplanamadı durumu gösterilir.
4. Önceki sonuç korunacaksa önceki bağlama ait olduğu açıkça belirtilir. Sonuç için gerek duyulan bağlam bilgisi uygulama sözleşmesinde taşınmalıdır; teknik mekanizma ARCH-01'de seçilecek.
5. Düzenleyici kapanınca kullanıcıyı açan kontrole geri döndürme ve klavye odağını koruma UX hedefidir. Ekranın kaydırılması bağlamı değiştirmez.

Konum değişiminde **aynı UTC anını koruyup yerel gösterimi yeni IANA bölgesine göre değiştirme** politikası ADR-0005 ile seçildi ve uygulandı. Aynı duvar saatini başka bölgeye taşımak farklı bir an seçer; bu sessizce yapılmaz. Yerel/UTC giriş ayrı, DST boş saat reddi/çift saat oluşum seçimi vardır; çözülemeyen bölge UTC/elle seçimle görünür. Veri bakımı ve fiziksel cihaz kabulü açıktır.

## Konum durumları

| ID | Durum | Beklenen davranış / korunacak bağlam | İz |
|---|---|---|---|
| **SN-K01** | İlk açılış | Önceden izin verilmişse taze yüksek doğruluk konumu; aksi halde etiketli örnek konum ve izin istemeden keşif. Yeni izin kullanıcı eylemiyle. Örnek noktanın seçimi A-011'de açık. | FR-01–02; AC-01 |
| **SN-K02** | GPS reddi / alınamaması | Manuel koordinat seçeneği kullanılabilir; örnek veya önceki konum ve mevcut zaman/hedef korunur. | FR-01; AC-02 |
| **SN-K03** | Boş, sayı olmayan veya aralık dışı giriş | Uygulama yok; alan hatası. Enlem −90…+90, boylam −180…+180 kontrol edilir; sessiz kırpma yapılmaz. | FR-01; AC-02–03 |
| **SN-K04** | Sıfır veya negatif koordinat | `0` ve negatif sayılar geçerli aralıktaysa kabul edilebilir; boş/bilinmiyor anlamına getirilmez. | FR-01; AC-03 |
| **SN-K05** | Türkçe ondalık virgül / diğer biçim | Kullanıcıya kabul edilen biçim gösterilir; ayrıştırma belirsizse uygulanmaz. Virgül/nokta giriş sözleşmesi UX/yerelleştirmede netleştirilecek. | FR-01; gereksinimler §8 |
| **SN-K06** | Düşük GPS doğruluğu | Sağlanan doğruluk görünür; hassasiyet garanti edilmez. Kullanıcı manuel konuma geçebilir. | FR-01 |
| **SN-K07** | Konum değişirken hesap devam ediyor | Hedef ve zaman korunur; önceki sonucun yeni konuma ait sanılması engellenir. | FR-01–03; AC-03–04 |
| **SN-K08** | Sensör yok / izin yok / sapma | Manuel yönlendirme çalışır; sensör durumu konum doğruluğuyla karıştırılmaz. | FR-01–02; AC-11 |

## Zaman durumları

| ID | Durum | Beklenen davranış / açık konu | İz |
|---|---|---|---|
| **SN-Z01** | Tarih/saat değiştirildi | Simülasyon açıkça görünür; konum ve hedef korunur, aynı bağlama bağlı hesaplar güncellenir. | FR-04; AC-03, AC-05 |
| **SN-Z02** | Şimdiye dön | Tek eylem canlı zamanı seçer; konum, nesne ve gereksiz değişmemesi gereken görünüm korunur. | FR-04; AC-05 |
| **SN-Z03** | Geçersiz tarih/saat veya iptal | Son geçerli bağlam korunur; hata/iptal sessiz yeni tarih üretmez. | FR-04; AC-03 |
| **SN-Z04** | Saat dilimi çözülemedi | Yerel saatin hangi ana karşılık geldiği tahmin edilmez. Geçerli mevcut an korunabilir; sorun açıklanır. ADR-0005: yerel kapsamlı geo-tz/all poligonları; hata/çoklu bölge görünür UTC/elle seçim. | FR-01, FR-04; AC-03 |
| **SN-Z05** | Yerel saat birden fazla ana karşılık geliyor | Seçenekler saat dilimi/ofset bilgisiyle ayırt edilebilir olmalı; otomatik ve görünmez seçim yapılmamalı. Ayrıntılı giriş politikası A-014'tür. | FR-01, FR-04; AC-03 |
| **SN-Z06** | Yerel saat geçiş nedeniyle mevcut değil | Giriş hatası açıklanır; kullanıcı geçerli bir saat seçer. Kendiliğinden başka saate kaydırılmaz. | FR-01, FR-04; AC-03 |
| **SN-Z07** | Motorun desteklediği tarih aralığı dışı | Hesaplanamadı nedeni gösterilir; katalog kaydı kullanılabilir. Tarih aralığı A-003'te doğrulanır. | FR-03–04, FR-08; AC-10 |
| **SN-Z08** | Uzak gelecek / geçmiş | Astronomik hesap destekleniyorsa devam eder; kapsanmayan tarih için hava tahmini üretilmez. | FR-04–05, FR-08 |
| **SN-Z09** | Konumla saat dilimi değişiyor | Korunacak an/yerel saat ayrımı açık olmalı; uygulanan aynı-an yaklaşımı ADR-0005/A-014'tür. | FR-01, FR-04; AC-03 |

## Görünürlük ve sonuç durumları

31 Ekim teknik eki: İlk adaptör geometrik merkez/0° ufuk ve ayrı standart kırılma modelini açıkça bildirir. İki kutup yön istisnası nedeniyle abs(enlem)>=89 için azimut `null` ve nedenli durumdur; koşullar bilinmiyor kalır. TECH-04C standart doğuş-batışı ayrı 0 m referans modeliyle ekler; geniş kutup/tarih/rakım/ufuk doğrulaması açıktır. Harita/kart eski yanıt koruması yazılımda uygulanmıştır. Bu ilk teknik sınırlar genel ürün kapsamını daraltmaz; [izlenebilirlik](teslimat-izlenebilirligi.md).

| ID | Durum | Kullanıcıya gösterilecek bilgi | İz |
|---|---|---|---|
| **SN-G01** | Hedef ufkun altında | Geometrik durum “Ufkun altında”; hesaplanabiliyorsa sonraki uygun aralık. Atlas içeriği açık kalır; hedef arazinin arkasındaysa/aşağı bakışta fotoğraf saydamlaşır, geometrik etiket değişmez. | FR-03, FR-05; AC-06 |
| **SN-G02** | Hedef ufkun üstünde, koşul verisi yok | Geometrik durum ayrı; koşullar “Bilinmiyor”; kesin görülebilir sonucu yok. | FR-05, FR-08; AC-06, AC-10 |
| **SN-G03** | Hedef ufka çok yakın / model varsayımları etkili | Kesin gözlem garantisi verilmez; kullanılan ufuk/kırılma varsayımı açıklanabilir. Eşik ve tolerans A-007/A-009'da belirlenir. | FR-05; AC-06 |
| **SN-G04** | Hedef aranan aralıkta doğmuyor / batmıyor | Sıfır saat veya hatalı doğuş/batış yerine nedenli özel durum; desteklenen aralık belirtilir. | FR-03–05 |
| **SN-G05** | Hava verisi gecikmiş veya erişilemiyor | Hava güncelliği ve son başarılı yenilenme varsa gösterilir; astronomik sonuçlar mümkünse sürer. P1 kaynağı temel haritaya erişim şartı olmaz. | FR-05, FR-08; AC-10 |
| **SN-G06** | Hesap başarısız / yeni bağlam sonucu bekleniyor | Geometrik durum da bilinmiyor olabilir. Eski değer yeni konum/zamanın hesabı gibi sunulmaz. | FR-08; AC-03, AC-10 |
| **SN-G07** | Katalog alanı veya kaynağı eksik | Alan anlamlıysa bilinmiyor; nesneye uygulanmayan alan zorla doldurulmaz. Kaynak belirsizliği gizlenmez. | FR-03, FR-08 |
| **SN-G08** | Birden fazla hesap isteği farklı sırada dönüyor | Görünen seçili bağlamla uyuşmayan eski sonuç güncel kartı/haritayı değiştirmez. | FR-02–04, FR-08; AC-03–04 |

## Kişisel kayıt ve veri yaşam döngüsü

Bu bölüm P0 davranış modelidir; MVP-0'a hesap veya senkronizasyon eklemez. Ayrıntılı kişisel ekranlar UX-02'de hazırlanacak.

| Kavram | İlişki / zorunluluk sınırı | Oluşturma, değiştirme ve silmede korunacak kural |
|---|---|---|
| Favori | Seçilen bir gök cismi veya atlas içeriğiyle bağ kurar | Aynı doğrulanmış hesabın aynı hedefi çoğaltılmaz; kaldırmak katalog nesnesini silmez |
| Gözlem kaydı | Nesne, gerçekleşen gözlem zamanı, konum ve ileride ekipman isteğe bağlıdır | Sistem oluşturma zamanı gerçekleşen gözlem zamanı gibi doldurulmaz; hangi bağların kaydedileceği görünürdür |
| Not/anı | Serbest metin; nesne/tarih/konum bağı isteğe bağlı | Düzenlemede bağlar sessizce eklenmez; saklama ve aktarım özel varsayımı korur |
| Kayıtlı konum | Yeniden kullanılabilen bir koordinat kaydıdır; ad/açıklama isteğe bağlı | Kaydı kaldırmak mevcut bir gözlemin geçmiş konumunu sessizce değiştirmemeli; ADR-0011 bağımsız konum kopyası seçildi/uygulandı |
| Astronomik olay bağlantısı | Kişisel gözlem bir olaya bağlanabilir; astronomik olayın kendisi kişisel kayıt değildir | Kişisel kaydı silmek göksel olayı veya başkalarının kayıtlarını etkilemez |

ADR-0011: favori hedef kimliği, diğer türler UUID; gözlem için açıklama+kişisel beyan, tek isteğe bağlı nesne/gerçek an/konum kopyası ve konum için koordinat seçildi/uygulandı. Gelecek gözlem reddedilir; oluşturma zamanı gözlem anı değildir. Çoklu hedef/ekipman/olay bağı sonraki kapsamdır.

| ID | Durum | Beklenen davranış / açık sınır | İz |
|---|---|---|---|
| **SN-P01** | Anonim kaydetme isteği | Hızlı kayıt/giriş açılır; kişisel kalıcı veri oluşturulmaz. Harita keşfi açık kalır. | FR-06–07; AC-01 |
| **SN-P02** | E-posta henüz doğrulanmadı | Doğrulanmış hesap işlevleri açılmaz; anonim keşfe geri dönüş mümkün kalır. | FR-07; AC-08 |
| **SN-P03** | Giriş iptal veya hesap değişti | Anonim kayıt yapılmaz; eski hesabın taslağı/verisi yeni hesaba yazılmaz. Eski deney verileri sessiz aktarılmaz/silinmez. | FR-07; AC-07, AC-09 |
| **SN-P04** | Aynı favori / çakışan not | Favori çoğaltılmaz; notun bir sürümü sessizce kaybedilmez. Ayrıntılı çatışma ve yeniden deneme A-006'dadır. | FR-07; AC-07 |
| **SN-P05** | Bağlı nesne/konum kaydı değişti veya kaldırıldı | Gözlem geçmişinin anlamı korunur; kaynak kaydı eksikliği açıklanabilir. ADR-0011: bağımsız değer kopyası, yerin düzenleme/çöp/geri yüklemesi gözlemi değiştirmez. | FR-06; AC-07, AC-09 |
| **SN-P06** | Sunucu kaydı doğrulanamıyor / bağlantı kesildi | Kaydedildi başarısı gösterilmez; kullanıcı metnini kaybetmeden yeniden deneme veya uygun dışa aktarma yolu tasarlanır. Kota/çatışma sözleşmesi A-006/A-013'tedir. | FR-06–07, FR-09; AC-07, AC-12 |

## Çevrimdışı ve kaynak sürümü

| ID | Durum | Beklenen davranış | İz |
|---|---|---|---|
| **SN-D01** | İlk açılışta ağ yok ve önbellek yok | Henüz mevcut olmayan arayüz/veri çalışıyormuş gibi sunulmaz; tekrar bağlantı yolu açıklanır. | FR-09; AC-12 |
| **SN-D02** | Önceden yüklenmiş çekirdek var | Mevcut yerel hesap/katalog işlevleri sürer; eksik paket sınırı görünürdür. | FR-08–09; AC-10, AC-12 |
| **SN-D03** | Bağlantı geri geldi | Kayıplı veya çift kayıt üreten sessiz tekrar yapılmaz; liste sunucudan yenilenir; belirsiz işlem kontrol edilmeden yinelenmez. Kişisel offline kuyruk yoktur. | FR-07, FR-09; AC-07, AC-12 |
| **SN-D04** | Katalog veya hesap verisi sürümü değişti | Kaynak sürümü izlenir; eski nesne kimliği bağı ve kişisel kayıt anlamı korunur. Teknik eşleme/göç politikası A-005/A-006'dadır. | FR-03, FR-08–09; AC-07, AC-10 |

## Teknik araştırmaya taşınacak sorular

- **A-002/A-003:** Motor seçili bağlam değişimlerini, tarih aralığını, hesaplanamama nedenlerini ve ufuk/kırılma varsayımlarını nasıl bildiriyor?
- **A-005:** Nesne kimliği, Türkçe/İngilizce adlar ve katalog sürümü değiştiğinde kalıcı bağlar nasıl korunuyor?
- **A-006/A-013:** Sunucu kalıcılık başarısı, sahiplik, not çatışması, silme ve dışa aktarma hangi sözleşmeyle doğrulanacak?
- **A-009:** Özellik bazlı doğruluk toleransları, cihaz bütçesi ve referans veri kümesi neler olacak?
- **A-014:** Saat sözleşmesi ADR-0005 ile uygulandı; IANA/ofset verisinin bakımı, siyasi bölge değişiklikleri ve fiziksel cihaz kabulü izlenecek. Teknik model tarih aralığı ADR-0003 ile sınırlıdır.

Bu matrisin hazırlanması, senaryoların uygulanıp geçtiği anlamına gelmez. Doğrulama görevleri [değerlendirme planına](kullanici-gorevleri.md), ekran davranışları [UX taslağına](ux-akislari.md) bağlanır.
