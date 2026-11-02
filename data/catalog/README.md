# İlk parlak gökyüzü kataloğu / Initial bright-sky catalogue

**Fotoğraf çevre paketi — TECH-04B:** [Stara Lesna manifesti](landscape-manifest.json) orijinal 4096×2048 saydam PNG, kaynak arşivi/hash/boyut/atıf ve kaynaklardaki CC BY-SA 4.0 / CC BY 4.0 ayrımını tutar. [Ayrı notice](../../third-party/stara-lesna/NOTICE.md). Fotoğraf değiştirilmedi; ekranda küresel projeksiyon/2048 doku örnekleme/gündüz-gece grading vardır. Bu kullanıcı konumunun topoğrafyası değildir. Yenileme yalnız `python scripts/science/prepare_landscape.py --refresh`; normal test/build indirmaz.

**TECH-04 ek paketi:** `overlays.json` / `overlays-manifest.json`, OpenNGC sabit revizyonundan 107 Messier eşleşmesi (M40/M45/M102 yok), 85 Johan Meuris/Stellarium Western çiziminin üç yıldız ankrajı ve dosya SHA'larını tutar. [OpenNGC CC BY-SA 4.0](../../third-party/openngc/LICENSE.txt), [çizim bildirimi ve Free Art License](../../third-party/stellarium-art/NOTICE.md). Görsel dosyaları değiştirilmedi; uygulama küresel örgüyle projekte eder. Pupa/Yılan/Yelken için upstream çizim yoktur. Bu paket tam Messier/NGC veya tüm kültür sanat arşivi değildir. Yenileme yalnızca `python scripts/science/prepare_overlays.py --refresh` ile açıktır; normal build/test ağdan indirme yapmaz.

`sun-content.json` iki dilde Wikipedia metin revizyonu/kaynağı, alınma tarihi ve Commons arşiv fotoğrafının üretici/lisans/hash bilgisidir. Fotoğraf: **Matúš Motlo**, [The Sun in white light](https://commons.wikimedia.org/wiki/File:The_Sun_in_white_light.jpg), CC BY-SA 4.0. Kısa metinler Wikipedia katkıda bulunanlar, CC BY-SA 4.0; giriş özeti alınmış/kısaltılmıştır, kaynak/revizyon saklıdır. Alınma tarihi fotoğrafın çekim veya canlı gözlem zamanı değildir. Açık yenileme: `python scripts/science/prepare_sun_content.py --refresh`. Bütün bu eklerin BFF ve Catalog API'sinde bağımsız veri hash'i vardır; eski HYG temel paketinin hash'i değiştirilmedi.

31 Ekim 2026. `bright-sky.json` uygulamanın tek kaynak paketidir; `manifest.json` ham kaynak URL/SHA-256, türetilmiş dosya özeti, eşleştirme mesafeleri ve atıf kaydını tutar. C# gömülü kaynak ve Next.js BFF aynı dosyayı kullanır. Kişisel konum içermez.

- **HYG Database v4.1**, David Nash / Astronexus, [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). [Kaynak](https://github.com/astronexus/HYG-Database/tree/c7f7f883fe678cc7680169a50ccd7dcc49b060ce), [korunan lisans](../../third-party/hyg/LICENSE.md). HYG'den türetilmiş yıldız verisi aynı CC BY-SA 4.0 koşullarıyla sunulur; uygulama kodunun lisansı bundan ayrı A-001 kararıdır.
- **d3-celestial**, Olaf Frohn, [BSD-3-Clause lisans metni](../../third-party/d3-celestial/LICENSE), [sabit revizyon](https://github.com/ofrohn/d3-celestial/tree/7e720a3de062059d4c5400a379146a601d9010e0). Yalnızca `constellations.lines.json` ve `constellations.json` verileri kullanıldı; d3 çalışma zamanı, diğer yıldız katalogları veya sanat eserleri alınmadı. Kaynak adlandırma atıfları IAU ve Wikipedia'yı içerir; upstream atıflar korunur.

**Yapılan değişiklikler / Changes:** Sol satırı hariç katalog kadiri <=6 olan 5070 yıldız süzüldü, çizim düğümleri için üç daha sönük yıldız eklendi (toplam 5073). Alanlar yeniden adlandırıldı/biçimlendirildi; uzaklık bilinmiyorsa HYG'nin >=100000 pc sentineli yerine `null` üretildi. 89 figürdeki iki Serpens/Yılan parçası tek `con-ser` kimliğine birleştirildi (88 takımyıldız). Çizgi düğümleri 30 yay saniyesi sınırıyla en yakın HYG yıldızına bağlandı; en büyük eşleşme 16,260 yay saniyesi. Bütün düğüm eşleşmeleri manifestte saklıdır. Lines are schematic conventions, not IAU boundary polygons.

RA saat, Dec derece, epoch/equinox J2000.0; konum parsek, hız parsek/yıl, özdevinim mas/yıl, radyal hız km/s. Bilinmeyen radyal hız için kaynak hız hesabının 0 varsayımı korunur. Bilinmeyen uzaklık iç hesapta upstream uzak vektörüyle yaklaşık sonsuz kabul edilir; kartta sayısal uzaklık sunulmaz. HYG yaygın adları her zaman resmî IAU adı değildir; varsayımsal ikincil yıldız adları içerebilir. Görünür kadir kesmesi çıplak gözle görünürlük garantisi değildir; değişkenlik, hava, arazi ve ışık kirliliği hesaba katılmaz. Renkler B−V değerinin şematik sınıflarıdır, ölçülmüş fotoğraf rengi değildir.

Yeniden üretim: `python scripts/science/prepare_catalog.py --download` yalnızca açık talimatla ham dosyaları `.local/catalog/` içine indirir. Normal `python scripts/science/prepare_catalog.py` yerel dosyalardan üretir; test/build internetten katalog yenilemez. HYG SHA sabittir. Yeni veri revizyonu için kaynak/lisans/manifest/referans/şema sürümünü birlikte değerlendir; sessiz veri güncellemesi yapma. İlk yenileme politikası elle incelenmiş revizyondur; otomatik zamanlanmış iş henüz yoktur.


## TECH-11D — Object archive photographs

[object-media.json](object-media.json) pins 11 additional source JPEG previews (1,293,299 bytes); the existing Sun makes 12 local photo targets. Original downloaded preview bytes are unaltered. Per-file source URL/credit/licence, source SHA-1/timestamp, local SHA-256/bytes, retrieval time and raw source date/description metadata are retained. `sourceDateText` is unverified source prose, not a normalised capture instant. The UI marks images as archival/processed, not the selected time/phase or naked-eye appearance. Normal staging verifies hashes; normal tests/build do not download images. Explicit refresh only:

```powershell
python scripts/science/prepare_object_media.py --refresh
```

| Object ID | Commons file | Credit | Per-file rights |
|---|---|---|---|
| moon | [FullMoon2010.jpg](https://commons.wikimedia.org/wiki/File:FullMoon2010.jpg) | Gregory H. Revera | [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0) |
| mercury | [Mercury in true color.jpg](https://commons.wikimedia.org/wiki/File:Mercury_in_true_color.jpg) | NASA/Johns Hopkins University Applied Physics Laboratory/Arizona State University/Carnegie Institution of Washington | [Public domain](https://commons.wikimedia.org/wiki/File:Mercury_in_true_color.jpg#Licensing) |
| venus | [Venus-real color.jpg](https://commons.wikimedia.org/wiki/File:Venus-real_color.jpg) | NASA or Ricardo Nunes | [Public domain](https://commons.wikimedia.org/wiki/File:Venus-real_color.jpg#Licensing) |
| mars | [OSIRIS Mars true color.jpg](https://commons.wikimedia.org/wiki/File:OSIRIS_Mars_true_color.jpg) | ESA & MPS for OSIRIS Team MPS/UPD/LAM/IAA/RSSD/INTA/UPM/DASP/IDA, CC BY-SA 3.0 IGO | [CC BY-SA 3.0 igo](https://creativecommons.org/licenses/by-sa/3.0/igo/deed.en) |
| jupiter | [Jupiter and its shrunken Great Red Spot.jpg](https://commons.wikimedia.org/wiki/File:Jupiter_and_its_shrunken_Great_Red_Spot.jpg) | NASA, ESA, and A. Simon (Goddard Space Flight Center) | [Public domain](https://commons.wikimedia.org/wiki/File:Jupiter_and_its_shrunken_Great_Red_Spot.jpg#Licensing) |
| saturn | [Saturn during Equinox.jpg](https://commons.wikimedia.org/wiki/File:Saturn_during_Equinox.jpg) | NASA / JPL / Space Science Institute | [Public domain](https://commons.wikimedia.org/wiki/File:Saturn_during_Equinox.jpg#Licensing) |
| uranus | [Uranus2.jpg](https://commons.wikimedia.org/wiki/File:Uranus2.jpg) | NASA/JPL-Caltech | [Public domain](https://commons.wikimedia.org/wiki/File:Uranus2.jpg#Licensing) |
| neptune | [Neptune Full.jpg](https://commons.wikimedia.org/wiki/File:Neptune_Full.jpg) | NASA | [Public domain](https://commons.wikimedia.org/wiki/File:Neptune_Full.jpg#Licensing) |
| hyg-32263 | [Sirius A and B Hubble photo.jpg](https://commons.wikimedia.org/wiki/File:Sirius_A_and_B_Hubble_photo.jpg) | NASA, ESA, H. Bond (STScI), and M. Barstow (University of Leicester) | [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/) |
| dso-ngc0224 | [M31-Andromede-16-09-2023-Hamois.jpg](https://commons.wikimedia.org/wiki/File:M31-Andromede-16-09-2023-Hamois.jpg) | Lviatour | [CC BY-SA 2.5](https://creativecommons.org/licenses/by-sa/2.5) |
| dso-ngc1976 | [Orion Nebula - Hubble 2006 mosaic 18000.jpg](https://commons.wikimedia.org/wiki/File:Orion_Nebula_-_Hubble_2006_mosaic_18000.jpg) | NASA, ESA, M. Robberto (Space Telescope Science Institute/ESA) and the Hubble Space Telescope Orion Treasury Project Team | [Public domain](https://commons.wikimedia.org/wiki/File:Orion_Nebula_-_Hubble_2006_mosaic_18000.jpg#Licensing) |

The Sirius file body/API declares public domain while structured data also declares CC BY 3.0; both are recorded (`metadataLicense` / `license`), and the UI retains CC BY 3.0 credit/link obligations. This is a file-specific source discrepancy, not a blanket claim about NASA images. Other public-domain rows link the original file's explicit licensing declaration when the API has no licence URL. Mars, Moon and M31 have separate Creative Commons terms. These images are not relicensed as Apache-2.0.

Neptune is an enhanced-colour Voyager image; Venus/Mercury/other spacecraft images may be processed composites. Sirius diffraction spikes/rings are telescope imaging artifacts. None is a calibrated naked-eye view. PWA includes the general photos only in its optional image pack; a first visit/unprepared images need a connection. Finder diagrams for remaining objects are computed from the existing horizontal frame and explicitly labelled as diagrams, not sourced photographs. Full catalogue photo coverage remains open.

The pinned Sun text archive is retained byte-for-byte. TECH-11D displays only its original first paragraph: a later Turkish paragraph contains a wrong km/s unit for Galactic motion. See [NASA Sun facts](https://science.nasa.gov/sun/facts/); the bad unit is not republished or silently presented as corrected source prose.


## TECH-11E — Extended Milky Way feature

[sky-features.json](sky-features.json) contains original paired en/tr educational summaries with NASA source links and the ESO/S. Brunier `eso0932a` CC BY 4.0 screensize JPEG provenance. The supplied 155,879-byte preview is unchanged, hashed and optional in the public PWA image pack. Its credit is always visible next to the image. [ESO source](https://www.eso.org/public/images/eso0932a/) / [rights](https://www.eso.org/public/outreach/copyright/). The restricted 800-million-pixel original is not redistributed. Source release date is not the capture instant.

Refresh only: `python scripts/science/prepare_milky_way.py --refresh`, after reviewing source/rights. Normal build verifies SHA and does not download. This is an extended feature within our home galaxy, not a new ephemeris target: no fabricated point coordinates/rise-set time, calibrated sky texture or personal notebook target is added. Its region action opens existing schematic `con-sgr`; original point catalogue and references stay unchanged. [Implementation and limits](../../docs/mobil-kart-samanyolu-ve-pusula-erisim.md).
