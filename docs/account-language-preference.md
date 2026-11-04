# Hesapta kalıcı dil tercihi — K-046 / 4 Kasım 2026

Dil, hesap profilinin PreferredLanguage alanında PostgreSQL identity modülünde tutulur. Varsayılan en; şu anda en/tr kabul edilir. Migration mevcut hesaplara en varsayılanını ekler; yeni hesap seçili kayıt diliyle başlar. İşlem e-postaları önceki karar gereği İngilizce kalır.

## Ortak backend sözleşmesi

- Kimlik doğrulanmış POST /api/v1/auth/language, JSON preferredLanguage: en veya tr alır; güncellenmiş UserProfile döndürür. Mevcut cookie ve JWT kimlik doğrulaması kullanılır; ileriki mobil istemci aynı endpoint'i çağırır.
- GET /api/v1/auth/me, browser login ve profil güncelleme yanıtları preferredLanguage içerir. Accept-Language yanıt mesajlarının dilidir; kayıtlı tercihi kendiliğinden değiştirmez.
- Kullanıcı ID'si gövdeden alınmaz. İsteğe bağlı X-Yorungez-Account eşleşmesi yanlış hesaba yazmayı 409 ile önler. Anonim yazma 401, desteklenmeyen değer 400; kişisel yanıtlar no-store.

## Web, PWA ve cihazlar

Sayfa açılışında, girişten sonra, pencere odağına/ağa dönüşte ve sekmeler arası hesap bildirimiyle profil yeniden okunur. Kayıtlı dil aktif hesaba uygulanır. Kullanıcı seçimi önce sunucuya yazılır; hata durumunda başarılı kaydetme gösterilmez. Bekleyen istek ve hesap değişimi nesil denetimiyle ayrılır; seçim sırasında gelen hesap bildirimi sonrasında yeniden profil kontrolü yapılır.

Hesapsız kullanıcı cihazlar arasında tanınamaz. Aynı tarayıcıda yalnız yorungez-language=en/tr tercih çerezi kullanılır: bir yıl, Path=/, SameSite=Lax ve HTTPS'de Secure. Kullanıcı ID, oturum, not veya koordinat içermez. Profil tercihi girişte bu yerel değerin önüne geçer. Ana adres yalnız desteklenen çerez değerine göre yönlenir, aksi halde /en; redirect private/no-store ve Vary: Cookie taşır.

Statik EN/TR PWA kabuğu korunur; hesaba ait yanıtlar offline pakete girmez. PWA İngilizce başlangıç yolundan açılsa da hidrasyonda aynı tarayıcı tercihi geri yüklenir. Çevrimdışıyken hesaba dil yazıldığı iddia edilmez. Diğer cihazın hesabı oturum açılışı/yenileme/odak dönüşünde güncellenir; aktif ekranlar arasında anlık sunucu push senkronizasyonu eklenmedi.

## Doğrulama

67 istemci testi ve tip kontrolü; yerel tarayıcıda TR seçim, yenileme, ana adres yönlenmesi, /en başlangıcından tercihin geri yüklenmesi ve 390 px menü kontrolü geçti. Entegrasyon testi JWT ile iki istemci, browser cookie oturumu, PostgreSQL okuması, hesap yalıtımı, anonim/yanlış sahip/bozuk dil retleri ve profil adı güncellemesinin dili korumasını kapsar. Yerel Docker/PostgreSQL üzerinde tam backend paketi (140 test) geçti; migration ve tercih akışı bu testte gerçek veritabanıyla uygulandı. Production/PWA derlemesi geçti; EF modelinin migration ile eşleşmesi doğrulandı. Fiziksel cihaz kabulü ayrı kalır.
