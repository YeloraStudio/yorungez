# ADR-0012 — Hesap menüsü, ad-soyad ve erişilebilir giriş

**1 Kasım 2026 / K-027 / TECH-07 / PRD 1.10 — Uygulandı; üretim kabulü kısmi.**

İz: FR-06–07/FR-11; UJ-04–05; AC-07–09/AC-13. Kullanıcının yeni talimatı kayıt sırasında ad, soyad, e-posta ve parola alınmasını; menüde oturumsuz giriş/kayıt ve oturumlu ad-soyad gösterilmesini gerektirir. Önceki e-posta/parola dışında zorunlu alan yok hükmü bu kararla değişir.

Identity modülünde `FirstName/LastName` en fazla 100 karakter, boş olmayan, kontrol karakteri içermeyen Unicode metindir. Yalnız Latin alfabesi veya iki kelimelik ad kısıtı yoktur. Girdi kırpılır; yeni kayıtta her iki alan sunucuda zorunludur. Parola 15–128 karakter, zorunlu e-posta doğrulaması, JWT/refresh, HttpOnly oturum ve İngilizce markalı e-posta kuralları değişmez. Ad-soyad JWT içine veya URL'ye eklenmez.

Migration `20261101084830_AccountNames` alanları nullable ekler; mevcut hesaplara isim uydurmaz ve notlarını değiştirmez. Eski hesap giriş yapabilir, ad-soyadını tamamlar. Yetkili `/auth/profile` yalnız oturum sahibini günceller; beklenen hesap başlığı başka sekmede hesap değişimini yakalar. İsimler `/auth/me` ve tarayıcı giriş yanıtında sunulur; UI kullanıcı metnini HTML olarak yürütmez.

Menü ve Defterim tek açık sayfa oturum durumunu kullanır. Giriş/çıkış/hesap değişimi BroadcastChannel ile yeniden denetlenir; başka hesabın taslağı devralınmaz. Ad-soyad yalnız oturum doğrulandığında gösterilir. Hesap yanıtı ve kişisel kayıtlar no-store/private kalır.

Oturum çerezi bulunmayan `me` isteği BFF'de doğrudan 401 olur; boş ziyaretçi hesabı kontrol etmek için .NET API beklemez. Servis erişim hatası, tarayıcının çevrimdışı bildirimi ve giriş yapılmamış olması ayrı durumlardır. Servis erişilemiyorken de giriş/kayıt formuna erişilir; gönderim başarısı uydurulmaz. Gerçek kişisel kayıt okuma/yazma için çalışan API ve PostgreSQL gerekir.

Yerel incelemede hesap API'si ve servisler kapalıydı; önceki arayüz bunu genel internet hatası olarak sunuyordu. [Ortak başlatıcı](../../scripts/Start-LocalApp.ps1) altyapı/API ve üretim Web/PWA'yı hazır olma kontrolüyle açar. Terminal açık tutulur; portu dolu hizmete müdahale edilmez. [Durdurucu](../../scripts/Stop-LocalApp.ps1) yalnız kaydedilen PID + oluşturma anı eşleşen başlatıcının süreç ağacını durdurur; DB volume'ları korunur. Testte `Mailpit`, normal kullanımda `Auto` özel Gmail ortamını seçer. Gerçek alıcıya QA e-postası gönderilmez.

[Uygulama, ekranlar ve doğrulama](../hesap-menusu-ve-cevrimdisi-gokyuzu.md). Üretim oturum/backup, gerçek posta istemcisi teslimi/render ve fiziksel cihaz kabulü açık kalır.
