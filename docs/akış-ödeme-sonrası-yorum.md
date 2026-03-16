# Ödeme Sonrası Yorum Akışı – Plan ve Çözüm

## Mevcut sorun

- Ödeme tamamlanınca **yorum yükleniyor** (loading) ekranı açılıyor.
- Yorum aslında **Benim Okumalarım**’a kaydediliyor ve orada “Yorum hazırlanıyor” / hazır görünüyor.
- Buna rağmen kullanıcı **bekleme ekranında** kalıyor; çıkıp **Profil → Benim Okumalarım**’a kendisi gitmek zorunda kalıyor.
- Bu durum her sekme (nümeroloji, doğum haritası, kahve, el falı vb.) için tekrarlanıyor ve kafa karıştırıcı.

## Hedef akış (net kurallar)

1. **Ödeme sonrası**  
   - Ödeme başarılı → **Loading ekranı** açılsın (mevcut davranış).

2. **Yorum hazır olunca**  
   - Loading ekranı yorumu alana kadar dener (mevcut retry mantığı).  
   - **Yorum hazır olduğu anda** → Doğrudan ilgili **Sonuç ekranına** gitsin (Nümeroloji, Doğum Haritası, Kahve, El, Synastry vb.).  
   - Kullanıcı yorumu **aynı akışta** okur, Benim Okumalarım’a gitmek zorunda kalmaz.

3. **Belirli süre / deneme sonunda hâlâ hazır değilse**  
   - Loading ekranı **sadece geri (pop) yapmasın**; kullanıcıyı boşta bırakmasın.  
   - Bunun yerine: **Profil sayfasına** yönlendirsin.  
   - Açıklayıcı bir **SnackBar** gösterilsin:  
     *“Yorumunuz arka planda hazırlanıyor. ‘Benim Okumalarım’ listesinde görünecek; aşağı çekerek yenileyebilirsiniz.”*  
   - Böylece kullanıcı ya hemen sonucu görür ya da **tam olarak nereye** (Profil → Benim Okumalarım) gideceğini bilir; ekrandan çıkıp “nerede görürüm?” diye düşünmez.

## Teknik uygulama özeti

| Ekran / Sekme   | Yorum hazır olunca        | Zaman aşımı / hata / retry bitince      |
|-----------------|---------------------------|-----------------------------------------|
| Nümeroloji      | → Nümeroloji sonuç ekranı | → **Profil** + SnackBar (pop yok)       |
| Doğum haritası  | → Doğum haritası sonuç    | → **Profil** + SnackBar                 |
| Kahve falı      | → Kahve sonuç ekranı      | → **Profil** + SnackBar (şu an Ana sayfa) |
| El falı         | → El falı sonuç ekranı    | → **Profil** + SnackBar (şu an Ana sayfa) |
| Synastry        | → Synastry sonuç          | (varsa loading) → **Profil** + SnackBar |

- **Profil ekranı**: İsteğe bağlı parametre ile “loading’den geldim” mesajı (SnackBar) gösterilebilir.  
- Tüm loading ekranlarında **hata / timeout** durumunda **Navigator.pop** yerine **Profil’e pushAndRemoveUntil + SnackBar** kullanılır.

## Sonuç

- Kullanıcı **tek bir net akış** görür:  
  - Ya **sonuç ekranı** (yorum hazır),  
  - Ya da **Profil → Benim Okumalarım** (hâlâ hazırlanıyorsa) + net mesaj.  
- “Bekleme ekranı çıkıyor ama nereye gideceğimi bilmiyorum” hissi ortadan kalkar.
