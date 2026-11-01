# yorungez — Kullanıcı görevleri ve değerlendirme planı

**Güncel K-024 / TECH-05:** Kişisel kayıt için doğrulanmış hesap zorunlu; anonim/IndexedDB kişisel kalıcılığı kaldırıldı. Not ve favoriler kullanıcıya bağlı PostgreSQL modülünde; TR/EN kayıt/giriş/doğrulama/sıfırlama ve panel geri dönüşü bağlıdır. [Uygulama ve sınırlar](hesap-ve-sunucu-defteri.md), [ADR-0010](adr/0010-hesap-zorunlu-defter-ve-sunucu-kayitlari.md). Aşağıdaki eski paket kayıtları kendi aşamasının tarihsel kanıtıdır.


**Önceki UX-02A çalışma notu:** KG-07/08 için ilk yerel favori/not/revizyon/JSON ve açık konum bağlama yüzeyi hazır. [UX-02 akışları](kisisel-kayit-hesap-cevrimdisi-akislari.md). Geliştirici tarayıcı kontrolü kullanıcı araştırması değildir; aşağıdaki oturum sonuçları hâlâ boş.

**Tarih:** 30 Ekim 2026  
**Durum:** Yürütülmeye hazır ilk araştırma taslağı. Katılımcıyla değerlendirme yapılmadı; sonuç ve başarı oranı yok.  
**İş:** DISC-03. Kaynaklar: [ürün gereksinimleri](urun-gereksinimleri.md), [ürün keşfi](urun-kesfi.md), [UX akışları](ux-akislari.md).

## Amaç ve yöntem

İlk kullanıcının bir hedefi bulabilmesini, konum/zaman bağlamını anlayabilmesini ve görünürlük bilgisini doğru yorumlamasını değerlendireceğiz. Harita doğruluğu ayrıca bağımsız astronomi referanslarıyla doğrulanacak; kullanıcı görevinin tamamlanması hesap doğruluğunu kanıtlamaz.

İlk değerlendirme wireframe üzerinde bir akış incelemesi olabilir. Çalışan prototip gerektiğinde aşağıdaki kanıtlar ayrıca toplanır. Wireframe'de astronomik konum, GPS, sensör, kayıt ve senkronizasyon işlevleri çalışmış kabul edilmez.

Katılımcı profilleri: ekipmansız meraklı, yeni amatör gözlemci, eğitim amaçlı kullanıcı ve mobil kullanıcı. Bunlar davet edilmiş veya görüşülmüş kişiler değildir. Gereksiz kimlik ve hassas konum bilgisi toplanmadan anonim oturum koduyla kayıt tutulur.

## Görev kartları

Görev metni kullanıcıya amacı anlatır; hangi menü veya düğmeye basacağını söylemez. Gözlemci, tamamlanmayı aşağıdaki davranıştan değerlendirir.

| ID / kapsam | Kullanıcıya verilecek görev | Başlangıç / önkoşul | Beklenen davranış ve kanıt | İz |
|---|---|---|---|---|
| **KG-01 · MVP-0** | “Bu uygulamayla seçtiğin bir yerden gökyüzündeki bir nesneyi tanı.” | İlk ziyaret, hesap ve ekipman yok; örnek konum etiketli | Keşfe giriş engeli yok; örnek konumu kendi konumu sanıp sanmadığı ve ilk bilgi kartına ulaşma yolu kaydedilir | UJ-01; AC-01; FR-01–03 |
| **KG-02 · MVP-0** | “Konum izni vermeden başka bir gözlem yerinden devam et.” | Konum isteği reddedilmiş; test için verilen açıkça temsili koordinat | Manuel giriş bulunur, hatalı değer düzeltilebilir, geçerli konum uygulanır; zaman/hedef gereksiz sıfırlanmaz | UJ-01; AC-02–03; FR-01 |
| **KG-03 · MVP-0** | “Bir nesneyi adıyla bul, sonra aynı nesneye haritadan ulaş.” | Önceden seçilmiş konum ve zaman; katalogda bulunan örnek hedef | Aynı nesne kimliği/kart; konum ve zaman sürekliliği. Çalışan prototipte Türkçe/İngilizce ad ve katalog kimliği aramaları da denenir | UJ-02; AC-04; FR-02–03 |
| **KG-04 · MVP-0** | “Başka bir tarihte gökyüzünü incele, ardından güncel zamana geri dön.” | Canlı mod, bilinen bir hedef seçili | Simülasyon etiketi fark edilir; kullanıcı gösterilen anın ne olduğunu anlatabilir; tek eylemle şimdiye döner, konum/hedef korunur | UJ-03; AC-03, AC-05; FR-04 |
| **KG-05 · MVP-0 / P1** | “Hedefin ufkun üzerinde olduğunu biliyorsun. Bu bilgi onu görebileceğin anlamına geliyor mu?” | İki ayrı temsili durum: ufuk altı; ufuk üstü fakat hava verisi yok | Ufuk durumu, koşullar ve algılanabilirlik birbirinden ayrılır; bilinmeyen hava için kesin sonuç çıkarılmaz. Hava kaynağının gerçek entegrasyonu P1'dir | UJ-02; AC-06, AC-10; FR-05, FR-08 |
| **KG-06 · MVP-0** | “Telefonun pusulası çalışmıyor. Bir hedefi bul ve ayrıntılarını incele.” | Mobil görünüm; sensör kullanılamıyor | Manuel yönlendirme, hedef seçimi ve alt panel kullanılır; haritaya dönüş bulunabilir. Gerçek sensör ve dokunma davranışı cihazda ayrıca denenir | UJ-06; AC-11; FR-01–02 |
| **KG-07 · P0** | “Bir not saklamak için hesap oluştur/doğrula/giriş yap; diğer girişten kaydını aç.” | Anonim kaydetme kapısı; doğrulanmamış/doğrulanmış hesap ve başka hesap senaryoları | Ekipman/nesne/konum bağları zorunlu olmaz; doğrulama sınırı anlaşılır; anonim kalıcılık yoktur; özel kayıt başka girişten bulunur, başka hesapta görünmez | UJ-04–05; AC-07–09; FR-06–07 |
| **KG-08 · P0** | “Ağ bağlantısı kesildiğinde daha önce yüklenen genel içeriğe dön; notun için bağlantı gereğini ve sunucu kaydını kontrol et.” | Önceden yüklenmiş arayüz/katalog; ağ kapalı ve sonra açık | Desteklenen işlevlerle devam edilir; kayıt ve senkronizasyon durumu anlaşılır; eski dış veri canlı sanılmaz. Kalıcılık ve çatışma gerçek uygulamada doğrulanır | UJ-07; AC-10, AC-12; FR-08–09 |

Bu kartların tümü MVP-0 iş listesi değildir. KG-07–08 P0 hazırlığıdır; P1 hava entegrasyonu KG-05'in temel görünürlük açıklamasından ayrılır.

## Gözlem formu

Her görev için aşağıdaki alanlar doldurulur. Başlangıçta alanlar boş bırakılır; örnek kullanıcı sonucu yazılmaz.

| Alan | Kayıt biçimi |
|---|---|
| Oturum / tarih | Anonim kod; kullanılan belge veya prototip sürümü |
| Ortam | Masaüstü/mobil; tarayıcı ve cihaz sınıfı; klavye/dokunma; çevrimiçi/çevrimdışı senaryo |
| Görev / başlangıç | KG kimliği; konum kaynağı, zaman modu ve seçili hedefin temsili durumu |
| Sonuç | Yardımsız tamamladı / yardımla tamamladı / tamamlayamadı / bu araçta yürütülemedi |
| Süre | Başlama ve bitiş; uzun duraklamanın nedeni. Ölçülmediyse boş. |
| Gözlem | Kullanıcının yaptığı eylem ve ilgili ekran; gözlemcinin yorumu ayrı alana |
| Anlama sorusu | “Şu an hangi konum ve zaman için bakıyorsun?”, “Bu görünürlük bilgisi neyi söylüyor?” |
| Sorun / etki | Görevi engelledi / yanlış anlamaya yol açtı / ek çaba gerektirdi; somut olay açıklaması |
| Gereksinim / takip | FR/UJ/AC kimlikleri; UX düzeltmesi, teknik doğrulama veya açık karar bağlantısı |

Katılımcının gerçek koordinatları, özel notları ve e-posta adresi formun parçası değildir. Ekran kaydı gibi ek bir veri toplama yöntemi bu planla otomatik olarak başlatılmaz.

## Ölçüm ve değerlendirme

- Görev tamamlama, yardım ihtiyacı ve bağlamı doğru açıklama ayrı kaydedilir. Katılımcı sayısı bilinmeden başarı yüzdesi veya süre eşiği uydurulmaz; A-012 açık kalır.
- Örnek konumun gerçek konum sanılması, simülasyonun canlı sanılması, ufuk üstü bilgisinin kesin gözlem garantisi sanılması ve fark edilmeden veri kaybı kritik inceleme bulgularıdır. Bu bulguların oluşmadığına dair şu anda kanıt yoktur.
- Tamamlanamayan görevde sorun arayüz, eksik prototip işlevi, astronomi hesabı veya dış veri kaynağı olarak ayrıştırılır. Sınıflandırma gözlem kaydına dayanır.
- Hesap doğruluğu, PWA kalıcılığı, gerçek cihaz sensörü, performans ve erişilebilirlik ayrı teknik doğrulama ister. Taslak görseller bu kontrolleri karşılamaz.
- Masa başı belge incelemesi bu çalışma paketinde yapılabilir; gerçek kullanıcı değerlendirmesi henüz yürütülmediği için Product Discovery tamamlanmış sayılmaz. Hazırlanabilir UX/mimari araştırmaları bu sırada sürdürülebilir.

## Sonuç kaydı

**Yürütülen kullanıcı oturumu: yok.** Sonuçlar geldiğinde tarih, kullanılan sürüm, görev bazlı gözlem, değişiklik ve tekrar değerlendirme ihtiyacı burada veya bağlantılı araştırma kaydında tutulacak. İlerleme [yol haritasında](yol-haritasi.md) güncellenir.
