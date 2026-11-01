# TECH-04 — Gerçek cihaz GPS ve pusula doğrulama protokolü

**TECH-08 hazırlığı:** S23/Chrome ve iPhone 15/Safari cihaz matrisi belirlendi; erişilebilir HTTPS test adresi henüz yok. [Oturum kartı](telefon-kabul-oturumu.md), [masaüstü kanıt ve yazılım düzeltmeleri](responsive-cihaz-ve-pwa-kabulu.md). Aşağıdaki DV satırları fiziksel ölçüm yapılana kadar bekliyor kalır.

**TECH-04D ek senaryosu:** Sensörsüz hedef yön/yükseklik/meraklısına ve özel liste/tarih kontrolleri masaüstünde sınanır; DV-07/12 fiziksel GPS/pusula ve VoiceOver/TalkBack yerine geçmez. Sensör bölümü kapatılınca dinleyici durmalı. [Güncel yazılım](ortak-bilesenler-ve-sensorsuz-gozlem.md).

**Durum:** Protokol hazır, fiziksel cihaz oturumu **yürütülmedi**. Yazılım testleri/masaüstü sensör yokluğu kontrolü cihaz kabulü yerine geçmez. İz: FR-01–02/11–12, UJ-01/06, AC-01–03/09/11/13–14. [Uygulama](dogal-gorunum-ve-pusula.md).

Test bir HTTPS geliştirme ortamında yürütülür. Telefonun `localhost` adresi geliştirme bilgisayarı değildir; LAN HTTP'sinde GPS/pusula desteği varmış gibi sonuç çıkarılmaz. Bu protokol public deployment/erişim açma yetkisi değildir. Kullanıcı izni/cihaz ayarı bilinçli yönetilir. Kayıtlara gerçek koordinat, adres, ham sensör akışı veya kişisel ekran görüntüsü yazılmaz; yalnız cihaz/tarayıcı sürümü, yuvarlanmış hata aralığı, durum ve süre sınıfı tutulur.

| ID | Türkçe senaryo / beklenen | English scenario / expected | Sonuç |
|---|---|---|---|
| DV-01 | Yeni ziyarette izin istemeden etiketli örnek harita; sol menü kapalı, üç katman açık | First visit: labelled example map without a prompt; closed menu, three layers enabled | Bekliyor / Pending |
| DV-02 | Konuma izin ver → güncel koordinat, kaynak/metre/ölçüm zamanı; tekrar açılışta önceden izinli taze ölçüm | Grant location → current coordinates, source/metres/time; fresh reading on reopen with an existing grant | Bekliyor / Pending |
| DV-03 | Konumu reddet/kapat/süre aşımı → açıklama, manuel koordinat ve önceki harita çalışır | Deny/disable/timeout location → explanation, manual coordinates and previous map remain usable | Bekliyor / Pending |
| DV-04 | Ölçüm beklerken manuel konum seç → geç GPS yanıtı seçimi değiştirmez | Choose manual coordinates while GPS is pending → late GPS does not replace them | Bekliyor / Pending |
| DV-05 | Zayıf/kapalı alan ölçümünde metre değeri gerçek cihaz bildirimi; OSM noktası donanım hassasiyeti diye sunulmaz | Weak/indoor signal retains reported uncertainty; map picking is not GPS hardware improvement | Bekliyor / Pending |
| DV-06 | Yerel/GMT/UTC aynı an; tr/en ve bölge değişimi an/nesne/katmanları korur | Local/GMT/UTC represent one instant; language/zone changes preserve instant/object/layers | Bekliyor / Pending |
| DV-07 | Pusula kapalı açılır, Başlat ayrı izin ister; ret/destek yokluğu/8 s veri yokluğu manuel yolu kapatmaz | Compass starts off; Start requests separate permission; denial/unsupported/no data in 8 s preserve manual use | Bekliyor / Pending |
| DV-08 | Düz telefonla bilinen dört gerçek yönde hizalama; portrait/landscape/359°→0° dikişi; bilinmeyen sapma bilinmiyor | Flat phone: align at four known true directions; portrait/landscape and 359°→0° seam; unknown accuracy remains unknown | Bekliyor / Pending |
| DV-09 | Manyetik etki/eğim/kötü sapma/eski veri → yanlış kesinlik ve kullanılabilir eski yön yok; yeniden hizalama | Magnetic interference/tilt/bad accuracy/stale data → no false precision or actionable stale reading; re-align | Bekliyor / Pending |
| DV-10 | Durdur/pencereyi kapat/uygulamayı gizle → dinleyici durur; geç izin yanıtı açmaz | Stop/close/hide → sensor listener stops; late permission does not restart it | Bekliyor / Pending |
| DV-11 | Harita zoom/pan/pinch, fotoğrafın sonradan gelmesi/katman off, ilk kare/texture/kare süresi/bellek ayrı ölçülür | Zoom/pan/pinch, delayed photo/layer off; first calculation, texture arrival, frame time and memory measured separately | Bekliyor / Pending |
| DV-12 | VoiceOver/TalkBack ve klavye: dil listesi/pusula/terimler/odak dönüşü, dar ekran taşma yok | VoiceOver/TalkBack and keyboard: language/compass/terms/focus return; no narrow-screen overflow | Bekliyor / Pending |

En az bir fiziksel iOS/Safari ve Android/Chrome; gerçek sürüm ve izin durumu sonuç formuna yazılır. Sadece taklit sensör/viewport ile Passed işaretlenmez. Başarı toleransları cihaz referansı ve gerçek ölçümle kararlaştırılır; rastgele “%100 doğru pusula” eşiği konmaz. Model/kutup yön sınırı ve bilinmeyen gözlem koşulları korunur.

Sonuç formu: tarih, cihaz/tarayıcı/OS sürümü, DV kimliği, tr/en, izin başlangıç durumu, beklenen/gözlenen davranış, kişisel veri içermeyen süre/hata aralığı, geçti/kaldı/denenemedi, gerekçeli takip işi. Şu anda sonuç kaydı yoktur.
