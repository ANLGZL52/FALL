# app/services/openai_service.py
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
    key = (settings.openai_api_key or "").strip()
    if not key:
        raise RuntimeError(
            "OpenAI API key yok. .env içine OPENAI_API_KEY=... yaz ve backend'i yeniden başlat."
        )
    return key


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
    """
    Model bazen JSON'u '```json ... ```' gibi sarmalayabiliyor veya etrafına yazı koyabiliyor.
    Bu fonksiyon hem direkt json.loads dener, hem de { ... } aralığını ayıklar.
    """
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
        candidate = t[start: end + 1]
        try:
            obj = json.loads(candidate)
            if isinstance(obj, dict):
                return obj
        except Exception:
            return None

    return None


def _make_client() -> OpenAI:
    key = _require_key()
    return OpenAI(api_key=key)


def _model_name() -> str:
    # settings.openai_model senin mevcut kahve fonksiyonunda zaten kullanılıyor
    m = (settings.openai_model or "").strip()
    if not m:
        # fallback (istersen default’u config’te ver)
        m = "gpt-4o-mini"
    return m


# -------------------------
# Coffee (Mevcut çalışan)
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
        model=_model_name(),
        input=[
            {"role": "user", "content": [{"type": "input_text", "text": prompt}, *images]}
        ],
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
        "Ton: samimi, sıcak, falcı edasında; sanki karşındaki kişiyle yüz yüze konuşuyorsun.\n"
        "Hitap serbest: 'canım', 'güzelim', 'kuzum', 'tatlım' gibi (abartmadan, her paragrafta 1 kez yeter).\n"
        "Biçim: KESİNLİKLE madde işareti, numaralı liste, A) B) başlıkları, şablon formatlar YOK.\n"
        "Sadece düz yazı: 6-9 paragraf. Her paragraf 3-6 cümle.\n\n"
        "Kural-1 (ÇOK ÖNEMLİ): UYDURMA YOK. Sadece görselde gerçekten seçilebilen telve izlerine dayan.\n"
        "Belirsizse 'tam seçilmiyor' de. Şekil uydurma.\n"
        "Kural-2: Kesin hüküm yok; olasılık dili: 'gibi', 'sanki', 'işaret ediyor olabilir'.\n"
        "Kural-3: Kullanıcının seçtiği konu ve soruya en az 2 paragraf direkt cevap ver.\n"
        "Kural-4: Korkutma yok; negatif şeyleri yumuşak uyarı gibi söyle.\n\n"
        "Üslup detayı: Metin akıcı olsun; kısa kısa değil, fal anlatır gibi sahne kur.\n"
        "Araya mini sezgisel cümleler kat: 'İçime doğan şu…', 'Burada bir işaret var…' gibi.\n\n"
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
        "İstek:\n"
        "Fincandaki telve izlerini önce zihninde 'görüntü' gibi tarif ederek anlat ama bunu listeleme.\n"
        "Ardından bu izlerin enerjisini yorumla: yakın vade / orta vade / uzun vade akışını paragraf içinde yedir.\n"
        "Son 1 paragrafta küçük bir 'niyet/ritüel/odak önerisi' ver (dini zorlama yok).\n"
        "Tekrar: LİSTE, MADDE, BAŞLIK KULLANMA.\n"
    )

    resp = client.responses.create(
        model=_model_name(),
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
# HAND (SENİN İSTEDİĞİN ŞEKİLDE - EKLENDİ)
# -------------------------

def validate_hand_images(image_paths: List[str]) -> Dict[str, Any]:
    """
    Amaç: Ödeme öncesi "el/avuç içi" mi? Değilse reddet.
    Sıkı kural: En az 1 görsel net şekilde avuç içi/elin çizgilerini göstermeli.
    Dönen format kahve ile aynı: ok/reason/confidence
    """
    client = _make_client()

    images = [{"type": "input_image", "image_url": _to_data_url(p)} for p in image_paths[:5]]

    prompt = (
        "Sen bir görüntü doğrulama denetçisisin.\n"
        "Görev: Yüklenen görseller 'EL FALI' için uygun mu?\n\n"
        "Uygun (ok=true): Avuç içi net (palm) + el çizgileri görünür + el fotoğrafı.\n"
        "Uygun değil (ok=false): kimlik/ehliyet, yüz, ekran görüntüsü, belge, kahve fincanı, manzara, ürün, yazı ağırlıklı görsel.\n\n"
        "Kural: En az 1 görsel bile avuç içi net değilse veya el yoksa ok=false.\n"
        "Sadece JSON döndür:\n"
        '{"ok": true/false, "reason": "kısa açıklama", "confidence": 0-1}\n'
        "JSON DIŞINDA hiçbir şey yazma."
    )

    resp = client.responses.create(
        model=_model_name(),
        input=[{"role": "user", "content": [{"type": "input_text", "text": prompt}, *images]}],
    )

    raw = (resp.output_text or "").strip()
    obj = _parse_json_object(raw)

    if not obj:
        # ödeme güvenliği için sıkı davran
        return {"ok": False, "reason": "Görseller doğrulanamadı. Lütfen avuç içi net fotoğraf yükle.", "confidence": 0.0}

    ok = bool(obj.get("ok", False))
    reason = str(obj.get("reason", "")).strip() or ("Uygun" if ok else "Görseller el falı için uygun değil (avuç içi net değil).")
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
    """
    Backend'in kontrol ettiği kritik cümle:
    El değilse -> SADECE şu cümleyi döndür:
    'Görseller el fotoğrafı gibi görünmüyor.'
    """
    client = _make_client()
    images = [{"type": "input_image", "image_url": _to_data_url(p)} for p in image_paths[:5]]

    # Kahvedeki gibi: liste/başlık yok, akıcı anlatı
    system = (
        "Sen deneyimli bir el falcısısın.\n"
        "Ton: samimi, mistik, falcı edasında; ama abartısız ve kesin hüküm vermeyen.\n"
        "Biçim: KESİNLİKLE madde işareti, numaralı liste, başlık, A) B) yok.\n"
        "Sadece düz yazı: 6-9 paragraf. Her paragraf 3-6 cümle.\n\n"
        "Kural-1: Uydurma yok. Görselde seçilebilen çizgilere/işaretlere dayan.\n"
        "Emin olmadığın yerde 'tam seçilmiyor / net değil' de.\n"
        "Kural-2: Kesin hüküm yok; olasılık dili kullan.\n"
        "Kural-3: Kullanıcının konu ve sorusuna en az 2 paragraf direkt cevap ver.\n"
        "Kural-4: Korkutma yok; negatif şeyleri yumuşak uyarı gibi söyle.\n\n"
        "İçerik akışı: kısa giriş -> çizgiler (görünüyorsa yaşam/akıl/kalp/kader) -> "
        "tepecikler (Venüs/Jüpiter/Satürn/Apollo/Merkür) -> zamanlama (0-4 hafta, 1-3 ay, 3-6 ay) -> "
        "kapanışta küçük bir odak/niyet önerisi.\n\n"
        "Dil: Türkçe.\n"
        "Uzunluk: en az 650 kelime.\n\n"
        "ÇOK ÖNEMLİ: Eğer görseller el/avuç içi fotoğrafı gibi görünmüyorsa, sadece şu tek cümleyi yaz ve dur:\n"
        "'Görseller el fotoğrafı gibi görünmüyor.'\n"
    )

    user_text = (
        f"İsim: {name}\n"
        f"Konu: {topic}\n"
        f"Soru: {question}\n"
        f"Baskın el: {dominant_hand or 'belirtilmedi'}\n"
        f"Fotoğraftaki el: {photo_hand or 'belirtilmedi'}\n"
        f"İlişki durumu: {relationship_status or 'belirtilmedi'}\n"
        f"Büyük karar: {big_decision or 'belirtilmedi'}\n\n"
        "İstek:\n"
        "Avuç içi çizgilerini gözlemle ve falcı üslubuyla akıcı bir yorum yaz. "
        "Listeleme yapma, başlık atma.\n"
    )

    resp = client.responses.create(
        model=_model_name(),
        input=[
            {"role": "system", "content": [{"type": "input_text", "text": system}]},
            {"role": "user", "content": [{"type": "input_text", "text": user_text}, *images]},
        ],
    )

    out = (resp.output_text or "").strip()
    if not out:
        raise RuntimeError("OpenAI boş yanıt döndü. (output_text empty)")
    return out
