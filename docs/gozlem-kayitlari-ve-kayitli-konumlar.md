# TECH-06 — Hesapta gözlem kayıtları ve kayıtlı konumlar

**1 Kasım 2026 — K-026 / PRD 1.9 / ADR-0011.** Kullanıcının onayladığı P0 devam dilimi uygulandı. [Veri ve anlam sözleşmesi](adr/0011-gozlem-kaydi-ve-kayitli-konumlar.md); [bütün gereksinimler ve kalanlar](teslimat-izlenebilirligi.md).

## Kullanıcıya sunulan davranış

Defterim'de favori/not yanında **Gözlemler** ve **Kayıtlı konumlar** var. Hepsi yalnız e-postası doğrulanmış hesabın PostgreSQL kayıtlarıdır; oturum olmadan kaydetme giriş/kayıt kapısını açar. JSON, IndexedDB veya localStorage uygulamanın kişisel veri deposu değildir. JSON düğmesi sunucudan taze liste alıp kullanıcının açık isteğiyle dosya indirir.

Gözlem için açıklama ve “gerçekten yaptığım gözlem” beyanı gerekir. Kullanıcı metni kişisel bildirimdir; bilimsel doğrulanmış tespit etiketi verilmez. Nesne, gerçek gözlem anı ve konum ayrı isteğe bağlı alanlardır, yeni kayıtta kapalıdır. Gerçek saat seçilmezse “Kaydedilmedi”; sistem oluşturma zamanı ayrı gösterilir. Simülasyon veya takvim zamanı buraya kendiliğinden yazılmaz.

Gerçek saat ekleme, ortak özel tarih/saat/IANA kontrollerini kullanır. Tarih/saat/dakika boş başlar. DST boşluğu ve belirsiz tekrar saati reddedilir; tekrar için oluşum seçilebilir. Gelecek gözlem sunucuda da reddedilir. Geçmiş kayıt tarihi astronomi hesap aralığıyla karıştırılmaz. Formu listeye alıp yeniden açmak veya dili değiştirmek açık sayfa taslağını korur; sayfa yenilemede taslak kalıcılığı vaat edilmez. Değiştirilmeyen eski gözlem anı saniye hassasiyetini korur.

Konum kaydı için yalnız enlem/boylam gerekir; ad/açıklama/yükseklik isteğe bağlıdır. Yeni alanlar boştur, İstanbul yalnız placeholder örneğidir. Harita koordinatını kopyalama açık düğmedir. Bilinmeyen yükseklik `null` kalır; elipsoidal/deniz seviyesi ayrımı yeni kaynaklı iki dilli terime bağlıdır. **52 terim**, cache `2026-10-31.7`; diğer 51 kimlik korunur.

Gözleme eklenen kayıtlı yer bağımsız kopyadır. Yeri düzenlemek/çöpe taşımak/geri yüklemek eski gözlemi değiştirmez. “Haritada kullan” konumu manuel bağlam olarak uygular; UTC anı, zaman modu, seçili nesne ve kamera değişmez. Konum düzenleyicisindeki “Kayıtlı konumlarım” aynı hesap envanterine gider. GPS ölçüm meta verisi yeniden kullanılmış koordinata yapıştırılmaz.

## Uygulama

- Notebook Domain/Application/Infrastructure modül sınırları, CQRS/MediatR ve mevcut hesap oturumu korunur. Sahiplik/revizyon/çöp kutusu bütün türlerde aynıdır; tür sessiz değiştirilemez.
- `ObservedAtUtc`/`ObservationConfirmed` eklendi; eski not/favoriler aynı kalır. Migration `20261031205237_ObservationsAndSavedPlaces` yerel DB'ye uygulandı; EF bekleyen model değişikliği yok.
- `InventoryPanel`, `ObservationTimeField`, boş değer destekli `DateField` ve saf konum/zaman yardımcıları eklendi. Varsayılan browser select/date/time kontrolü kullanılmadı. Yoğun yazmada yeni taslağın geç yanıtla kaybolmasına karşı formlar bekleme süresince devre dışıdır.
- Dışa aktarma `yorungez-notebook` sürüm 2: dört tür, gerçek gözlem zamanı, bağımsız konum kopyası ve çöp kutusu bilgisi. İçe aktarma/kalıcı silme bu dilimde yoktur.

## Kanıt

**120 .NET testi** geçti: 18 çekirdek, 19 astronomi, 83 API/gerçek PostgreSQL–Redis entegrasyonu. Yeni 14 API vakası minimum gözlem, zorunlu kişisel beyan, gelecek/mixed tür reddi, 1988 tarihinin UTC korunması, hesap sahipliği, revizyon çakışması, türün değiştirilememesi ve kayıtlı yer düzenleme/çöp/geri yükleme sonrası gözlem kopyasını kapsar. Notebook katman/modül bağımsızlığı mimari testine eklendi; hedefli tekrar geçti. Önceki SMTP testleri fake/Mailpit kullanır.

**38 istemci testi**, Next üretim derlemesi ve TypeScript kontrolü geçti. Yeni yardımcı testleri koordinat hassasiyeti/bilinmeyen yükseklik, GPS meta verisinin kopyalanmaması, açık tarih/saat/DST, dört tür ve dışa aktarma v2 sözleşmesini kapsar. Arayüz taslağının tarih/saat koruması ayrıca üretim önizlemesinde kontrol edildi.

Yerel IAB önizlemesinde yalnız sentetik geliştirme hesabı ve örnek koordinatlar kullanıldı:

1. Eski not/favori migration ve sunucu yeniden başlangıcından sonra korundu. Zamanı bilinmeyen gözlem ve hassas koordinatlı/yüksekliği boş konum hesaba kaydedildi.
2. Kayıtlı yer 41.0123456789/28.987654321'den 40.1/29.2'ye düzenlendi, çöp kutusuna taşınıp geri alındı; gözlemde ilk ad/koordinatlar kaldı.
3. Gözleme zaman eklemede boş alanlar görüldü, eksik giriş reddedildi. Özel kontrollerle 30 Ekim 2026 20:15 UTC girildi; listeye dönüp taslağı açınca aynı alanlar korundu, kayıt sonrası gerçek an/sistem zamanı ayrı gösterildi.
4. Jüpiter seçili ve simülasyon 1 Kasım 2026 07:52 UTC iken kayıtlı yer uygulandı; aynı an/mod/hedef/kamera korundu, hesap yeni konuma göre yenilendi.
5. TR/EN geçişi, boş konum formu, yükseklik terimi/NOAA bağlantısı, panelden geri dönüş ve dil değişiminde açık taslağın korunması kontrol edildi. Kullanıcı metni çevrilmedi.
6. Arayüzden indirilen JSON v2 dört türü, gerçek UTC anını ve yerden bağımsız gözlem kopyasını içerdi. Oturum kapatıldığında hesap kapısına dönüş kontrol edildi.

[İngilizce gözlem/konum ekranı](ux/inventory/observations-en.png), [Türkçe ekran](ux/inventory/observations-tr.png) ve [makine okunur kayıt](science/inventory-browser-qa.json). Geliştirici önizlemesi gerçek mobil, ekran okuyucu, kullanıcı araştırması veya üretim yükü testi değildir. 390 px/telefon kabulü iddia edilmedi. 502 yerel belge/dosya bağlantısı ve bütün 12 FR/7 UJ/14 AC kimliği doğrulandı; başlangıç arşivinin SHA-256 özeti değişmedi. Deneme hesabından çıkıldı, ajan sekmesi ve önizleme/API süreçleri kapatıldı; bu Compose projesi durduruldu, volume/veriler korundu.

## Bilimsel ve işletim sınırları

Astronomi algoritması/katalog koordinatları/takvim olayları bu paketle değiştirilmedi. Önceki 144 Astropy yıldız/72 DSO, 1168 JPL karşılaştırması içindeki korunmuş iki kutup yön istisnası, abs(enlem)≥89 azimut koruması, 1781 USNO evresi ve 22 standart doğuş-batış referansının sınırlı kapsamı devam eder. Kişisel kayıt bilimsel modelin doğrulama verisi sayılmaz.

Kullanıcının gerçek GPS verisi/sensör izni alınmadı. Gerçek e-posta gönderilmedi; UI kontrolünde Mailpit ve kapalı outbox worker kullanıldı. Gmail sırrı özel `.env` içinde değişmeden kalır; İngilizce varsayılan/İngilizce markalı mail korunur. Genel offline/PWA henüz uygulanmadı; özel kayıt için ağ gerekir.

## Sıradaki somut iş

P0'daki **genel katalog için PWA/çevrimdışı yeniden açılış**: ilk ağsız açılış, sürümlü genel cache, eksik panorama/içerik ve güncelleme akışı. Özel hesap/not/konumlar cache veya offline kuyruğa alınmayacak. Bunun yanında [fiziksel GPS/pusula/erişilebilirlik protokolü](cihaz-konum-pusula-dogrulamasi.md) gerçek cihazla yürütülecek; üretim DB yedek/geri yükleme, kalıcı temizleme/içe aktarma/kota ve ek takvim olaylarının kaynak doğrulaması açık kalır. Bütün MVP-0/P0 tamamlandı denmez.
