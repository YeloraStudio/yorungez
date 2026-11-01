# ADR-0003 — İlk astronomi adaptörü ve doğruluk sınırları

**Sonraki karar notu:** İlk adaptörün tarih/birim/ufuk ve kutup sınırları korunur. Aşağıda o aşamada açık yerel saat konusu artık [ADR-0005](0005-tam-ekran-konum-ve-yerel-zaman.md) ile uygulanmıştır; [TECH-04](../tam-ekran-harita-gelistirmesi.md) Canvas haritasına katman/konum/IANA ekler. Eski aşamanın test/model sonuçları değiştirilmez.

**Tarih:** 31 Ekim 2026. **Durum:** İlk sınırlı hesap adaptörü uygulandı; genel doğruluk ve çizim motoru kararı tamamlanmadı. **İş:** TECH-02A / DATA-01. **İz:** FR-01–05, FR-08, FR-11–12; AC-03, AC-06, AC-10, AC-13–14.

## Karar

Astronomy Engine **2.1.19**, C# `CosineKitty.AstronomyEngine` paketiyle Astronomy modülünün Infrastructure katmanına alındı. Domain/Application bu kütüphaneye referans vermez. Bu karar anında JavaScript paketi geliştirici denemesi içindi; daha sonra [ADR-0004](0004-ilk-harita-ve-parlak-katalog.md) ile aynı sürüm Web Worker'da kullanıldı. [MIT lisansı](https://raw.githubusercontent.com/cosinekitty/astronomy/v2.1.19/LICENSE), kaynak commit'i `61dc07020aaa6885d2c7f688a4d82beaf6edb9ef`, NuGet/npm kilitleri ve [upstream kaydı](../../third-party/astronomy-engine/UPSTREAM.json) korunur. Paketlerin kaynak commit'inden bit düzeyinde yeniden üretildiği iddia edilmez.

Güneş, Ay, Merkür, Venüs, Mars, Jüpiter, Satürn, Uranüs ve Neptün için ilk hesap yapılır. Yıldız kataloğu, takımyıldız çizgileri, Plüton/diğer hedefler ve çizim bu kararla tamamlanmış sayılmaz. Gözlemci konumu + açık UTC/ofsetli an hesap bağlamıdır. API anonimdir; hesap için PostgreSQL, Redis veya canlı dış servis çağrısı gerekmez. İstek gövdesindeki koordinatlar URL'ye, telemetriye veya kalıcı tabloya yazılmaz.

## Girdi ve model sözleşmesi

- Enlem −90…90, doğu pozitif boylam −180…180 derece. Kaynak `double` hassasiyeti korunur; sıfır geçerlidir. Varsayılan/gizli cihaz konumu okunmaz.
- An açık `Z` veya `±hh:mm` içeren ISO 8601 olarak alınır ve UTC'ye normalize edilir. Saat dilimi çözücü ve belirsiz/olmayan yerel saat girişi A-014'te hâlâ açıktır. Bu ilk teslimatın teknik tarih sınırı **2000-01-01 dahil, 2036-01-01 hariç**; her gün için aynı doğruluk kanıtlanmış değildir. Aralığı genişletme ek referansla yapılacaktır.
- Yükseklik metre olarak modelin referans Dünya elipsoidine göre yorumlanır; ilk giriş sınırı −500…10000 m. Bilinmiyorsa `null` kalır, etkili değer 0 m ve `elevationAssumed=true` bildirilir. Geoit/gerçek ortalama deniz seviyesi dönüşümü veya GPS doğruluğu hesaplanmaz. Cihaz yüksekliği gelecekte datumuyla birlikte bağlanacak.
- Konumlar topocentric apparent, equator/equinox-of-date çerçevesindedir; ışık zamanı/aberrasyon motor tarafından ele alınır. Azimut kuzey 0°, doğu 90°; yükseklik −90…90°; sağ açıklık **saat**, dik açıklık derece. J2000 ile of-date karıştırılmaz.
- Ana yükseklik atmosferik kırılmasızdır; standart atmosferle kırılmalı yükseklik ayrı alandır. Yerel arazi, balkon, dağ, hava ve algılanabilirlik bilinmiyor kalır. Ufkun üzerinde olmak gözle görülebilirlik garantisi değildir.
- Motor UT girdisi ile Espenak–Meeus DeltaT yaklaşımından TT kullanır. Canlı IERS UT1/polar hareket/nutasyon verisi alınmaz; bu UTC, UT1, TT ve TDB'nin eşit olduğu anlamına gelmez. Model TT Julian günü belirtilir, yüksek hassasiyetli zaman hizmeti iddia edilmez. [Motorun zaman sözleşmesi](https://github.com/cosinekitty/astronomy/blob/v2.1.19/source/csharp/README.md#astrotime), [JPL zaman ölçekleri](https://ssd.jpl.nasa.gov/horizons/manual.html).

## Referans ve kabul sınırı

[Dondurulmuş JPL dosyaları](../../tests/ReferenceData/Horizons/references.json) 12 tekil konum ve dört 24 saatlik seri içerir; 1.168 yön karşılaştırması yapılır. Dokuz hedef, iki yarımküre, sıfır koordinatı, tarih çizgisinin iki yazımı, gece yarısı, yüksek gözlemci, 2000/2035 örnekleri ve kutup yakınları dahildir. Tüm gezegenlerin tüm tarihlerde tarandığı iddia edilmez.

Önceden seçilen yön hedefi **1 yay dakikası**, geometrik merkez-ufuk geçişi hedefi **60 saniye** idi. Yön hedefini aşan iki ±89,9° örneği raporda **başarısız istisna olarak korunur**. Daha geniş toleransla başarılıya çevrilmedi. Bu nedenle API ihtiyatlı olarak `abs(enlem) >= 89°` bölgesinde azimutu `null`, durumunu `unsupported_near_pole` ve açıklamasını tr/en döndürür; yükseklik ayrı sunulur. 89° fiziksel tekillik değildir, ilk teslimatın koruyucu sınırıdır. Tam kutup desteği için yerel kuzey/Dünya yönelimi farklarının araştırılması ve yeni bağımsız doğrulama gerekir. Sapmanın kesin nedeni bu çalışma ile kanıtlanmadı.

Sunulan yön örneklerinin en büyük açısal farkı **0,3355 yay dakikası**, bütün örneklerde yükseklik farkı **0,2690 yay dakikası**; iki ham kutup istisnasında en büyük yön farkı **3,8914 yay dakikası** oldu. Dört aralıktaki geometrik geçişlerde bağımsız JPL serilerinden doğrusal enterpolasyona göre en büyük fark **0,391 saniye**; iki kutup Güneş serisinde geçiş bulunmaması da eşleşti. Referans serisi 5 dakika örneklenmiştir; bu sayı kesin JPL olay çözümü veya genel saniye altı doğruluk garantisi değildir. [Makine raporu](../science/astronomy-engine-2.1.19-report.json), [deney yöntemi](../astronomi-denemesi.md).

C#/JavaScript 1.168 örnekte eşleşti; azimut/yükseklik farkları 1e-7° hedefinin çok altındadır. Aynı motorun iki dilinin eşleşmesi **bağımsız bilimsel referansın yerine geçmez**; JPL karşılaştırması bu nedenle ayrıdır.

## Ufuk geçişi ve performans

İlk olay ucu yalnızca cismin merkezinin kırılmasız 0° yüksekliğini artan/azalan yönde geçtiği anı, `[başlangıç, başlangıç+24 UTC saat)` penceresinde arar. Bulunamayan an `null` döner; sürekli hiç doğmuyor veya her zaman görünür yorumu yapılmaz. Disk kenarı, kırılma, ufuk eğimi ve yerel takvim günü içeren geleneksel Güneş/Ay doğuş-batış özelliği ayrıca doğrulanıp eklenecektir. FR-03/04'ün tamamı bu uçla bitmiş sayılmaz.

Yerel masaüstü ölçümü aynı sabit konum/an ile 200 ısınma + 1.000 dokuz-hedef partisiyle kaydedildi. C# p95 yaklaşık 0,056 ms, Node p95 yaklaşık 0,121 ms/parti; sürüm ve ortam makine raporundadır. Bu browser, mobil, çizim, API yükü veya üretim kapasitesi ölçümü değildir. Minify browser motoru 116.424 bayt, gzip örneği 46.706 bayttır; toplam PWA boyutu değildir.

Bu kanıtlar ilk hesap için Astronomy Engine kullanımını destekliyor. TECH-02B çizim/lisans/katman/mobil/çevrimdışı denemesi ve TECH-03 iki dilli harita akışı hâlâ sıradadır. İstemci sık hesapları Web Worker'da yapma adayıdır; her karede API/DB çağrısı tasarım koşulu değildir. Stellarium/Aladin veya özel çizim seçilmiş değildir.
