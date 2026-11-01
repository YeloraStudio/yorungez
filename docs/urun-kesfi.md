# yorungez — Ürün keşfi

**Tarih:** 30 Ekim 2026  
**Durum:** İlk taslak; kaynaklara dayalı masa başı incelemesi yapıldı, kullanıcı araştırması ve kullanılabilirlik testi henüz yapılmadı.  
**Kapsam kaynağı:** [Ürün gereksinimleri](urun-gereksinimleri.md), özellikle §1–3 ve §9–10.

## Değer önerisi

yorungez, kullanıcının seçtiği yer ve zamanda gökyüzündeki nesneleri bulmasına, ne gördüğünü anlamasına ve kişisel deneyimini kaydetmesine yardımcı olur. Harita, katalog, zaman kontrolü ve kişisel defter tek gözlem bağlamında çalışır.

Ürün sorusu: **“Bulunduğum noktadan gökyüzünde ne var, nerede, ne zaman görülebilir ve neden?”**

Bu deneyim hesap veya ekipman bilgisi girmeden başlar. Kullanıcının bilgi düzeyi arttığında aynı deneyim kataloglar, olaylar ve ileride isteğe bağlı ekipman araçlarıyla derinleşir.

## Hedef kullanıcılar ve görevleri

| Kullanıcı | Somut ihtiyaç | Başarı göstergesi | Kaynak |
|---|---|---|---|
| Meraklı / ekipmansız ziyaretçi | Baktığı parlak nesneyi tanımak | Konum ve zamanı seçip harita veya aramadan aynı bilgi kartına ulaşır | UJ-01–02, AC-01–04 |
| Yeni amatör gözlemci | Bir hedefi ne zaman ve hangi yönde arayacağını anlamak | Yön/yükseklik ile ufuk durumunu ve hesaplanabiliyorsa uygun zamanı ayırt eder | FR-01, FR-03–05, AC-06 |
| Öğrenci / öğretmen | Gökyüzünün zamanla değişimini keşfetmek | Simülasyonu kullanır ve tek eylemle canlı zamana döner | UJ-03, AC-03, AC-05 |
| Kişisel kayıt tutan gözlemci | Favori, not ve gözlemlerine tekrar ulaşmak | Anonim kayıtlarını saklar; hesap seçerse açık onayla kayıpsız taşır | UJ-04–05, AC-07–09 |
| Mobil / bağlantısı değişken kullanıcı | Sensör veya ağ olmadığında desteklenen işleri sürdürmek | Manuel yönlendirme ve önbellekli işlevlerle devam eder; veri güncelliğini anlar | UJ-06–07, AC-10–12 |

Bunlar başlangıç belgesindeki hedef kitlenin görev tanımlarıdır; yapılmış görüşme veya doğrulanmış pazar büyüklüğü verisi değildir.

## Benzer ürünlerden ilk bulgular

İnceleme tarihi 30 Ekim 2026'dır. Bulgular aşağıdaki birincil ürün sayfalarıyla sınırlıdır; uygulamalarda cihaz testi yapılmadı. Sürüm, paket ve platform farkları bu incelemede ayrıntılı karşılaştırılmadı.

| Ürün | Kaynakta doğrulanan yaklaşım | yorungez için çıkarım / incelenecek soru |
|---|---|---|
| **Stellarium Web** | Tarayıcıda çalışan, açık kaynak Stellarium web projesine dayanan çevrimiçi planetaryum olarak tanımlanıyor. | Haritaya doğrudan giriş yaklaşımı için referans. Hedef seçimi ve kontrol yoğunluğu gerçek kullanımda incelenecek. Bu bulgu motor seçimi veya lisans uygunluğu kararı oluşturmaz. |
| **SkySafari** | Resmî sayfa gökyüzü haritası, gözlem planlama araçları, olay takvimi, ekipmana göre görüş alanları ve LiveSky ile gözlem verilerinin senkronizasyonunu anlatıyor. | Gelişmiş gözlem akışları için referans. yorungez'de ekipman seçenekleri P2'de ve isteğe bağlı kalacak; temel keşif bunlara bağlanmayacak. |
| **timeanddate Night Sky** | Yardım sayfası konum/koordinat seçimini, tarih-saat kontrolünü, haritadan veya aramadan nesne seçimini, nesne hareketini ve doğuş/batış bilgilerini açıklıyor. | Konum-zaman-nesne sürekliliği ve görünmeme nedenlerinin açıklanması için referans. Mobil ve masaüstü kontrol farkları kullanıcı görevleriyle incelenecek. |

Kaynaklar: [Stellarium Labs — Stellarium Web](https://stellarium-labs.com/stellarium-web/), [SkySafari resmî ürün sayfası](https://skysafariastronomy.com/), [timeanddate Night Sky kullanım kılavuzu](https://www.timeanddate.com/astronomy/night/help).

**Konumlandırma hipotezi:** yorungez'in odağı; kolay başlayan harita deneyimini, kaynaklı bilimsel açıklamayı ve özel kişisel astronomi defterini tutarlı konum/zaman bağlamında birleştirmek. Bu bir ürün yönüdür; rakiplerde aynı özelliklerin bulunmadığı veya pazarda tek olduğu iddiası değildir. Karşılaştırma yeni özellikleri otomatik olarak kapsamımıza eklemez.

## Kapsam ve öncelik

| Aşama | Amaç | Dahil olan ana deneyim |
|---|---|---|
| **MVP-0** | Harita çekirdeğinin teknik ve UX doğrulaması | Bir konum ve seçili zaman; temel nesne arama/seçme, bilgi kartı, mobil/masaüstü etkileşim, canlı/simülasyon ayrımı |
| **P0** | İlk herkese açık kullanılabilir sürüm | Temel harita/atlas/olay bilgileri, anonim yerel kayıtlar, doğrulanmış hesap ve senkronizasyon, PWA ve tanımlı temel çevrimdışı durumlar |
| **P1** | Astronomi derinliği | Daha geniş katalog ve takvim, gözlem pencereleri, hava/ışık kirliliği, yerel ufuk ve gelişmiş çevrimdışı veri |
| **P2** | İsteğe bağlı uzmanlaşma | Ekipman profilleri, görüş alanı simülasyonu, gelişmiş koordinatlar ve ileri planlama |

Kesin ayrıntılar ve sınırlar gereksinimlerin §9 bölümündedir. Sürüm sıralaması tarih taahhüdü değildir.

Sosyal akış, forum, ekipman pazaryeri, reklam/alışveriş karşılaştırması, zorunlu AI asistanı ve astronomi dışı genel günlük kapsam dışıdır. Yeni bir fikir gökyüzünü bulma, görme, anlama veya kaydetme amacına katkısıyla değerlendirilir.

## Başarı ölçümü taslağı

Henüz ölçüm sonucu yoktur. Aşağıdaki tablo değerlendirme yöntemini önerir; geçme eşikleri belirtilmeyen alanlar araştırmayla netleştirilecek.

| Boyut | Ölçüm / doğrulama yöntemi | İz |
|---|---|---|
| Keşfe başlayabilme | Hesapsız ilk ziyaret → konum seçimi → ilk nesne görevinin tamamlanması; izin reddi senaryosu ayrıca denenir | UJ-01, AC-01–02 |
| Nesneye ulaşma | Aynı hedefin aramadan ve haritadan bulunması; bilgi kartı ve bağlamın karşılaştırılması | UJ-02, AC-04 |
| Zamanı anlama | Kullanıcının canlı/simülasyon modunu doğru tanıması; şimdiye dönüş görevi | UJ-03, AC-05 |
| Bilimsel doğruluk | Sabit konum/zaman senaryolarında bağımsız referansla karşılaştırma; toleranslar özellik bazında tanımlanacak | AC-03, AC-06, A-003, A-009 |
| Kayıt bütünlüğü ve gizlilik | Yerel kayıt → doğrulanmış hesap → açık onaylı aktarım; tekrar ve çatışma senaryoları, izinsiz paylaşım kontrolü | UJ-04–05, AC-07–09 |
| Hata ve çevrimdışı süreklilik | Sensör yokluğu, harici kaynak hatası, ağ kesintisi ve yeniden bağlantı görevleri | UJ-06–07, AC-10–12 |
| Performans ve erişilebilirlik | Kaynak belgedeki LCP ≤ 2,5 sn, INP ≤ 200 ms, CLS ≤ 0,1 ve WCAG 2.2 AA hedefleri; harita için ayrıca cihaz/işlem bütçesi belirlenecek | Gereksinimler §8, A-009 |

Ölçüm tasarımı hassas koordinat veya kişisel notları gereksiz yere toplamamalı. Kullanım analitiğinin araçları ve veri toplama politikası henüz seçilmedi.

## Sonraki doğrulama

[Kullanıcı görevleri ve değerlendirme planı](kullanici-gorevleri.md) bu çalışmanın yürütme taslağıdır. Sekiz kart ve gözlem formu hazırdır; gerçek katılımcı veya başarı sonucu henüz yoktur. [UX akışları](ux-akislari.md) ile [sınır durumları](baglam-ve-sinir-durumlari.md) masa başı incelemeye hazırdır.

1. Temsilî kullanıcı görevleriyle ilk nesneyi bulma, zamanı değiştirme ve görünürlük açıklamasını anlama akışlarını değerlendirmek.
2. Benzer ürünlerde aynı görevleri masaüstü ve mobilde incelemek; kaynak bulgularıyla kullanım gözlemlerini ayırmak.
3. Başarı ölçütlerinin gerekli sayısal eşiklerini ve test ortamını belirlemek; ölçülmemiş değerleri gerçekleşmiş sonuç gibi sunmamak.
4. [Alan sözlüğünü](alan-sozlugu.md) iş kurallarıyla genişletmek; [açık kararları](kararlar.md) UX ve teknik değerlendirmeye taşımak.

Kullanıcı görüşmesi, ölçüm veya test yapılmadan bu aşama tamamlandı olarak işaretlenmez. İlerleme ve somut işler [yol haritasında](yol-haritasi.md) izlenir.
