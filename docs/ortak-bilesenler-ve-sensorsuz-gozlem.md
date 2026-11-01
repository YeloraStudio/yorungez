# TECH-04D — Ortak bileşenler ve sensörsüz gözlem

**Güncel K-024 / TECH-05:** Kişisel kayıt için doğrulanmış hesap zorunlu; anonim/IndexedDB kişisel kalıcılığı kaldırıldı. Not ve favoriler kullanıcıya bağlı PostgreSQL modülünde; TR/EN kayıt/giriş/doğrulama/sıfırlama ve panel geri dönüşü bağlıdır. [Uygulama ve sınırlar](hesap-ve-sunucu-defteri.md), [ADR-0010](adr/0010-hesap-zorunlu-defter-ve-sunucu-kayitlari.md). Aşağıdaki eski paket kayıtları kendi aşamasının tarihsel kanıtıdır.


**31 Ekim 2026 / PRD 1.6 / K-022–023.** Kullanıcı Bugün seçeneğinin kaldırılmasını, bütün seçim/tarih alanlarının ürün tasarımına taşınmasını, İstanbul konum örneğini ve sensörsüz dürbün yönlendirmesini istedi. Önceki kapsam korunarak uygulandı. FR-01–05/FR-11–12, UJ-01–03/UJ-06, AC-02–06/AC-11/AC-13–14; devam eden yerel kişisel dilim FR-06–09/UJ-04–05/UJ-07/AC-07/AC-09–10/AC-12 ile ilişkilidir.

## Bu gece ve ortak kontroller

Menüde ve panelde **yalnız Bu gece** vardır; Today/Bugün modu kaldırıldı. Hesap yerel öğleden sonraki öğlene UTC sınırlarını Temporal/IANA ile bulur, hedeflerin standart ufuk üstü aralıklarını **Güneş batışı–doğuşu ile kesiştirir**. Tarih değişince çizelge yenilenir. DST penceresi 23/25 saat olabilir. Kutup gündüzünde sahte gece/aralık gösterilmez; kutup gecesinde öğlen–öğlen referansı ve alacakaranlığın sürebileceği belirtilir. Tek geçişli sınır günlerinde kısmi pencere açıklanır. Klavye önerisi varsa Güneş merkezinin −6° altında olduğu örnekleri tercih eder; kesin transit veya gözlenebilirlik skoru değildir. Akşam alacakaranlığı ve astronomik gece (−18°) aynı kavram değildir; Ay/gezegenlerin bazı gündüz gözlemlerinin varlığı inkâr edilmez. Harita/takvimde gündüz simülasyonu korunur.

`components/ui/SelectField`, `DateField`, `DateTimeField`, `PickerPopover` ortak ürün bileşenleridir. Görünen native select/date/time girişleri kaldırıldı. Dil, takvim ay/yıl, IANA bölgesi, DST oluşum seçimi, Bu gece tarihi ve harita tarih/saat alanı aynı gri-bordo tasarımı kullanır. Konum arama placeholder'ı tr **İstanbul**, en **Istanbul** örneğidir.

Seçim listelerinde ok/Enter/Escape, uzun listelerde arama, seçili değere kaydırma; tarihte tek dolaşılabilir gün, oklarla gün/hafta, Home/End hafta sınırı, Page Up/Down ay ve Shift ile yıl, min/max ve artık yıl vardır. İç açılır liste Escape'i yalnız kendisini kapatır, ana pencereyi kapatmaz; odak tetikleyiciye döner. Popover API yalnız top-layer taşıyıcıdır, görünen panel uygulama CSS'idir; modaldaki overflow sınırlarından çıkabilir. Destek yokluğunda sınırlı inline yol vardır, eski tarayıcı eşliği sertifikalı değildir.

Formlar teknik ISO değeri hidden input ile taşır; saat taslağı kendi bileşen durumundadır. Canlı haritanın saniyelik yenilenmesi düzenlenen saati geri alamaz. UTC tek an, IANA/yerel/GMT ayrı gösterim; DST boş saat reddi/çift oluşum seçimi ve bilimsel tarih sınırı korunur. [W3C select-only örüntüsü](https://www.w3.org/WAI/ARIA/apg/patterns/combobox/examples/combobox-select-only/), [tarih gezinme örüntüsü](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/examples/datepicker-dialog/). Kod örnekleri kopyalanmadı; ekran okuyucu/fiziksel mobil kabulü ayrıca bekler.

## Sensör olmadan nereye bakılır?

Pusula penceresi önce **Nereye bakmalıyım?** rehberini gösterir; telefon sensörü isteğe bağlı açılır bölümde kalır. Şema gerçek kuzeyi üstte tutar, hedefin hesaplanan azimutu/yüksekliğini ve sekiz yönden karşılığını gösterir; bilgisayarın baktığı fiziksel yönü bildiğini iddia etmez. Konum ve pusula ayrı veri kaynaklarıdır. Sensör erişim hatası artık her durumu kesin donanım yokluğu veya kullanıcının reddi gibi sunmaz; sensörsüz yol açık kalır.

Seçili harita saati/IANA bölgesi ve simülasyon etiketi görünür. Karanlıkta ve ufuk üstünde Jüpiter gibi hedef için yön + yaklaşık yumruk yüksekliği, önce çıplak gözle bulup dürbünü kaldırma ve dirsekleri sabitleme kısa brief'i verilir. Kol boyunda yumruk yaklaşık 10° kaba rehberdir; kişiye göre değişir, ölçüm doğruluğu değildir. Meraklısına bölümünde kuzey yarımkürede Kutup Yıldızı yardımı ve onu haritada bulma bağlantısı vardır. Uygun şartlarda Jüpiter'in büyük uydularından bazılarının seçilebileceği anlatılır; hepsi her an görünür denmez. Kaynak: [NASA skywatching FAQ](https://science.nasa.gov/skywatching/faq/).

Ufuk altında, bilinmeyen hesapta veya Güneş merkezi −6° altında değilse olumlu gece/dürbün brief'i verilmez. Güneş hedefinde ayrı uygun filtre uyarısı vardır. Bu ürün eşiği sivil alacakaranlık referansıdır; gerçek hava/ışık/engel veya algılanabilirlik ölçümü değildir. abs(enlem)>=89 yön koruması ve önceki iki ham JPL kutup yön başarısızlığı korunur. Sensör yolu ayrı izin, mutlak yön, açık gerçek yön hizalaması, 8 s eski veri/timeout, eğim/sapma ve kapanış temizliğini sürdürür. Sensör bölümü kapatılınca da dinleyici durur. [W3C orientation kaynağı](https://www.w3.org/TR/orientation-event/).

## Sonraki planın ilk çalışan dilimi

Defterim artık yerel **favori ve not/anı** dilimini açar. Nesne kartından da erişilir. Kayıt/silinme geri alma/düzenleme/JSON yedek ve iki sekmeli çakışma koruması vardır; konum/zaman/hedef bağları ayrı, varsayılan boş seçimlerdir. [Kişisel kayıt/hesap/çevrimdışı akışları](kisisel-kayit-hesap-cevrimdisi-akislari.md), [ADR-0009](adr/0009-yerel-defter-ve-kayipsiz-duzenleme.md). Bu dilim gerçek gözlem kayıtları/kayıtlı konum/hesap aktarımı veya PWA'nın tamamı değildir.

## Kanıt ve kalanlar

**33 istemci testi**, TypeScript ve Next üretim derlemesi geçti. 144 yıldız/72 DSO Astropy örnekleri, donmuş JPL yön koruması, 1781 USNO Ay evresi ve 22 standart doğuş-batış karşılaştırması normal testte ağsız korunur. Backend kodu bu pakette değişmedi; önceki **93 .NET** sonucu tarihsel temel kanıtıdır, bu tur yeniden çalıştırıldığı iddia edilmez.

[Tarayıcı kaydı](science/controls-notebook-browser-qa.json): tr/en, özel ay/yıl/tarih/saat, iç içe Escape, yön brief'i, yerel kalıcılık/JSON/mahremiyet/çakışma ve dar viewport sonuçları. [Türkçe Jüpiter rehberi](ux/controls/jupiter-guide-tr.jpg), [İngilizce rehber](ux/controls/jupiter-guide-en.jpg), [özel tarih](ux/controls/date-picker-tr.jpg), [mobil tarih](ux/controls/mobile-date-tr.jpg), [mobil ay listesi](ux/controls/mobile-calendar-select-tr.jpg), [Defterim](ux/controls/notebook-tr.jpg), [mobil Defterim](ux/controls/mobile-notebook-tr.jpg). Gerçek cihaz GPS/pusula/VoiceOver/TalkBack ve üretim yükü açık; [fiziksel protokol](cihaz-konum-pusula-dogrulamasi.md) yürütülmedi. Hesap UI/SMTP, açık onaylı aktarım/senkronizasyon, service worker/çevrimdışı yeniden açılış ve ek olay türlerinin kaynak doğrulaması sıradadır. Bütün FR/UJ/AC kalanları [izlenebilirlikte](teslimat-izlenebilirligi.md) korunur.
