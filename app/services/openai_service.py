# app/services/openai_service.py
from __future__ import annotations

import base64
import json
import os
import re
from datetime import date, timedelta
from typing import List, Dict, Any, Optional

from openai import OpenAI
from app.core.config import settings


# ============================================================
# Core helpers
# ============================================================

def _require_key() -> str:
    key = (getattr(settings, "openai_api_key", "") or "").strip()
    if not key:
        raise RuntimeError(
            "OpenAI API key yok. .env içine OPENAI_API_KEY=... yaz ve backend'i yeniden başlat."
        )
    return key


def _make_client() -> OpenAI:
    """
    ✅ Railway / prod ortamında uzun yanıt ve ağ gecikmelerinde kopmayı azaltır.
    Env:
      OPENAI_TIMEOUT_SECONDS=90
      OPENAI_MAX_RETRIES=2
    """
    timeout = getattr(settings, "openai_timeout_seconds", 90)
    max_retries = getattr(settings, "openai_max_retries", 2)

    try:
        timeout = int(timeout)
    except Exception:
        timeout = 90

    try:
        max_retries = int(max_retries)
    except Exception:
        max_retries = 2

    return OpenAI(
        api_key=_require_key(),
        timeout=timeout,
        max_retries=max_retries,
    )


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
    Uzun metin için.
    .env -> OPENAI_MAX_OUTPUT_TOKENS=3000 gibi ayarlanabilir.
    """
    v = getattr(settings, "openai_max_output_tokens", None)
    try:
        if v is None:
            return int(default)
        return int(v)
    except Exception:
        return int(default)


def _clamp_tokens(x: int, lo: int = 256, hi: int = 6000) -> int:
    try:
        x = int(x)
    except Exception:
        x = lo
    return max(lo, min(hi, x))


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
    """Model bazen JSON dışı yazarsa yakalamaya çalışır."""
    if not text:
        return None
    t = text.strip()

    # direct
    try:
        obj = json.loads(t)
        if isinstance(obj, dict):
            return obj
    except Exception:
        pass

    # substring
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


def _infer_spread_count(spread_type: str, selected_cards: List[str]) -> int:
    """
    spread_type backend'den "three/six/twelve" gelebilir.
    Tutmazsa selected_cards uzunluğundan yakalar.
    """
    st = (spread_type or "").lower().strip()

    if "three" in st or st in ("3", "3card", "3-card"):
        return 3
    if "six" in st or st in ("6", "6card", "6-card"):
        return 6
    if "twelve" in st or st in ("12", "12card", "12-card"):
        return 12

    n = len(selected_cards or [])
    if n in (3, 6, 12):
        return n
    return 6


def _today_str_tr() -> str:
    # UI’da “tarih bugüne ait değil” problemini prompt’ta kökten bitiriyoruz:
    return date.today().isoformat()


def _next_14_days_lines_tr() -> str:
    """
    14 günlük planı LLM'e net formatla verdiriyoruz.
    Model artık 2024 gibi saçmalık yazmasın.
    """
    d0 = date.today()
    lines = []
    for i in range(14):
        di = d0 + timedelta(days=i)
        lines.append(f"- {di.isoformat()} (Gün {i+1}):")
    return "\n".join(lines)


# ============================================================
# ✅ Text-only OpenAI call
# ============================================================

def call_openai_text(*, system: str, user: str, max_output_tokens: Optional[int] = None) -> str:
    """
    - max_output_tokens verilmezse env/default kullanır.
    - tek yerden token kontrolü
    """
    client = _make_client()
    mot = _clamp_tokens(int(max_output_tokens or _max_output_tokens()))
    resp = client.responses.create(
        model=_text_model_name(),
        max_output_tokens=mot,
        input=[
            {"role": "system", "content": [{"type": "input_text", "text": system}]},
            {"role": "user", "content": [{"type": "input_text", "text": user}]},
        ],
    )
    out = (resp.output_text or "").strip()
    if not out:
        raise RuntimeError("OpenAI boş yanıt döndü. (output_text empty)")
    return out


# ============================================================
# ✅ Truncation Guard (Numerology fix)
# ============================================================

_SENTENCE_END_RE = re.compile(r"[.!?…]\s*$")


def _looks_truncated(text: str) -> bool:
    """
    Çok basit ama pratik bir heuristik:
    - çok kısa
    - cümle noktalama ile bitmiyor
    - açıkça yarım bırakılmış gibi (son karakter virgül, iki nokta vb.)
    """
    t = (text or "").strip()
    if not t:
        return True
    if len(t) < 300:
        return True

    last = t[-1]
    if last in {",", ":", ";", "-", "(", "["}:
        return True

    if not _SENTENCE_END_RE.search(t):
        return True

    return False


def _numerology_continue_user(prev_text: str) -> str:
    """
    Devam prompt’u: tekrar etmesin, kaldığı yerden tamamlasın.
    """
    return f"""
Aşağıdaki numeroloji metni daha önce üretildi ancak muhtemelen YARIM kaldı.
Görev:
- KALDIĞIN YERDEN devam et.
- Önceki cümleleri tekrar ETME.
- Metni düzgün bir sonuç paragrafı ile bitir.
- En sonda 14 günlük plan zaten yazıldıysa tekrar yazma; yazılmadıysa ekle.
- Mutlaka TAMAMLanmış cümle ile bitir (sonu nokta olsun).

[ŞU ANA KADARKİ METİN]
{prev_text}

DEVAM:
""".strip()


def _stitch_with_guard(
    *,
    system: str,
    initial_user: str,
    initial_tokens: int,
    continue_tokens: int,
    max_hops: int = 2,
) -> str:
    """
    1) ilk üret
    2) yarım görünüyorsa 1-2 kez "devam et" çağır
    3) birleştir ve dön
    """
    out = call_openai_text(system=system, user=initial_user, max_output_tokens=initial_tokens).strip()

    for _ in range(max_hops):
        if not _looks_truncated(out):
            break

        cont_user = _numerology_continue_user(out)
        nxt = call_openai_text(system=system, user=cont_user, max_output_tokens=continue_tokens).strip()
        if not nxt:
            break

        # basit birleştirme
        if not out.endswith("\n"):
            out += "\n\n"
        out += nxt

    # Final temizlik: çok aşırı boşlukları sadeleştir
    out = re.sub(r"\n{3,}", "\n\n", out).strip()
    return out


# ============================================================
# Coffee (vision)
# ============================================================

def validate_coffee_images(image_paths: List[str]) -> Dict[str, Any]:
    client = _make_client()
    images = [{"type": "input_image", "image_url": _to_data_url(p)} for p in (image_paths or [])[:5]]

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
    images = [{"type": "input_image", "image_url": _to_data_url(p)} for p in (image_paths or [])[:5]]

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
        f"Bugün: {_today_str_tr()}\n"
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
            {"role": "user", "content": [{"type": "input_text", "text": user_text}, *images]}],
    )

    out = (resp.output_text or "").strip()
    if not out:
        raise RuntimeError("OpenAI boş yanıt döndü. (output_text empty)")
    return out


# ============================================================
# Hand (vision)
# ============================================================

def validate_hand_images(image_paths: List[str]) -> Dict[str, Any]:
    client = _make_client()
    images = [{"type": "input_image", "image_url": _to_data_url(p)} for p in (image_paths or [])[:5]]

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


def _call_openai_vision_json(*, prompt: str, image_paths: List[str], max_output_tokens: int = 1400) -> Dict[str, Any]:
    """
    Vision model çağrısı: SADECE JSON üretmeye zorlarız.
    JSON parse edilemezse {} döner.
    """
    client = _make_client()
    images = [{"type": "input_image", "image_url": _to_data_url(p)} for p in (image_paths or [])[:5]]

    resp = client.responses.create(
        model=_vision_model_name(),
        max_output_tokens=_clamp_tokens(max_output_tokens, 256, 2500),
        input=[{"role": "user", "content": [{"type": "input_text", "text": prompt}, *images]}],
    )

    raw = (resp.output_text or "").strip()
    obj = _parse_json_object(raw)
    return obj or {}


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
    val = validate_hand_images(image_paths)
    if not val.get("ok", False):
        return "Görseller el fotoğrafı gibi görünmüyor."

    vision_prompt = (
        "Sen bir avuç içi GÖZLEMLEYİCİSİN. Fal yazmıyorsun.\n"
        "Görev: Fotoğraflarda GERÇEKTEN gördüğün çizgi ve işaretleri özetle.\n"
        "Uydurma yok. Emin değilsen 'unclear' yaz.\n"
        "Sadece JSON döndür. JSON dışında hiçbir şey yazma.\n\n"
        "Şu şemaya uy:\n"
        "{\n"
        '  "photo_quality": "good/medium/poor",\n'
        '  "visibility": {"heart_line":"clear/partial/unclear","head_line":"clear/partial/unclear","life_line":"clear/partial/unclear","fate_line":"clear/partial/unclear"},\n'
        '  "heart_line": {"depth":"deep/medium/shallow/unclear","shape":"curved/straight/unclear","breaks":"none/some/unclear","notes":"..."},\n'
        '  "head_line": {"length":"long/medium/short/unclear","shape":"straight/curved/unclear","start":"joined/separate/unclear","notes":"..."},\n'
        '  "life_line": {"depth":"deep/medium/shallow/unclear","continuity":"continuous/broken/unclear","arc":"wide/narrow/unclear","notes":"..."},\n'
        '  "fate_line": {"presence":"clear/faint/none/unclear","breaks":"none/some/unclear","notes":"..."},\n'
        '  "mounts": {"venus":"prominent/normal/flat/unclear","moon":"prominent/normal/flat/unclear","jupiter":"prominent/normal/flat/unclear","saturn":"prominent/normal/flat/unclear","apollo":"prominent/normal/flat/unclear","mercury":"prominent/normal/flat/unclear"},\n'
        '  "special_marks": ["star/triangle/cross/island/none/unclear"],\n'
        '  "overall_notes": "Sadece gördüklerin"\n'
        "}\n"
    )

    obs = _call_openai_vision_json(prompt=vision_prompt, image_paths=image_paths, max_output_tokens=1600)
    obs_text = json.dumps(obs, ensure_ascii=False)

    system = (
        "Sen çok deneyimli bir el falcısısın.\n"
        "Dil: Türkçe.\n"
        "Ton: samimi, sıcak, güven verici; mistik ama abartısız.\n"
        "Biçim: KESİNLİKLE madde işareti/numara/başlık yok. Sadece düz yazı.\n"
        "Uydurma yok: SADECE verilen GÖZLEM verisine dayan.\n"
        "Kesin kehanet yok: olasılık dili.\n"
        "Korkutma yok.\n\n"
        "ZORUNLU ÇIKTI:\n"
        "- En az 1200 kelime.\n"
        "- 8–12 paragraf.\n"
        "- Topic & Question'a en az 3 paragraf direkt cevap.\n"
        "- Metin boyunca en az 6 kez 'gözlem net/partial/unclear' gibi referanslar yap.\n"
        "- Sonda tek paragraf: 14 günlük mini plan (BUGÜNDEN başlayarak tarihli).\n"
        "- Tarihler KESİNLİKLE sabit/örnek tarih olmayacak.\n"
    )

    user_text = (
        f"Bugün: {_today_str_tr()}\n"
        f"14 gün şablonu:\n{_next_14_days_lines_tr()}\n\n"
        f"İsim: {name}\n"
        f"Konu: {topic}\n"
        f"Soru: {question}\n"
        f"Baskın el: {dominant_hand or 'belirtilmedi'}\n"
        f"Fotoğraftaki el: {photo_hand or 'belirtilmedi'}\n"
        f"İlişki durumu: {relationship_status or 'belirtilmedi'}\n"
        f"Büyük karar: {big_decision or 'belirtilmedi'}\n\n"
        "Aşağıdaki GÖZLEM JSON'una dayanarak uzun ve derin bir el falı yaz.\n"
        "Eğer bazı alanlar 'unclear/partial' ise bunu açıkça söyle.\n\n"
        f"[GÖZLEM JSON]\n{obs_text}\n"
    )

    return call_openai_text(system=system, user=user_text, max_output_tokens=_max_output_tokens(3200))


# ============================================================
# ✅ Tarot (text-only)
# ============================================================

def generate_tarot_reading(
    *,
    name: str,
    age: Optional[int],
    topic: str,
    question: str,
    spread_type: str,
    selected_cards: List[str],
) -> str:
    count = _infer_spread_count(spread_type, selected_cards)

    if count == 3:
        min_words, max_words = 900, 1200
        token_default = 2200
        spread_label = "3 Kart Açılımı (Geçmiş–Şimdi–Yakın Gelecek)"
    elif count == 6:
        min_words, max_words = 1400, 1900
        token_default = 2800
        spread_label = "6 Kart Açılımı (Sen–Karşı Taraf–Aranız–Engel–Tavsiye–Sonuç)"
    else:
        min_words, max_words = 2200, 3000
        token_default = 3600
        spread_label = "12 Kart Premium Açılımı (Genel Enerji…Kapanış)"

    system = (
        "Sen üst düzey, deneyimli bir Tarot yorumcususun.\n"
        "Dil: Türkçe.\n"
        "Ton: profesyonel, güven verici, sezgisel ama abartısız.\n\n"
        "TEMEL KURALLAR:\n"
        "- Tarot kesin kehanet değildir; olasılık dili kullan.\n"
        "- Korkutma yok, sağlık/ölüm gibi ağır iddialar yok.\n"
        "- Genel geçer cümlelerle geçiştirme yok; her şey soruya bağlanacak.\n\n"
        "ZORUNLU YAPI (başlıklar kullan):\n"
        "1) Genel Açılım Enerjisi (8-12 cümle)\n"
        "2) Kart Kart Detaylı Yorum (tüm kartlar sırayla; her kart için 2-4 paragraf)\n"
        "3) Kartlar Arası İlişki Analizi\n"
        "4) Sorunun Özüne Net Cevap (en az 3 paragraf)\n"
        "5) Gözden Kaçan Mesajlar / Bilinçaltı (1-2 paragraf)\n"
        "6) Net Mesaj (5–7 cümle)\n"
        "7) Önümüzdeki 14 Gün Mini Plan (BUGÜNDEN başlayarak tarihli)\n"
        "8) Dikkat & Denge (2-4 cümle)\n"
        "9) Kapanış\n\n"
        f"Uzunluk zorunluluğu: {min_words}-{max_words} kelime.\n"
        "Kısa/üstünkörü çıktı yasak.\n"
        "14 günlük planda sabit/örnek tarih kullanma.\n"
    )

    user = (
        f"Bugün: {_today_str_tr()}\n"
        f"14 gün şablonu:\n{_next_14_days_lines_tr()}\n\n"
        f"Danışan: {name}{f' ({age})' if age is not None else ''}\n"
        f"Konu: {topic}\n"
        f"Soru: {question}\n"
        f"Açılım: {spread_type} -> {spread_label}\n"
        f"Kartlar (id|R/U): {', '.join(selected_cards)}\n\n"
        "Notlar:\n"
        "- Kartları pozisyon sırasına göre yorumla.\n"
        "- Kart id'lerinden isim çıkaramıyorsan id üzerinden sembolik yorum yap.\n"
    )

    return call_openai_text(system=system, user=user, max_output_tokens=_max_output_tokens(token_default))


# ============================================================
# ✅ Numerology (text-only)  <-- FIX HERE
# ============================================================

def generate_numerology_reading(
    *,
    name: str,
    birth_date: str,   # YYYY-MM-DD
    topic: str,
    question: Optional[str] = None,
) -> str:
    q = (question or "").strip() or "Genel numeroloji yorumu istiyorum."

    system = (
        "Sen üst düzey profesyonel bir numeroloji analistisin.\n"
        "Dil: Türkçe.\n"
        "Ton: sıcak, güven verici, olgun ve danışman gibi.\n"
        "Kesin kehanet yok; olasılık dili kullan.\n"
        "Korkutma yok; sağlık/ölüm gibi ağır iddialar yok.\n"
        "Boş genelleme yok: her paragraf kullanıcının verisine ve sorusuna bağlanacak.\n\n"
        "BİÇİM KURALI:\n"
        "- Liste/madde işareti/numaralandırma YOK.\n"
        "- Sadece akıcı düz yazı.\n"
        "- 10–14 paragraf.\n\n"
        "ZORUNLU KALİTE:\n"
        "- Doğum tarihinden yaşam yolu hesaplamasını metin içinde anlaşılır şekilde yap.\n"
        "- 11/22/33 gibi master sayıları koru.\n"
        "- Kullanıcının sorusuna en az 4 paragraf direkt cevap ver.\n"
        "- Sonda tek paragrafta: 14 günlük mini plan (BUGÜNDEN başlayarak tarihli).\n"
        "- Tarihler sabit/örnek olmayacak.\n"
        "- Uzunluk: en az 1800 kelime hedefle.\n"
        "- Metni mutlaka tamamlanmış bir cümleyle bitir (sonu nokta olsun).\n"
    )

    user = f"""
Bugün: {_today_str_tr()}
14 gün şablonu:
{_next_14_days_lines_tr()}

Kullanıcı:
- Ad: {name}
- Doğum tarihi: {birth_date}
- Konu: {topic}
- Soru: {q}

İstek:
Bu verilerle çok kapsamlı ve derin bir numeroloji analizi yaz.
""".strip()

    # ✅ İlk çağrı için yüksek token (ama env clamp var)
    # ✅ Devam çağrıları daha küçük token ile tamamlar
    initial_tokens = _max_output_tokens(4200)
    continue_tokens = _max_output_tokens(1800)

    return _stitch_with_guard(
        system=system,
        initial_user=user,
        initial_tokens=initial_tokens,
        continue_tokens=continue_tokens,
        max_hops=2,
    )


# ============================================================
# BirthChart (text-only)
# ============================================================

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
    has_time = bool((birth_time or "").strip())

    system = (
        "Sen profesyonel bir astroloji yorum asistanısın.\n"
        "Dil: Türkçe.\n"
        "Ton: profesyonel, sıcak, motive edici; abartısız.\n"
        "Kesin kader/kehanet dili yok; olasılık dili kullan.\n"
        "Korkutma yok (sağlık/ölüm vb.).\n"
        "Boş genelleme yok; her bölüm kullanıcı verisine ve konu/soruya bağlanacak.\n"
        "Saat yoksa yükselen/ev/ASC iddiası yapma.\n"
        "Çıktı Markdown başlıkları ile yapılandırılacak.\n"
    )

    time_note = (
        "Doğum saati VERİLMİŞ. Yorumlarda olasılık diliyle daha net vurgu yapabilirsin; kesinlik kurma."
        if has_time
        else
        "Doğum saati BİLİNMİYOR. Yükselen/ev yerleşimleri gibi kesin teknik iddialar YAPMA."
    )

    user = f"""
Bugün: {_today_str_tr()}

Kullanıcı:
- Ad: {name}
- Doğum tarihi: {birth_date}
- Doğum saati: {birth_time or "Bilinmiyor"}
- Doğum yeri: {birth_city}, {birth_country}
- Konu: {topic}
- Soru: {q}

Kritik not:
- {time_note}

Kurallar:
- En az 1200 kelime hedefle; ideal 1400-2200.
- Topic merkeze alınacak.
- Sağlık/ölüm gibi korkutucu kehanet yok.

İskelet:

### 1) Kısa Özet (5-7 madde)
- (Madde madde)

### 2) Veri Notu ve Netlik Seviyesi
- (2 paragraf)

### 3) Çekirdek Kişilik Temaları (Güçlü + Gölge)
- Güçlü yönler
- Gölge yönler
- Dengeleme önerileri (en az 5 madde)

### 4) İlişki Dinamikleri
- En az 7 net öneri

### 5) Kariyer / Para Temaları
- En az 7 net öneri

### 6) Yakın Dönem Enerjileri
- (3-6 ay) ve (12 ay)

### 7) {topic} İçin Net Öneriler (en az 9 madde)

### 8) “Bugünden Başlayarak” 5 Aksiyon Planı
- 5 madde

### 9) Not
- kısa kapanış
""".strip()

    return call_openai_text(system=system, user=user, max_output_tokens=_max_output_tokens(3800))


# ============================================================
# Personality Fusion (Numerology + BirthChart -> TEK metin)
# ============================================================

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
        "Elindeki iki kaynaktan (Numeroloji + Doğum Haritası) bilgileri HARMANLAYIP TEK BİR PROFİL çıkaracaksın.\n"
        "İki metni yan yana ekleme.\n"
        "‘Numeroloji şöyle / astroloji böyle’ diye ayıran dil kullanma.\n"
        "Aynı şeyi tekrarlama.\n"
        "Kesin kehanet yok; korkutma yok.\n\n"
        "Çıktı bölümleri:\n"
        "1) Net özet\n"
        "2) Entegre çekirdek profil\n"
        "3) Duygusal düzen & stres\n"
        "4) İlişki dinamikleri\n"
        "5) Kariyer/para tarzı\n"
        "6) Gölge çalışma planı (6 hafta)\n"
        "7) 14 günlük mini plan (BUGÜNDEN başlayarak tarihli)\n"
        "8) 90 günlük yol haritası\n"
        "9) Kapanış\n\n"
        "Uzunluk: 2600-3600 kelime.\n"
        "14 günlük planda sabit/örnek tarih kullanma.\n"
        "Dil: Türkçe."
    )

    user = f"""
Bugün: {_today_str_tr()}
14 gün şablonu:
{_next_14_days_lines_tr()}

Kullanıcı:
- Ad: {name}
- Doğum tarihi: {birth_date}
- Doğum saati: {birth_time or 'bilinmiyor'}
- Doğum yeri: {birth_city}, {birth_country}
- Konu: {topic}
- Soru: {q}

Aşağıda iki ayrı metin var. Bunları harmanlayıp TEK bir birleşik analiz yaz:

[NUMEROLOJİ METNİ]
{numerology_text}

[DOĞUM HARİTASI METNİ]
{birthchart_text}
""".strip()

    return call_openai_text(system=system, user=user, max_output_tokens=_max_output_tokens(3600))


def generate_personality_reading(
    *,
    name: str,
    birth_date: str,               # YYYY-MM-DD
    birth_time: Optional[str],     # HH:MM
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


# ============================================================
# ✅ Synastry (Sinastri)
# ============================================================

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
        "Kesin kehanet yok; korkutma yok.\n\n"
        "ÇIKTI ŞU YAPIYLA:\n"
        "1) Özet + ilişkinin ana teması\n"
        "2) Çekim/uyum profili\n"
        "3) Duygusal tetikleyiciler + çözüm ritüelleri\n"
        "4) İletişim dili örnekleri\n"
        "5) Romantik kimya + sınırlar\n"
        "6) Uzun vadeli uyum: para/aile/yaşam\n"
        "7) Risk haritası: 6-10 risk + her risk için 1 önlem\n"
        "8) 21 günlük ilişki planı (BUGÜNDEN itibaren gün gün; sabit tarih yok)\n"
        "9) Kapanış\n\n"
        "Doğum saati eksikse bunu belirt, yorumları daha genel kur.\n"
        "Dil: Türkçe.\n"
        "Uzunluk hedefi: 2200-3200 kelime."
    )

    user = f"""
Bugün: {_today_str_tr()}

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

İstek: Çok detaylı sinastri üret.
""".strip()

    return call_openai_text(system=system, user=user, max_output_tokens=_max_output_tokens(3600))
