# Google Play için AAB imzalama

Hata: **"Yüklenen tüm paketler imzalanmış olmalıdır"**

AAB'nin **release keystore** ile imzalanması gerekir. Aşağıdakileri yapın:

## 1. Keystore dosyası

- **Zaten varsa:** `lunaura-release.keystore` dosyanızı `mobile/android/` klasörüne kopyalayın.
- **Yoksa:** Yeni keystore oluşturun (bir kez yapılır, şifreleri saklayın):

```bash
cd mobile/android
keytool -genkey -v -keystore lunaura-release.keystore -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

Sorulan şifreleri (store password, key password) not alın; `key.properties` için gerekli.

## 2. key.properties oluşturma

1. `mobile/android/` klasöründe `key.properties.example` dosyasını `key.properties` olarak kopyalayın.
2. `key.properties` içindeki değerleri doldurun:

```properties
storePassword=KEYSTORE_SIFRESI
keyPassword=KEY_SIFRESI
keyAlias=upload
storeFile=../lunaura-release.keystore
```

- **storePassword / keyPassword:** Keystore oluştururken girdiğiniz şifreler (genelde aynı).
- **keyAlias:** Keystore’daki alias (yukarıdaki komutta `upload` kullandıysanız `upload` yazın). Emin değilseniz: `keytool -list -keystore lunaura-release.keystore`
- **storeFile:** Keystore `android/` içindeyse `../lunaura-release.keystore` kalsın; `android/app/` içindeyse `lunaura-release.keystore` yapın.

## 3. AAB’yi yeniden oluşturma

Proje kökünde (fal-app veya mobile bir üstü):

```bash
cd mobile
flutter build appbundle --dart-define=API_HOST=https://fall-production.up.railway.app
```

Çıkan dosya: `build/app/outputs/bundle/release/app-release.aab` — bunu Play Console’a yükleyin.

## Önemli

- `key.properties` ve `*.keystore` dosyalarını **asla** Git’e eklemeyin; zaten .gitignore’da.
- Şifreleri güvenli yerde saklayın; keystore kaybedilirse mevcut uygulama güncellenemez.
