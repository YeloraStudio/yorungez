# TECH-02B / TECH-03 — İlk çalışan harita ve katalog denemesi

**Sonraki güncel paket:** [TECH-04C çizelge/takvim/yer adı/saydam geniş açı](gozlem-cizelgesi-ve-takvim.md). Aşağıdaki sayılar ve ekranlar bu belgenin kendi aşamasının tarihsel kanıtıdır; yeni kapsam ve kalanlar güncel kayıtta tutulur.

**Tarihsel TECH-02B/03 kaydı:** Bu aşamanın 82 .NET/9 istemci, 28 terim ve panel/GPS yokluğu sonuçları aşağıda korunur. Sonraki TECH-04 tam ekran/konum/IANA/Wikipedia/107 DSO/85 çizim ve 84+19 test sonucu [güncel geliştirme kaydındadır](tam-ekran-harita-gelistirmesi.md).

**31 Ekim 2026.** [ADR-0004](adr/0004-ilk-harita-ve-parlak-katalog.md), [gereksinim izlenebilirliği](teslimat-izlenebilirligi.md). Bu kayıt ilk dikey prototipin kanıtıdır; bütün MVP-0/P0 veya fiziksel mobil doğrulama değildir.

## Teslim edilen akış

Next.js 16.4.3/React 19.3.1/TypeScript 5.9.3 ile `/tr`, `/en`: etiketli örnek konum → manuel ondalık koordinat → canlı/UTC simülasyon → yıldız/gezegen/takımyıldız haritası → ad/HIP/HYG/IAU kimliğiyle arama veya haritadan seçim → aynı kimlikli bilgi kartı. Canvas 2D, stereografik görünüm, pan/zoom/klavye, çizgi/ad/ızgara katmanları ve gece görünümü vardır. Mobil alt panel ve masaüstü yan panel kullanılır. Olaylar/Defterim planı korunur; bu ekranlar henüz uygulanmadığı için ilgili düğmeler devre dışıdır. Keşfet şimdilik ortak aramaya odaklar, tam atlas bölümü değildir.

5073 yıldız + dokuz Güneş Sistemi hedefi + 88 şematik figür aynı Worker karesinde hesaplanır. Float64 gözlem bağlamı/astronomik çıktı; yalnızca projeksiyon pikselleri Float32. Kart ve harita aynı sonucu kullanır. Sıra numarası önceki bağlam yanıtını engeller; beklerken önceki hesap etiketi görünür. GPS/sensör/konum paylaşımı/kalıcı kayıt eklenmedi. Koordinatlar URL, localStorage veya ağ isteğine yazılmaz; sentetik test verisi kullanıldı.

İlk kaynak HYG 4.1 ve d3-celestial verisidir; tam revizyon/hash/atıf [manifestte](../data/catalog/manifest.json), lisanslar ve türetme işlemleri [veri kaydında](../data/catalog/README.md). API `GET /api/v1/catalog/sky` MediatR/Catalog sınırından döner, DB/cache gerektirmez. Next BFF `/api/catalog` aynı hash'li yerel pakete düşebilir, terimlerle birlikte zayıf ETag kullanır. API çalışırken iki paket SHA eşliği ve BFF 304; API durdurulduğunda aynı katalog + 28 terim doğrulandı. Bu sunucu fallback'i tam tarayıcı offline desteği değildir.

## Bilimsel yöntem ve sınırlar

Yıldız vektörü: J2000 Kartezyen konum + TT yıl farkı × uzay hızı, Dünya barycentrik konumu ve gözlemci vektörünü çıkararak paralaks, birinci dereceden yıllık aberasyon, Astronomy Engine EQJ→HOR rotasyonu. Basınç/kırılma yok; yüksekliğin bilinmediği örnekte 0 m açık varsayımı. Bilinmeyen radyal hız 0; bilinmeyen uzaklık katalogda `null`, hesapta uzak kaynak vektörü. Kaynak özdevinim ve doğruluk hataları giderilmiş varsayılmaz. Diurnal aberasyon, kütleçekimsel ışık sapması, canlı Dünya yönelimi, hava/arazi modeli yoktur. Takımyıldız merkezi çizim düğümlerinin şematik ortalamasıdır; fiziksel gökcismi veya IAU sınırı değildir. Güneş/Ay/gezegen yolu aynı Worker'da Astronomy Engine 2.1.19 kullanır, [önceki JPL sınırları](astronomi-denemesi.md) korunur.

Bağımsız dönüşüm kontrolü: Astropy 8.0.2 / ERFA `apply_space_motion` ve kırılmasız `AltAz`; 12 yıldız × dört yer × üç an = 144. [Donmuş referans](../tests/ReferenceData/Stars/README.md) ve [sayısal rapor](science/star-reference-report.json). Maksimum açısal ayrım **0,307578 yay dakikası**, maksimum yükseklik hatası **0,264807 yay dakikası**; başlangıç hedefi 1 yay dakikası. Bu örnekler bütün 5073 yıldızın doğruluğunu ispatlamaz. 2035 için IERS/polar motion ve gelecekteki leap-second varsayımlarına ait altı uyarı türü raporda aynen korunur. Normal test internete çıkmaz/referansı yeniden üretmez. [Astropy yöntem belgesi](https://docs.astropy.org/en/stable/coordinates/apply_space_motion.html).

ADR-0003'teki ±89,9° başarısızlıkları silinmedi. abs(enlem)>=89 için hedefler çizilmez, kart azimutu `—`, yükseklik ve iki dilli neden korunur. Matematiksel ufkun üzeri, fiziksel gözlem koşulları ve çıplak gözle algılanabilirlik farklıdır; bilinmeyen koşullar açıkça yazılır. Katalog kesmesi/harita işareti görünürlük garantisi değildir.

## Çizim deneyi

Üretim derlemesi, Node v22.20.0, Windows geliştirme ortamından IAB tarayıcısı, DPR 1. Tarayıcı yüzeyleri 1440×900 ve 390×844; dar yüzey fiziksel telefon değildir. 5082 ortak yıldız/gezegen, 105° görüş, aynı 150 adımlı bakış; 30 ısınma + 120 ölçüm. Ortak CPU projeksiyonu ve yalnızca nokta katmanının gönderimi ölçülür; etiket/çizgi/ufuk/DOM/Worker maliyeti ve GPU tamamlanması kapsam dışıdır. Ham `viewport.width/height` alanı tarayıcının değil çizim yüzeyinin ölçüsüdür.

| Çizici | Masaüstü CPU p95 | Dar yüzey CPU p95 | 25 ms üzeri rAF aralığı masaüstü/dar |
|---|---:|---:|---:|
| Canvas 2D | 0,3 ms | 0,3 ms | 0 / 0 |
| SVG | 5,8 ms | 4,6 ms | 0 / 1 |
| WebGL | 0,7 ms | 1,0 ms | 0 / 0 |

Ham sonuçlar: [masaüstü](science/renderer-desktop.json), [dar yüzey](science/renderer-mobile-viewport.json). IAB rAF zamanlaması fiziksel ekran yenilemesi olarak yorumlanmaz; bu sayılardan gerçek FPS veya telefon bütçesi üretilmez. İlk seçim Canvas 2D; Stellarium/Aladin kurulup ölçülmedi, onların hızlarıyla bir karşılaştırma iddiası yoktur. Saf Node yıldız hesabının ayrı 100 batch ölçümü yıldız raporundadır; çizim süresi değildir. Katalog JSON ham 2.091.661 bayt; transfer sıkıştırması/ağ/ilk açılış ve gerçek mobil bellek bütçesi henüz ölçülmedi.

## Doğrulama kanıtı

- **82 .NET testi:** 18 çekirdek + 19 astronomi + 45 API/entegrasyon. Yeni katalog testleri TR/EN kimlik/düğüm/sentinel, olmayan DB/cache ile anonim kullanım ve ETag 304'ü kapsar. Mevcut kimlik testleri gerçek yerel PostgreSQL/Redis ile geçti. Release derleme ve Next üretim derlemesi geçti, TypeScript kontrolü temiz.
- **9 istemci testi:** veri hash/88 kimlik/tüm düğümler, 144 Astropy ve donmuş JPL konumları, gerçek Worker hesap yolu, hassas bağlam/sıra numarası, hatalı takvim/ofset/sıfır koordinatı, projeksiyon yönü, hedef hit-test ve eş TR/EN anahtarları. [Test kaynağı](../src/Yorungez.Web/tests/sky.test.ts).
- Son kontrolde Güneş'in arama/öneri sınıfı gezegen yerine yıldız olarak düzeltildi; Ay ayrı korunur, aynı yardımcı kartta da kullanılır. Dil/etiket testine bu bilimsel sınıflandırma kontrolü eklendi. `Start-Web -Production` ana harita 200, varsayılan kapalı laboratuvar 404 verdi. `npm audit --omit=dev` ve NuGet transitif güvenlik bildirimi sorgusu mevcut kaynaklarda bilinen açık bildirmedi; bu tam güvenlik incelemesi değildir. `python scripts/verify_docs.py` 178 yerel bağlantı, 12 FR/7 UJ/14 AC kapsamı ve arşiv SHA'sını doğruladı.
- Tarayıcı üretim denemesi: geçersiz 91° reddi, ondalık virgül, 12 basamaklı örnek koordinatın dil değişiminde aynen korunması, UTC 2026-10-30 20:00 simülasyonu, şimdiye dönüş, klavye sağ ok, Sirius HIP32349→hyg-32263, Satürn arama ve harita merkezi→`saturn`, aynı kart. Tarih alanının görünen değeri yerine önceki React taslağını uygulama hatası bulundu; native FormData ile düzeltildi ve aynı test tekrar geçti.
- Dil değişimi seçili an/mod/hedef/kamera ve katmanları korudu; sayılar/tarih yerelleşti. Karttan Azimut açıklaması Enter ile açıldı; ESC sonrası odak kaynak düğmesine döndü. 390×844 denemesinde yatay taşma yok (375 px içerik + scrollbar), harita/alt panel incelendi. Son üretim akışında konsol error/warn yoktu. Kutup bölgesinde yön verilmedi; sıfır koordinatı çalıştı. Bunlar fiziksel dokunma/pinch, ekran okuyucu veya bütün WCAG AA kontrolü değildir.

Ekran kanıtları: [Türkçe masaüstü](ux/prototype/desktop-tr.png), [İngilizce dar ekran](ux/prototype/mobile-en.png). Kaynak bağlamı sentetik/örnektir; screenshot gök fotoğrafı veya gerçek kullanıcı ölçümü değildir.

## Tekrar çalıştırma ve kalan işler

```powershell
./scripts/Verify-Backend.ps1
./scripts/Verify-Web.ps1
# Aynı .next klasörünü kullanan sunucuları önce kapat:
./scripts/Start-Web.ps1 -Production -EnableLab
# Tarayıcı: /tr/lab/renderers; Denemeyi çalıştır.
# Test bitince Ctrl+C; yalnızca bu projenin servisleri:
docker compose stop
```

Bilimsel yıldız raporu: `node --experimental-strip-types tools/science-js/star-probe.mjs`; bu `.local/catalog/star-report.json` yazar. Yayımlamak açık çıktı argümanıyla yapılır. Katalog/referans yenilemesi ayrı, açık işlemdir; [Web rehberi](../src/Yorungez.Web/README.md). Laboratuvar varsayılan kapalıdır; üretim ürünü özelliği değildir.

**Sonraki:** TECH-04 GPS izin/doğruluk/ölçüm zamanı ve cihaz yönü/kalibrasyon, manuel alternatifler, fiziksel cihaz protokolü. PWA/service worker/offline yeniden açılma, ekran okuyucu, mobil tam kare/ilk açılış/bellek ölçümü ve kullanıcı görevleri açık kalır. Geleneksel Güneş/Ay doğuş-batış, evre ve görünürlük derinliği ayrı bilimsel iştir. P0 kişisel kayıt/hesap ekranları/açık onaylı aktarım/çatışma/eşitleme planı ve bütün FR/UJ/AC kapsamı korunur; SMTP Gmail placeholder'dır.
