# yorungez — Alan sözlüğü ve iş kuralları

**Güncel TECH-07 / K-027–028 (1 Kasım 2026):** Menüde giriş/kayıt veya doğrulanmış oturumun ad-soyadı; kayıt için ad/soyad/e-posta/parola. Servis hatası ve çevrimdışı durum ayrıldı, ortak yerel başlatıcı eklendi. Genel katalog/terim/takvim için hash doğrulamalı PWA paketi ve yeniden açılış uygulandı; kişisel kayıt/oturum/koordinat cache'e girmez. 125 .NET/44 istemci testi; fiziksel cihaz/üretim backup kabulü açık. [Uygulama ve kanıt](hesap-menusu-ve-cevrimdisi-gokyuzu.md), [hesap ADR](adr/0012-hesap-menusu-ve-ad-soyad.md), [PWA ADR](adr/0013-genel-gokyuzu-pwa-ve-cevrimdisi-paket.md).

**Güncel K-026 / TECH-06 (1 Kasım 2026):** Hesap envanterinde not/favori yanında ayrı gözlem ve kayıtlı konum uygulandı. Gözlem açıklama + kişisel beyan ister; gerçek zaman/nesne/konum isteğe bağlıdır, simülasyon zamanı kendiliğinden bağlanmaz. Konum kopyası geçmişi korur; haritada kullanım an/mod/hedef/kamerayı korur. 120 .NET + 38 istemci testi ve üretim derlemesi geçti; 52 tr/en terim/cache .7. [Uygulama ve sınırlar](gozlem-kayitlari-ve-kayitli-konumlar.md), [ADR-0011](adr/0011-gozlem-kaydi-ve-kayitli-konumlar.md). Fiziksel cihaz, genel katalog PWA/offline ve üretim backup kabulü açık; kişisel tarayıcı kalıcılığı yoktur.

**Güncel K-024 / TECH-05:** Kişisel kayıt için doğrulanmış hesap zorunlu; anonim/IndexedDB kişisel kalıcılığı kaldırıldı. Not ve favoriler kullanıcıya bağlı PostgreSQL modülünde; TR/EN kayıt/giriş/doğrulama/sıfırlama ve panel geri dönüşü bağlıdır. [Uygulama ve sınırlar](hesap-ve-sunucu-defteri.md), [ADR-0010](adr/0010-hesap-zorunlu-defter-ve-sunucu-kayitlari.md). Aşağıdaki eski paket kayıtları kendi aşamasının tarihsel kanıtıdır.


**Önceki UX-02A:** İlk yerel favori/not modeli ve revizyon/deletedAtUtc seçildi: [ADR-0009](adr/0009-yerel-defter-ve-kayipsiz-duzenleme.md). Not sistem zamanı gözlem zamanı değildir; bağlar ayrı opsiyonel snapshot, her yeni notta kapalı. Gözlem/kayıtlı yer ve hesap aktarımı açık. [Akış ve alanlar](kisisel-kayit-hesap-cevrimdisi-akislari.md).

**TECH-04C:** Geçici gözlemci bağlamına isteğe bağlı `placeName` eklendi; kayıtlı kişisel konum değildir. Yer adı noktası idari sınır/GPS doğruluğu değildir. Çizelge standart 0 m/üst kenar modelidir; harita merkez/0° ve gerçek gözlenebilirlikten ayrı. Takvim olayı küresel UTC anı + hedef + kaynak taşır. [Güncel sözleşme](gozlem-cizelgesi-ve-takvim.md).

**Tarih:** 30 Ekim 2026  
**Durum:** Kaynak gereksinimlerden çıkarılmış ilk taslak. Bu belge fiziksel veritabanı şeması, API sözleşmesi veya tamamlanmış domain tasarımı değildir.  
**Kaynak:** [Ürün gereksinimleri](urun-gereksinimleri.md), FR-01–10 ve §5–7.

## Temel kavramlar

| Terim | Tanım / sınır | Dayanak |
|---|---|---|
| Gök cismi | Atlas ve haritada aynı tekil kimlikle temsil edilen astronomik nesne. Türkçe/İngilizce adlar ve katalog kimlikleri bu kimliğe bağlanır. | FR-02–03 |
| Katalog bilgisi | Kimlik, sınıf, fiziksel nitelik ve bilimsel açıklama gibi kaynaklı içerik. Her nesneye her alan uygulanmaz. | FR-03, FR-08 |
| Gözlemci konumu | Hesaplamada kullanılan enlem/boylam ve varsa ek konum bilgisi. Örnek, manuel veya GPS kaynağı ayırt edilir. | FR-01 |
| GPS doğruluğu | Konum sonucuyla sağlanabiliyorsa gösterilen doğruluk bilgisi; koordinatın kendisiyle aynı veri değildir. | FR-01 |
| Seçili an | Astronomik hesabın değerlendirildiği tarih/saat. Yerel gösterim ve saat dilimi bu anla tutarlı olmalıdır. | FR-01, FR-04 |
| Zaman modu | Canlı zaman veya kullanıcının seçtiği simülasyon zamanı. Mod açıkça görünürdür. | FR-04 |
| Harita görünümü | Yön, ölçek ve katmanlar gibi görsel durum. Konum veya hedef değişiminde gereksiz yere sıfırlanmaz. | FR-02, UJ-02–03 |
| Keşif bağlamı | Seçili konum, an, zaman modu, hedef ve harita görünümünün birlikte oluşturduğu geçici deneyim durumu. | §5 bağlamsal durum |
| Azimut / yükseklik | Yatay koordinat bileşenleri. Azimut 0–360°, yükseklik −90° ila +90° aralığında sunulur. | FR-01 |
| Geometrik görünürlük | Hedefin seçili konum ve zamanda yerel ufka göre konumu. Ufuk/kırılma varsayımları ayrıca tanımlanır. | FR-05, A-007 |
| Gözlem koşulları | Ay ışığı, astronomik karanlık, atmosfer ve bulutluluk gibi uygunluğu etkileyen etkenler. Veri eksikliği bilinmiyor durumudur. | FR-05 |
| Algılanabilirlik | Hedefin çıplak göz veya isteğe bağlı ekipmanla pratikte seçilebilme beklentisi. Kesin gözlem garantisi değildir. | FR-05, FR-10 |
| Zaman olayı / gözlem aralığı | Doğuş, batış veya uygun gözlem penceresi gibi konum ve zamana bağlı sonuç. Hesaplanamama nedeni açıkça sunulur. | FR-03–05 |
| Astronomik olay | Ay evresi, tutulma veya kavuşum gibi hesaplanan/kataloglanan göksel olay. Kullanıcının bu olayı gözlemesi ayrı kayıttır. | FR-04, FR-06 |
| Favori | Kullanıcının tekrar dönmek istediği gök cismi veya atlas içeriğiyle ilişkisi. | FR-06 |
| Gözlem kaydı | Gerçekten yapılmış bir gözlemin kişisel kaydı. Nesne, gözlem zamanı, koordinat ve ekipman bağlamak isteğe bağlıdır. | FR-06 |
| Kayıtlı konum | Yeniden kullanılabilen koordinat ve isteğe bağlı ad/açıklama. Hesaplama için seçili konumla aynı yaşam döngüsüne sahip değildir. | FR-06 |
| Not / anı | Bir nesne, tarih, konum veya kişisel deneyime isteğe bağlı bağlanabilen serbest metin. | FR-06 |
| Kişisel hesap kaydı | Yalnız doğrulanmış oturumla, PostgreSQL’de sahibine bağlı kayıt. Anonim tarayıcı kalıcılığı yoktur. | FR-06–07 |
| Doğrulanmış hesap | E-posta doğrulaması tamamlanmış hesap. Hesaba bağlı kalıcılık ve cihazlar arası senkronizasyon bu bağlamda sağlanır. | FR-07 |
| Veri aktarımı / senkronizasyon | Doğrulanmış hesap aynı sunucu kayıtlarına cihazlar arasında erişir; anonim aktarım K-024 ile kaldırıldı. | FR-07, FR-09 |
| Veri kökeni ve güncelliği | Kaynak/sürüm, hesaplanma ve son başarılı yenilenme zamanları; güncel, gecikmiş veya erişilemiyor durumu. | FR-08–09 |

## Temel ilişkiler

- Harita seçimi ve arama sonucu aynı gök cismi kimliğini ve bilgi kartını kullanır.
- Göksel konum hesapları gök cismi + gözlemci konumu + seçili an üzerinden değerlendirilir. Katalog açıklaması ve kişisel not bununla aynı veri türü değildir.
- Kayıtlı konum keşif bağlamında seçilebilir; seçili zaman ve hedef mümkün olduğunca korunur.
- Bir astronomik olaya kişisel gözlem kaydı bağlanabilir; olayın oluşması kullanıcının gözlem yaptığı anlamına gelmez.
- Favori, gözlem kaydı ve not/anı gök cismiyle ilişkilendirilebilir; kaynak gereksinimde isteğe bağlı olan bağlar zorunlu hale getirilmez.
- Her kişisel kayıt oturum sahibine bağlıdır. Anonim kalıcı veri ve otomatik aktarım yoktur; değişen hesap eski taslağı devralmaz.

## Korunacak iş kuralları

| ID | Kural | Gereksinim / kabul kriteri |
|---|---|---|
| IK-01 | Temel harita ve atlas keşfi hesap veya ekipman gerektirmez. | FR-02–03, FR-07, AC-01 |
| IK-02 | Konum izni reddi keşfi engellemez; manuel koordinat alternatifi vardır. | FR-01, AC-02 |
| IK-03 | Konum/anda değişiklik konuma bağlı sonuçları yeniden hesaplatır; harita ve bilgi kartı aynı bağlamı kullanır. | FR-01–04, AC-03–04 |
| IK-04 | Simülasyon canlı zaman gibi sunulmaz; şimdiye dönüş tek eylemdir. | FR-04, AC-05 |
| IK-05 | Ufkun altındaki hedef geometrik olarak görünür etiketlenmez. Koşullar ve algılanabilirlik ayrı açıklanır. | FR-05, AC-06 |
| IK-06 | Hava veya katalog alanı eksikse değer uydurulmaz. Eski hava verisi canlıymış gibi gösterilmez. | FR-03, FR-05, FR-08–09, AC-10, AC-12 |
| IK-07 | Kişisel kayıtlar ve hassas koordinatlar varsayılan olarak özeldir; tam konum paylaşımı açık onay gerektirir. | FR-01, FR-06–07, AC-09 |
| IK-08 | Kişisel kayıt için hesap gerekir; aynı favori çoğaltılmaz, not çakışmaları veri kaybıyla çözülmez. | FR-07, AC-07 |
| IK-09 | E-posta doğrulaması tamamlanmadan doğrulanmış hesap işlevleri etkinleşmez. | FR-07, AC-08 |
| IK-10 | Sensör yokluğu veya izin verilmemesi manuel harita kullanımını engellemez. | FR-01–02, AC-11 |
| IK-11 | Çevrimdışında desteklenen işlevler ve güncellik sınırları anlaşılırdır; sunucudan onay alınmadan kişisel kayıt başarısı gösterilmez. | FR-09, AC-12 |
| IK-12 | Gözlem kaydındaki isteğe bağlı bağlar, kayıt oluşturmanın ön koşuluna dönüştürülmez. | FR-06, UJ-05 |

## Henüz modellenmesi gerekenler

Konum/zaman/görünürlük ve kişisel kayıt davranışları [bağlam ve sınır durumları matrisinde](baglam-ve-sinir-durumlari.md) ayrıntılandırıldı. Aşağıdaki teknik ve kalıcı model seçimleri açık kalıyor:

- ADR-0011 minimum gözlem (açıklama+beyan), tek opsiyonel hedef/an/konum kopyası ve kayıtlı konum (koordinat) modelini seçti. İleri ilişki çoklukları/ekipman/olay, kalıcı silme ve içe aktarma açık.
- ADR-0011: gerçek gözlem zamanı ayrı nullable alandır; sistem zamanı/simülasyon otomatik atanmaz. Gelecek gözlem reddedilir, kişisel beyan bilimsel doğrulama değildir.
- Konum/yerel saat sözleşmesi ADR-0005 ile uygulandı: UTC anı korunur, IANA/yerel/GMT ayrı gösterimdir; boş saat reddi ve çift saat için oluşum seçimi vardır. Veri bakımı/cihaz kabulü açıktır.
- Hiç doğmayan/batmayan hedefler ve hesap aralığı dışındaki tarihlerin motor tarafından nasıl bildirildiği; kullanıcı davranışı matris içinde tanımlı.
- İçerik kaynaklarının sürümlenmesi, değişen katalog kimlikleri ve ad eşlemeleri.
- Hesap saklama kotaları, kalıcı temizleme/içe aktarma ve üretim yedek/geri yükleme kabulü.

Bu konular çözülmeden fiziksel şema veya kalıcı API sözleşmesi kesinleşmiş sayılmaz. Açık başlıklar [karar kaydına](kararlar.md) ve sonraki işlere [yol haritasından](yol-haritasi.md) bağlanır.

Bu geliştirici alan sözlüğü kullanıcıya sunulan terim kataloğundan ayrıdır. Güncel 52 kaynaklı tr/en terim, anonim API ve ilk kart/sözlük penceresi [yerelleştirme ve terimler sözleşmesinde](yerellestirme-ve-terimler.md); hesap çerçevesi/birimleri ADR-0003/0004 içinde açıklanır. İlk klavye/ESC denemesi yapıldı; ayrı sözlük/derin bağlantı/ekran okuyucu kabulü açık.
