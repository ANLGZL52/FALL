# Ödeme Sonrası Yorum Gelmezse – Ne Yapılacak?

## Kullanıcı tarafı (uygulama içinde adımlar)

Aşağıdaki adımlar, **kullanıcıya uygulama içinde veya yardım metninde** anlatılabilir.

---

### Adım 1: Uygulamayı kapatmayın, bir süre bekleyin

- Ödeme tamamlandıktan sonra **en az 30–60 saniye** uygulama açık kalsın.
- Bazen yorum 10–30 saniye içinde gelir; ekran otomatik güncellenir.
- **Uygulamayı arka plana almayın** ve bildirimlere tıklayıp çıkmayın.

---

### Adım 2: Yine gelmediyse – Profil’e gidin

1. Ana sayfada sol üst **menü (≡)** veya **Profil** ikonuna tıklayın.
2. **Profil** ekranına girin.

---

### Adım 3: “Benim Okumalarım” bölümünü açın

1. Aşağı kaydırarak **“Benim Okumalarım”** kartını bulun.
2. Son yaptığınız okumalar (kahve falı, tarot, el falı vb.) burada listelenir.
3. **Az önce ödeme yaptığınız okuma** listede görünüyor olmalı (tarih ve tür ile).

---

### Adım 4: İlgili okumaya tıklayın

1. Ödeme yaptığınız okumanın **satırına** tıklayın (örn. “Kahve Falı”, “Tarot”).
2. Ekran “Okuma yükleniyor...” diyerek açılır.
3. Sunucuda yorum hazırsa **sonuç ekranı** açılır; yorumu burada görürsünüz.

---

### Adım 5: Hâlâ “henüz hazır değil” veya boşsa

1. **Birkaç dakika bekleyip** aynı okumaya tekrar tıklayın (Profil → Benim Okumalarım → ilgili okuma).
2. Ödeme bazen geç işlenir; bir süre sonra yorum hazır olur.
3. **Birkaç denemeden sonra da** sonuç gelmiyorsa: Uygulama içi **Destek / İletişim** veya **yardım** bölümünden bize yazın; okuma ID’si veya tarih bilgisiyle kontrol edebiliriz.

---

## Özet akış (kullanıcı için)

```
Ödeme yaptım → Yorum gelmedi
    ↓
1. 30–60 sn bekledim, uygulama açık kaldı → Yine gelmedi
    ↓
2. Profil → Benim Okumalarım
    ↓
3. Az önce ödediğim okumaya tıkladım
    ↓
4. Sonuç açıldı → Yorumu gördüm
    VEYA
   “Henüz hazır değil” → Birkaç dakika sonra tekrar tıkladım → Sonuç geldi
    VEYA
   Hâlâ gelmiyor → Destek / iletişim ile yazıyorum
```

---

## Teknik taraf (ne olmalı ki bu akış çalışsın?)

- **Backend:** Ödeme doğrulandığı anda (`mark_paid` / verify) ilgili okuma için **generate** tetiklenmeli; yorum sunucuda üretilmeli.
- **Profil listesi:** `profile/history` API’si son okumaları (ödemenin yapıldığı okumalar dahil) döndürmeli.
- **Okumaya tıklayınca:** Detay API’si (coffee/tarot/el/numerology/birthchart/synastry detail) çağrılmalı; `result_text` / `comment` doluysa sonuç ekranı açılmalı (bunu zaten `ReadingDetailLoaderScreen` ve ilgili result ekranları yapıyor).

Bu doküman, kullanıcıya “ödeme sonrası yorum gelmezse ne yapılacak?” sorusunun **aşama aşama** cevabıdır.
