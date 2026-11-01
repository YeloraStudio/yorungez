# ADR-0002 — Modüler temel, CQRS, kimlik ve lisans seçimi

**1 Kasım 2026 güncellemesi:** A-001 özgün kod lisansı kullanıcı seçimiyle Apache-2.0 olarak kapandı. Aşağıdaki açık lisans ifadeleri tarihsel aşamayı anlatır; üçüncü taraf lisansları değişmez. [ADR-0014](0014-acik-kaynak-yayin-ve-apache-2.md).

**Tarih:** 31 Ekim 2026  
**Durum:** Uygulandı; harita ve hesap motoru seçimi açık.  
**İz:** FR-07–08, FR-11–12; AC-08–09, AC-13–14. [ADR-0001](0001-teknik-temel-ve-ilk-dikey-akis.md) üzerine eklenir.

## Karar ve gerekçe

**Sonraki basamak:** Bu belge ilk Identity/Catalog temelinin kaydıdır. Astronomy modülü ve üçüncü etkin modülün sınırlı hesap adaptörü [ADR-0003](0003-ilk-astronomi-adaptoru-ve-dogruluk-sinirlari.md) ile eklendi; aşağıdaki ilk kapsam ve doğrulama kayıtları tarihsel olarak korunur.

Kullanıcı .NET 10, modüler monolit, Clean Architecture, CQRS, lisans ücreti gerektirmeyen MediatR, PostgreSQL, Redis, JWT ve e-posta doğrulamasını seçti. Bu paket söz konusu altyapıyı çalışır hâle getirir. Ana ürün hedefi hâlâ anonim kullanılabilen gökyüzü haritasıdır; hesap bütün harita uçlarına zorunlu tutulmaz.

Bağımlılık yönü `Domain ← Application ← Infrastructure` şeklindedir. API sunum ve birleştirme katmanıdır. Domain ve Application EF Core/ASP.NET veya Infrastructure referansı almaz. Modüller birbirlerinin kalıcı tablolarına doğrudan erişmez. CQRS, ayrı komut/sorgu tipleri ve MediatR handler'larıyla uygulanır; ayrı veritabanı, event sourcing veya mikroservis zorunluluğu doğurmaz.

| Mevcut proje grubu | Uygulanan sorumluluk |
|---|---|
| `Yorungez.Core` | Bağımsız enlem/boylam doğrulaması; fiziksel ölçüm doğruluğu iddiası içermez |
| `BuildingBlocks/Yorungez.Application` | Komut/sorgu sözleşmeleri, hata kodu, çeviri arayüzü ve istek süresi ölçümü |
| `Modules/Identity` | Domain/Application/Infrastructure; hesap, doğrulama, JWT/refresh oturumları, şifreli e-posta kuyruğu |
| `Modules/Catalog` | Domain/Application/Infrastructure; kaynaklı tr/en terim kataloğu ve arama; gök cismi kataloğu henüz yok |
| `Yorungez.Api` | HTTP, dil seçimi, kimlik yetkisi, hata/health yanıtları ve DI birleştirmesi |

Ürün planındaki sekiz mantıksal modül korunur. Kullanılmayan altı modül için boş proje iskeleti üretilmedi; ihtiyaçla eklenecek. Identity PostgreSQL `identity` şemasının sahibidir. Katalog şimdilik sürümlü gömülü JSON'dur; Redis yalnızca yeniden üretilebilir önbellektir.

## Bağımlılık ve lisans

- **MediatR 12.5.0** tam sürümle sabittir. İndirilen paketin lisans ifadesi ve [etiketli kaynak lisansı](https://raw.githubusercontent.com/LuckyPennySoftware/MediatR/v12.5.0/LICENSE) Apache-2.0'dır. Kullanıcının ücretli sürüm istememe talebini karşılamak için bu sürüm seçildi. Bu, ticari kullanımı yasak bir lisans anlamına gelmez. Yeni ana sürüme otomatik geçiş yapılmaz; güncellemelerde lisans ve bakım ayrıca kontrol edilir.
- PostgreSQL seçildi; PostGIS kurulmadı. Redis 8'in [sunulan lisans seçeneklerinden](https://redis.io/legal/licenses/) AGPLv3 bu yerel sunucu için esas alınır. Ücretli Redis Cloud/Enterprise hizmeti kullanılmaz. Değiştirilmiş Redis kodu dağıtılmıyor.
- Paket sürümleri `Directory.Packages.props` içinde, geçişli çözümlemeler `packages.lock.json` dosyalarında sabittir. Docker imajları sürüm ve içerik özetiyle sabittir. Güncelleme sırasında zafiyet ve lisans denetimi sürdürülür; eski sürüme sabitlemek bakım ihtiyacını kaldırmaz.
- Envanter [THIRD_PARTY_NOTICES](../../THIRD_PARTY_NOTICES.md) dosyasındadır. Yorungez'ın kendi açık kaynak lisansı A-001'de açıktır; bu paket kendi başına ürün lisansı seçmez.

## Sonuç ve doğrulama

Gerçek PostgreSQL/Redis ile kayıt → şifreli outbox → doğrulama → giriş → JWT → refresh döndürme → çıkış akışı sınanır. Refresh özeti saklanır; tekrar kullanım oturum ailesini iptal eder. Redis kesilince sözlük gömülü kaynağa döner. Mimari referans sınırları test edilir.

Bu katmanlar bir üretim dağıtımı değildir. Frontend/BFF, kişisel kayıtlar, anonim aktarım/senkronizasyon, harita, bilimsel motor ve performans bütçesi henüz uygulanmadı. [İşletim ve kimlik belgesi](../altyapi-ve-kimlik.md) mevcut davranışı ve üretim öncesi eksikleri açıklar. Sonraki ana iş TECH-02 motor denemesi ve TECH-03 tr/en harita akışıdır.
