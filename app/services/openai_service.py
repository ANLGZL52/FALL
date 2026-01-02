# app/services/openai_service.py
from __future__ import annotations

import base64
import json
import os
from typing import List, Dict, Any, Optional

from openai import OpenAI
from app.core.config import settings


# -------------------------
# Helpers
# -------------------------

def _require_key() -> str:
    key = (getattr(settings, "openai_api_key", "") or "").strip()
    if not key:
        raise RuntimeError(
            "OpenAI API key yok. .env içine OPENAI_API_KEY=... yaz ve backend'i yeniden başlat."
        )
    return key


def _make_client() -> OpenAI:
    return OpenAI(api_key=_require_key())


def _text_model_name() -> str:
    """
    Config uyumsuzluklarına dayanıklı:
    - settings.openai_model varsa onu kullanır (OPENAI_MODEL)
    - yoksa settings.openai_model_text varsa onu kullanır (OPENAI_MODEL_TEXT)
    - ikisi de yoksa fallback
    """
    m = (getattr(settings, "openai_model", "") or "").strip()
    if m:
        return m
    mt = (getattr(settings, "openai_model_text", "") or "").strip()
    return mt or "gpt-4.1-mini"


def _vision_model_name() -> str:
    mv = (getattr(settings, "openai_model_vision", "") or "").strip()
    if mv:
        return mv
    m = (getattr(settings, "openai_model", "") or "").strip()
    return m or "gpt-4.1-mini"


def _normalize_path(p: str) -> str:
    if os.path.isabs(p):
        return p
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    return os.path.abspath(os.path.join(project_root, p))


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


def _parse_json_object(text: str) -> Optional[dict]:
    if not text:
        return None
    t = text.strip()

    # direkt dene
    try:
        obj = json.loads(t)
        if isinstance(obj, dict):
            return obj
    except Exception:
        pass

    # aradan { } çek
    start = t.find("{")
    end = t.rfind("}")
    if start != -1 and end != -1 and end > start:
        candidate = t[start:end + 1]
        try:
            obj = json.loads(candidate)
            if isinstance(obj, dict):
                return obj
        except Exception:
            return None

    return None


# -------------------------
# ✅ Text-only OpenAI call (NUMEROLOGY / TAROT)
# -------------------------

def call_openai_text(*, system: str, user: str) -> str:
    client = _make_client()
    resp = client.responses.create(
        model=_text_model_name(),
        input=[
            {"role": "system", "content": [{"type": "input_text", "text": system}]},
            {"role": "user", "content": [{"type": "input_text", "text": user}]},
        ],
    )
    out = (resp.output_text or "").strip()
    if not out:
        raise RuntimeError("OpenAI boş yanıt döndü. (output_text empty)")
    return out


# ✅ GERİ UYUMLULUK: bazı dosyalar eski isimle çağırıyor olabilir
def _call_openai_text(*, system: str, user: str) -> str:
    return call_openai_text(system=system, user=user)


# -------------------------
# Coffee
# -------------------------

def validate_coffee_images(image_paths: List[str]) -> Dict[str, Any]:
    client = _make_client()
    images = [{"type": "input_image", "image_url": _to_data_url(p)} for p in image_paths[:5]]

    prompt = (
        "Sen bir görüntü doğrulama asistanısın.\n"
        "Görev: YÜKLENEN GÖRSELLER kahve falı için uygun mu?\n\n"
        "Uygun (ok=true): kahve fincanının İÇİ görünür + telve izleri/lekeleri bariz.\n"
        "Uygun değil (ok=false): kimlik, evrak, ekran görüntüsü, manzara, insan yüzü, yemek, ürün, fincan dışı görüntü vb.\n\n"
        "Kural: Görsellerin en az 1 tanesi bile kahve fincanı içi değilse ok=false.\n"
        "Sadece JSON döndür:\n"
        '{"ok": true/false, "reason": "kısa açıklama", "confidence": 0-1}\n'
        "JSON DIŞINDA hiçbir şey yazma."
    )

    resp = client.responses.create(
        model=_vision_model_name(),
        input=[{"role": "user", "content": [{"type": "input_text", "text": prompt}, *images]}],
    )

    raw = (resp.output_text or "").strip()
    obj = _parse_json_object(raw)

    if not obj:
        return {"ok": False, "reason": "Görseller doğrulanamadı. Lütfen fincan içi fotoğraf yükleyin.", "confidence": 0.0}

    ok = bool(obj.get("ok", False))
    reason = str(obj.get("reason", "")).strip() or ("Uygun" if ok else "Görseller kahve fincanı içi değil.")
    conf = obj.get("confidence", 0.5)
    try:
        conf = float(conf)
    except Exception:
        conf = 0.5

    return {"ok": ok, "reason": reason, "confidence": conf}


def generate_fortune(
    *,
    name: str,
    topic: str,
    question: str,
    image_paths: List[str],
    relationship_status: Optional[str] = None,
    big_decision: Optional[str] = None,
) -> str:
    client = _make_client()
    images = [{"type": "input_image", "image_url": _to_data_url(p)} for p in image_paths[:5]]

    system = (
        "Sen deneyimli bir kahve falcısısın.\n"
        "Ton: samimi, sıcak, falcı edasında.\n"
        "Biçim: KESİNLİKLE madde işareti/numara/başlık yok.\n"
        "Sadece düz yazı: 6-9 paragraf.\n\n"
        "Kural-1: UYDURMA YOK. Sadece görselde gerçekten seçilebilen telve izlerine dayan.\n"
        "Belirsizse 'tam seçilmiyor' de.\n"
        "Kural-2: Kesin hüküm yok; olasılık dili.\n"
        "Kural-3: Konu ve soruya en az 2 paragraf direkt cevap ver.\n"
        "Kural-4: Korkutma yok.\n\n"
        "Uzunluk: en az 750 kelime.\n"
        "Dil: Türkçe.\n\n"
        "Eğer görseller kahve fincanı içi değilse: sadece şu tek cümleyi yaz ve dur:\n"
        "'Görseller kahve fincanı içi görünmüyor.'\n"
    )

    user_text = (
        f"Kullanıcı adı: {name}\n"
        f"Konu: {topic}\n"
        f"Soru: {question}\n"
        f"İlişki durumu: {relationship_status or 'belirtilmedi'}\n"
        f"Büyük karar: {big_decision or 'belirtilmedi'}\n\n"
        "İstek: Akıcı bir fal yaz. Listeleme yapma.\n"
    )

    resp = client.responses.create(
        model=_vision_model_name(),
        input=[
            {"role": "system", "content": [{"type": "input_text", "text": system}]},
            {"role": "user", "content": [{"type": "input_text", "text": user_text}, *images]},
        ],
    )

    out = (resp.output_text or "").strip()
    if not out:
        raise RuntimeError("OpenAI boş yanıt döndü. (output_text empty)")
    return out


# -------------------------
# Hand
# -------------------------

def validate_hand_images(image_paths: List[str]) -> Dict[str, Any]:
    client = _make_client()
    images = [{"type": "input_image", "image_url": _to_data_url(p)} for p in image_paths[:5]]

    prompt = (
        "Sen bir görüntü doğrulama denetçisisin.\n"
        "Görev: Yüklenen görseller 'EL FALI' için uygun mu?\n\n"
        "Uygun (ok=true): Avuç içi net (palm) + çizgiler görünür.\n"
        "Uygun değil (ok=false): kimlik/ehliyet, yüz, ekran görüntüsü, belge, kahve fincanı, manzara, ürün.\n\n"
        "Kural: En az 1 görsel avuç içi net değilse ok=false.\n"
        "Sadece JSON döndür:\n"
        '{"ok": true/false, "reason": "kısa açıklama", "confidence": 0-1}\n'
        "JSON DIŞINDA hiçbir şey yazma."
    )

    resp = client.responses.create(
        model=_vision_model_name(),
        input=[{"role": "user", "content": [{"type": "input_text", "text": prompt}, *images]}],
    )

    raw = (resp.output_text or "").strip()
    obj = _parse_json_object(raw)

    if not obj:
        return {"ok": False, "reason": "Görseller doğrulanamadı. Lütfen avuç içi net fotoğraf yükle.", "confidence": 0.0}

    ok = bool(obj.get("ok", False))
    reason = str(obj.get("reason", "")).strip() or ("Uygun" if ok else "Görseller el falı için uygun değil.")
    conf = obj.get("confidence", 0.5)
    try:
        conf = float(conf)
    except Exception:
        conf = 0.5

    return {"ok": ok, "reason": reason, "confidence": conf}


def generate_hand_fortune(
    *,
    name: str,
    topic: str,
    question: str,
    image_paths: List[str],
    dominant_hand: Optional[str] = None,
    photo_hand: Optional[str] = None,
    relationship_status: Optional[str] = None,
    big_decision: Optional[str] = None,
) -> str:
    client = _make_client()
    images = [{"type": "input_image", "image_url": _to_data_url(p)} for p in image_paths[:5]]

    system = (
        "Sen deneyimli bir el falcısısın.\n"
        "Dil: Türkçe.\n"
        "Biçim: liste/başlık yok, düz yazı.\n"
        "Uydurma yok, olasılık dili.\n"
        "Eğer görseller el/avuç içi gibi görünmüyorsa, sadece şu tek cümleyi yaz ve dur:\n"
        "'Görseller el fotoğrafı gibi görünmüyor.'\n"
    )

    user_text = (
        f"İsim: {name}\n"
        f"Konu: {topic}\n"
        f"Soru: {question}\n"
        f"Baskın el: {dominant_hand or 'belirtilmedi'}\n"
        f"Fotoğraftaki el: {photo_hand or 'belirtilmedi'}\n"
        f"İlişki durumu: {relationship_status or 'belirtilmedi'}\n"
        f"Büyük karar: {big_decision or 'belirtilmedi'}\n"
        "İstek: Akıcı bir yorum yaz.\n"
    )

    resp = client.responses.create(
        model=_vision_model_name(),
        input=[
            {"role": "system", "content": [{"type": "input_text", "text": system}]},
            {"role": "user", "content": [{"type": "input_text", "text": user_text}, *images]},
        ],
    )

    out = (resp.output_text or "").strip()
    if not out:
        raise RuntimeError("OpenAI boş yanıt döndü. (output_text empty)")
    return out


# -------------------------
# Tarot (text-only)
# -------------------------

def generate_tarot_reading(
    *,
    name: str,
    age: Optional[int],
    topic: str,
    question: str,
    spread_type: str,
    selected_cards: List[str],
) -> str:
    system = (
        "Sen üst düzey deneyimli bir Tarot yorumcususun.\n"
        "Dil: Türkçe.\n"
        "Derin, katmanlı, içgörülü yaz.\n"
        "Kesin kehanet yok.\n"
    )

    user = (
        f"Danışan: {name}{f' ({age})' if age is not None else ''}\n"
        f"Konu: {topic}\n"
        f"Soru: {question}\n"
        f"Açılım: {spread_type}\n"
        f"Kartlar: {', '.join(selected_cards)}\n"
        "İstek: Pozisyon bazlı derin yorum.\n"
    )

    return call_openai_text(system=system, user=user)


# -------------------------
# ✅ Numerology (text-only)
# -------------------------

def generate_numerology_reading(
    *,
    name: str,
    birth_date: str,   # YYYY-MM-DD
    topic: str,
    question: Optional[str] = None,
) -> str:
    q = (question or "").strip() or "Genel numeroloji yorumu istiyorum."

    system = (
        "Sen profesyonel bir numeroloji uzmanısın.\n"
        "Dil: Türkçe.\n"
        "Üslup: sıcak, mistik ama boş genelleme yok; somut ve açıklayıcı.\n"
        "Korkutma yok, kesin hüküm yok.\n"
        "Uzunluk: en az 650-900 kelime bandında.\n"
    )

    user = f"""
Kullanıcı bilgileri:
- Ad: {name}
- Doğum tarihi: {birth_date}
- Konu: {topic}
- Soru: {q}

İstenen içerik:
1) Kısa özet (3-5 cümle)
2) Yaşam Yolu sayısını doğum tarihinden hesapla ve kısa adımlarla göster.
   Master sayılar (11/22/33) gelirse koru.
3) Konu özel yorum (güçlü yanlar, dikkat edilmesi gerekenler, uygulanabilir öneriler)
4) 7 günlük mini enerji takvimi (gün gün kısa)
5) Kapanış: motive edici tek paragraf.
"""
    # burada call_openai_text kullanıyoruz; ama eski yerler _call_openai_text çağırsa da wrapper var
    return call_openai_text(system=system, user=user)
