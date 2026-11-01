# yorungez — Tekrarlanabilir astronomi denemesi

**Tarih:** 31 Ekim 2026. **İş:** TECH-02A tarihsel hesap kanıtı. [ADR-0003](adr/0003-ilk-astronomi-adaptoru-ve-dogruluk-sinirlari.md) karar, sınır ve sayısal sonuçların kaynağıdır. Bu ilk pakette çizim/cihaz denemesi yoktu. Sonraki [TECH-02B/03 harita kaydı](harita-ve-katalog-denemesi.md) yıldız/çizim/frontend ve güncel 82 .NET + 9 istemci testi kanıtını ekler; fiziksel cihaz hâlâ açık.

## Çalıştırma ve veri kökeni

```powershell
./scripts/Verify-Science.ps1
# Bağımlılıklar daha önce kurulduysa JPL/restore isteği olmadan:
./scripts/Verify-Science.ps1 -Offline
# Bu makinenin yeni ölçümünü belgeye açıkça yazmak için:
./scripts/Verify-Science.ps1 -Offline -PublishReport
```

.NET 10, Node ve Python 3 gerekir. Normal test/probe'lar kayıtlı referansları okur; NASA, SMTP veya veritabanı gerekmez. İlk restore NuGet/npm ağı kullanabilir. `-Offline` bunu da atlar; bağımlılıkların önceden kurulu olmasını gerektirir. Tam backend testinde kimlik için yerel PostgreSQL/Redis ayrı gereklidir.

Referanslar [NASA/JPL Horizons API](https://ssd-api.jpl.nasa.gov/doc/horizons.html) üzerinden **tek seferde tek istek** ile alındı. Ham JSON, tam parametreli kaynak URL'si, alınma anı, API imzası/sürümü ve SHA-256 saklanır. Girdiler kamuya açık örnek/sentetik koordinatlardır, kullanıcının cihazından alınmadı. Normal testler servise trafik üretmez. Verileri bilinçli yenilemek için:

```powershell
python scripts/science/refresh_horizons.py --refresh
```

Bu komut dış hizmetten yeni referans indirip dosyaları değiştirir; API veya uygulama açılışında çağrılmaz. Yenileme sonrası bilimsel farklar incelenir, test/rapor tekrar üretilir. JPL'in geleceğe ait Dünya yönelimi öngörüleri ve modelleri güncellenebileceği için yeni indirmenin aynı sayıları üretmesi garanti edilmez.

JPL ayarı Earth topocentric observer, `GEODETIC`, doğu pozitif boylam/enlem/yükseklik-km sırası; `QUANTITIES=4`, `APPARENT=AIRLESS`, UT/UTC çıktı, Gregorian takvimdir. Yerel uygulama metreyi API isteğinde kilometreye dönüştürür. Yerel üretim hesapları JPL servisine bağlı değildir. Sayısal referansların kaynağı NASA/JPL olarak korunur; kendi kod/veri lisans kararı A-001'in yerine geçmez.

## Yöntem ve sınırlar

- Birim kürede açısal ayrım kullanılır; 0/360° sarmalanması ve zenit yakınında ham azimut çıkarmanın hatası önlenir. Kırılmasız yükseklik farkı ayrıca ölçülür.
- ±89,9° iki yön başarısızlığı saklanır; kutup için gizli tolerans gevşetilmez. Koruyucu API davranışı ayrıca test edilir. Tam yön desteği açık iştir.
- Olay serileri 24 saat boyunca 5 dakika aralıkla örneklenir. İlk yükselen/alçalan işaret değişiminde doğrusal enterpolasyon bağımsız zaman referansıdır. Matematiksel ufuk, merkez ve kırılmasız varsayım aynı tutulur. Teğet geçen/sınır durumları ve geleneksel doğuş-batış modeli genişletilecektir.
- C#/JS eşliği bir port tutarlılığı testidir. Bağımsız JPL kontrolünden ayrı raporlanır. Atmosferik kırılma sütunu gerçek hava ölçümüyle doğrulanmış değildir.
- Tarih aralığı/observer yüksekliği ilk teslimat sözleşmesidir. Seyrek örnekler aralıktaki her konum ve anın aynı doğrulukta olduğunu kanıtlamaz. Mobil/istemci performans bütçesi A-009 hâlâ açıktır.

Detaylı yerel raporlar `.local/science/` altına çıkar; [paylaşılan rapor](science/astronomy-engine-2.1.19-report.json) özeti, bütün tekil konumları, istisnaları, olay farklarını ve ortamı tutar. Yayın script'i sunulan yön, yükseklik, olay veya dil portu eşiği aşılırsa raporu başarılı kabul etmez.

## Anonim API denemesi

`./scripts/Start-LocalBackend.ps1` sonrasında:

```powershell
$body = @{ latitude=41.0082; longitude=28.9784; instant='2026-10-30T23:00:00+03:00'; bodies=@('saturn') } | ConvertTo-Json
Invoke-RestMethod http://127.0.0.1:5187/api/v1/sky/positions -Method Post -ContentType application/json -Headers @{'Accept-Language'='tr'} -Body $body
```

`POST /api/v1/sky/positions`: istekte `latitude`, `longitude`, açık ofsetli `instant`, isteğe bağlı `elevationMeters` ve `bodies` vardır. `bodies` yoksa dokuz hedef; varsa 1–9 farklı desteklenen kimlik gerekir. `earth`, sayısal enum, geçersiz/ofsetsiz tarih ve sınır dışı konum sessizce düzeltilmez. Yanıt UTC anı, iki dilli ad/açıklamalar, birimleri belirli sayılar, model bilgisi ve sözlük kimliklerini içerir. Girdi koordinatları geri kopyalanmaz. İstemci gelen yanıtı kendi istek/bağlam sürümüyle eşleştirecek; frontend'de eski yanıtın yeni bağlamı ezmesini önleme işi hâlâ gereklidir.

`POST /api/v1/sky/horizon-crossings`: aynı gözlemci/an alanları ve tek `body` alır. Aralık tam 24 UTC saatidir, yerel takvim günü değildir; merkez/0°/kırılmasız tanımı yanıt içinde iki dilde açıklanır. Aralıkta bulunamayan zaman `null` kalır.

Bu iki uç anonimdir, `Cache-Control: no-store` kullanır, istek gövdesi 8 KiB ile sınırlıdır; hesap politikası süreç/IP başına 120 istek/dakikadır. Çoklu instance ortak limit ve proxy adres güveni üretim işi olarak açıktır. Hava, arazi, yıldız/takımyıldız kataloğu, harita çizimi, GPS izni veya pusula bu uçlarla uygulanmış sayılmaz.

## Bu basamağın doğrulama kaydı

79 otomatik test: 18 koordinat/çekirdek, 19 astronomi ve 42 API/entegrasyon. Temiz Release derlemesi 0 uyarı/0 hata. Kamuya açık astronomi uçları, olmayan kimlik DB'si ve kullanılamayan cache ile de API testinde çalışır; kimlik regresyonları gerçek yerel PostgreSQL/Redis ile sınandı. Sonraki gerçek Kestrel HTTP denemesinde tr/en dokuz hedef, 21 terim/sözlük bağlantıları, model metadata'sı, kutup yön sınırı ve geçiş bulunmayan pencere doğrulandı; chunked aktarımda 8 KiB sınırı ve çevrilmiş 413 yanıtı da geçti. Deneme host'u kapatıldı.

1.168 normalize satır ham JPL yanıtları ve SHA-256 değerleriyle birebir kontrol edildi; C#/JS eşlik raporu ayrı üretildi. Güncel kaynaklarla NuGet ve npm taraması bilinen zafiyet raporlamadı. Bu kayıt iki ham kutup yön başarısızlığını ortadan kaldırmaz; genel bilimsel doğruluk, üretim güvenliği/performansı veya bütün kabul kriterlerinin tamamlandığı anlamına gelmez.
