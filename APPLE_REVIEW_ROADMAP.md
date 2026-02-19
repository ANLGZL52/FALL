# Apple App Store Ret Analizi ve Kabul Yol Haritası

**Gönderim ID:** be09bdd7-29df-43cd-a506-ba907e53b141  
**İnceleme tarihi:** 17 Şubat 2026  
**İncelenen cihazlar:** iPad Air 11-inch (M3), iPhone 17 Pro Max  
**Versiyon:** 1.0  

---

## Mevcut Durum Özeti

Apple, uygulamanızı **3 ayrı guideline ihlali** gerekçesiyle reddetti. Bunlar **metadata (ekran görüntüleri + uygulama adı)** ve **kategori doygunluğu (4.3(b) Spam)** ile ilgili. Hepsi düzeltilebilir; biri kodla, ikisi App Store Connect + strateji ile.

---

## Sorun 1: Guideline 2.3.3 – Yanlış / Uygun Olmayan Ekran Görüntüleri

### Apple’ın söylediği
- **13-inch iPad ekran görüntüleri**, iPhone görüntüsünün büyütülmüş/uzatılmış hali gibi görünüyor.
- Ekran görüntüleri, uygulamanın **her desteklenen cihazda** gerçekten nasıl göründüğünü yansıtmalı.

### Ne yapmalısınız (yol haritası)

| Adım | Yapılacak | Not |
|------|------------|-----|
| 1 | iPad için **gerçek iPad ekran görüntüleri** alın. | Xcode Simulator’da **iPad Air 11-inch (M3)** veya gerçek iPad ile uygulamayı çalıştırıp ekran görüntüsü alın. iPhone görüntüsünü iPad boyutuna stretch etmeyin. |
| 2 | App Store Connect → Uygulama → **Previews and Screenshots** bölümüne gidin. | |
| 3 | **“View All Sizes in Media Manager”** ile tüm cihaz boyutlarını görün. | 13-inch iPad ayrı bir boyut olarak listelenir. |
| 4 | 13-inch iPad için yüklenen eski (iPhone’dan uyarlanmış) görselleri **silin**. | |
| 5 | Yeni **gerçek iPad ekran görüntülerini** (6.5", 5.5", 12.9" vb. gerekli tüm iPad boyutları için) yükleyin. | Her boyut için App Store’un istediği çözünürlük ve sayıya uyun. |
| 6 | Ekran görüntüleri: **uygulamanın ana özelliklerini** göstersin (ana sayfa, fal türleri, bir sonuç ekranı). | Sadece splash veya login ekranı ağırlıklı olmasın. |

**Sonuç:** Bu madde **tamamen sizin yükleme ve görsel hazırlık sürecinizle** çözülür; kod değişikliği gerekmez.

---

## Sorun 2: Guideline 2.3.8 – Uygulama Adı Uyumsuzluğu

### Apple’ın söylediği
- **Mağaza adı:** LunAura  
- **Cihazda görünen ad:** Fall App  
- İki isim yeterince benzer olmadığı için kullanıcı indirdiği uygulamayı bulmakta zorlanıyor.

### Ne yapmalısınız (yol haritası)

| Adım | Yapılacak | Durum |
|------|------------|--------|
| 1 | iOS projesinde cihazda görünen adı **LunAura** yapın. | **Yapıldı:** `ios/Runner/Info.plist` içinde `CFBundleDisplayName` = `LunAura` olarak güncellendi. |
| 2 | Yeni build alıp tekrar gönderin. | Cihazda “LunAura” görünecek; mağaza adıyla uyumlu olacak. |

**Not:** Bundle Identifier değiştirilmemeli (Apple zaten belirtiyor).

**Sonuç:** Bu madde **projede yapılan isim değişikliğiyle** çözüldü; bir sonraki gönderimde geçerli olacak.

---

## Sorun 3: Guideline 4.3(b) – Spam / Doygun Kategori

### Apple’ın söylediği
- Uygulama **astroloji, burç, el falı, fal, zodiac raporları** gibi özellikler sunuyor.
- Bu kategoride **benzer içerik ve işlevselliğe sahip çok sayıda uygulama** zaten var.
- Uygulamanız **faydalı / bilgilendirici / eğlenceli** olabilir ve **onu ayıran özellikler** de olabilir; ancak mağazada “yeterince” bu tür uygulama olduğu için reddedildi.
- **Beklenti:** Daha **benzersiz bir deneyim** sunan yeni bir uygulama konsepti ile tekrar başvurmanız.

### Neden bu kadar kritik?
4.3(b), “çok sayıda benzer uygulama”yı sınırlamak için kullanılıyor. Sadece “bir fal uygulaması daha” gibi görünürseniz ret riski yüksek. **Farkınızı** hem uygulama içinde hem de mağaza sayfası ve inceleme notlarında net göstermeniz gerekiyor.

### Ne yapmalısınız (yol haritası)

#### A) App Store Connect tarafı (metadata + inceleme notu)

| Adım | Yapılacak |
|------|------------|
| 1 | **App Store açıklamasında** LunAura’yı “sadece fal uygulaması” değil, **net bir değer önerisi** ile tanımlayın. Örnek açı: “Kişisel gelişim ve self-reflection için tek bir yerde birleşik deneyim: kahve falı, el falı, tarot, numeroloji, doğum haritası ve kişilik analizi; AI destekli kişiselleştirilmiş raporlar ve indirilebilir PDF’ler.” |
| 2 | **Anahtar kelimeler** ve alt başlıkta benzersiz özellikleri vurgulayın: örn. “AI ile kişiselleştirilmiş raporlar”, “PDF indirme”, “tek uygulamada 7+ analiz türü”. |
| 3 | **App Review notu (Review Notes)** alanına İngilizce kısa bir paragraf yazın. Örnek çerçeve: “LunAura is not a generic horoscope app. It offers [X, Y, Z unique points]. Our differentiators: [1] … [2] … [3] … We target users who want [specific use case]. Thank you for reviewing.” Bu, incelemecinin 4.3(b) kararını yeniden düşünmesine yardımcı olur. |

#### B) Uygulama içi farklılaştırma (isteğe bağlı ama güçlü)

Aşağıdakiler “başka fal uygulaması” algısını azaltıp “benzersiz deneyim” algısını artırır:

| Fikir | Açıklama |
|-------|----------|
| **Kişisel gelişim / günlük açısı** | “Günlük niyet”, “haftalık özet” veya “kişisel notlar” gibi fal dışı bir modül ekleyin. Uygulama “fal + kişisel gelişim/günlük” olarak konumlanabilir. |
| **Tek platform** | Açıklamada vurgulayın: “Kahve falı, el falı, tarot, numeroloji, doğum haritası, kişilik ve sinastri tek uygulamada; raporlar PDF olarak indirilebilir.” Rakip uygulamaların çoğu 1–2 tür sunar. |
| **AI kişiselleştirme** | “OpenAI ile kişiselleştirilmiş, soruya özel yorumlar” ifadesini hem mağaza hem Review notunda kullanın. |
| **Gizlilik / veri sahipliği** | “Hesap zorunlu değil, cihaz bazlı; verileriniz sizin kontrolünüzde” gibi bir satır (uygunsa) farklılaştırma için kullanılabilir. |

**Örnek App Review Note (App Store Connect → Version → App Review Information → Notes):**

```
Thank you for reviewing LunAura.

LunAura is not a generic horoscope or single-purpose fortune app. Our differentiators:

1. All-in-one platform: One app combines coffee reading, palm reading, tarot (multiple spreads), numerology, birth chart, personality analysis (numerology + birth chart), and synastry (relationship compatibility) with downloadable PDF reports. Most similar apps offer only one or two of these.

2. AI-personalized content: Interpretations are generated per user and per question using modern AI, not static pre-written texts.

3. No account required: Users can use the app with device-based identification; we emphasize privacy and user control.

We have updated our screenshots to show the app as it actually appears on iPad (no stretched iPhone assets) and aligned the on-device display name with the store name (LunAura).

We believe these aspects provide a distinct experience. We are happy to answer any follow-up questions.
```

*(İsterseniz Türkçe bir cümle ekleyebilirsiniz; inceleme genelde İngilizce yapılır.)*

#### C) Reddedilirse alternatif

- Apple, “web app” seçeneğini öneriyor: kullanıcı siteyi “Ana ekrana ekle” ile uygulama gibi kullanabilir. Native uygulama zorunlu değilse bu geçerli bir alternatiftir.
- İsterseniz önce **sadece metadata + Review notu** ile tekrar deneyin; ret gelirse bir sonraki adımda uygulama içi farklılaştırma (günlük, “tek platform” vurgusu vb.) ekleyip yeniden başvurabilirsiniz.

**Sonuç:** 4.3(b) kod tek başına çözmez; **metadata + Review notu + (isteğe bağlı) uygulama içi benzersiz özellikler** ile ele alınmalı.

---

## Yapılacaklar Özet Listesi

| # | Görev | Kim / Nerede | Öncelik |
|---|--------|----------------|----------|
| 1 | iOS cihaz adını **LunAura** yap | Geliştirici / `Info.plist` | ✅ Yapıldı |
| 2 | iPad için **gerçek iPad ekran görüntüleri** çek ve App Store Connect’e yükle (13" ve gerekli diğer boyutlar) | Siz / App Store Connect | Yüksek |
| 3 | App Store **açıklama ve alt başlık**ta benzersiz değer önerisini vurgula | Siz / App Store Connect | Yüksek |
| 4 | **App Review notu** yaz (farklılaşma + 4.3(b) için kısa gerekçe) | Siz / App Store Connect | Yüksek |
| 5 | (İsteğe bağlı) Uygulama içi farklılaştırma: günlük, “tek platform” vurgusu vb. | Geliştirici / kod | Orta |

---

## Tekrar Gönderim Öncesi Kontrol Listesi

- [ ] `CFBundleDisplayName` = **LunAura** (iOS) — **tamamlandı**
- [ ] Yeni iOS build alındı ve yüklendi
- [ ] 13-inch iPad (ve diğer iPad boyutları) için **gerçek iPad ekran görüntüleri** yüklendi; hiçbiri iPhone’dan stretch edilmiş değil
- [ ] Mağaza adı (LunAura) ile cihaz adı (LunAura) uyumlu
- [ ] Açıklama ve anahtar kelimeler güncellendi (benzersiz özellikler vurgulandı)
- [ ] App Review notu eklendi (4.3(b) için farklılaşma açıklaması)
- [ ] Bundle Identifier değiştirilmedi

Bu adımları tamamladıktan sonra aynı versiyonu (veya 1.0.1 gibi patch) “Submit for Review” ile tekrar gönderebilirsiniz.
