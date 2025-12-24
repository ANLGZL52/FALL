# app/services/openai_service.py
import base64
import json
import os
from typing import List, Dict, Any, Optional

from openai import OpenAI
from app.core.config import settings


def _require_key() -> str:
    if not settings.OPENAI_API_KEY:
        raise RuntimeError(
            "OPENAI_API_KEY env değişkeni boş. Key'i sisteme tanımla ve terminali yeniden aç."
        )
    return settings.OPENAI_API_KEY


def _normalize_path(path: str) -> str:
    """
    DB'de path bazen relative (storage/uploads/..) bazen absolute olabilir.
    - absolute ise direkt kullan
    - relative ise proje köküne göre absolute'a çevir
    """
    if not path:
        return path

    # Windows / Linux uyumu
    p = path.replace("\\", "/")

    if os.path.isabs(p):
        return p

    # Proje kökü: .../app/services -> .../(project_root)
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    abs_path = os.path.abspath(os.path.join(project_root, p))
    return abs_path


def _to_data_url(path: str) -> str:
    abs_path = _normalize_path(path)

    if not os.path.exists(abs_path):
        raise FileNotFoundError(f"Image not found: {abs_path} (from: {path})")

    lower = abs_path.lower()
    mime = "image/jpeg"
    if lower.endswith(".png"):
        mime = "image/png"
    elif lower.endswith(".webp"):
        mime = "image/webp"

    with open(abs_path, "rb") as f:
        b64 = base64.b64encode(f.read()).decode("utf-8")
    return f"data:{mime};base64,{b64}"


def _safe_json_loads(text: str) -> Dict[str, Any]:
    """
    Model bazen JSON dışı metin ekleyebilir.
    - Direkt parse dene
    - Olmazsa: ilk '{' ile son '}' arasını kırpıp dene
    """
    text = (text or "").strip()
    if not text:
        return {}

    try:
        return json.loads(text)
    except Exception:
        pass

    try:
        i = text.find("{")
        j = text.rfind("}")
        if i >= 0 and j > i:
            return json.loads(text[i : j + 1])
    except Exception:
        pass

    return {}


def validate_coffee_images(image_paths: List[str]) -> Dict[str, Any]:
    """
    Fotoğraflar kahve falı için uygun mu?
    Return:
      { "ok": bool, "reason": "..." }
    """
    _require_key()
    client = OpenAI(api_key=settings.OPENAI_API_KEY)

    images = [{"type": "input_image", "image_url": _to_data_url(p)} for p in image_paths[:5]]

    prompt = (
        "Sen bir içerik doğrulama asistanısın. Görev: Kullanıcının yüklediği görsellerin kahve falı için uygun olup olmadığını tespit et.\n"
        "Uygun görsel örnekleri: kahve fincanı içi, telve izleri, tabak üzerindeki telve, fincanın üstten/yan/alt açıları.\n"
        "Uygun olmayan örnekler: insan yüzü, manzara, evrak, ekran görüntüsü, yemek, ürün fotoğrafı vb.\n\n"
        "Sadece JSON döndür. Şema:\n"
        '{ "ok": true/false, "reason": "kısa açıklama" }\n'
        "Eğer en az 1 görsel bile alakasızsa ok=false yap."
    )

    resp = client.responses.create(
        model=settings.OPENAI_MODEL,
        input=[
            {
                "role": "user",
                "content": [{"type": "input_text", "text": prompt}, *images],
            }
        ],
    )

    text = (resp.output_text or "").strip()
    data = _safe_json_loads(text)

    if not data:
        return {"ok": False, "reason": f"Doğrulama yanıtı parse edilemedi: {text[:200]}"}

    return {
        "ok": bool(data.get("ok")),
        "reason": str(data.get("reason", "")).strip(),
    }


def generate_fortune(
    name: str,
    topic: str,
    question: str,
    image_paths: List[str],
    relationship_status: Optional[str] = None,
    big_decision: Optional[str] = None,
) -> str:
    _require_key()
    client = OpenAI(api_key=settings.OPENAI_API_KEY)

    images = [{"type": "input_image", "image_url": _to_data_url(p)} for p in image_paths[:5]]

    system = (
        "Sen deneyimli bir kahve falcısısın. Üslup: sıcak, mistik, ama abartısız; "
        "kullanıcıya umut verirken gerçekçi ve nazik ol. "
        "Kesin hüküm verme; olasılık dili kullan. "
        "Yorumun detaylı olsun: semboller, duygu hali, zamanlama (yakın/orta vade), öneri.\n"
        "Türkçe yaz."
    )

    user_text = (
        f"Kullanıcı adı: {name}\n"
        f"Fal konusu: {topic}\n"
        f"Soru: {question}\n"
        f"İlişki durumu: {relationship_status or 'belirtilmedi'}\n"
        f"Büyük karar: {big_decision or 'belirtilmedi'}\n\n"
        "Görsellerdeki telve/fincan izlerini analiz et. "
        "Önce gördüğün sembolleri madde madde yaz, sonra uzun fal yorumuna geç."
    )

    resp = client.responses.create(
        model=settings.OPENAI_MODEL,
        input=[
            {"role": "system", "content": [{"type": "input_text", "text": system}]},
            {"role": "user", "content": [{"type": "input_text", "text": user_text}, *images]},
        ],
    )

    out = (resp.output_text or "").strip()
    if not out:
        raise RuntimeError("OpenAI boş yanıt döndü.")
    return out
