# K-032 — Dağıtım ertelenirken yerel çalışma sırası

**TECH-10 sonucu:** Birinci sıradaki sentetik yerel yedek/geri yükleme provası geçti; [127 .NET testi, kanıt ve sınırlar](yerel-yedek-geri-yukleme.md). Sıradaki yerel paket ikinci sıradaki iki dil/erişilebilirlik denetimidir. Üretim yedek kabulü bekler.

**2 Kasım 2026.** Kullanıcı uygulamanın deployment, HTTPS erişimi ve canlı yayına alınmasını erteledi. `yorungez.com` henüz alınmadı. Mevcut bir alan adında alt alan adı kullanılması yalnız gelecekteki bir olasılıktır; seçilmiş veya yapılandırılmış ortam değildir. Kullanıcı yeniden haber vermeden DNS/alt alan adı bağlama, tünel açma, HTTPS ortamı veya sunucu/Portainer dağıtımı yapılmaz.

Bu karar geliştirmeyi durdurmaz. HTTPS kökenine bağlı fiziksel GPS/pusula/PWA kurulum kabulü beklemede tutulur; yapılmış sayılmaz. P0/P1/P2 kapsamı ve [FR/UJ/AC kalanları](teslimat-izlenebilirligi.md) korunur. Aşağıdaki sıra, mevcut açık işlerin yerelde yürütülebilen bölümüdür; bu dosya işlerin uygulandığına dair kanıt değildir.

## Önce P0 sağlamlaştırma

| Sıra | İş ve mevcut iz | Somut çıktı / sınır |
|---|---|---|
| 1 | Yerel yedek/geri yükleme provası — A-006, ARCH-01, AC-07 | Ayrı ve açıkça test için oluşturulmuş veritabanında sentetik hesap/favori/not/gözlem/konum verisini yedekle, başka test veritabanına geri yükle ve sahiplik/ilişki/revizyon bütünlüğünü doğrula. Gereken Data Protection anahtarlarının kurtarma planıyla ilişkisini belgelemek dahil; gerçek kullanıcı verisi/sırları public çıktıya girmez. Bu, üretim yedek kabulünü kapatmaz. |
| 2 | İki dil ve erişilebilirlik — FR-11–12, UX-01/02, AC-13–14 | Harita/hesap/defter/takvim/Bu gece/hata/boş/offline akışlarını iki dilde denetle; klavye, odak dönüşü, kontrast, büyütme ve masaüstü ekran okuyucu değerlendirmesi. Ayrı sözlük sayfası ve terim derin bağlantıları mevcut açık kapsamdır. Telefon okuyucuları ayrıca bekler. |
| 3 | Kişisel veri yaşam döngüsü — DOM-01, A-006/A-013, FR-06–07 | Mevcut çöp/geri yükleme/dışa aktarma korunarak kota, kalıcı silme ve içe aktarma sözleşmesini kesinleştir; kayıp/yanlış hesap/çakışma sınırlarını doğrula. Yeni saklama süresi veya kota sayısı bu planla otomatik seçilmez. Hesap zorunluluğu, sunucu kalıcılığı ve açık sayfa taslağının yalnız bellekte kalması sürer. |
| 4 | Yerel performans bütçesi — A-009, FR-02/09 | İlk açılış, hesap süresi, pan/zoom, bellek ve genel paket boyutunu tekrarlanabilir masaüstü senaryolarıyla ölç; başlangıç/kayıp Worker/büyük ekran senaryolarını izle. Gerçek telefon ve üretim Core Web Vitals ölçümleri ayrı bekler. |
| 5 | Gerçek görev değerlendirmesi — DISC-03, A-012, KG-01–08 | Yerel prototiple arama, hedefi anlama, zaman değiştirme, kişisel kayıt ve bağlantı sınırlarının anlaşılmasını gözle; katılımcı/başarı sonucu uydurma. Kullanıcıya/katılımcıya bağlı oturumlar yazılım testiyle kapatılmaz. |

## Ardından mevcut P1 astronomi işleri

- **DATA-P1 / FR-04:** Meteor yağmurları, tutulmalar, kavuşumlar, asteroit ve Ay–yıldız olayları için tür bazında kaynak/lisans/zaman tanımı ve bağımsız doğrulama. Kaynak bulmak uygulamanın ve bilimsel kabulün tamamlandığı anlamına gelmez.
- **FR-03 / A-005:** Daha geniş Messier/NGC/yıldız atlası; eksik görseller, alternatif adlar/katalog kimlikleri, nesneye uygun fiziksel bilgiler ve kısa/açılabilir kaynaklı açıklamalar.
- **FR-05 / A-003/A-007/A-009:** Astronomik karanlık ve Ay ışığı; doğuş-batış, kırılma, yükseklik ve ufuk varsayımlarının daha geniş konum/tarih/hedef örnekleriyle sınanması. Mevcut kutup yön kısıtları ve bilinmeyen koşul açıklamaları korunur.
- **FR-08:** Veri kaynağı envanteri, sürüm/lisans/son başarılı yenileme ve güncel/gecikmiş/erişilemiyor durumları; kontrollü içeri alma ve yenileme politikası. Normal build/test bilimsel veri indirmez.
- **A-008 / P1:** Hava, bulutluluk, ışık kirliliği ve yerel ufuk/arazi kaynakları araştırması ve ardından uygunluk değerlendirmesi. Veri yoksa bilinmiyor; doğrulanmamış skor yok. PostGIS yalnız gerçek Dünya mekânsal sorgusu gerektirdiğinde değerlendirilir.

## Daha sonraki P2

İsteğe bağlı dürbün/teleskop profilleri, görüş alanı simülasyonu, ekipmana uygun açıklamalar, gözlem/olay/ekipman bağları ve ileri planlama/analitik. Temel keşif ekipman veya hesap gerektirmez; kişisel kayıt hesabı gerektirir.

## Beklemede kalan işler

- Domain/alt alan adı, DNS, HTTPS, tünel, sunucu/Portainer dağıtımı ve canlı yayın.
- Erişilebilir HTTPS ortamına bağlı [S23/Chrome ve iPhone 15/Safari kabul oturumu](telefon-kabul-oturumu.md).
- Üretim yükü/gerçek mobil performans, gerçek OS kurulum ve depolama temizliği kabulü; üretim backup/restore ve işletim kabulü.

Kaynaklar: [gereksinimler](urun-gereksinimleri.md), [yol haritası](yol-haritasi.md), [kararlar](kararlar.md), [kişisel kayıt kalanları](kisisel-kayit-hesap-cevrimdisi-akislari.md).
