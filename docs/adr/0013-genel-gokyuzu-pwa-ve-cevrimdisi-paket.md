# ADR-0013 — Genel gökyüzü PWA ve çevrimdışı paket

**1 Kasım 2026 / K-028 / TECH-07 / PRD 1.10 — Uygulandı; tarayıcı kabulü sınırlı.**

İz: FR-02–04/FR-08–09/FR-11–12; UJ-01–03/UJ-07; AC-01/AC-03/AC-05/AC-09–14; SN-D01–04. [Hesap zorunlu kişisel veri kararı](0010-hesap-zorunlu-defter-ve-sunucu-kayitlari.md) korunur.

## Paket ve kaynak

Next.js Web App Manifest, mevcut marka simgesinden üretilmiş 192/512 PNG ikonlar ve bir service worker eklenir. Üretim derlemesi genel TR/EN gökyüzü HTML'ini statik üretir; sunucu oturum veya kullanıcı verisini HTML'e gömmez. Hesap e-posta işlem sayfaları dinamik/no-store kalır.

Mevcut hash doğrulamalı tek katalogdan genel `catalog.json`, iki dilde 52 terim ve aynı 2623 olayı taşıyan `calendar.json` üretilir. Astronomi motoru ve kaynak verisi değiştirilmez. HTML/CSS/JS/Worker/font ve genel JSON'lar build sırasında SHA-256/byte envanterine girer. Dil route'larındaki kodlanmış `%5Blang%5D` dosya yolları açıkça eşlenir; HTML'in bütün statik bağımlılıklarının pakette olduğu derlemede doğrulanır. Worker/pack dosyaları aktif `.next` veya `.next-preview` çıktısından sunulur; ayrı önizleme başka derlemenin SW dosyasını kullanmaz.

Kurulumda her çekirdek yanıtının başarılı, genel ve SHA eşleşmeli olması gerekir. Tamamlanamayan yeni paket kaldırılır, önceki çalışan paket korunur. Çekirdek yaklaşık 4,2 MiB; mevcut derlemede 51 dosya. Kaynaklı panorama/85 çizim/Güneş görselleri toplam 88 dosya, yaklaşık 12,7 MiB ayrı genel görsel paketidir. Görünen genel fotoğraf/çizim istenince önbelleğe alınabilir; tamamını hazırlamak açık kullanıcı eylemidir. Görseller eksikse hesap çalışır, sade çizim ve eksik içerik açıklaması korunur. Kaynak/atıf/lisans metinleri genel paketle erişilebilir kalır.

## Sınırlar ve mahremiyet

Cache Storage'a yalnız aynı kökenli, açık envanterdeki GET kaynakları girer. POST, RSC, Range, sorgu parametreleri ve kişisel yanıtlar cache'e girmez. Önbelleğe alınacak yanıtta private/no-store varsa işlem reddedilir. Kurulum isteği `credentials: omit` kullanır. `me`, profile, oturum/token, isim/e-posta, not/gözlem/kayıtlı konum, koordinat POST'ları ve kişisel taslaklar kalıcı offline veri değildir. Otomatik offline yazma/yeniden gönderme kuyruğu yoktur.

OSM döşemeleri/toplu indirme, Wikipedia ve diğer dış içerikler pakete alınmaz. Yer adı ve coğrafi saat dilimi servisleri çevrimdışı çalışıyor sayılmaz; manuel koordinat, açık IANA/UTC seçimi ve görünür UTC alternatifi korunur. İlk ziyaret/önbellek yokluğu bağlantı gerektirir. Tarayıcı depolamayı silebilir; hazırlanmamış veya silinmiş paket çalışıyormuş gibi etiketlenmez. Hesap sayfasına ağsız navigasyon nötr, kaynaklı genel bağlantı açıklaması gösterir; kişisel HTML/JSON yedeği göstermez.

## Sürüm değiştirme

Yeni service worker tamamlanınca bekler. UI kullanıcıya taslaklarını kaydetmesini, diğer Yorungez sekmelerini kapatmasını ve açık güncelleme/yeniden açmayı seçmesini söyler. Worker birden çok pencere açıkken zorla etkinleşmeyi reddeder. Tek pencerede açık eylemle etkinleşir; kullanıcı isteğini kaydeden sayfa controller değişiminde yeniden açılır. İlk kurulum otomatik sayfa yenilemez. Kurulum, yalnız kendisinden önce bulunan genel paket adlarını kendi genel metadata kaydına alır. Yeni sürüm etkinleşirken sadece bu önceki paketler temizlenir; eski worker bekleyen yeni paketi silemez. Metadata kişisel bilgi taşımaz. Bekleyen worker uzun süre durup yeniden başlasa da liste cache içinde korunur. PWA kaydı canlı hesap render'larında her saniye tekrar yapılmaz; ilk hazır gökyüzünden sonra etkinleşir.

Kısmi paket, hash hatası, kota/ağ hatası ve güncelleme için görünür durum/yeniden deneme vardır. Bu sürüm bir üretim dağıtımı, fiziksel telefon kurulumu veya işletim sistemi uçak modu sertifikası değildir. HTTPS/localhost gereksinimi ve platform kurulum farkları [MDN service worker rehberiyle](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API/Using_Service_Workers) uyumludur. Cache API başarı yanıtlarını kendi kendine süzmediği için durum/mahremiyet/hash kontrolleri uygulamada yapılır ([Cache.put](https://developer.mozilla.org/en-US/docs/Web/API/Cache/put)).

[Kanıt ve kalan işler](../hesap-menusu-ve-cevrimdisi-gokyuzu.md).
