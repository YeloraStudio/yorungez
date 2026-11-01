# ADR-0004 — İlk harita çizimi ve parlak yıldız kataloğu

**1 Kasım 2026 güncellemesi:** A-001 özgün kod lisansı kullanıcı seçimiyle Apache-2.0 olarak kapandı. Aşağıdaki açık lisans ifadeleri tarihsel aşamayı anlatır; üçüncü taraf lisansları değişmez. [ADR-0014](0014-acik-kaynak-yayin-ve-apache-2.md).

**Sonraki karar notu:** İlk prototipteki panel yerleşimi, manuel konum/28 terim ve BFF fallback yaklaşımı bu aşamanın kaydıdır. Kullanıcı düzeltmeleriyle tam ekran/kapalı menü, 39 terim, izinli GPS/OSM/IANA, yeni katmanlar ve doğrudan doğrulanmış yerel BFF paketi [ADR-0005](0005-tam-ekran-konum-ve-yerel-zaman.md) ile uygulanmıştır. İlk veri/hesap referansları korunur; [güncel kanıt](../tam-ekran-harita-gelistirmesi.md).

**31 Ekim 2026. Durum:** İlk prototip için uygulandı; fiziksel cihaz/bütün ürün kabulü açık. **İz:** FR-01–05, FR-08–09, FR-11–12; UJ-01–03/06; AC-01–06/10–14; K-018; A-002/005/009/011.

## Problem ve seçenekler

TECH-02A yalnızca Güneş/Ay/gezegen hesabını doğruladı. Harita için ortak hedef kimliği, iki dil, kaynaklı yıldız/takımyıldız ve seçili gözlem bağlamını koruyan düşük maliyetli çizim gerekiyor. Stellarium Web Engine kapsamlı planetaryum adayıdır; AGPL/ticari seçenek ve asset/lisans uyumu ayrı değerlendirme gerektirir. Aladin Lite'ın HiPS/atlas rolü yerel ufuk planetaryumuyla eşdeğer değildir. İkisi kurulmadı veya performans deneyine alınmadı; hızları hakkında sonuç çıkarılmadı.

Sınırlı 5 bin hedef için aynı veri/projeksiyonla kendi Canvas 2D, SVG ve WebGL katmanları uygulandı. [Deneme](../harita-ve-katalog-denemesi.md) ortak 30 ısınma + 120 ölçüm karesi, üretim derlemesi, sabit sentetik konum/an ile çalıştı. IAB tarayıcısında Canvas CPU p95 0,3 ms; SVG 5,8/4,6 ms; WebGL 0,7/1,0 ms (masaüstü/dar yüzey). Bu CPU gönderim ölçümüdür; GPU bitişi, bütün harita/etiket katmanı, fiziksel telefon veya garanti FPS ölçümü değildir.

## Karar

- İlk yol **Canvas 2D + stereografik projeksiyon**. Küçük katalogda DOM/GPU kaynak yönetimi maliyetini azaltır; eldeki deneyde yeterli. SVG/WebGL karşılaştırma laboratuvarında kalır. Geniş katalog/HiPS/cihaz ölçümleri farklı karar gerektirebilir. Uygulama kod lisansı A-001'de açık kalır.
- **HYG 4.1**: kadir <=6 olan 5070 yıldız ve çizgilerin üç sönük düğümü; toplam 5073. **d3-celestial** çizgi/ad verileriyle 88 iki dilli takımyıldız. [Veri ve lisans kaydı](../../data/catalog/README.md); HYG türevi CC BY-SA 4.0, d3 veri kaynak atıfları/BSD metni korunur. Derin uzay/Messier/NGC kapsamı seçilmiş sayılmaz.
- C# Catalog modülü salt okunur gömülü veriyi MediatR sorgusuyla sunar. Next.js BFF aynı SHA doğrulanmış paketi API yokluğunda kullanır. Kaynak dosya tek; PostgreSQL/Redis'e 5073 statik kayıt kopyası eklenmez. Genel katalog sürümü/ETag vardır; kişisel konum cache anahtarına veya URL'ye yazılmaz.
- İstemcide **Web Worker** yıldız+gezegen karelerini hesaplar, bilimsel değerleri Float64 tutar. Eski sonuçlar sıra numarasıyla elenir. Harita ve kart aynı kareyi kullanır; beklerken önceki hesap açıkça etiketlenir. Canlı saat/simülasyon ayrılır; form UTC'yi açıkça ister. Girdi koordinatı yuvarlanmaz; kart gösterim biçimi ayrı tutulur.
- İlk konum **etiketli İstanbul örneği**dir; kullanıcının gerçek konumu değildir. Bu prototip varsayılanıdır, üretim ilk kullanım araştırmasının tamamlandığı anlamına gelmez. GPS/pusula TECH-04; hiçbir gerçek konum/sensör izni istenmedi.
- `/tr`, `/en`, eş anahtarlı metinler, iki dilde 28 kaynaklı terim ve karttan erişim birlikte uygulanır. Dil değişimi bellekteki konum/an/mod/hedef/kamera/katmanları korur. Kaynak bilgiler, varsayımlar, bilinmeyen koşullar ve kutup sınırı iki dilde görünürdür.

## Sınırlar ve sonuçlar

Yıldız dönüşümünün 144 Astropy/ERFA karşılaştırması 1 yay dakikası deneme hedefinde: en büyük yön farkı 0,30758, yükseklik farkı 0,26481 yay dakikası. HYG gerçekliğinin veya bütün yıldız/zaman/konumların doğrulandığı iddiası değildir. Sabit IERS/leap tablolarının 2035 uyarıları korunur. ADR-0003'teki iki kutup yön başarısızlığı korunur; abs(enlem)>=89 için harita hedefi/azimut verilmez. Kırılma, hava/arazi, geleneksel doğuş-batış ve hassas EOP hesabı bu görünümde yoktur.

Hesap/arama/terimler yüklenmiş sekmede yereldir; PWA kurulum, service worker, soğuk offline açılış ve senkronizasyon henüz yoktur. Klavye, native dialog/ESC odak dönüşü ve dar ekran yerleşimi geliştirici denemesi yapıldı; ekran okuyucu, fiziksel dokunma/pinch, GPS/pusula ve mobil performans bütçesi açık. MVP-0 bütünü veya WCAG uygunluğu tamamlandı işaretlenmez. Sonraki basamak TECH-04 izin/doğruluk/sensör durumu ve manuel alternatif, gerçek cihaz protokolü; ardından P0 kişisel veri/hesap/offline UX ve uygulamasıdır.
