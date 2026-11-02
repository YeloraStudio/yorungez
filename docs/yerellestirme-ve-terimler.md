# yorungez — Türkçe/İngilizce ve terimler sözleşmesi

**K-036 / TECH-11C (2 Kasım 2026):** Kullanıcı yeni alanlar yerine mevcut deneyimin derinleştirilmesini önceliklendirdi. Aynı 52 kaynaklı terim ortak bileşende iki dilden aranır; kartta tam terim odağı/geri dönüş, ayrı statik sözlük, sabit terim bağlantıları ve genel PWA kapsamı geliştirildi. 55 istemci testi, tip/üretim derlemesi ve iki dil/320 px/sunucusuz sözlük kontrolü geçti. [Kanıt ve kalan kabul işleri](sozluk-ve-terim-baglantilari.md). Diğer P0/P1/P2 hedefleri ve K-032 beklemesi korunur.

**Güncel TECH-07 / K-027–028 (1 Kasım 2026):** Menüde giriş/kayıt veya doğrulanmış oturumun ad-soyadı; kayıt için ad/soyad/e-posta/parola. Servis hatası ve çevrimdışı durum ayrıldı, ortak yerel başlatıcı eklendi. Genel katalog/terim/takvim için hash doğrulamalı PWA paketi ve yeniden açılış uygulandı; kişisel kayıt/oturum/koordinat cache'e girmez. 125 .NET/44 istemci testi; fiziksel cihaz/üretim backup kabulü açık. [Uygulama ve kanıt](hesap-menusu-ve-cevrimdisi-gokyuzu.md), [hesap ADR](adr/0012-hesap-menusu-ve-ad-soyad.md), [PWA ADR](adr/0013-genel-gokyuzu-pwa-ve-cevrimdisi-paket.md).

**Güncel K-026 / TECH-06 (1 Kasım 2026):** Hesap envanterinde not/favori yanında ayrı gözlem ve kayıtlı konum uygulandı. Gözlem açıklama + kişisel beyan ister; gerçek zaman/nesne/konum isteğe bağlıdır, simülasyon zamanı kendiliğinden bağlanmaz. Konum kopyası geçmişi korur; haritada kullanım an/mod/hedef/kamerayı korur. 120 .NET + 38 istemci testi ve üretim derlemesi geçti; 52 tr/en terim/cache .7. [Uygulama ve sınırlar](gozlem-kayitlari-ve-kayitli-konumlar.md), [ADR-0011](adr/0011-gozlem-kaydi-ve-kayitli-konumlar.md). Fiziksel cihaz, genel katalog PWA/offline ve üretim backup kabulü açık; kişisel tarayıcı kalıcılığı yoktur.

**Güncel K-025 / TECH-05B:** Gönderen `sender@example.com`; parola yalnız özel kök `.env`, Gmail STARTTLS/AUTH kontrolü başarılı (ileti gönderilmedi). İşlem e-postaları İngilizce markalı HTML + düz metin, uygulama/API varsayılan dili İngilizce; açık Türkçe seçimi korunur. [Güncel paket](eposta-ve-varsayilan-dil.md). Önceki SMTP placeholder ve iki dilde e-posta hükümleri bu kararla değişti.


**Güncel K-024 / TECH-05:** Kişisel kayıt için doğrulanmış hesap zorunlu; anonim/IndexedDB kişisel kalıcılığı kaldırıldı. Not ve favoriler kullanıcıya bağlı PostgreSQL modülünde; TR/EN kayıt/giriş/doğrulama/sıfırlama ve panel geri dönüşü bağlıdır. [Uygulama ve sınırlar](hesap-ve-sunucu-defteri.md), [ADR-0010](adr/0010-hesap-zorunlu-defter-ve-sunucu-kayitlari.md). Aşağıdaki eski paket kayıtları kendi aşamasının tarihsel kanıtıdır.


**TECH-04D:** Yalnız Bu gece, ortak özel dil/tarih/saat/bölge listeleri, sensörsüz brief ve yerel Defterim bütün durumları tr/en eşli. Not metni çevrilmez; güncel katalog adı seçili dilde bulunur, eski kimlik/ad snapshot korunur. 51 terim/cache .6 değişmedi. [Kanıt](ortak-bilesenler-ve-sensorsuz-gozlem.md).

**TECH-04C:** Bugün/Bu gece, Takvim, yer adı/manuel yükseklik, saydam ufuk altı uyarısı ve pusula hedefi tr/en eşli. Toplam **51 terim**, cache `2026-10-31.6`; önceki 43 korunur, sekiz yeni kimlik rise-set/moon-phase/opposition/conjunction/elongation/equinox/solstice/twilight. [Kanıt](gozlem-cizelgesi-ve-takvim.md).

**TECH-04B:** Native sol menü dil listesi, doğal çevre kaynakları ve pusula bütün destek/hata/hizalama/terim metinleri eşli tr/en geliştirildi. Pusula penceresi dört yeni terime erişir; TECH-04B aşamasında 43, cache `.5`. [Güncel kanıt](dogal-gorunum-ve-pusula.md). Fiziksel ekran okuyucu/cihaz kabulü açık.

**Tarih:** 31 Ekim 2026. **İz:** FR-11–12, AC-13–14. Her yeni kullanıcı özelliği iki dilde birlikte teslim edilir. Üçüncü dillere yapı açıktır; şu anda yalnızca `tr` ve `en` desteklenir.

## Mevcut backend

API `Accept-Language` ile dil seçer; `tr-TR` ve `en-GB` gibi istekler desteklenen üst dile düşer. Varsayılan/desteklenmeyen dil K-025 ile `en` olur. Yanıtta `Content-Language` bulunur. Teknik JSON alanları, nesne kimlikleri ve hata kodları sabittir; kullanıcıya sunulan mesaj ve kategori adı çevrilir. API sayıları kültürden bağımsız JSON sayılarıdır. UTC anı, saat dilimi ve ekranın dili ayrı kavramlardır.

`src/Yorungez.Api/Localization/tr.json` ve `en.json` aynı anahtarları taşımalıdır. Eksik/boş çeviri başlangıçta hata verir; eksik Türkçe metni İngilizceyle tamamlanmış sayma. Başarı, doğrulama, yetki, hız sınırı ve genel hata mesajları bu kataloğu kullanır. K-025 ile işlem e-postaları ayrı İngilizce markalı HTML/plain şablonundan üretilir; eski Email.* çeviri anahtarları tarihsel uyumluluk için kalır. Health durumları ve geliştirici logları makine/işletim içindir; son kullanıcı ekran metni olarak kullanılmaz.

`GET /api/v1/terms/?q=...` ve `GET /api/v1/terms/{id}` anonim erişilir. Güncel kaynak **52 terimdir**; `ellipsoidal-height` NOAA kaynaklı TECH-06 ekidir; önceki 43 kimlik korunur; sekiz yeni terim TECH-04C kapsamındadır. Önceki pusula, gerçek kuzey, manyetik kuzey ve pusula kalibrasyonu TECH-04B eklemeleridir; daha önceki katman/zaman terimleri de korunur. AU/AB, IANA saat dilimi, yerel saat, konum doğruluğu, azimutal/ekvatoral ızgara, DSO, takımyıldız çizimi, atmosfer, arazi ve GMT eklendi. Sabit kimlik, varsa kısaltma, iki dilde ad/tanım/alternatif ad ve resmî kaynak bağlantıları saklanır. Arama iki dildeki adları, takma adları, kısaltmaları ve Türkçe karakterlerin sadeleştirilmiş yazımını destekler. Kategori kimliği sabittir; `categoryName` çevrilir. Güncel içerik/cache sürümü `2026-10-31.7` oldu; önceki .6 tarihsel TECH-04C sürümüdür.

Terimler sürümlü gömülü JSON'da tutulur. Redis 30 dakikalık önbellektir; erişilemediğinde kaynak dosya kullanılır. Yeni terim için iki çeviri, sade açıklama ve kaynak gerekir. İçerik değişiminde cache sürümü artırılır; AI çıktısı denetimsiz bilimsel kaynak yerine geçmez. Bu geliştirici alan sözlüğünden farklı, kullanıcıya sunulan ilk içerik kataloğudur.

## Frontend teslimat koşulu

TECH-02A anonim hesap uçlarında dokuz cismin adı, varsayımlar, bilinmeyen koşullar, kutup yön sınırı, pencere içi geçiş durumu ve giriş hataları tr/en eşli eklendi. Hesap çıktısı ilgili sekiz sözlük kimliğini içerir; bu kimliklerin katalogda bulunması API testinde kontrol edilir. Teknik JSON alan/çerçeve/birim kodları sabit kalır; UI ham teknik İngilizce metadata'yı çeviri yerine kullanmayacak.

İlk Next.js haritası `/tr`, `/en` yolları ve eş anahtarlı sözlüklerle uygulanmıştır. BFF genel katalog ve 52 terimin iki dilini birlikte yükler; dil değişiminde terimler için yeni istek gerekmez. Konum/an/mod/hedef/kamera/katmanlar bellekte korunur. Sayı/tarih `Intl` ile yerelleşir; konumun IANA yerel saati/GMT ofseti ve UTC birlikte görünür. Yerel/UTC giriş ayrı, UTC anı asıldır; Temporal boş/çift saat koruması vardır. Dil/konum/bölge değişimi anı değiştirmez; bölge hazır değilken giriş UTC olarak etiketlenir. [Saat sözleşmesi](adr/0005-tam-ekran-konum-ve-yerel-zaman.md). Kart adları, hata, koşul, kaynak, kutup ve erişilebilir etiketler eşlidir. Bütün ürün yüzeyleri/hesap UI henüz uygulanmadığı için tam ürün dil kabulü tamamlandı denmez.

Navigasyon, nesne kartları, kaynak/güncellik etiketleri, hata/boş/çevrimdışı durumlar, form doğrulaması, izin açıklamaları ve erişilebilir adlar aynı akışın tr/en kontrolüne dahildir. İşlem e-postaları arayüzden bağımsız İngilizcedir ve `/en/account/...` bağlantısı içerir. Kullanıcı notları otomatik çevrilmez. Katalog kimlikleri ve özgün bilimsel adlar çeviriyle değiştirilmez.

Terim açıklamasına yalnızca hover ile erişilmez. Kart içindeki açıklama eylemi dokunma/klavyeyle çalışır, odak geri döner, ekran okuyucu adı ve düz metin tanımı vardır. Ayrı sözlük sayfası ve ilgili terime derin bağlantı sunulur; bağlantı açıklamayı okumak için hesap istemez. Bunlar frontend kabul koşullarıdır, yapılmış erişilebilirlik testi iddiası değildir.

## Kanıt

Entegrasyon testleri dil seçimini, iki dilde aynı terim kimliklerini, dolu tanım/kaynakları, Türkçe/İngilizce aramayı ve hata dilini doğrular. İstemci anahtar eşliği testlidir. Üretim tarayıcısında bağlamı koruyan dil değişimi, kaynaklı Azimut açıklamasına Enter ile erişim ve ESC sonrası odak dönüşü geçti. Ayrı sözlük sayfası/sabit terim bağlantıları ve ortak iki dilden arama TECH-11C ile uygulandı; gerçek ekran okuyucu/dokunma, bütün yüzeylerin kapsamlı kontrolü ve gerçek kullanıcı değerlendirmesi açık. [İlk kanıt](harita-ve-katalog-denemesi.md), [güncel tam ekran/GPS/zaman/kart kanıtı ve sınırlar](tam-ekran-harita-gelistirmesi.md).

Dil seçimi davranışının temeli: [ASP.NET Core kültür seçimi](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/localization/select-language-culture?view=aspnetcore-10.0).
