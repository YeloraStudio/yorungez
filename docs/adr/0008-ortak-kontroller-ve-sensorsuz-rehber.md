# ADR-0008 — Ortak ürün kontrolleri ve sensörsüz yön rehberi

**Tarih:** 31 Ekim 2026. **Durum:** TECH-04D yazılımı seçildi/uygulandı; fiziksel ve ekran okuyucu kabulü açık. K-022; FR-01–05/FR-11–12, UJ-01–03/UJ-06, AC-02–06/AC-11/AC-13–14.

Son kullanıcı talimatı önceki native dil listesi kararının yerini alır. Dil/ay/yıl/bölge/DST seçimi için ortak SelectField; tarih için DateField ve tarih+saat için DateTimeField seçildi. Görünen native select veya date/time picker yoktur. Yerleşim/palet değiştirilmez. Popover top-layer modaldaki kırpılmayı önler; görünüm uygulamaya aittir. HTML düğme/listbox/grid semantiği, ok/Enter/Escape, roving gün odağı, arama, min/max ve artık yıl birlikte korunur. W3C örüntüleri referanstır, bütün yardımcı teknoloji kombinasyonlarında uygunluk sertifikası değildir. Yeni UI kütüphanesi eklenmedi.

UTC anı/sıra koruması ve Temporal DST sözleşmesi değişmez. Taslak tarih/saat bileşen içinde korunur, ana canlı saatin render'ı tarafından ezilmez; FormData ISO hidden alanını okur.

Bugün modu kaldırılır. Bu gece, yerel öğlen penceresinde standart Güneş batışı/doğuşu ile hedef aralıklarının kesişimidir; polar gündüz/gece/kısmi sınır ayrı durumdur. Örnek yönlendirmede mümkünse Güneş merkezi −6° altındaki aday tercih edilir. Bu sivil alacakaranlık ürün referansıdır; astronomik gece −18° veya gözlenebilirlik garantisiyle eşitlenmez. 0 m/standart kırılma/üst kenar sınırı ADR-0007 ile korunur.

Masaüstünde konumdan fiziksel ekran yönü çıkarılamaz. Sensörsüz rehber, hesaplanan gerçek kuzey azimutu + yükseklik + yaklaşık kol boyu yumruk açısını ve bilinen kuzey işareti gereğini anlatır. Kuzey yarımküre için Polaris yalnız kaba kuzey yardımcısıdır. Telefon sensörü isteğe bağlı ayrı izin/hizalama/timeout yoludur; yokluğu ana kullanımın hatası değildir. Gündüz/ufuk altı/Güneş hedefi olumlu dürbün önerisi almaz. Kalibre cihaz/AR veya hava/algılanabilirlik iddiası yoktur.

[Uygulama/kanıt/kaynaklar](../ortak-bilesenler-ve-sensorsuz-gozlem.md), [önceki model sınırı](0007-gozlem-takvimi-ve-yer-adlari.md).
