# ADR-0009 — Yerel Defterim ve kayıpsız düzenleme

**Yürürlükten kaldırıldı (K-024):** Tarayıcı/anonim kişisel kayıt yönü kullanıcı tarafından reddedildi. Güncel [ADR-0010](0010-hesap-zorunlu-defter-ve-sunucu-kayitlari.md) uygulanır. Aşağısı önceki deneyin değiştirilmemiş tarihsel gerekçesidir.

**31 Ekim 2026 / K-023. Durum:** P0 ilk yerel dilim seçildi/uygulandı; hesap senkronizasyonu ve bütün kişisel model açık. FR-06–09/FR-11; UJ-04–05/UJ-07; AC-07/AC-09–10/AC-12–13.

Kullanıcı mevcut plandaki kişisel kayıt/hesap/çevrimdışı akışlarına devam edilmesini istedi. İlk bağımsız dilim favori + not/anıdır. Gerçek gözlem kaydı, kayıtlı konum, hesabın UI oturumu ve service worker bu dilime tamamlanmış olarak eklenmez.

IndexedDB `yorungez-notebook`, sürüm1, `entries` keyPath `id`; tek köken ve tarayıcı profili içinde. Favori kimliği hedef kimliğinden deterministik üretilir. Not gövdesi 1–8000 karakter; hedef/an/koordinat isteğe bağlıdır, her yeni notta kutular kapalıdır. `createdAtUtc` ve `updatedAtUtc` sistem zamanıdır, gerçekleşmiş gözlem anı sayılmaz. İsteğe bağlı `instantUtc` harita anıdır. Konum bağlanırsa koordinat/yükseklik/ad kopyası saklanır, sonraki konum değişikliği geçmiş notu değiştirmez. Anonim ve hesap verisi otomatik birleşmez.

Her yazma `readwrite` transaction içinde mevcut revizyonu okur, beklenen revizyonla karşılaştırır ve yalnız eşleşiyorsa artırıp yazar. Çakışma eski metni korur; yeni kopya veya liste yenileme yolu vardır. Yeni kopya da seçilmiş bağları korur. Başarı yalnız transaction tamamlanınca gösterilir. Depolama yok/kota/yazma hatasında taslak metin korunur ve indirilebilir. İlk bağlantı 8 s gözetimlidir; gerçek cihaz/kota baskısı ayrıca sınanacak.

Silme bu dilimde `deletedAtUtc` ile çöp kutusuna taşımadır, geri alınabilir; kalıcı temizleme/kapsamlı silme UI'si sonraki iştir. JSON yedeği indirme anında IndexedDB'den taze okunur, sürüm ve çöp kutusu dahil kayıtları içerir. Taslak ayrı indirilir. İçe aktarma/göç/hesap çatışması henüz uygulanmadı; JSON tek başına kayıpsız geri yükleme kabulü değildir.

Veri sunucuya/telemetriye/URL'ye gönderilmez; kullanıcı açık konum kutusunu seçmedikçe hassas koordinat kalıcı kayda girmez. Yerel saklama şifreli veya paylaşılan tarayıcı profilinden gizli bir kasa değildir. Tarayıcı verisi temizliği/eviction/cihaz değişimi veri kaybettirebilir. PWA/offline yeniden açılış kabulüyle IndexedDB kalıcılığı ayrı tutulur. [IndexedDB standardı](https://www.w3.org/TR/IndexedDB/).

[UX-02 akışları ve minimum alanlar](../kisisel-kayit-hesap-cevrimdisi-akislari.md), [teknik/UI kanıtı](../ortak-bilesenler-ve-sensorsuz-gozlem.md). A-006/A-013 yerel ilk dilimde kısmen çözüldü; hesap aktarımı, kota politikası, kayıtlı konum/gözlem modeli ve silme/geri yükleme kapsamı açık kalır.
