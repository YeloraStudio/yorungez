# Harita panellerini küçültme — K-045 / 4 Kasım 2026

Kullanıcı kapsamı: gök cismi bilgi kartı, konum ve saat panelleri; masaüstü ve mobil.

- Ortak CollapseToggle düğmesi TR/EN etiket, aria-expanded, aria-controls ve 44 px dokunma hedefi sağlar. Enter/Space ile çalışır.
- Bilgi kartı başlığı küçülünce görünür kalır; gövde hidden olur. Kapatma ayrı bir işlemdir. Yeniden açma aynı seçimi/görseli/açık ayrıntıları korur; yeni hedef seçimi kartı açar. Samanyolu da aynı kabuğu kullanır.
- Konum küçülünce yer adı kalır, koordinatlar gizlenir. Saat küçülünce canlı/simülasyon durumu ve yerel kısa saat kalır; genişletilince IANA/UTC ayrıntıları geri gelir. Zaman hesabı, gözlemci, harita kamerası ve sensör durumu değiştirilmez.
- Durum yalnız açık sayfa belleğindedir; kişisel tarayıcı kalıcılığı eklenmez. Katmanlar ve yan menü mevcut aç/kapa davranışını korur.

Yerel doğrulama: 65 istemci testi, tip kontrolü ve production/PWA derlemesi geçti. Tarayıcıda masaüstü, 390x844, 320x568 ve 844x390 görünüm; iki dil, bağımsız küçült/aç, Enter/Space, normal cisim ve Samanyolu denendi. 320 px genişlikte DOM ölçümünde yatay taşma yok; küçültülen içerik erişilebilirlik ağacından çıktı. Fiziksel cihaz kabulü yapılmış sayılmaz.

Bu paket Web arayüzüdür; e-posta tanı düzeltmesi ayrı PR #24'te korunur. Canlı yayın ve public CI sonuçları ayrıca doğrulanmalıdır.
