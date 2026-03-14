# Release AAB imzalama (Google Play)

Google Play hatası: **"Yüklenen tüm paketlar imzalanmış olmalıdır."**  
Sebep: `key.properties` ve keystore tanımlı değilse AAB imzasız üretilir.

## Önemli

- **Daha önce bu uygulamayı Play’e yüklediysen** başka bir keystore kullanma; aynı upload key’i kullanmalısın. Eski keystore’u kaybettiysen Play Console’da “Anahtar sıfırlama” gerekir.
- **İlk kez yüklüyorsan** aşağıdaki adımlarla yeni keystore oluştur.

---

## 1. Keystore oluştur (sadece ilk kez)

`mobile/android/` klasöründe PowerShell veya CMD:

```bash
keytool -genkey -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

- **store password** ve **key password** sorulacak (ikisini de güçlü bir şifre seç, not al).
- Ad, birim, şehir vb. bilgileri girebilirsin (Enter ile atlayabilirsin).

Bu işlem `upload-keystore.jks` dosyasını `android/` içinde oluşturur.

---

## 2. key.properties oluştur

`mobile/android/key.properties` dosyasını oluştur (Proje kökündeki `android` klasörü, `app` ile aynı seviye). İçeriği:

```properties
storePassword=BURAYA_KEYSTORE_SIFREN
keyPassword=BURAYA_KEY_SIFREN
keyAlias=upload
storeFile=upload-keystore.jks
```

- `storePassword`: keystore oluştururken verdiğin şifre  
- `keyPassword`: key için verdiğin şifre (genelde aynı)  
- `keyAlias`: yukarıdaki komutta kullandığın alias (`upload`)  
- `storeFile`: keystore dosya adı (`upload-keystore.jks` dosyası `android/` içindeyse böyle yeterli)

Dosya yolu: `d:\Desktop\deneme\fal-app\mobile\android\key.properties`

---

## 3. AAB’yi yeniden derle

Proje kökünde (`mobile/`):

```bash
cd d:\Desktop\deneme\fal-app\mobile
flutter clean
flutter pub get
flutter build appbundle --release
```

İmzalı AAB: `mobile\build\app\outputs\bundle\release\app-release.aab`

Bu dosyayı Google Play Console’a yükleyebilirsin; “imzalanmış olmalıdır” hatası bu şekilde giderilir.

---

## Güvenlik

- `key.properties` ve `*.jks` / `*.keystore` projede `.gitignore` ile takip dışı (commit etme).
- Keystore ve şifreleri güvenli yerde yedekle; kaybedersen mevcut uygulama için yeni sürüm yayınlamak zorlaşır.
