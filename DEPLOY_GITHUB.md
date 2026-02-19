# GitHub'a Deploy

## Yapılanlar
- Git deposu oluşturuldu (`git init`)
- Tüm proje dosyaları eklendi (FALL backend + mobile, `app.db` ve `storage/` hariç)
- İlk commit atıldı: `feat: Railway API varsayilan, yorum kalitesi ve tamamlama...`
- Release commit: `release: AAB version 1.0.0+43 (build +22), key.properties opsiyonel`

## GitHub'a göndermek için

1. **GitHub'da yeni bir repo oluşturun** (https://github.com/new)
   - Repo adı örn: `fal-app` veya `lunaura`
   - "Add a README" seçmeyin (zaten yerel commit var)

2. **Remote ekleyip push edin** (PowerShell veya CMD):

   ```bash
   cd d:\Desktop\deneme\fal-app
   git remote add origin https://github.com/KULLANICI_ADINIZ/REPO_ADI.git
   git branch -M main
   git push -u origin main
   ```

   `KULLANICI_ADINIZ` ve `REPO_ADI` yerine kendi GitHub kullanıcı adınızı ve repo adınızı yazın.

3. **Railway** kullanıyorsanız: Railway dashboard'da projeyi bu GitHub repo'suna bağlayın; her `git push` sonrası otomatik deploy olur.

## Hata kontrolü
- Push sırasında **authentication** hatası alırsanız: GitHub'da Personal Access Token (PAT) oluşturup şifre yerine onu kullanın veya Git Credential Manager / SSH key kullanın.
- **Branch** farklıysa: `git push -u origin main` yerine kullandığınız dal adını yazın.
