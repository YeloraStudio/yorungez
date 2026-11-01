# ADR-0014 — Apache-2.0 ve public kaynak yayını

- Tarih: 1 Kasım 2026
- Durum: Kabul edildi; kullanıcının public yayın talimatı ve açık Apache-2.0 seçimi
- İz: K-029, A-001; mevcut FR/UJ/AC kimlikleri ve ürün öncelikleri değişmez

## Karar

Mevcut çözümün backend, frontend, test, veri kökeni ve belgeleri tek `YeloraStudio/yorungez` public deposunda tutulur. Bu karar başka yerel projeleri yayınlama yetkisi olarak genişletilmez. Özgün kod/özgün proje belgeleri Apache-2.0; LICENSE/NOTICE kökte. Üçüncü taraf kaynak, veri, çizim ve fotoğraflar kendi lisans/atıflarında kalır. Apache-2.0 bunları yeniden lisanslamaz.

Gerçek `.env`, yerel ayarlar, key ring, kişisel veri/veritabanı dökümleri, üretim/Portainer ayarları ve sunucu erişimi yayınlanmaz. Genel geliştirme Compose, migration ve placeholder örnekler kaynak kodunun parçasıdır. Public SMTP adresleri operasyonel hesabı açıklamak yerine `sender@example.com` gösterir; tarihsel SMTP başarı kaydı bu örnek adrese ait bir kimlik doğrulama iddiası değildir.

Git index'i özel dosya/değer karşılaştırmasıyla; başlangıç commit geçmişi redakte Gitleaks ile yayın öncesi incelenir. CI salt okuma varsayılanı, SHA sabitli action, GitHub-hosted runner, kilitli restore, uygulama/bilimsel kontrol ve CodeQL kullanır. Üretim sırları veya deploy yetkisi yoktur. Güvenlik bildirimi özel GitHub kanalıyla alınır; branch kuralları/secret scanning fiili destek ve erişimle doğrulanır.

Tek aktif bakımcı kendi PR'ını onaylayamaz. PR ve başarılı kontroller istenirken zorunlu insan onay sayısı başlangıçta sıfır tutulabilir; bu, inceleme kalitesinin tamamlandığı iddiası değildir. Ekip genişlediğinde bağımsız onay politikası tekrar değerlendirilir.

## Sonuç ve sınırlar

İki dilde README ve katkı/güvenlik rehberi eklendi. Eski README paket geçmişi ayrı belgede korunur. Orijinal PRD arşivi ve kaynak veri/görsel byte'ları değişmez. Public yayın önceki fiziksel cihaz, PWA çok tarayıcı ve üretim backup kabulünü kapatmaz. Yayın güvenliği incelemesi tam uygulama pentesti değildir; tarayıcılar her sırrı/hata türünü bulamaz.

[İnceleme ve kanıt](../open-source-publication.md), [lisans envanteri](../../THIRD_PARTY_NOTICES.md).
