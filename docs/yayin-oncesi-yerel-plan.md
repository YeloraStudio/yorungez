# K-032 — Dağıtım ertelenirken yerel çalışma sırası

**K-039 / 2 Kasım 2026 — Güncel durum denetimi:** Önce Web kabulünü tamamlamak, ardından aynı .NET backend/hesap/verilerle mobil uygulama geliştirmek kullanıcı hedefidir. [Plan, eksikler, kanıt ve mobil hazırlık](web-tamamlama-ve-ortak-backend-mobil-hedef.md). Bilgi/görsel önceliği, K-032 yayın beklemesi ve açık P0/P1/P2 kapsamı korunur; aşağıdaki eski paketler kendi aşamalarının tarihsel kanıtıdır.

**K-038:** [Bilgi/görsel ve fiziksel deneme geri bildirimi](mobil-kart-samanyolu-ve-pusula-erisim.md) mevcut önceliği derinleştirir: mobil kart rengi, Samanyolu ve engelli sensör izni. S23 genel kullanım bildirimi olumlu; tam cihaz kabulü açık. Yeni yedek/çöp işleri bu önceliğin önüne geçmez.

**K-037 güncel öncelik:** Kullanıcı bilgi/görsellik ve mevcut nesne kartlarının UX geliştirmesini öne aldı. [TECH-11D](gok-cismi-gorselleri-ve-yerel-telefon-testi.md) kaynaklı görsel/kısa bilgi paketi uygulandı; sırada kalan atlas nesnelerinin görselleri/bilgileri ve S23 yerel denemesi var. Yeni yedek/çöp/yaşam döngüsü işleri ve genel klavye/hata sağlamlaştırma paketi şimdilik ertelendi; aşağıdaki önceki sıra güncel öncelik değildir. Mevcut çalışan kişisel kayıtlar ve tüm FR/UJ/AC kalanları korunur. USB-localhost denemesi deployment gerektirmez; TECH-11E ile S23 genel kullanım/PWA olumlu bildirimi alındı, tam GPS/pusula/cihaz protokolü açık.

**K-036 / TECH-11C:** Kullanıcı mevcut özelliklerin derinliğini önceliklendirdi. İkinci sıradaki [sözlük/sabit terim bağlantıları](sozluk-ve-terim-baglantilari.md) uygulandı; sırada mevcut harita/hesap/defter/takvim/gece/hata yüzeylerinde okunabilirlik, klavye/odak ve iki dil kabulünü derinleştirmek var. Sonraki yaşam döngüsü/performans işleri korunur; yeni bağımsız alan açmak bu sağlamlaştırmanın önüne geçmez. P1/P2 kapsamı iptal edilmez.

**TECH-11B / K-035:** Kullanıcının form boşluğu ve canlı bilimsel veri talebi [uygulandı ve envanterlendi](canli-hesap-ve-veri-guncelligi.md): canlı hesap/özgün paket tarihi/simülasyon ayrımı görünür. Sürekli olay akışı henüz yok; aşağıdaki FR-08/P1 veri yenileme kabulüne bağlıdır. İkinci sıradaki kalan sözlük/erişilebilirlik işleri devam eder.

**TECH-11A sonucu:** İkinci sıradaki iki dil/erişilebilirlik işinin [ilk klavye/form paketi](iki-dil-klavye-denetimi.md) tamamlandı; gerçek ekran okuyucu/kontrast ve kapsamlı E2E açık kalır. O aşamada açık olan sözlük/derin bağlantı kısmı TECH-11C ile uygulandı. Bu satır ikinci sıranın tümü tamamlandı anlamına gelmez.

**TECH-10 sonucu:** Birinci sıradaki sentetik yerel yedek/geri yükleme provası geçti; [127 .NET testi, kanıt ve sınırlar](yerel-yedek-geri-yukleme.md). Sıradaki yerel paket ikinci sıradaki iki dil/erişilebilirlik denetimidir. Üretim yedek kabulü bekler.

**2 Kasım 2026.** Kullanıcı uygulamanın deployment, HTTPS erişimi ve canlı yayına alınmasını erteledi. `yorungez.com` henüz alınmadı. Mevcut bir alan adında alt alan adı kullanılması yalnız gelecekteki bir olasılıktır; seçilmiş veya yapılandırılmış ortam değildir. Kullanıcı yeniden haber vermeden DNS/alt alan adı bağlama, tünel açma, HTTPS ortamı veya sunucu/Portainer dağıtımı yapılmaz.

Bu karar geliştirmeyi durdurmaz. S23 USB-localhost genel kullanım/PWA denemesi TECH-11E ile bildirildi; güvenilir HTTPS gerektiren diğer cihazlar ve tam fiziksel GPS/pusula/PWA protokolü bekler, yapılmış sayılmaz. P0/P1/P2 kapsamı ve [FR/UJ/AC kalanları](teslimat-izlenebilirligi.md) korunur. Aşağıdaki sıra, mevcut açık işlerin yerelde yürütülebilen bölümüdür; bu dosya işlerin uygulandığına dair kanıt değildir.

## Önce P0 sağlamlaştırma

| Sıra | İş ve mevcut iz | Somut çıktı / sınır |
|---|---|---|
| 1 | Yerel yedek/geri yükleme provası — A-006, ARCH-01, AC-07 | Ayrı ve açıkça test için oluşturulmuş veritabanında sentetik hesap/favori/not/gözlem/konum verisini yedekle, başka test veritabanına geri yükle ve sahiplik/ilişki/revizyon bütünlüğünü doğrula. Gereken Data Protection anahtarlarının kurtarma planıyla ilişkisini belgelemek dahil; gerçek kullanıcı verisi/sırları public çıktıya girmez. Bu, üretim yedek kabulünü kapatmaz. |
| 2 | İki dil ve erişilebilirlik — FR-11–12, UX-01/02, AC-13–14 | Harita/hesap/defter/takvim/Bu gece/hata/boş/offline akışlarını iki dilde denetle; klavye, odak dönüşü, kontrast, büyütme ve masaüstü ekran okuyucu değerlendirmesi. Ayrı sözlük sayfası ve terim bağlantıları TECH-11C ile uygulandı; bütün yüzeylerden erişim ve gerçek yardımcı teknoloji kabulü açıktır. Telefon okuyucuları ayrıca bekler. |
| 3 | Kişisel veri yaşam döngüsü — DOM-01, A-006/A-013, FR-06–07 | Mevcut çöp/geri yükleme/dışa aktarma korunarak kota, kalıcı silme ve içe aktarma sözleşmesini kesinleştir; kayıp/yanlış hesap/çakışma sınırlarını doğrula. Yeni saklama süresi veya kota sayısı bu planla otomatik seçilmez. Hesap zorunluluğu, sunucu kalıcılığı ve açık sayfa taslağının yalnız bellekte kalması sürer. |
| 4 | Yerel performans bütçesi — A-009, FR-02/09 | İlk açılış, hesap süresi, pan/zoom, bellek ve genel paket boyutunu tekrarlanabilir masaüstü senaryolarıyla ölç; başlangıç/kayıp Worker/büyük ekran senaryolarını izle. Gerçek telefon ve üretim Core Web Vitals ölçümleri ayrı bekler. |
| 5 | Gerçek görev değerlendirmesi — DISC-03, A-012, KG-01–08 | Yerel prototiple arama, hedefi anlama, zaman değiştirme, kişisel kayıt ve bağlantı sınırlarının anlaşılmasını gözle; katılımcı/başarı sonucu uydurma. Kullanıcıya/katılımcıya bağlı oturumlar yazılım testiyle kapatılmaz. |

## Ardından mevcut P1 astronomi işleri

- **DATA-P1 / FR-04:** Meteor yağmurları, tutulmalar, kavuşumlar, asteroit ve Ay–yıldız olayları için tür bazında kaynak/lisans/zaman tanımı ve bağımsız doğrulama. Kaynak bulmak uygulamanın ve bilimsel kabulün tamamlandığı anlamına gelmez.
- **FR-03 / A-005:** Daha geniş Messier/NGC/yıldız atlası; eksik görseller, alternatif adlar/katalog kimlikleri, nesneye uygun fiziksel bilgiler ve kısa/açılabilir kaynaklı açıklamalar.
- **FR-05 / A-003/A-007/A-009:** Astronomik karanlık ve Ay ışığı; doğuş-batış, kırılma, yükseklik ve ufuk varsayımlarının daha geniş konum/tarih/hedef örnekleriyle sınanması. Mevcut kutup yön kısıtları ve bilinmeyen koşul açıklamaları korunur.
- **FR-08 / K-035:** Çalışan hesap ve kaynak/paket tarihleri TECH-11B ile görünür; sırada sağlayıcı başına son başarılı alım/sağlık, güncel/gecikmiş/erişilemiyor durumları, kontrollü içeri alma ve zamanlanmış yenileme var. Önemli yeni/geçici gök olayı akışı tür/kaynak/lisans ve bağımsız doğrulamayla genişletilir; henüz bağlı değildir. Normal build/test bilimsel veri indirmez.
- **A-008 / P1:** Hava, bulutluluk, ışık kirliliği ve yerel ufuk/arazi kaynakları araştırması ve ardından uygunluk değerlendirmesi. Veri yoksa bilinmiyor; doğrulanmamış skor yok. PostGIS yalnız gerçek Dünya mekânsal sorgusu gerektirdiğinde değerlendirilir.

## Daha sonraki P2

İsteğe bağlı dürbün/teleskop profilleri, görüş alanı simülasyonu, ekipmana uygun açıklamalar, gözlem/olay/ekipman bağları ve ileri planlama/analitik. Temel keşif ekipman veya hesap gerektirmez; kişisel kayıt hesabı gerektirir.

## Beklemede kalan işler

- Domain/alt alan adı, DNS, HTTPS, tünel, sunucu/Portainer dağıtımı ve canlı yayın.
- [S23/Chrome USB-localhost veya güvenilir HTTPS; iPhone 15/Safari güvenilir HTTPS kabul oturumu](telefon-kabul-oturumu.md).
- Üretim yükü/gerçek mobil performans, gerçek OS kurulum ve depolama temizliği kabulü; üretim backup/restore ve işletim kabulü.

Kaynaklar: [gereksinimler](urun-gereksinimleri.md), [yol haritası](yol-haritasi.md), [kararlar](kararlar.md), [kişisel kayıt kalanları](kisisel-kayit-hesap-cevrimdisi-akislari.md).
