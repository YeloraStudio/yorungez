# yorungez — Web tamamlanma denetimi ve ortak backend ile mobil hedef

**2 Kasım 2026 / K-039.** Kullanıcının yönü: önce web uygulamasını doğrulanmış kabul ölçütleriyle tamamlamak, ardından **aynı backend ve aynı kullanıcı verileriyle mobil uygulama** geliştirmek. Bu kayıt mobil geliştirmeyi başlatmaz veya bir mobil framework seçmez. Mevcut P0/P1/P2 kapsamı, bilgi/görsel önceliği ve deployment beklemesi korunur.

## Denetimin kapsamı ve kanıtı

Başlangıç commit'i `e32287378e71dabf9279fd8f2203f92649bc599a` üzerindeki **79 takip edilen Markdown dosyası / 4585 satır** envanterlendi: güncel gereksinim/karar/yol haritası, keşif/domain/UX, uygulama ve bilimsel kanıt kayıtları, 15 ADR, katkı/çalışma rehberleri, altı üçüncü taraf lisans/atıf dosyası ve özgün arşiv dahil. Dosya/satır/hash listesi [başlangıç envanterinde](audits/2026-11-02-markdown-inventory.json). Bu sayı bu yeni rapor ve sonraki belge değişikliklerinden **önceki** durumu gösterir. Özel ortam dosyaları, üretilmiş çıktılar ve bağımlılıklar bu envantere dahil değildir.

Güncel ve özgün plan, FR-01–12 / UJ-01–07 / AC-01–14 ile açık A-001–014 kararları karşılaştırıldı; API uçları, kimlik seçimi, Next.js servisleri ve istemci hesap/render sınırları koddan kontrol edildi. Eski bir aşamanın test sayısı güncel toplam yerine kullanılmadı. Arşivin SHA-256 değeri `6d748df5dd0777b5570401f1f5bb163b94c2d51567f55c7139b9d42fd4c7c1fc`; özgün belge değiştirilmez.

Son doğrulanmış uygulama temeli [PR #15](https://github.com/YeloraStudio/yorungez/pull/15): **127 .NET testi** (18 çekirdek + 19 astronomi + 90 API), **62 istemci testi**, tip kontrolü/üretim derlemesi ve bilimsel veri bütünlüğü/port eşliği. [Uygulama CI](https://github.com/YeloraStudio/yorungez/actions/runs/41509359520), [CodeQL](https://github.com/YeloraStudio/yorungez/actions/runs/41509360056). Bunlar bu belge denetiminde yeniden çalıştırılmış sonuçlar değildir; test sayısı ürünün tamamlanma yüzdesi değildir.

**Durum dili:** “Uygulandı” çalışan yazılım ve belirtilen kanıt demektir; tüm cihazlar, tüm gökyüzü, üretim veya bütün kabul kriterleri geçti demek değildir. Aşağıdaki açık işler için teslim tarihi veya gerçekleşmemiş performans yüzdesi verilmez.

## Ne planladık, ne yaptık, ne kaldı?

| Alan / iz | Uygulanan bölüm | Eksik veya henüz kabul edilmemiş bölüm |
|---|---|---|
| **Mimari ve altyapı** — §7, ARCH-01 | .NET 10 modüler monolit; Clean Architecture/CQRS, MediatR 12.5.0, PostgreSQL/Redis. Identity, Catalog, Astronomy ve Notebook sınırları mevcut. | İleri veri içeri alma/sağlık/yenileme ve üretim işletim kabulleri. Sekiz mantıksal sorumluluk sekiz servis kurma zorunluluğu değildir. |
| **Tam ekran harita** — FR-02, UJ-01/02/06 | Kapalı sol menü, gri-bordo marka, katmanlar, Worker açılış/kurtarma, pan/zoom/klavye, 0,6°–330° stereografik görünüm, fotoğraf çevre, saydam ufuk altı/aşağı bakış. | Gerçek telefonlarda ölçülmüş tam kare süresi, ilk açılış/bellek/uzun oturum, pinch ve yön değişimi protokolü; geniş katalogda aynı bütçe. |
| **Katalog, arama, kart ve görsel** — FR-03, A-005 | 5073 yıldız, 88 takımyıldız, 9 Güneş Sistemi hedefi, 107 Messier eşleşmesi, 85 kaynaklı çizim. İki dil/kimlik/alternatif ad araması; 13 hedefte yerel kaynaklı arşiv fotoğrafı, diğerlerinde uygun lisanslı ağ fotoğrafı veya açıkça etiketli hesaplanan konum kesiti. Samanyolu geniş galaksi kartı ve Andromeda takımyıldızı/M31 ayrımı var. | Seçilen veri kümesinde **M40, M45, M102** yok; tam Messier ve daha geniş NGC/yıldız kapsamı açık. Bütün nesnelerde doğrulanmış görsel, kısa iki dilli açıklama ve türe uygun fiziksel alanlar tamamlanmadı; ilgili olaylara geçiş ve ileri doğuş-batış kapsamı genişletilecek. Samanyolu için kalibre harita görüntü katmanı yok; geniş galaksiye sahte tek nokta/doğuş-batış atanmaz. |
| **UTC, yerel zaman ve simülasyon** — FR-04, A-014 | Tek UTC anı, konumdan IANA/GMT, yerel/UTC giriş, DST boş/çift saat koruması, canlı/simülasyon ayrımı ve şimdiye dönüş. | IANA/siyasi bölge değişikliklerinin bakım süreci ve daha geniş gerçek cihaz/tarih/konum kabulü. Konum, dil veya bölge değişimi anı sessizce değiştirmemeli. |
| **Bu gece ve takvim** — FR-04/05 | Yalnız Bu gece; konuma bağlı standart 0 m doğuş-batış çizelgesi, hedefe/zamana navigasyon; kaynaklı 2623 olaylık hazırlanmış takvim. | Meteor yağmurları, tutulmalar, asteroit ve Ay–yıldız dahil ek türlerde kaynak/lisans/zaman tanımı ve bağımsız kontrol. Anlık yeni/geçici önemli olay akışı bağlı değil. Gün batımı–gün doğumu aralığı tam astronomik karanlık veya algılanabilirlik modeli değildir. |
| **Bilimsel doğruluk ve gözlem koşulları** — FR-05, A-003/007/009 | Referans karşılaştırmaları, geometrik ufuk/koşul/algılanabilirlik ayrımı, bilinmeyen koşul ve model sınırı açıklamaları. | Astronomik karanlık, Ay ışığı, geniş ufuk/rakım/kırılma örnekleri; daha hassas zaman/Dünya yönelimi değerlendirmesi. Hava/bulut, ışık kirliliği, yerel arazi/engeller ve güvenilir gözlem penceresi P1'de açık. |
| **Konum ve pusula** — FR-01, UJ-06 | İzinli taze GPS, doğruluk/ölçüm zamanı, manuel koordinat/ad/yükseklik, GeoNames yer adı, isteğe bağlı OSM seçimi. Düz telefon pusulası, açık gerçek kuzey hizalaması, eski/göreli/eğik veri korumaları; sensörsüz yön/yükseklik/dürbün rehberi. | Ölçümlü fiziksel GPS, izin sonrası gerçek kuzey/pusula kabulü, yön/eğim/kalibrasyon/geri dönüş; iPhone testi. Kamera AR, WMM/manyetik sapma düzeltmesi ve sürekli kamera takibi uygulanmadı; hepsi ilk sürümün zorunlu bağımlılığı olarak seçilmedi. |
| **Hesap ve kişisel envanter** — FR-06/07, UJ-04/05 | Ad/soyad/e-posta/parola, doğrulama, giriş/sıfırlama/refresh/çıkış; hesabın sunucu not/favori/gözlem/kayıtlı konumu. Sahiplik, revizyon çakışması, geçmişi koruyan konum kopyası. | İki dilde gerçek cihaz tam hesap yolculukları ve üretim oturum kabulü; ileri olay/ekipman/çoklu hedef bağları. Yeni kalıcı silme/kota/içe aktarma çalışması **K-037 ile ertelendi**; mevcut çöp/geri yükleme/export korunur. Anonim veya çevrimdışı kişisel kalıcı yazma geri gelmez. |
| **E-posta** — FR-07/11, K-025 | Özel yerel SMTP yapılandırması; TLS/AUTH kontrolü, markalı İngilizce HTML + düz metin. Varsayılan uygulama/API dili İngilizce, açık Türkçe seçimi korunur. | Gerçek alıcıda teslim/istenmeyen posta ve mail istemcisi görünüm kabulü. TLS/AUTH başarısı ileti teslimi kanıtı değildir; kullanıcı ayrıca istemeden gerçek alıcıya test gönderilmez. |
| **Canlı veri ve kaynak yönetimi** — FR-08 | Canlı göksel hesap; katalog/olay kaynağı, sürümü ve özgün hazırlanma tarihi; hash/ETag, hata/tekrar deneme, eski sonuç korumaları. | Sağlayıcı başına son başarılı alım, sağlık/gecikme, kontrollü içeri alma ve zamanlanmış güncelleme. Normal build/test veri indirmez. Canlı hesap yapılıyor olması tüm katalog/olayların sürekli dış API'den geldiği anlamına gelmez. |
| **PWA ve genel çevrimdışı içerik** — FR-09, UJ-07 | Hash doğrulamalı yalnız genel paket; iki dil shell/katalog/terim/takvim ve hazırlanmış görseller; sürüm/güncelleme korumaları. S23 Chrome/Brave ve PWA ekleme/genel kullanım için kullanıcı olumlu bildirdi. | Tam soğuk açılış/güncelleme-hatası/kota/eviction kabulü, iOS kurulum/offline ve uzun oturum/enerji testleri. Kişisel API, hesap HTML'i, token ve özel koordinatlar PWA cache'ine girmez. |
| **İki dil, sözlük ve erişilebilirlik** — FR-11/12, AC-13/14 | EN/TR ürün/hesap ekranları ve 52 kaynaklı terim; ortak sözlük, ayrı statik sayfa, iki dilden arama, sabit terim bağlantısı ve offline kapsamı. Klavye/form/odak için ilk düzeltmeler var. | Bütün hesap/defter/gece/takvim/hata/boş/offline yollarında iki dil E2E; gerçek TalkBack/VoiceOver/masaüstü okuyucu, kontrast/büyütme ve WCAG 2.2 AA kabulü. Geniş sağlamlaştırma paketi şimdilik ertelenmiş olsa da kabul hedefi iptal edilmedi. |
| **SEO ve dünya çapında erişim** — FR-03/09/11, §8 | Gerçek `/en` ve `/tr` yolları, statik sözlük, temel title/description/manifest/icons/html lang; dil değişiminde belge dili/başlığı güncellenir. | Canonical/hreflang, sitemap/robots, sosyal önizleme, herkese açık nesne içerik URL'leri ve özel hesap/lab indeksleme politikası için tamamlanmış paket yok. Yayın kökeni seçilince gerçek indeksleme/uluslararası erişim ölçülmeli. |
| **Performans ve kullanılabilirlik** — §8, DISC-03 | Otomatik test, sınırlı geliştirici tarayıcı/dar ekran kontrolleri ve olumlu sahip geri bildirimi var; sekiz görev kartı/35 sınır durumu hazır. | LCP ≤2,5 sn / INP ≤200 ms / CLS ≤0,1 ve harita cihaz bütçesi gerçekleşmiş olarak ölçülmedi. Temsilî görev oturumu/başarı eşikleri ve dünya çapında üretim gecikmesi açık. |
| **Yayın, güvenlik ve işletim** — A-001/006/010 | Apache-2.0 kod/belge, ayrı veri/görsel lisansları, public kaynak repo, korumalı kontroller; yerelde sentetik PostgreSQL/keyring geri yükleme provası var. | Public deployment/domain/DNS/HTTPS/Portainer **K-032 ile kullanıcı haber verene kadar bekliyor**. Gerçek üretim yükü, gözlemlenebilirlik, proxy/origin/anahtar/secret işletimi ve üretim kurtarma kabulü tamamlanmadı. |
| **İleri uzmanlaşma** — FR-10/P2 | İsteğe bağlı kapsam ve modül sınırı tanımlı. | Dürbün/teleskop profilleri, görüş alanı simülasyonu, ileri koordinatlar ve planlama/analitik henüz uygulanmadı. Temel keşif ekipmana bağlanmaz. |

## Bilimsel kabulün mevcut sınırı

- İlk teknik model aralığı **2000-01-01 dahil, 2036-01-01 hariç**. Daha geniş tarih desteği bağımsız doğrulama olmadan tamamlandı sayılmaz.
- 1168 JPL karşılaştırması/port eşliği raporunda **iki özgün kutup yön başarısızlığı korunur**; API `abs(enlem) >= 89°` için azimut sunmaz. Bu kısıt test eşiği gevşetilerek kapatılmaz.
- 144 yıldız ve 72 DSO bağımsız Astropy örneği, belgedeki 1 yay dakikası toleransıyla doğrulandı. 1781 USNO ana Ay evresinde en büyük fark 79,946 sn (120 sn sınırı); 22 standart doğuş-batış örneğinde 25,48 sn (180 sn sınırı). Bunlar her nesne/yer/gün için eksiksiz kabul değildir.
- Harita hava kırılmasız merkez konumu, çizelge standart 0 m doğuş-batış varsayımı kullanır. Fotoğraf çevre kullanıcının gerçek arazisi, yıldız halesi kalibre fotometri, arşiv nesne fotoğrafı seçili andaki görünüş değildir.

Kaynak ve yöntem: [hesap denemesi](astronomi-denemesi.md), [katalog denemesi](harita-ve-katalog-denemesi.md), [çizelge/takvim](gozlem-cizelgesi-ve-takvim.md), [donmuş referanslar](../tests/ReferenceData/README.md). Erişilebilir ve bilimsel olarak anlaşılır hata/sınır açıklaması doğruluğun bir parçasıdır.

## PWA ve telefon kabulünün doğru durumu

Son test edilen paket `2d7195b7d24710660484`: **68 çekirdek dosya / yaklaşık 5,3 MiB**, **100 isteğe bağlı görsel / yaklaşık 14,1 MiB**. 13 yerel fotoğraf hedefi tüm katalogdaki her nesnede gerçek fotoğraf var anlamına gelmez.

Kullanıcının S23 Chrome/Brave ve PWA genel kullanım bildirimi olumlu; OS/tarayıcı sürümleri, ölçümlü GPS ve tam senaryo kaydı alınmadı. Pusula hatasında Chrome **Hareket sensörleri engeli** doğrulandı. İzin değiştirildikten sonraki başarılı gerçek yön ölçümü henüz bildirilmedi. iPhone 15/Safari kabulü bekliyor. Bu nedenle “hiç fiziksel deneme yapılmadı” da “tüm mobil kabuller geçti” de güncel durumu anlatmaz. [Ayrıntı](mobil-kart-samanyolu-ve-pusula-erisim.md), [cihaz protokolü](telefon-kabul-oturumu.md).

## Aynı backend ile mobil uygulama: hazır olan sınır ve açık işler

**İkinci bir kullanıcı/veritabanı sistemi gerekmiyor.** Mobil istemci aynı .NET API, Identity/Notebook yetkilendirmesi ve PostgreSQL verileriyle çalışabilecek yönde kurulmuş. Bunun bugün bitmiş bir native uygulama olduğu veya web arayüzünün değişmeden telefona taşınacağı sonucu çıkarılmaz.

| Parça | Kodda bulunan | Mobil hazırlığında gereken |
|---|---|---|
| API | [Sürümlü `/api/v1` uçları](../src/Yorungez.Api/Http/Endpoints.cs): katalog, overlays, terimler, takvim, yer arama, konum/ufuk hesapları, auth ve notebook. | Makinece okunabilir OpenAPI ve istemci sözleşmeleri; hata/UTC/birim/null/sürüm uyumluluğu ve Web+mobil sözleşme testleri. `v1` zaten var; eksik olan sürüm öneki değil. |
| Oturum | JWT access + dönen refresh token; ayrıca Web için HttpOnly cookie/BFF. [Auth seçimi](../src/Yorungez.Api/Http/BrowserAuthentication.cs) Bearer ve cookie yollarını ayırır. | Mobil platformun güvenli token deposu, yenileme/iptal/hesap değişimi, e-posta doğrulama/sıfırlama dönüş linkleri ve cihaz yaşam döngüsü kararı. Mevcut özel auth API'si OAuth/OIDC/PKCE sağlayıcısı diye sunulmaz. Web'in cookie/CSRF koruması kaldırılmaz. |
| Ortak hesap/veriler | Sunucuda hesap sahibi, doğrulama ve revizyon kontrolleri; dört kişisel kayıt türü. | Aynı hesabın Web ve mobilde karşılıklı kayıt görmesi, çakışma/iptal/oturum süresi kabulü. Mobil için sessizce kişisel offline veritabanı eklenmez. |
| Coğrafi hizmetler | .NET'te yer/şehir arama uçları **zaten var**. Koordinattan IANA saat dilimi çözümü halen [Next.js/geo-tz](../src/Yorungez.Web/app/api/location/time-zone/route.ts) içinde. | Saat dilimi davranışını ortak sürümlü servis sözleşmesine almak veya eşdeğer paylaşılan veri/adaptörü seçmek; koordinat gizliliği/no-store sürer. |
| Nesne açıklaması ve görsel | Ortak katalog kimlikleri/veriler; makale/Commons erişimi [Next.js nesne rotası](../src/Yorungez.Web/app/api/objects/%5Bid%5D/route.ts), statik yerel görseller ve Web meta verileri. | İki istemcinin aynı içerik/kaynak/lisans/sürüm/hata davranışına erişeceği servis/varlık manifesti sınırı. Takvim ve GeoNames'i yeniden sıfırdan backend'e taşınacakmış gibi sayma; eşleri var. |
| Harita ve hesap | Web, akıcı/offline keşif için TypeScript Worker içinde yerel hesap/render yapar; .NET konum API'si de mevcut. | Native renderer, sensör yön çerçevesi, offline genel paket ve yerel hesap adaptörü kararı; aynı nesne kimlikleri/UTC/IANA/birimler/donmuş referanslarla eşlik. Her kareyi ağdan hesaplatma zorunluluğu yok. |
| Platform | Responsive Web/PWA var. | Android/iOS proje yapısı, framework, mağaza/derleme-imzalama, platform izinleri/sensörler ve dağıtım kararı henüz yok. Bu denetim MAUI/Flutter/React Native seçimi yapmaz. |

OpenAPI, istemciden bağımsız bir API sözleşmesi üretmek için mevcut .NET çizgisiyle uyumlu bir seçenektir; henüz uygulandığı iddia edilmez. [ASP.NET Core resmî belgesi](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/openapi/overview?view=aspnetcore-10.0). Web SEO hazırlığında dil sürümleri ve JavaScript içerik keşfi ayrıca ele alınmalıdır: [Google dil sürümleri](https://developers.google.com/search/docs/specialty/international/localized-versions), [JavaScript SEO](https://developers.google.com/search/docs/crawling-indexing/javascript/javascript-seo-basics).

## Sırayı nasıl koruyacağız?

1. **Şimdiki uygulama önceliği:** FR-03/A-005 — mevcut nesne kartlarının kaynaklı görsel/kısa bilgi/kimlik kapsamı; eksik Messier kayıtlarını doğru sınıf ve veriyle ele almak. Daha çok bağımsız menü veya yeni yedek/çöp işi açmak bu işin önüne geçmez.
2. **Astronomi derinliği:** FR-04/05/08 — olay türü bazında doğrulama, karanlık/Ay ışığı ve kaynak yenilemesi; özellik başına donmuş bağımsız referans ve açık sınır. P1 hava/ışık/ufuk işleri ve P2 ekipman kapsamı takipte kalır.
3. **Web kabulünü kapatma:** AC-01–14 izlenebilirliği üzerinden iki dilde gerçek akışlar, fiziksel GPS/pusula/PWA, ölçülen performans, erişilebilirlik ve SEO; ertelenmiş geniş paketler tekrar çalışma sırasına alındığında uygulanır. Kullanıcının cihaz/katılımcı girdisi gereken sonuçlar uydurulmaz.
4. **Yayın kabulü:** K-032 kullanıcı tarafından kaldırıldığında HTTPS/domain/deployment ve gerçek üretim işletim/uluslararası erişim kontrolü. Bu plan izin verilmiş bir deployment değildir.
5. **Sonraki mobil hedef:** Web'in seçilen sürüm çıkış ölçütleri kapandıktan sonra yukarıdaki ortak backend hazırlığı ve native platform kararı; aynı hesap/veriyle Android/iOS kabulü. P1/P2'nin hangi Web sürümüne gireceği mevcut önceliklere göre açıkça izlenir, bu hedefle sessizce silinmez veya hepsi ilk P0 sürümüne zorunlu taşınmaz.

## Kabul checklist'i

- [x] Kaynak plan/arşiv, güncel kararlar ve 12 FR / 7 UJ / 14 AC kapsamı envanterlendi; yeni mobil hedef kaydedildi.
- [x] Harita/hesap/kişisel sunucu kayıtları/genel PWA/iki dil/sözlük çalışan temel olarak mevcut.
- [x] S23 genel kullanım/PWA olumlu kullanıcı bildirimi ve pusula izin engeli ayrı kaydedildi.
- [ ] Katalog/görsel/fiziksel bilgi kapsamı ve eksik Messier kayıtları tamamlandı diye kanıt yok.
- [ ] Ek olay türleri, sürekli dış veri yenilemesi ve gelişmiş gözlem koşulları tamamlanmadı.
- [ ] Fiziksel GPS/pusula, iPhone/Safari, kontrollü PWA/performans/yardımcı teknoloji kabulleri kapanmadı.
- [ ] Tam iki dil yolculukları, gerçek e-posta teslim/render ve global SEO/indeksleme kabulü kapanmadı.
- [ ] Üretim yayın/işletim kabulü kullanıcı kararıyla bekliyor.
- [ ] Mobil uygulama ve ortak sözleşme/Next.js servis sınırlarının tamamı hazır değil.

**Koşullu ve ileri işler:** PostGIS yalnız Dünya üzerindeki gözlem alanı/ışık/arazi sorguları gerektirirse; FITS/WCS/ADQL/TAP/HiPS/HEALPix/Q3C/pgSphere ve Skyfield/Stellarium Web Engine/Aladin Lite rol bazlı değerlendirme adaylarıdır. Hepsini MVP'ye kurma sözü yok. Anonim kişisel saklama, Bugün modu ve yalnız arama odaklayan Keşfet düğmesi yürürlükteki kararlara göre kaldırılmıştır; “unutulan eksik” diye geri eklenmez. Sosyal akış/pazaryeri/zorunlu AI kapsam dışıdır.

Bu rapor güncel durum özetidir; ayrıntılı koşullar [gereksinimler](urun-gereksinimleri.md), [FR/UJ/AC tablosu](teslimat-izlenebilirligi.md), [kararlar](kararlar.md) ve [yerel çalışma sırası](yayin-oncesi-yerel-plan.md) ile birlikte okunur. Geçmiş aşama raporları kendi tarihlerinin kanıtı olarak korunur.
