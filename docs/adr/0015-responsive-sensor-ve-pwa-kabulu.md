# ADR-0015 — Responsive görünüm, sensör geçerliliği ve PWA kabul hazırlığı

**1 Kasım 2026 / K-030 / TECH-08 — Yazılım uygulandı; fiziksel kabul açık.**

İz: FR-01–05/08–09/11–12, UJ-01–03/06–07, AC-01–03/05/09–14. Kullanıcı mevcut cihaz/PWA kabul adımını onayladı; responsive, bilimsel, güvenilir ve hızlı çalışma önceliğini yineledi. Astronomi motoru, katalog kaynakları, toleranslar ve kutup istisnaları değişmez.

## Sensör ve gözlem bağlamı

Önce geçerli bir yön veren telefonun eğimi/sapması bozulunca son yön sekiz saniye boyunca uygulanabilir kalmamalı. Geçersiz eğim, bildirilen kötü WebKit sapması veya geçersiz ekran açısı yönü anında kullanılmaz yapar. UI eski yön ve hizalamayı temizler; yeni geçerli örnekte tekrar gerçek yöne hizalama gerekir. Android'in geçerli mutlak olay yanında üretebildiği yalnız göreli olay tek başına gerçek kuzey sayılmaz ve geçerli mutlak örneği düşürmez. Önceki 35° düz tutuş / 30° bildirilen sapma korumaları ve 8 saniyelik veri yokluğu sınırı korunur; bunlar ölçülmüş donanım doğruluk garantisi değildir.

İzin yanıtı araç kapandıktan sonra gelirse sensör başlamaz. Sayfa gizlenince dinleyici kapanır. Hesaplanan göksel azimut ve cihazın manyetik/belirsiz yön kaynağı ayrı kalır. Mevcut [fiziksel protokol](../cihaz-konum-pusula-dogrulamasi.md) değiştirilerek masaüstü testinden geçmiş sayılmaz.

## Responsive ve erişilebilirlik

Full-screen gökyüzü/palet/kapalı menü korunur. `viewport-fit=cover` ve safe-area inset'leri birlikte kullanılır; üst arama/marka, alt konum/zaman, araçlar ve çekmeceler çentik/ana ekran göstergesini hesaba katar. Pencere ve VisualViewport olayları yalnız CSS piksel ölçülerini günceller; astronomik koordinat, zaman veya hesaplama hassasiyetini değiştirmez. Yeni sürekli ölçüm/polling veya kişisel veri toplama yoktur.

Özel seçiciler klavye/pinch sonrası görünen alanın sınırlarında yeniden yerleşir; içerik gerektiğinde kaydırılır. Mobil metin girişleri 16px, temel harita araçları 44px hedef boyutundadır. Kullanıcı yakınlaştırması kapatılmaz. Gerçek iOS klavyesi, çentik, pinch ve VoiceOver/TalkBack ayrıca kabul edilir; viewport taklidi bunların yerine geçmez.

## PWA bağlantı ve güncelleme yaşam döngüsü

Kayıt/denetleyici değişimi ve görünür sayfaya dönüşte aynı kökenli genel bağlantı işareti yeniden denetlenir. Eşzamanlı sorgular tek isteği paylaşır; `credentials: omit` / `no-store` kullanılır. HTTP 200 tek başına yeterli değildir, `online:true` JSON işareti beklenir. Sorgu ve kişisel yanıtlar cache'e eklenmez. İlk kurulumdan sonra geçici `waiting` durumu gerçek güncelleme gibi kalıcı gösterilmez; yeniden açma isteği yalnız halen `installed` bekleyen worker varsa kaydedilir.

Genel paket/katalog/terim/takvim çevrimdışı olabilir; kişisel kayıtlar doğrulanmış hesapla sunucudadır. Aktif PRD'nin eski UJ-07 satırındaki offline not/eşitleme ifadesi K-024 ile uyumlu hale getirildi; kimlik ve arşiv korunur.

## Kabul sınırı

Planlanan fiziksel matris Samsung Galaxy S23 / Android-Chrome ve iPhone 15 / iOS-Safari'dir. Henüz telefonların erişeceği geçerli HTTPS test adresi yoktur. Bu nedenle sensör/kurulum/gerçek klavye sonuçları bekliyor; sertifika uyarısı atlanmaz, güvenli olmayan LAN HTTP sensör kanıtı sayılmaz ve bu ADR otomatik public deploy yetkisi oluşturmaz.

[Uygulama ve kanıt](../responsive-cihaz-ve-pwa-kabulu.md), [telefon oturumu](../telefon-kabul-oturumu.md).
