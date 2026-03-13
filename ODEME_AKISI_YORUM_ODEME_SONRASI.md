# Ödeme Akışı: Yorum Önce Üretilir, Ödeme Sonrası Görünür

## Hedef

- **Yorum (result_text)** ödeme yapılmadan **hiçbir zaman** istemciye gönderilmez.
- **Ödeme tamamlandıktan sonra** istemci sadece detay çektiğinde yorumu görür; ekstra "generate bekleme" veya arka plana alınca kaybolma riski olmaz.

## Mantık

1. **Üretim zamanı:** Yorum, kullanıcı ödemeden önce (veri tamam olduğunda) üretilip veritabanında saklanır.
2. **Gösterim:** Tüm "reading detail" API’leri, `is_paid == false` iken `result_text` / `comment` alanını **döndürmez** (null/boş). `is_paid == true` iken döndürür.
3. **Ödeme sonrası:** Uygulama sadece `GET detail` yapar; yorum zaten hazır olduğu için ekranda hemen gösterilir. Generate tetikleme veya polling gerekmez.

---

## Backend Değişiklikleri (Özet)

### 1. Detail / get yanıtlarında result_text’i is_paid’e bağla

Her okuma türü için "detail" veya "get" dönen yerde:

- `is_paid == False` → `result_text` / `comment` alanını **null** veya boş string yap (veya hiç ekleme).
- `is_paid == True` → Mevcut gibi `result_text` / `comment` doldur.

Böylece ödeme yapılmadan yorum asla görünmez.

### 2. Generate’i “ödeme öncesi” tetikle

Yorumun, ödeme ekranına gelmeden veya "Öde"ye basılmadan önce üretilmesi gerekir. İki pratik yol:

**Seçenek A – Ödeme ekranına girince (önerilen)**  
- Uygulama ödeme ekranına geçer geçmez (veya "Öde" butonuna basıldığında) **generate’i tetikleyen** bir endpoint çağırır (örn. `POST /coffee/{id}/ensure-generated` veya mevcut `POST /.../generate`).
- Backend: Okuma zaten üretilmişse hemen 200 döner; üretilmemişse generate eder, **yanıtta result_text göndermez** (sadece 200 veya status).
- Uygulama: Bu çağrı bittikten sonra (veya zaman aşımı ile) IAP’e geçer. Kullanıcı ödemeyi yapar → verify → `GET detail` → yorum gelir ve gösterilir.

**Seçenek B – Veri tamam olunca (upload/select sonrası)**  
- Foto yükleme / kart seçimi gibi "veri tamam" anında backend generate’i (arka planda veya senkron) tetikler.
- Artı: Ödeme ekranında bekleme olmaz.  
- Eksi: Ödemeyi tamamlamayan kullanıcılar için de yorum üretilir (maliyet).

Hangisini kullanacağınızı siz seçin; bu dokümanda **Seçenek A** üzerinden gidiyoruz.

### 3. Verify sadece mark_paid yapsın

`/payments/verify` sadece ödemeyi doğrulasın ve ilgili okumayı **mark_paid** yapsın. Verify içinde generate çağrısı **olmasın**; yorum zaten önceden üretilmiş olacak.

---

## Uygulama (Mobile) Değişiklikleri (Özet)

### 1. Ödeme ekranında “önce generate, sonra IAP”

- Ödeme ekranı açıldığında (veya "Öde" tıklanınca) önce **ensure-generated** (veya generate) endpoint’ini çağır.
- İstersen "Yorumunuz hazırlanıyor..." gibi kısa bir loading göster; bitince IAP’i aç.
- Generate tamamlandıktan sonra IAP’e geç; kullanıcı ödemeyi yapar.

### 2. Verify sonrası doğrudan “sonuç” ekranına geç

- Verify başarılı olunca **loading/polling ekranına değil**, doğrudan **sonuç ekranına** geç.
- Sonuç ekranı sadece `GET detail` (ilgili reading için) yapsın.
- Gelen yanıtta `result_text` / `comment` dolu olacak (çünkü is_paid true ve backend artık döndürüyor). Bunu göster; ekstra generate veya poll **yapma**.

### 3. Eski akışla uyum (opsiyonel)

- Eğer `GET detail` bazen hâlâ boş dönüyorsa (eski kayıtlar veya geçiş dönemi), o zaman mevcut gibi bir kez generate tetikleyip kısa poll ile sonuç ekranına geçmeyi fallback olarak bırakabilirsiniz.

---

## Tür bazlı kısa kontrol listesi

| Tür        | Detail’de result_text’i is_paid’e bağla | Generate tetikleme noktası (Seçenek A) |
|-----------|-----------------------------------------|----------------------------------------|
| Coffee    | Evet                                    | Ödeme ekranı açılınca veya “Öde” tıklanınca |
| Tarot     | Evet                                    | Ödeme ekranı açılınca veya “Öde” tıklanınca |
| Hand      | Evet                                    | Aynı şekilde                            |
| Numerology| Evet                                    | Aynı şekilde                            |
| Birthchart| Evet                                    | Aynı şekilde                            |
| Personality | Evet                                  | Aynı şekilde                            |
| Synastry  | Evet                                    | Aynı şekilde                            |

---

## Sonuç

- **Yorum gelir, ödeme yapılmadan görünmez:** Backend detail API’leri result_text’i sadece `is_paid == true` iken döndürür.
- **Ödeme yapıldıktan sonra gelen yorum görünür:** Uygulama verify sonrası doğrudan detail çekip sonuç ekranında gösterir; generate’i verify sonrasına bırakmadığımız için arka plana alınca “ödeme oldu yorum gelmedi” durumu ortadan kalkar.

Bu doküman, "ödeme sonrası yorum gelir ama ödeme yapılmadan görünmez" akışının nasıl uygulanacağının aşama aşama özetidir. İsterseniz bir sonraki adımda backend’de hangi dosyada hangi satırın değişeceğini ve mobilde hangi ekranlarda ne yapılacağını tek tek yazabilirim.
