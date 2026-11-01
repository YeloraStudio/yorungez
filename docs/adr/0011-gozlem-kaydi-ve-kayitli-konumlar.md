# ADR-0011 — Kişisel gözlem kaydı ve kayıtlı konum

**Durum:** Uygulandı; üretim/cihaz kabulü kısmi. **Tarih:** 1 Kasım 2026. **Karar:** K-026 / TECH-06 / PRD 1.9.

**İz:** FR-01/FR-04/FR-06–07/FR-09/FR-11–12; UJ-03–05/UJ-07; AC-03/AC-05/AC-07–09/AC-12–14; SN-P01–06; A-006/A-013.

## Bağlam

[Hesap zorunlu Defterim](0010-hesap-zorunlu-defter-ve-sunucu-kayitlari.md) not/favori kalıcılığını sağladı. Kullanıcının onayladığı sonraki dilim, nottan ayrı gerçek gözlem ve yeniden kullanılabilen konumdur. Bir simülasyon, astronomik olay veya sistem zaman damgası kullanıcının gözlem yaptığına kanıt sayılamaz. Konum düzenlemek geçmiş kayıtları değiştirmemelidir.

## Karar

Notebook modülünün hesabın sahibine kapsamlanan PostgreSQL tablosunda dört ayrı, sonradan sessizce değiştirilemeyen tür vardır: `note`, `favorite`, `observation`, `place`. Identity oturumu sahibi belirler; başka modül tablosuna doğrudan erişim yoktur. PostGIS basit koordinat saklamanın ön koşulu değildir.

| Tür | Minimum içerik | İsteğe bağlı bağlar |
|---|---|---|
| Not/anı | Boş olmayan, en çok 8000 karakter metin | Bir nesne, harita anı ve konum kopyası |
| Favori | Hedef kimliği; hesapta aynı hedef çoğaltılmaz | Önceki açık bağ seçimi sözleşmesi korunur |
| Gözlem | Boş olmayan açıklama ve gerçekten yapılmış gözleme ilişkin kişisel beyan | En fazla bir nesne, kullanıcı tarafından girilen gerçek gözlem anı ve bir konum kopyası |
| Kayıtlı konum | Geçerli enlem/boylam | Ad, açıklama ve biliniyorsa elipsoidal yükseklik |

`ObservationConfirmed` yalnız **kişisel beyan** anlamındadır; bağımsız bilimsel doğrulama, görüntü tespiti veya gözlenebilirlik sertifikası değildir. Nesne, zaman ve koordinat gözlem oluşturmanın zorunlu alanları yapılmaz. Ekipman ve astronomik olaya doğrudan bağ bu dilimde uygulanmadı; sonraki kapsam korunur.

### Zamanın anlamı

`CreatedAtUtc/UpdatedAtUtc` sunucu kayıt zamanıdır. `InstantUtc` nottaki isteğe bağlı simülasyon/harita anıdır. Gözlem bunu kabul etmez; ayrı `ObservedAtUtc` kullanır. Yeni gerçek gözlem tarihi/saat/dakikası boş başlar, saat dilimi UTC olarak açıkça gösterilir. Harita veya oluşturma zamanı buraya kopyalanmaz. Zaman bilinmiyorsa `null` ve “Kaydedilmedi” gösterilir.

IANA bölgesi seçilirse mevcut Temporal sözleşmesi uygulanır: var olmayan yerel saat reddedilir, çift saatte kullanıcı oluşumu seçer; UTC saklanır. Gelecekteki gözlem hem UI hem sunucuda reddedilir. Sistem saati doğruluğu işletim sorumluluğudur. Kişisel tarih 0001–9999 veri tipi sınırları içinde, gelecek olmamak koşuluyla tutulabilir; UI en geç seçilen bölgedeki bugünü açar. Bu, astronomi motorunun 2000–2035 teknik hesap aralığını genişletmez. Örneğin 1988 tarihli anı saklanabilir; o tarih için gökyüzü hesabı vaat edilmez.

Gözlem düzenlemede değiştirilmeyen zamanın saniyeleri korunur; yeni UI girişi dakika hassasiyetindedir. Tarih/saat taslağı liste, panel ve dil geçişinde açık sayfa belleğinde tutulur. Yenileme sonrası kalıcılığı yoktur.

### Konumun anlamı

Enlem −90…+90°, boylam −180…+180°, varsa yükseklik −500…10000 m sınırındadır. Ondalık virgül/nokta kabul edilir, saklama öncesi gereksiz yuvarlama yapılmaz. Yeni kayıt formu boş başlar. Harita koordinatını kopyalama ayrı açık eylemdir; haritada bir konum seçmek onu hesaba kaydetmez.

Ad/açıklama isteğe bağlıdır. Yükseklik bilinmiyorsa `null` kalır; deniz seviyesinden rakım elipsoidal yükseklikmiş gibi atanmaz. Uygun datum/jeoit dönüşümü yapılmıyor. Yeni iki dilli `ellipsoidal-height` terimi [NOAA açıklamasına](https://geodesy.noaa.gov/GEOID/GPSonBM96/gpsbms.html) dayanır; katalog 52 terim/cache `2026-10-31.7` olur. Standart doğuş-batışın mevcut 0 m referansı değişmez.

Gözleme bağlanan konum bağımsız değer kopyasıdır; canlı foreign key değildir. Kayıtlı yerin adı/koordinatı değişse, çöp kutusuna taşınsa veya geri yüklense gözlemdeki eski değerler değişmez. GPS doğruluk/ölçüm zamanı bu kopyaya ölçüm kanıtı gibi taşınmaz. Kayıtlı konumu haritada kullanmak kaynağı `manual` yapar, bekleyen GPS sonucunu geçersiz kılar; seçili UTC anı, canlı/simülasyon modu, nesne ve kamera korunur. Yerel saat gösterimi yeni koordinatın IANA bölgesine göre çözülür.

### Kalıcılık ve uyumluluk

Mevcut doğrulanmış hesap/BFF HttpOnly oturumu, beklenen hesap başlığı, no-store, revizyon kontrolü ve geri alınabilir çöp kutusu dört türe de uygulanır. Başka hesap aynı id'ye sahip olsa bile erişemez. Başarılı commit gelmeden kayıt başarısı gösterilmez. Çakışan taslak korunur; yeni kopya veya sunucu listesini inceleme yolu vardır. Yazma sürerken form değişikliği kapatılarak geç gelen yanıtın yeni metni silmesi önlenir.

Migration `20261031205237_ObservationsAndSavedPlaces` yalnız nullable gözlem anı ve varsayılan `false` beyan alanı ekler; eski not/favoriyi dönüştürmez. Şema değişikliği yerel geliştirme DB'sine uygulandı; EF model/migration farkı yoktur. Dışa aktarma açık kullanıcı indirmesidir, format sürümü 2 ve dört türü içerir. JSON uygulamanın deposu değildir; importer henüz yoktur. Kişisel veri tarayıcı kalıcı deposuna, service worker'a veya offline kuyruğa yazılmaz.

## Sonuçlar ve açık sınırlar

İki dil, İngilizce varsayılan ve İngilizce markalı e-posta kararı korunur. Minimum gözlem ve konum ilişkisi A-013 için seçilmiştir; çoklu nesne/ekipman/olay bağı, kota, kalıcı silme, içe aktarma ve üretim yedek/geri yükleme kabulü açıktır. Fiziksel GPS/pusula, ekran okuyucu, gerçek mobil performans ve genel katalog PWA/offline ayrı işlerdir. Bu teslimat bütün MVP-0/P0 kabulünün tamamlandığı anlamına gelmez.

[Uygulama ve doğrulama kaydı](../gozlem-kayitlari-ve-kayitli-konumlar.md), [UX-02](../kisisel-kayit-hesap-cevrimdisi-akislari.md), [izlenebilirlik](../teslimat-izlenebilirligi.md).
