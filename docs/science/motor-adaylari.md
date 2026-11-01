# Hesap ve çizim adaylarının durumu

**1 Kasım 2026 güncellemesi:** A-001 özgün kod lisansı kullanıcı seçimiyle Apache-2.0 olarak kapandı. Aşağıdaki açık lisans ifadeleri tarihsel aşamayı anlatır; üçüncü taraf lisansları değişmez. [ADR-0014](../adr/0014-acik-kaynak-yayin-ve-apache-2.md).

**TECH-04 ayrımı:** Stellarium Web Engine kurulmadı/kodu alınmadı. Ayrı `stellarium-skycultures` veri kaynağından Johan Meuris’in Free Art License kapsamındaki 85 değiştirilmemiş çizimi ve üç yıldızlı bağları alındı; motor lisansı ile görsel lisansı karıştırılmaz. OpenNGC 107 Messier eşleşmesi/72 Astropy referansı ve IANA/konum paketi [güncel rapordadır](../tam-ekran-harita-gelistirmesi.md).

**31 Ekim 2026 — TECH-02.** Hesap ve çizim ayrı karardır. Kurulmamış adayların boyutu/performansı ölçülmüş gibi yazılmaz.

| Aday | Rol | Lisans / mevcut kanıt | Kalan iş |
|---|---|---|---|
| Astronomy Engine 2.1.19 | C#/JS Güneş/Ay/gezegen hesabı | MIT; JPL karşılaştırması, port eşliği ve desktop hesap ölçümü yapıldı; iki kutup yön istisnasıyla sınırlı adaptör alındı | Kutup yönü/geniş doğrulama; çizim motoru değildir |
| Astropy 8.0.2 | Python bağımsız yıldız dönüşümü referansı | BSD-3-Clause; izole doğrulama venv'i, sabit IERS ile 144 donmuş örnek | Üretim bağımlılığı/Python servisi değil; 2035 uyarıları ve geniş doğrulama açık |
| Skyfield | Python efemeris hesabı/ek karşılaştırma | Kurulmadı; sürüm, efemeris ve dağıtım koşulları seçilmedi | İlk bağımsız referans JPL oldu; aynı veri/modelden türeyen sonuç bağımsız kanıt sayılmayacak |
| Stellarium Web Engine | WebGL planetaryum, yıldız/katman ve ufuk çizim adayı | İncelenen kaynak başlığı AGPLv3 veya ticari lisans seçeneği içeriyor; projeye kodu alınmadı | TECH-02B: dağıtım/veri lisansı, aynı konum/an/kimliklerle çizim, asset boyutu, mobil ve offline denemesi |
| Aladin Lite | HiPS görüntü/katalog katmanları, ek atlas adayı | İncelenen kaynak lisansı LGPLv3; projeye kodu alınmadı | Yerel ufuk/canlı planetaryumla aynı işlev varsayılmaz; paket/asset lisansı ve rol denemesi |
| Uygulamaya özgü Canvas 2D / SVG / WebGL | Ortak hesap çıktısı, stereografik görünüm | Üç çizim katmanı aynı 5082 hedefle IAB üretim denemesinde ölçüldü; ilk Canvas seçildi, kod lisansı A-001 açık | Etiket/ufuk dahil tam kare, fiziksel mobil/bellek/açılış bütçesi açık; [ADR-0004](../adr/0004-ilk-harita-ve-parlak-katalog.md) |

Birincil kaynaklar: [Astronomy Engine](https://github.com/cosinekitty/astronomy/tree/v2.1.19), [Astropy](https://docs.astropy.org/en/stable/), [Skyfield](https://rhodesmill.org/skyfield/), [Stellarium](https://github.com/Stellarium/stellarium-web-engine), [Aladin](https://github.com/cds-astro/aladin-lite).

Lisans ön incelemesi: Stellarium commit `1162c9ef73cc94f4762dfbfd24c637190119ea93` [kaynak başlığı](https://github.com/Stellarium/stellarium-web-engine/blob/1162c9ef73cc94f4762dfbfd24c637190119ea93/src/algos/bv_to_rgb.c); Aladin commit `60c5cf414d6d56a10b406761e62e8c2ce9f2a760` [LICENSE](https://github.com/cds-astro/aladin-lite/blob/60c5cf414d6d56a10b406761e62e8c2ce9f2a760/LICENSE). Bu revizyonlar seçilmiş ürün bağımlılığı değildir; bir kaynak başlığı tüm paket/asset denetimini tamamlamaz.

TECH-02B/03 ilk veri/atıf paketi (HYG 4.1/d3-celestial), projeksiyon/kimlik/arama-kart eşliği, klavye/metinsel alternatif ve tr/en harita sağlandı. [Deneme](../harita-ve-katalog-denemesi.md) hangi çıktının doğrulandığını ve fiziksel mobil/çevrimdışı/erişilebilirlik kalanlarını ayırır. Bunlar kapanmadan TECH-02 veya MVP-0 bütünü tamamlandı işaretlenmez. Stellarium ve Aladin hızları ölçülmüş değildir.
