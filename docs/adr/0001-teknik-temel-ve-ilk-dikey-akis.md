# ADR-0001 — Backend temeli ve ilk harita akışı

**Tarih:** 30 Ekim 2026  
**Durum:** İlk teknik temel yönü benimsendi; motor/veri seçimleri bu kararın dışında açık kalır.

**31 Ekim eki:** Bu ADR ilk host/koordinat aşamasının tarihsel kaydıdır. PostgreSQL/Redis, Clean Architecture/CQRS ve kimlik temeli sonraki kullanıcı talimatıyla [ADR-0002](0002-moduler-temel-cqrs-ve-lisanslar.md) kapsamında kuruldu. Aşağıdaki “ilk temel” kapsamı bu ilk aşamayı anlatır; güncel durum [teknik başlangıç](../teknik-baslangic.md) belgesindedir. PostGIS ve astronomi/çizim motoru seçimleri hâlâ açıktır.
**Dayanak:** Kullanıcının haritayı birincil öncelik olarak teyit etmesi, hassas konum verilerini işleme kapsamı ve gerektiğinde ücretsiz/açık kaynak coğrafi altyapı kullanma yönlendirmesi. Kaynak: [gereksinimler](../urun-gereksinimleri.md), FR-01–05, FR-08–09 ve MVP-0.

## Karar

1. İlk kod temeli ASP.NET Core API host'u ve altyapıdan bağımsız bir C# çekirdeğiyle başlar. Hedef framework **.NET 10**; yerelde mevcut kararlı SDK **10.0.403** `global.json` ile seçilir, önizleme SDK'sı kullanılmaz.
2. İlk çekirdek kapsamı enlem/boylam değerlerinin geçerliliği ve kayıpsız taşınmasıdır. Bu aşama göksel konum hesabı veya hesap motoru seçimi değildir.
3. İlk ürün hedefi konum + seçili an → hesap → gökyüzü haritası → nesne kartı akışıdır. Backend'in tüm modüllerinin tamamlanması beklenerek harita doğrulaması ertelenmez.
4. Next.js + TypeScript/PWA yönü korunur. Çizim/hesap motoru için lisans, koordinat/zaman doğruluğu, mobil etkileşim ve çevrimdışı uygunluk denemesi yapıldıktan sonra ilk harita bağlanır.
5. PostgreSQL/PostGIS ihtiyacı veri modeli ve mekânsal sorguyla gerekçelendirilir. MVP-0'daki her harita hareketi için veritabanı veya dış API çağrısı gerektiren bir tasarım ön koşul değildir.
6. Hesap/kimlik, favoriler, notlar ve cihazlar arası eşitleme P0'dır. İlk teknik temel bunları çalışıyormuş gibi sunmaz.

## Sorumluluk sınırları

| Parça | İlk sorumluluk |
|---|---|
| Web istemcisi | Açık eylemle cihaz konumu/sensör izni, manuel koordinat, harita etkileşimi ve seçili bağlam |
| Astronomi çekirdeği / seçilecek motor | Zaman ve koordinat dönüşümleri, gök cismi konumları ve açıklanabilir hesap sınırları |
| API host'u | Giriş/çıktı sözleşmeleri, sunucu tarafı kurallar ve sonraki modüllerin uygulama sınırı |
| PostgreSQL / gerekirse PostGIS | Kalıcı konum ve kişisel veriler; ihtiyaç doğrulanırsa mekânsal saklama/indeks/sorgu |

Hesapların hangi kısmının istemcide, hangi kısmının sunucuda çalışacağı A-002/A-003/ARCH-01'de değerlendirilecek. Bu ADR bütün hesapları API'ye veya bütün verileri sunucuya taşıma kararı değildir.

## Seçimin gerekçesi ve sınırı

- .NET 10 resmî destek politikasında LTS hattıdır. Yerelde kararlı SDK bulunduğu için ilk temel için yeni bir sistem kurulumu gerekmez. SDK/çalışma zamanı yama güncelliği sürdürülmelidir; burada “en güncel sürüm” iddiası yoktur. [Microsoft destek politikası](https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core).
- ASP.NET Core'un yerleşik health check altyapısı ilk host doğrulaması için yeterlidir. `/health/live` yalnızca host'un yanıt verdiğini gösterecek; henüz kurulmamış veritabanı veya astronomi hesabı hazırmış gibi yorumlanmayacak. [Microsoft health check belgesi](https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/health-checks?view=aspnetcore-10.0).
- Ayrı çekirdek projesi koordinat kurallarını API, veritabanı ve seçilecek motor bağımlılığı olmadan sınamayı sağlar. Sekiz mantıksal modül için şimdiden sekiz servis veya boş proje üretilmez.
- İstemci ve sunucu arasında aktarılırken hassasiyet korunması, cihaz ölçümünün fiziksel doğruluğunu artırmaz; doğruluk bilgisi ayrıca ele alınır.

## Doğrulama ve sonraki iş

İlk temel için Release build başarılıdır (0 uyarı/0 hata); koordinat sınır/sonlu sayı/hassasiyet senaryolarından oluşan 18 test geçmiştir. Yerel HTTP kontrolünde `/health/live` 200/Healthy ve `/api/v1/status` beklenen servis kimliğini döndürmüştür; kontrol süreci durdurulmuştur. Astronomik toleranslar, gerçek GPS/pusula, harita performansı ve PostGIS sorguları bu kontrollerle kanıtlanmış sayılmaz.

Sonraki somut hedef [teknik başlangıç planındaki](../teknik-baslangic.md) motor denemesi ve ilk harita akışıdır. Mevcut sonuçlar [yol haritasına](../yol-haritasi.md) kaydedilir.
