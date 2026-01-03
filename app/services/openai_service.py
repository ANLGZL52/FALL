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


def _max_output_tokens(default: int = 2500) -> int:
    """
    Uzun metin (çok sayfa PDF) için.
    .env -> OPENAI_MAX_OUTPUT_TOKENS=3000 gibi ayarlanabilir.
    Not: Çok yüksek verirsen maliyet + latency artar.
    """
    v = getattr(settings, "openai_max_output_tokens", None)
    try:
        if v is None:
            return int(default)
        return int(v)
    except Exception:
        return int(default)


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

    try:
        obj = json.loads(t)
        if isinstance(obj, dict):
            return obj
    except Exception:
        pass

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
# ✅ Text-only OpenAI call
# -------------------------

def call_openai_text(*, system: str, user: str, max_output_tokens: Optional[int] = None) -> str:
    """
    - max_output_tokens verilmezse env/default kullanır.
    - tek yerden token kontrolü
    """
    client = _make_client()
    resp = client.responses.create(
        model=_text_model_name(),
        max_output_tokens=int(max_output_tokens or _max_output_tokens()),
        input=[
            {"role": "system", "content": [{"type": "input_text", "text": system}]},
            {"role": "user", "content": [{"type": "input_text", "text": user}]},
        ],
    )
    out = (resp.output_text or "").strip()
    if not out:
        raise RuntimeError("OpenAI boş yanıt döndü. (output_text empty)")
    return out


# -------------------------
# Coffee (vision)
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
# Hand (vision)
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
# Numerology (text-only)
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
        "Derinlik: Orta-üst.\n"
    )

    user = f"""
Kullanıcı bilgileri:
- Ad: {name}
- Doğum tarihi: {birth_date}
- Konu: {topic}
- Soru: {q}

İstenen içerik:
1) Kısa özet (6-8 cümle)
2) Yaşam Yolu sayısını doğum tarihinden hesapla ve adımları göster (11/22/33 korunur)
3) Karakter çekirdeği (motivasyonlar, değerler, gölge taraf)
4) İlişki stili (yakınlık/alan ihtiyacı, tetikleyiciler)
5) Kariyer-para stili (para psikolojisi, risk iştahı, planlama)
6) 12 somut öneri (kısa ama uygulanabilir)
7) 14 günlük mini enerji planı (gün gün, tek satır)
8) Kapanış (tek paragraf)

Uzunluk hedefi: 1200-1800 kelime.
""".strip()

    return call_openai_text(system=system, user=user)


# -------------------------
# BirthChart (text-only)
# -------------------------

def generate_birthchart_reading(
    *,
    name: str,
    birth_date: str,               # YYYY-MM-DD
    birth_time: Optional[str],     # HH:MM (opsiyonel)
    birth_city: str,
    birth_country: str,
    topic: str,
    question: Optional[str] = None,
) -> str:
    q = (question or "").strip() or "Genel doğum haritası yorumu istiyorum."

    system = (
        "Sen profesyonel bir astrologsun.\n"
        "Dil: Türkçe.\n"
        "Üslup: mistik ama boş genelleme yok; somut ve açıklayıcı.\n"
        "Korkutma yok, kesin hüküm yok.\n"
        "Önemli: Doğum saati yoksa bunu açıkça belirt ve yorumu 'genel' temalar üzerinden kur.\n"
        "Derinlik: Orta-üst.\n"
    )

    user = f"""
Kullanıcı bilgileri:
- Ad: {name}
- Doğum tarihi: {birth_date}
- Doğum saati: {birth_time or 'bilinmiyor'}
- Doğum yeri: {birth_city}, {birth_country}
- Konu: {topic}
- Soru: {q}

İstenen içerik:
1) Kısa özet (6-8 cümle)
2) Harita veri kontrolü (saat varsa/ yoksa etkisi)
3) Kişilik temaları (liderlik, duygu düzeni, iletişim, ilişki dili)
4) Gölge taraf + tetikleyiciler + dengeleme önerileri
5) Konu özel yorum (topic ağırlıklı)
6) 12 somut öneri
7) 14 günlük mini enerji planı (gün gün, tek satır)
8) Kapanış (tek paragraf)

Uzunluk hedefi: 1400-2000 kelime.
""".strip()

    return call_openai_text(system=system, user=user)


# -------------------------
# Personality Fusion (Numerology + BirthChart -> TEK metin)
# -------------------------

def generate_personality_fusion_reading(
    *,
    name: str,
    birth_date: str,
    birth_time: Optional[str],
    birth_city: str,
    birth_country: str,
    topic: str,
    question: Optional[str],
    numerology_text: str,
    birthchart_text: str,
) -> str:
    q = (question or "").strip() or "Genel kişilik analizi istiyorum."

    system = (
        "Sen elit seviyede bir 'BİRLEŞİK KİŞİLİK ANALİSTİ'sin.\n"
        "Elindeki iki kaynaktan (Numeroloji + Doğum Haritası) bilgileri HARMANLAYIP TEK BİR PROFİL çıkaracaksın.\n\n"
        "KRİTİK KURAL: İki metni yan yana ekleme / blok blok gitme.\n"
        "Kural: Aynı şeyi iki kere söyleme.\n"
        "Kural: 'Numeroloji şöyle, astroloji böyle' diye ayıran dil kullanma.\n"
        "Kural: Her bölümde iki kaynaktan da izler taşı (karıştır).\n"
        "Kural: Kesin kehanet yok; olasılık dili; korkutma yok.\n\n"
        "Biçim: Başlıklar olabilir ama '### Numeroloji' / '### Doğum Haritası' gibi ayıran başlıklar YOK.\n"
        "Çıktı bölümleri şu sırada olsun:\n"
        "1) Net özet (8-12 cümle)\n"
        "2) Entegre çekirdek profil (motivasyonlar, değerler, kimlik dili)\n"
        "3) Duygusal düzen & stres (tetikleyiciler + regülasyon teknikleri)\n"
        "4) İlişki dinamikleri (davranış örnekleri + 10 öneri)\n"
        "5) Kariyer/para tarzı (strateji + risk noktaları + 10 öneri)\n"
        "6) Gölge çalışma planı (alışkanlıklar, sabote eden kalıplar, 6 haftalık pratik)\n"
        "7) 14 günlük mini plan (gün gün, tek satır)\n"
        "8) 90 günlük yol haritası (haftalık başlıklar halinde)\n"
        "9) Kapanış (1 paragraf, motive edici)\n\n"
        "Uzunluk: 2600-3600 kelime (PDF’de 7-8 sayfa hedef).\n"
        "Dil: Türkçe."
    )

    user = f"""
Kullanıcı:
- Ad: {name}
- Doğum tarihi: {birth_date}
- Doğum saati: {birth_time or 'bilinmiyor'}
- Doğum yeri: {birth_city}, {birth_country}
- Konu: {topic}
- Soru: {q}

Aşağıda iki ayrı kaynak analiz metni var. Bunları HARMLA ve TEK bir birleşik kişilik analizi yaz:

[NUMEROLOJİ METNİ]
{numerology_text}

[DOĞUM HARİTASI METNİ]
{birthchart_text}
""".strip()

    # fusion çıktısı uzun olduğu için token'i yükselt
    return call_openai_text(system=system, user=user, max_output_tokens=_max_output_tokens(3000))


def generate_personality_reading(
    *,
    name: str,
    birth_date: str,               # YYYY-MM-DD
    birth_time: Optional[str],     # HH:MM (opsiyonel)
    birth_city: str,
    birth_country: str,
    topic: str,
    question: Optional[str] = None,
) -> str:
    numerology_text = generate_numerology_reading(
        name=name,
        birth_date=birth_date,
        topic=topic,
        question=question,
    )

    birthchart_text = generate_birthchart_reading(
        name=name,
        birth_date=birth_date,
        birth_time=birth_time,
        birth_city=birth_city,
        birth_country=birth_country,
        topic=topic,
        question=question,
    )

    return generate_personality_fusion_reading(
        name=name,
        birth_date=birth_date,
        birth_time=birth_time,
        birth_city=birth_city,
        birth_country=birth_country,
        topic=topic,
        question=question,
        numerology_text=numerology_text,
        birthchart_text=birthchart_text,
    )


# -------------------------
# ✅ SYNSTRY (Aşk Uyumu / Sinastri) - yeni feature için
# -------------------------

def generate_synastry_reading(
    *,
    name_a: str,
    birth_date_a: str,
    birth_time_a: Optional[str],
    birth_city_a: str,
    birth_country_a: str,
    name_b: str,
    birth_date_b: str,
    birth_time_b: Optional[str],
    birth_city_b: str,
    birth_country_b: str,
    topic: str,
    question: Optional[str] = None,
) -> str:
    q = (question or "").strip() or "Genel aşk uyumu analizi istiyorum."

    system = (
        "Sen elit seviyede bir SİNASTRİ (aşk uyumu) analistisin.\n"
        "Yaklaşım: numeroloji + doğum haritası temaları.\n"
        "İki kişiyi ayrı ayrı anlatıp yapıştırma; her bölümde iki kişiyi birlikte ele al.\n"
        "Kesin kehanet yok; olasılık dili; korkutma yok.\n\n"
        "ÇIKTI ŞU YAPIYLA:\n"
        "1) 8-10 cümle özet + ilişkinin ana teması\n"
        "2) Çekim/uyum profili (iletişim, güven, çatışma) — örnek davranışlarla\n"
        "3) Duygusal tetikleyiciler + çözüm ritüelleri\n"
        "4) İletişim dili: büyüten/kıran konuşma örnekleri\n"
        "5) Romantik kimya + sınırlar\n"
        "6) Uzun vadeli uyum: para/aile/ortak yaşam\n"
        "7) Risk haritası: 6-10 risk + her risk için 1 önlem\n"
        "8) 21 günlük ilişki planı: gün gün kısa\n"
        "9) Kapanış\n\n"
        "Doğum saati eksikse bunu belirt, yorumları daha genel kur.\n"
        "Dil: Türkçe.\n"
        "Uzunluk hedefi: 2200-3200 kelime."
    )

    user = f"""
Konu: {topic}
Soru: {q}

Partner A:
- Ad: {name_a}
- Doğum: {birth_date_a}
- Saat: {birth_time_a or "bilinmiyor"}
- Yer: {birth_city_a}, {birth_country_a}

Partner B:
- Ad: {name_b}
- Doğum: {birth_date_b}
- Saat: {birth_time_b or "bilinmiyor"}
- Yer: {birth_city_b}, {birth_country_b}

İstek: Çok detaylı sinastri üret (PDF’de 6-8 sayfa hedef).
""".strip()

    return call_openai_text(system=system, user=user, max_output_tokens=_max_output_tokens(3200))
