# Donmuş olay takvimi

2000–2035 dahil **2623 kayıt**. `calendar.json` tek kök kaynak; `manifest.json` içerik SHA-256, motor sürümü, adet ve toleransı saklar. BFF/C# aynı baytları doğrular. Son başarılı üretim zamanı manifesttedir; otomatik yenilenen canlı olay servisi değildir.

**1781 birincil Ay evresi**, [USNO](https://aa.usno.navy.mil/data/MoonPhases) yıllık API'sinden arşivlendi. `usno/2000.json`…`2035.json`, URL/hash kaydı `sources.json`. USNO Universal Time dakika değerleri UTC dakika hassasiyetinde yorumlanır; saniye/UT1 hassasiyeti iddia edilmez. Her olayda USNO anı, Astronomy Engine 2.1.19 bağımsız hesap anı ve mutlak fark saklanır. 120 s eşiğe karşı en büyük fark 79,946 s. [Rapor](../../docs/science/calendar-reference-report.json).

Diğer **842 hesaplanan kayıt**: yılda iki ekinoks/iki gündönümü, Mars/Jüpiter/Satürn/Uranüs/Neptün karşı konumları, Merkür/Venüs alt/üst kavuşumları ve en büyük uzanımları. [Sabit MIT motor](https://github.com/cosinekitty/astronomy/tree/v2.1.19). Motorun göreli ekliptik boylam/mevsim/uzanım tanımı kullanılır; bu zamanlar başka takvimlerin farklı görünür/minimum açısal ayrım tanımlarıyla eşit varsayılmaz, bağımsız sertifikalı değildir. UI kaynaklı Ay evresi ve hesaplanan olay etiketlerini ayırır.

Olay UTC anı küreseldir; seçili konumda ufuk üstünde olması veya gözlenebilirliği garanti edilmez. ±2 gün aylık API tamponu IANA yerel ayına istemcide filtrelenir. Meteor yağmurları, asteroitler, Ay–yıldız yakınlaşmaları/tutulmalar yeni kaynak/lisans/doğrulama bekleyen P1 genişlemesidir.

Yalnız açık bakım işlemi:

```powershell
python scripts/science/refresh_planning_sources.py --refresh --source events
node scripts/science/build_event_catalog.mjs --refresh
```

İlk komut mevcut arşivi tekrar kullanır; yeni kaynak anlık görüntüsü istenirse ilgili arşiv önce ayrı bakım kararıyla yenilenir, kaynak tarihi/hash yeniden değerlendirilir. Normal test/derleme indirme yapmaz. USNO sayısal olguları kod veya makale metni değildir; kaynak atfı korunur. [API belgeleri](https://aa.usno.navy.mil/data/api), [ADR](../../docs/adr/0007-gozlem-takvimi-ve-yer-adlari.md).
