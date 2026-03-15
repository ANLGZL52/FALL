# Apple App Store 4.3(b) – Planlama Dokümanı

Bu dokümanda **Guideline 4.3 Design: Spam** nedir, neden fal/astroloji uygulamaları risk altında, diğer geliştiriciler nasıl çözmüş ve **LunAura** için somut aksiyon planı özetlenmektedir. **Sadece planlama** yapılmıştır; kod değişikliği bu dokümanda yoktur.

---

## 1. Apple 4.3(b) Nedir?

- **Kategori:** Design → Spam  
- **Resmi odak:** Aynı işlevi sunan, sadece içerik/dil ile ayrışan uygulamaların reddedilmesi; “junk / tekrarlayan” deneyim.

### 1.1 Ne Zaman Tetiklenir?

| Durum | Açıklama |
|-------|----------|
| Aynı özellik seti | Diğer App Store uygulamalarıyla aynı işlevler, sadece içerik/dil farkı |
| Benzer binary / metadata | Aynı veya çok benzer ikon, ekranlar, kavram |
| Benzersiz deneyim yok | Kategoride zaten çok uygulama var; yeni uygulama belirgin fark sunmuyor |
| Template / reskin | Hazır şablon veya satın alınan kodla üretilmiş, çok sayıda benzer uygulama |
| Çoklu benzer uygulama | Aynı veya farklı hesaplardan benzer uygulamaların gönderilmesi |

### 1.2 Apple’ın Özellikle Sıkı Baktığı Kategoriler

- Astroloji / horoscope  
- Fal (kahve, el, tarot vb.)  
- Fortune telling / kehanet  
- Dating, flashlight, basit utility gibi doymuş kategoriler  

**LunAura:** Fal + astroloji (el, kahve, tarot, numeroloji, doğum haritası, kişilik, sinastri) → **4.3 riski yüksek kategoride.**

---

## 2. İnsanlar Bu Durumu Nasıl Çözmüş? (Web / Forum Özeti)

### 2.1 Apple ve Geliştirici Önerileri

- **Farklılaşma:** Özellik seti ve kullanıcı deneyiminde **ölçülebilir, anlatılabilir** farklar.
- **“Meet with Apple”:** 4.3 reddinde bi-weekly randevu ile özel durumu anlatmak.
- **Tek container uygulama:** Aynı türde birkaç uygulama yerine tek uygulama + IAP ile varyasyonlar (LunAura zaten bu modelde: tek uygulama, 7+ analiz türü).

### 2.2 Geliştirici Deneyimleri (Özet)

| Yöntem | Açıklama |
|--------|----------|
| **Orijinallik belgesi** | Appeal’da “rakiplerden farkımız” net yazılır; hedef kitle, benzersiz özellikler, inovasyon maddeler halinde. |
| **İkon / görsel farklılaşma** | İkon ve ekran görüntüleri rakiplerden ayırt edilebilir olur; yaratım süreci kısaca açıklanır. |
| **Metadata güncelleme** | Uygulama adı (anlamlı sonek), subtitle, açıklama, anahtar kelimeler tamamen yenilenir; “template” izlenimi azaltılır. |
| **Kategori / pazar** | Mümkünse daha az rekabetçi alt kategori veya bölge; “fortune telling” tek başına bırakılmaz, “wellness / lifestyle / entertainment” vurgusu. |
| **İlk açılış deneyimi** | İlk ekranda benzersiz değer önerisi (7-in-1 platform, AI kişiselleştirme, PDF rapor vb.) net gösterilir. |
| **Kod / binary** | Template kullanılıyorsa kaldırılır; kritik modüllerde özelleştirme; aşırı olmayan obfuscation (dikkatli). |
| **Bundle ID** | Yeni gönderimlerde farklı bundle ID; “önceki reddedilmiş uygulama” ile karışma engellenir. |
| **Tekrarlayan appeal** | Aynı metinle sürekli appeal yerine, **somut iyileştirmeler** yapıldıktan sonra yeniden başvuru. |

### 2.3 Başarılı Fal / Astroloji Uygulamalarının Farklılaşma Noktaları (Örnekler)

- **Kismet:** Tarot + palm + horoscope + doğum haritası + melek kartları + oyun (Solitaire).  
- **AstroBot:** Tarot, numeroloji, rüya, kahve, el + “AI oracle” (açık / evet-hayır soruları) + XP/ödül sistemi.  
- **Astro:** Geleneksel astroloji + veri odaklı içgörüler + enerji takibi (duygusal/fiziksel/sosyal).  
- **Fortuna:** 27 fal yöntemi + “AI Relocation” (şans için seyahat önerisi).  

Ortak nokta: **“Sadece fal” değil; birden fazla yöntem + net bir “hook” (AI, rapor, oyun, enerji takibi vb.).

---

## 3. LunAura Mevcut Durum Değerlendirmesi

### 3.1 Güçlü Yanlar (Farklılaşma için kullanılabilir)

| Öğe | Mevcut durum |
|-----|----------------|
| **7+ analiz türü tek uygulama** | Kahve, el, tarot, numeroloji, doğum haritası, kişilik, sinastri → “container app” modeli 4.3 için olumlu. |
| **AI kişiselleştirme** | Yorumlar kullanıcı bilgisi/sorusuna göre üretiliyor; “içerik kişiselleştirmesi” vurgulanabilir. |
| **PDF rapor** | Kişilik ve sinastri için indirilebilir rapor → rakiplerden ayrışan özellik. |
| **Backend / API** | Kendi backend’i (Railway); template değil, özel mimari. |
| **Türkçe odak** | Pazar ve dil olarak niş; “Türkiye’ye özel kişiselleştirilmiş fal/astroloji platformu” hikâyesi. |

### 3.2 Zayıf / Riskli Yanlar

| Öğe | Risk |
|-----|------|
| **Kategori** | Fal / astroloji doğrudan 4.3 hedef kategorisi. |
| **Genel açıklama** | “A new Flutter project.” (pubspec) → profesyonel/orijinallik izlenimi zayıf. |
| **App Store metadata** | Başlık, alt başlık, açıklama, anahtar kelimeler rakiplerden ve “template”den ayırt edici mi bilinmiyor; gözden geçirilmeli. |
| **İkon / ekran görüntüleri** | Diğer fal uygulamalarına çok benzer görünüm (mor/lila, yıldız, genel “mistik” tema) riski. |
| **İlk 10 saniye** | Kullanıcı “neden bu uygulama?” sorusuna hemen cevap alıyor mu belirsiz; “benzersiz değer” net değilse 4.3’te dezavantaj. |
| **Teknik izlenim** | Flutter + standart paketler; kodun özgünlüğü dokümante edilmediyse “template” şüphesi kalabilir. |

### 3.3 Özet Risk

- Ürün **içerik ve mimari olarak** farklılaşmaya uygun (7-in-1, AI, PDF, kendi API’si).  
- Risk daha çok **sunum, metadata ve “görünür farklılaşma”** tarafında: isim, ikon, açıklama, ekran görüntüleri ve ilk ekran deneyimi yeterince “benzersiz” anlatılmıyorsa 4.3 reddi devam edebilir.

---

## 4. Aksiyon Planı (Sadece Planlama)

### 4.1 Faz 1: Metadata ve Mağaza Sunumu

| # | Aksiyon | Detay |
|---|---------|--------|
| 1.1 | **Uygulama adı / subtitle** | LunAura’yı koruyup subtitle ile farkı netleştir: örn. “7 Fal & Astroloji Tek Uygulama” veya “Kişisel Analiz Platformu”. Rakiplerle karışmayacak, Türkçe/TR pazarına uygun ifade. |
| 1.2 | **App Store açıklaması** | İlk 2–3 cümlede: (a) 7+ analiz türü tek yerde, (b) AI ile kişiselleştirilmiş yorumlar, (c) PDF rapor indirme. “Template / genel fal uygulaması” değil “kişisel analiz platformu” vurgusu. |
| 1.3 | **Anahtar kelimeler** | “fal, tarot, astroloji” yanında “kişisel analiz, PDF rapor, doğum haritası, sinastri, numeroloji” gibi özellik odaklı kelimeler; spam yoğunluğu düşük. |
| 1.4 | **Kategori seçimi** | Mümkünse Lifestyle / Entertainment veya Wellness ile ilişkilendirilebilir bir alt kategori; “Fortune Telling” tek başına kalmasın. |
| 1.5 | **Ekran görüntüleri** | Her ekranda 1–2 cümle: “7 analiz türü”, “AI yorumu”, “PDF indir” gibi farklılaşma mesajları. Görsel stil (renk, tipografi) rakiplerden ayırt edilebilir olsun. |

### 4.2 Faz 2: Görsel ve İlk Deneyim

| # | Aksiyon | Detay |
|---|---------|--------|
| 2.1 | **İkon farklılaşması** | Mevcut ikon rakiplerle (mor yıldız, genel mistik ikonlar) karşılaştırılsın; renk, sembol veya tipografi ile ayırt edici hale getirilsin. Değişiklik ve yaratım süreci kısa metinle dokümante edilsin (appeal için). |
| 2.2 | **Splash / ilk açılış** | “LunAura – 7 fal ve astroloji tek uygulamada” veya “Kişisel analiz platformunuz” gibi tek cümle; 2–3 saniye. |
| 2.3 | **Onboarding / rehber** | Guide overlay veya ilk açılışta “Neden LunAura?”: 7 tür, AI kişiselleştirme, PDF rapor maddeleri; 1 ekran yeterli olabilir. |
| 2.4 | **Profil “Hakkında” metni** | Mevcut “Hakkında LunAura” metni App Store ile uyumlu ve biraz daha “platform / kişisel analiz” odaklı güncellenebilir. |

### 4.3 Faz 3: Teknik ve Dokümantasyon

| # | Aksiyon | Detay |
|---|---------|--------|
| 3.1 | **Proje açıklaması** | pubspec.yaml `description`: “A new Flutter project.” → “LunAura: 7-in-1 personal analysis platform (coffee, palm, tarot, numerology, birth chart, personality, synastry) with AI-generated readings and PDF reports.” gibi gerçek ürün tanımı. |
| 3.2 | **Orijinallik notu** | 1 sayfalık “Originality / Differentiation” dokümanı: mimari (kendi backend, FastAPI), 7 tür tek uygulama, AI pipeline, PDF çıktı. Appeal veya “Meet with Apple” için hazır. |
| 3.3 | **Kod / binary** | Template kullanımı yoksa kısa not; varsa hangi kısımların özelleştirildiği listelensin. Gerekirse kritik modüllerde anlamlı özelleştirme planı (obfuscation sadece ikincil, aşırı kullanılmamalı). |
| 3.4 | **Bundle ID** | Önceki reddedilmiş gönderimle aynı bundle ID kullanılıyorsa, yeni bir bundle ID ile “yeni ürün” sunumu değerlendirilsin (dikkatli; sertifika ve mevcut kullanıcılar etkilenebilir). |

### 4.4 Faz 4: Başvuru ve İtiraz Stratejisi

| # | Aksiyon | Detay |
|---|---------|--------|
| 4.1 | **Review notu (Resolution Center)** | Her gönderimde kısa, profesyonel not: “LunAura is a single container app offering 7+ distinct analysis types (coffee, palm, tarot, numerology, birth chart, personality, synastry) with AI-personalized readings and PDF export. Built on our own backend (no template). We target users seeking one app for multiple personal analysis methods.” |
| 4.2 | **İlk red sonrası** | Aynı metinle tekrarlayan appeal yerine: Faz 1–3’ten en az 2–3 maddelik somut güncelleme yapıldıktan sonra yeniden gönderim; “We have updated [X, Y, Z] to better demonstrate uniqueness” cümlesi eklenebilir. |
| 4.3 | **4.3 özel reddi** | “Meet with Apple” randevusu talep edilsin; yanında Orijinallik / Farklılaşma dokümanı ve (varsa) yeni ekran görüntüleri/ikon özeti. |
| 4.4 | **Hedef kitle netliği** | “Türkiye’de fal ve astroloji ile ilgilenen, tek uygulamada birden fazla yöntem ve PDF rapor isteyen kullanıcılar” gibi net tanım; appeal’da kısaca yazılsın. |

---

## 5. Öncelik Sırası (Tavsiye)

1. **Hemen:** Metadata (isim, açıklama, anahtar kelimeler, kategori), Review notu, pubspec description.  
2. **Kısa vadede:** İkon ve ekran görüntüleri, splash/onboarding’de “7-in-1 + AI + PDF” mesajı.  
3. **Red gelirse:** Orijinallik dokümanı + somut değişiklik listesi ile appeal; mümkünse “Meet with Apple”.  
4. **İsteğe bağlı:** Teknik dokümantasyon ve kod tarafı özelleştirme (template yoksa hafif; varsa daha detaylı).

---

## 6. Sonuç

- **4.3(b),** özellikle fal/astroloji gibi doymuş kategoride “aynılık / spam” hissi veren uygulamalara uygulanıyor.  
- LunAura, **ürün olarak** (7 tür, AI, PDF, kendi API’si) farklılaşmaya uygun; risk **mağaza sunumu, görsel ve anlatım** tarafında.  
- Bu plandaki adımlar: mağaza ve ilk izlenimi güçlendirmek, redde karşı net ve somut bir “orijinallik + farklılaşma” hikâyesi sunmak ve tekrarlayan appeal yerine iyileştirme odaklı yeniden başvuru yapmak üzerine kurgulanmıştır.  
- **Uygulama:** Bu dokümanda sadece planlama vardır; kod veya asset değişikliği yapılmamıştır. İstersen bir sonraki adımda Faz 1’den başlayarak somut metin ve alan örnekleri (App Store description, Review notu vb.) ayrı bir dosyada yazılabilir.
