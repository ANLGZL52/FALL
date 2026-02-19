from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse  # ✅ EKLENDİ

from app.api.v1 import api_router
from app.core.config import settings
from app.db import init_db

app = FastAPI(title="Lunaura API")

origins = settings.cors_origins

# "*" varsa allow_credentials=False olmalı
allow_credentials = False if origins == ["*"] else True

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=allow_credentials,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def _startup() -> None:
    settings.ensure_dirs()
    init_db()


@app.get("/health")
def health():
    return {"ok": True, "env": settings.environment}


# ✅ YENİ: Privacy Policy URL (App Store Connect için)
@app.get("/privacy", response_class=HTMLResponse)
def privacy_policy():
    return """
<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>LunAura - Gizlilik Politikası</title>
  <style>
    body{font-family:-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Arial;max-width:900px;margin:24px auto;padding:0 16px;line-height:1.6}
    h1,h2{line-height:1.2}
    .muted{color:#666}
    code{background:#f3f3f3;padding:2px 6px;border-radius:6px}
  </style>
</head>
<body>
  <h1>LunAura Gizlilik Politikası</h1>
  <p class="muted">Yürürlük tarihi: 2026-02-13</p>

  <p>
    LunAura (“Uygulama”) eğlence amaçlı tarot, kahve falı, el falı, numeroloji, sinastri ve benzeri içerikler sunar.
    Bu politika, Uygulama’yı kullanırken hangi verilerin işlendiğini ve nasıl korunduğunu açıklar.
  </p>

  <h2>1) Toplanan Veriler</h2>
  <ul>
    <li><b>Kullanıcı girdileri:</b> Kullanıcının girdiği metinler, tercihler ve içerik üretimi için sağladığı bilgiler.</li>
    <li><b>Profil/analiz verileri (özelliğe bağlı):</b> Doğum tarihi/saati/şehir gibi kullanıcı tarafından girilen bilgiler.</li>
    <li><b>Cihaz/teknik veriler:</b> Hata ayıklama, güvenlik ve kullanım bütünlüğü için teknik tanımlayıcılar (örn. cihaz kimliği).</li>
    <li><b>Satın alma doğrulama verileri:</b> Apple/Google tarafından sağlanan işlem doğrulama bilgileri (kart bilgileri tarafımızca tutulmaz).</li>
    <li><b>Log kayıtları:</b> Performans ve hata analizleri için teknik günlükler.</li>
  </ul>

  <h2>2) İşleme Amaçları</h2>
  <ul>
    <li>Talep edilen içeriği üretmek ve kullanıcıya sunmak</li>
    <li>Uygulama içi satın alımları doğrulamak ve hizmeti sağlamak</li>
    <li>Hizmeti iyileştirmek, hataları gidermek, güvenliği artırmak ve suistimali önlemek</li>
  </ul>

  <h2>3) Ödeme İşlemleri</h2>
  <p>
    Ödemeler Apple App Store / Google Play altyapısı üzerinden alınır.
    Kart bilgileri tarafımızca saklanmaz; yalnızca satın alımın doğrulanması için işlem bilgileri işlenebilir.
  </p>

  <h2>4) Paylaşım</h2>
  <p>
    Veriler; yalnızca hizmetin sağlanması için gerekli olduğu ölçüde ödeme sağlayıcıları ve teknik altyapı servisleriyle paylaşılabilir.
    Yasal zorunluluklar dışında üçüncü taraflara satılmaz.
  </p>

  <h2>5) Saklama Süresi</h2>
  <p>
    Veriler, hizmetin sağlanması ve yasal yükümlülükler için gerekli süre boyunca saklanır; ihtiyaç kalmadığında silinir veya anonimleştirilir.
  </p>

  <h2>6) Güvenlik</h2>
  <p>
    Makul teknik ve idari önlemler uygulanır; ancak internet üzerinden iletimde %100 güvenlik garanti edilemez.
  </p>

  <h2>7) İletişim</h2>
  <p>Gizlilik talepleri için: <b>anlgzl52@gmail.com</b></p>

  <p class="muted">Not: LunAura içerikleri eğlence amaçlıdır; finansal/medikal/hukuki tavsiye değildir.</p>
</body>
</html>
"""


app.include_router(api_router, prefix="/api/v1")
