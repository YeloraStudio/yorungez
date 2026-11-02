# TECH-11F — Özgün 4K arazi panoraması

**3 Kasım 2026 / K-040.** FR-02/08/09, UJ-06/07 ve AC-03/11/12. Kullanıcının 4K/8K sorusu üzerine mevcut fotoğrafın özgün 4K ayrıntısı çizimde açıldı; yeni arazi veya bilimsel model seçilmedi. Önceki P0/P1/P2, K-039 Web sonrası aynı backend ile mobil hedefi ve K-032 deployment beklemesi korunur.

## Kaynak ve çizim arasındaki sınır

Stara Lesna Meadows kaynak PNG'si zaten **4096×2048 / 12.365.293 bayt**. Önceki çizim bunu GPU'ya **2048×1024** olarak yüklüyordu. Şimdi kaynak ve GPU sınırı uygunsa **4096×2048** yüklenir; 4K doku tahsisi başarısızsa sırasıyla 2K/1K/512 denenir. Tam başarısızlık veya bağlam kaybında açıklamalı sade harita yolu korunur. Kaynaktan büyük görüntü üretilmez. Bu genişlik 360° panoramanın tamamına aittir; her yakınlaştırılmış görüşün ayrı bir 4K fotoğraf olduğu anlamına gelmez.

- Özgün fotoğraf/SHA/atıf/lisans değiştirilmedi; yeni indirme veya normal build sırasında dış veri alımı yok.
- Tam fotoğraf yalnız arazi GPU geçişine yüklenir. Atmosfer geçişi artık gereksiz ikinci büyük fotoğraf kopyasını tutmaz.
- CPU örtüşme örneklemesi önceki 2048×1024 boyutunda/aynı alfa eşiğinde kalır; RGB yerine yalnız **2 MiB alfa maskesi** saklanır. Haritanın ufuk altı saydamlığı ve geometrik görünürlük anlamı değişmez.
- Başlangıç astronomi karesi fotoğrafı beklemez. GPU sınırı/tahsis hatası kontrolleri yüklemede yapılır; her kareye sorgu eklenmez. Bağlam kaybında maske ve çözünürlük tanısı temizlenir.

4K RGBA dokunun temel piksel içeriği yaklaşık **32 MiB**, 8K (8192×4096) için **128 MiB** olur; sürücü, framebuffer ve decode maliyetleri bu hesaba dahil değildir. GPU'nun boyutu desteklemesi performans veya boş bellek garantisi değildir. [WebGL bellek/tahsis rehberi](https://developer.mozilla.org/en-US/docs/Web/API/WebGL_API/WebGL_best_practices). Gerçek S23/iPhone FPS/bellek kabulü hâlâ açık.

**8K henüz uygulanmadı.** Mevcut dosya 4K'dır; 8K'da ek fotoğraf ayrıntısı için gerçek yüksek çözünürlüklü, uygun lisanslı şeffaf panorama gerekir. Aynı kaynağı büyütüp gerçek 8K ayrıntı varmış gibi sunulmaz. Böyle bir kaynak seçilirse atıf/hash, ağ/PWA boyutu ve cihaz bütçesi ayrıca doğrulanacak; bu kayıt kaynak değişimini kesinleştirmez.

## Doğrulama

- **64 istemci testi**, tip kontrolü ve üretim derlemesi geçti. Yeni regresyonlar: özgün 4K, GPU sınırına uyma/kaynağı büyütmeme, başarısız 4K tahsisinde daha küçük dokuya dönüş ve bütün tahsislerin reddinde sade yol. Önceki yıldız/DSO/JPL örnekleri test paketinde korunur.
- Tarayıcıda yeni PWA paketi açık güncelleme akışıyla etkinleştirildi; arazi DOM tanısı **`4096x2048`**, GPU fallback yok. Örnek İstanbul konumu/işaretli öğle simülasyonu kullanıldı; gerçek kullanıcı koordinatı veya sensörü alınmadı.
- Varsayılan masaüstü ve **390×844** dar viewport kontrolünde 4K doku yükü/taşma yokluğu doğrulandı. Dar viewport fiziksel telefon kabulü değildir.
- PWA paketi **`b457d4df4ddf5e24d508`**: 68 çekirdek dosya/~5,3 MiB, 100 isteğe bağlı görsel/~14,1 MiB. Panorama dosyası değişmediği için görsel indirme boyutu artmadı. Tam soğuk offline/eviction/gerçek cihaz protokolünün tamamlandığı iddia edilmez.

[Masaüstü](ux/panorama-4k/desktop.jpg) · [Dar ekran](ux/panorama-4k/mobile.jpg). Ekran görüntülerindeki fotoğraf **Ľubomír Hambálek / Stara Lesna Meadows** kaynaklıdır; [atıf ve ayrı CC BY-SA 4.0 liste / CC BY 4.0 arşiv kayıtları](../third-party/stara-lesna/NOTICE.md) korunur. Fotoğraf kullanıcının gerçek arazisi veya ölçülmüş ufku değildir.

## Commit/push kapsamı

Önceki plan denetimi PR #16 ile ana daldaydı. Yerelde kalan `GlossaryRepository.cs` farkı yalnız `using` sıralamasıydı; işlev değiştirmediği kontrol edilerek bu yayın paketine dahil edilir. Ortam dosyaları, SMTP sırrı, anahtarlar, kişisel veriler ve `.local/` Git dışında kalır. Uygulama deployment'ı yapılmaz.
