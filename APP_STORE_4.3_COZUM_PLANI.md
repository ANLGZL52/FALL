# App Store 4.3(b) Reddi – Problem, Deneyimler ve Çözüm Planı

## 1. PROBLEM TANIMI

### Apple’ın gerekçesi (Guideline 4.3(b) – Design – Spam)

- Uygulamanız **birincil olarak** şunları sunuyor: **astroloji, burçlar, el falı, fal/kehanet veya zodiyak raporları**.
- Bu özellikler, mağazada zaten **çok sayıda benzer uygulama** ile **içerik ve işlev olarak tekrarlanıyor**.
- Apple’ın ifadesi: *“Bu özellikler yararlı, bilgilendirici veya eğlenceli olabilir; ancak App Store’da bu tür uygulamalardan yeterince var ve spam kabul ediliyor.”*

### Sizin uygulamanız (LunAura) neden bu tanıma giriyor?

Ana ekranda ve tanıtımda **birincil odak** tam olarak bu kategoride:

- Kahve falı  
- El falı (palm reading)  
- Tarot  
- Numeroloji  
- Doğum haritası (astroloji)  
- Kişilik analizi (astroloji tabanlı)  
- Sinastri (astroloji)  

“Hakkında” metninde de uygulama **“astroloji ve fal kategorisinde benzersiz bir birleşik platform”** olarak tanımlanıyor. Apple için bu, **kategori olarak doymuş fal/astroloji uygulaması** anlamına geliyor; “birleşik” olsa bile birincil konsept aynı kaldığı sürece 4.3(b) riski devam ediyor.

**Özet:** Problem, **teknik hata değil**; Apple’ın **“bu kategoride yeterince uygulama var, bir tane daha istemiyoruz”** politikası. Yani **konsept ve sunum** (birincil özelliklerin ne olduğu) problem.

---

## 2. BU PROBLEMLE KARŞILAŞANLAR NE YAPMIŞ?

### 2.1 Sadece özellik çıkarmak / sadece Tarot bırakmak – **işe yaramıyor**

- Apple Developer Forums’da bir geliştirici: horoskop, numeroloji vb. kaldırıp **sadece Tarot** bıraktı; Apple yine **aynı 4.3(b)** gerekçesiyle reddetti.
- Mesaj: “Apple içeriğe çok takılmıyor, bu **tür uygulama kategorisinin** kendisini doymuş görüyor.”

### 2.2 İtiraz (Appeal) – **genelde düşük başarı**

- Birçok geliştirici “benzersiz özelliklerimiz var” diye itiraz etti; çoğu yine aynı kopyala-yapıştır red cevabı aldı.
- Yine de **denenebilir** (özellikle gerçekten farklı bir açı varsa), ancak tek başına güvenilir çözüm değil.

### 2.3 İşe yarayan yaklaşım: **Kategori değiştirmek – fal/astroloji “ikincil” olmalı**

Onay alan uygulamaların ortak noktası:

- **Birincil kategori:** Wellness (refah), mental sağlık, **günlük (journal)**, meditasyon, kişisel gelişim.
- **İkincil öğe:** Astroloji, tarot, rüya yorumu vb. **ana ürün değil**, ana ürünün bir parçası.

Örnekler (App Store’da mevcut):

| Uygulama | Birincil konsept | Astroloji/fal rolü |
|----------|------------------|---------------------|
| **Yap: Dream Astrology Journal** | Video günlük + rüya + duygu takibi | Astroloji, ay evreleri günlük/ruh hali ile entegre; “dream astrology **journal**” |
| **Lumia** | Spiritüel / kişisel **günlük** | Tarot + astroloji günlük ve yansıma aracı olarak |
| **Soulloop** | Meditasyon, yoga, wellness, koçluk | Astroloji ve rehberlik bunun bir parçası |
| **Reflection (AI Journal)** | Günlük, kariyer, ilişkiler, mindfulness | Astroloji **tek bir rehber programı** olarak, ana odak değil |

Sonuç: **“Fal / astroloji uygulaması”** olarak sunulursan 4.3(b) riski yüksek; **“günlük / wellness / kişisel gelişim uygulaması, içinde fal/astroloji araçları da var”** olarak konumlanırsan onay şansı artıyor.

---

## 3. SİZ NE YAPMALISINIZ?

### Seçenek A: **Konsept pivotu (önerilen uzun vadeli yol)**

Uygulamayı **“fal uygulaması”** yerine **“kişisel refah / günlük / yansıma”** uygulaması gibi konumlayın; fal ve astroloji **araç** olsun, **ana kimlik** olmasın.

Yapılabilecekler (fikir):

1. **Günlük / yansıma modülü ekleyin**  
   - Günlük not, ruh hali, hedef, minnettarlık vb.  
   - Tarot/kahve/el falı **okumalarını** günlük kayıtlarla ilişkilendirin (örn. “Bugünkü tarot çekimim + notlarım”).

2. **Ana ekran ve mağaza metinlerini değiştirin**  
   - Ana başlık: “Günlük & Kişisel İçgörü” / “Reflection & Insights” benzeri.  
   - Alt metin: “Günlük tutma, tarot, kişisel analiz ve astroloji araçlarıyla kendini keşfet.”  
   - **Önce** günlük/wellness, **sonra** “içinde tarot, kahve falı, doğum haritası da var” vurgusu.

3. **App Store Connect’te**  
   - **Kategori:** Lifestyle veya Health & Fitness (wellness odaklı) daha uyumlu olabilir.  
   - **Alt başlık / açıklama / anahtar kelimeler:** “astroloji uygulaması”, “fal uygulaması” yerine “günlük”, “kişisel gelişim”, “içgörü”, “reflection” ağırlıklı.

4. **Ekran sırası**  
   - İlk açılışta günlük/hoş geldin ekranı; fal türleri ikinci planda (bir “Keşfet” veya “Araçlar” bölümünde).

Bu, mevcut 7+ analiz türünü kaldırmak değil; **sunumu ve birincil kimliği** değiştirmek.

### Seçenek B: **Önce itiraz (Appeal)**

- App Store Connect’te red mesajına **Reply** ile itiraz edin.
- Kısa ve net yazın:  
  - “We have redesigned our app as a **personal reflection and journaling** tool; astrology and reading types are **supporting tools** for self-reflection, not the primary purpose. We have added [X] and changed positioning to [Y]. We believe we are no longer primarily a fortune-telling app and would appreciate a re-review.”
- Eğer henüz günlük/wellness özelliği yoksa, “we are adding a journal/reflection module and repositioning the app” diyebilir ve sonra gerçekten ekleyip yeniden gönderebilirsiniz.
- Başarı garantisi yok; ama denemek mantıklı, özellikle pivot planınızı anlattığınızda.

### Seçenek C: **Alternatif dağıtım (EU)**

- AB’de (EU) alternatif mağazalar ve notary ile App Store dışı dağıtım mümkün.  
- Sadece EU kullanıcıları için ek bir seçenek; 4.3(b) reddini “çözmüş” olmaz, farklı bir kanal açar.

---

## 4. ÖZET VE SIRALI ADIMLAR

| Adım | Ne yapılacak |
|------|-------------------------------|
| 1 | **Problemi kabul edin:** Red, “hatalı kod” değil; **kategori (fal/astroloji birincil)** politikası. |
| 2 | **İtiraz (isteğe bağlı):** App Store Connect’te Reply ile kısa, İngilizce, saygılı bir açıklama + “repositioning as journal/wellness” ifadesi. |
| 3 | **Pivot planı:** Uygulamayı **günlük / kişisel refah / yansıma** uygulaması olarak konumlayın; fal/astroloji **ikincil araç** olsun. |
| 4 | **Ürün:** Mümkünse günlük/yansıma modülü ekleyin; ana ekran ve metinleri buna göre güncelleyin. |
| 5 | **Mağaza:** App Store’da kategori, başlık, açıklama ve anahtar kelimeleri wellness/journal odaklı yapın. |
| 6 | **Yeni sürüm:** Değişiklikleri paketleyip yeni versiyon olarak tekrar gönderin; itiraz cevabı beklemeden de yapabilirsiniz. |

---

## 5. KAYNAKLAR

- [App Store Review Guidelines – 4.3 Design](https://developer.apple.com/app-store/review/guidelines/#design)  
- [Apple Developer Forums – App Rejection for Astrology App (Thread 737999)](https://developer.apple.com/forums/thread/737999)  
- [Apple Developer Forums – 4.3 Design Spam (Thread 112848)](https://developer.apple.com/forums/thread/112848)  
- Onaylı örnekler: Yap (dream astrology **journal**), Lumia (tarot + **spiritual journal**), Soulloop (wellness + astrology).

---

*Bu belge, 24 Şubat 2026 tarihli 4.3(b) reddine ve LunAura projesine göre hazırlanmıştır. Resmi hukuki veya Apple politikası yorumu değildir.*
