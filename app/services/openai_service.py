# app/services/openai_service.py
from __future__ import annotations

import base64
import json
from typing import List, Tuple, Optional

from openai import OpenAI
from app.core.config import settings


def _to_data_url(image_bytes: bytes, mime: str = "image/jpeg") -> str:
    b64 = base64.b64encode(image_bytes).decode("utf-8")
    return f"data:{mime};base64,{b64}"


class OpenAIService:
    def __init__(self):
        api_key = (settings.openai_api_key or "").strip()
        if not api_key:
            raise RuntimeError("OPENAI_API_KEY (.env) boş. Lütfen .env içine openai_api_key gir.")
        self.client = OpenAI(api_key=api_key)
        self.model = settings.openai_model

    def _guess_mime(self, filename: str | None) -> str:
        if not filename:
            return "image/jpeg"
        f = filename.lower()
        if f.endswith(".png"):
            return "image/png"
        if f.endswith(".webp"):
            return "image/webp"
        return "image/jpeg"

    # -----------------------------
    # COFFEE VALIDATION + GENERATE
    # -----------------------------
    def validate_coffee_images(self, images: List[Tuple[bytes, str | None]]) -> dict:
        """
        Kahve fincanı/telve içeriyor mu? Basit doğrulama.
        Return: {"ok": bool, "reason": str}
        """
        if not images:
            return {"ok": False, "reason": "Görsel bulunamadı."}

        # ilk görsel üzerinden kontrol yeterli
        img_bytes, fname = images[0]
        mime = self._guess_mime(fname)
        data_url = _to_data_url(img_bytes, mime=mime)

        prompt = """
Sen bir doğrulama sistemisin.
Görev: Verilen görsel kahve falı için uygun mu? (fincan/telve/çekilmiş kahve fincanı).
- Uygun değilse: ok=false
- Uygunsa: ok=true
Yalnızca şu JSON'u döndür:
{"ok": true/false, "reason": "kısa açıklama"}
"""

        resp = self.client.responses.create(
            model=self.model,
            input=[{
                "role": "user",
                "content": [
                    {"type": "input_text", "text": prompt.strip()},
                    {"type": "input_image", "image_url": data_url},
                ],
            }],
        )

        text = (resp.output_text or "").strip()
        if text.startswith("{") and text.endswith("}"):
            try:
                return json.loads(text)
            except Exception:
                pass

        # fallback
        lowered = text.lower()
        if "ok" in lowered and "true" in lowered:
            return {"ok": True, "reason": "Uygun görünüyor."}
        return {"ok": False, "reason": "Görsel kahve falı için net değil. Fincanı/telveyi net çek."}

    def generate_coffee_reading(
        self,
        images: List[Tuple[bytes, str | None]],
        topic: str,
        focus_text: str,
        name: str | None,
        age: int | None,
    ) -> str:
        who = f"İsim: {name}" if name else "İsim: (belirtilmedi)"
        ag = f"Yaş: {age}" if age is not None else "Yaş: (belirtilmedi)"

        system_style = """
Sen "MysticAura" uygulamasının kahve falı yorumcususun.
Türkçe yaz.
Üslup: mistik, sıcak, güçlü betimlemeler; ama saçma iddialar yok.
Çıktı formatı:
1) Gördüğüm İşaretler (madde madde, kısa)
2) Yorum (2-4 paragraf)
3) Yakın Dönem (7-14 gün) (madde madde)
4) Öneri & Denge (kısa)

Kural: Eğer görseller kahve fincanı/telve değilse bunu dürüstçe söyle ve yeniden çekmesini iste.
"""

        user_prompt = f"""
Kullanıcı kahve falı istiyor.
Konu: {topic}
Odak: {focus_text or "(boş)"}
{who}
{ag}
"""

        content = [{"type": "input_text", "text": system_style.strip() + "\n\n" + user_prompt.strip()}]

        for (img_bytes, fname) in images:
            mime = self._guess_mime(fname)
            content.append({"type": "input_image", "image_url": _to_data_url(img_bytes, mime=mime)})

        resp = self.client.responses.create(
            model=self.model,
            input=[{"role": "user", "content": content}],
        )
        return (resp.output_text or "").strip()

    # -----------------------------
    # HAND VALIDATION + GENERATE
    # -----------------------------
    def validate_hand_image(self, image_bytes: bytes, filename: str | None = None) -> dict:
        """
        Elden başka bir şey mi? -> ödeme öncesi kontrol.
        Return: {"ok": bool, "reason": str}
        """
        mime = self._guess_mime(filename)
        data_url = _to_data_url(image_bytes, mime=mime)

        prompt = """
Sen bir doğrulama sistemisin.
Görev: Verilen görsel "insan eli/avuç içi" içeriyor mu? (El falı için).
- Görselde baskın şekilde insan eli/avuç içi yoksa: ok=false
- Varsa: ok=true
Yalnızca şu JSON'u döndür:
{"ok": true/false, "reason": "kısa açıklama"}
"""

        resp = self.client.responses.create(
            model=self.model,
            input=[{
                "role": "user",
                "content": [
                    {"type": "input_text", "text": prompt.strip()},
                    {"type": "input_image", "image_url": data_url},
                ],
            }],
        )

        text = (resp.output_text or "").strip()
        if text.startswith("{") and text.endswith("}"):
            try:
                return json.loads(text)
            except Exception:
                pass

        lowered = text.lower()
        if "true" in lowered and "ok" in lowered:
            return {"ok": True, "reason": "El tespit edildi."}
        return {"ok": False, "reason": "Görselde insan eli/avuç içi net değil. Lütfen sadece el fotoğrafı yükle."}

    def generate_hand_reading(
        self,
        images: List[Tuple[bytes, str | None]],
        topic: str,
        focus_text: str,
        name: str | None,
        age: int | None,
    ) -> str:
        who = f"İsim: {name}" if name else "İsim: (belirtilmedi)"
        ag = f"Yaş: {age}" if age is not None else "Yaş: (belirtilmedi)"

        system_style = """
Sen "MysticAura" uygulamasının el falı yorumcususun.
Türkçe yaz.
Üslup: mistik, sıcak, güçlü betimlemeler; ama saçma iddialar yok.
Çıktı formatı:
1) Gördüğüm İşaretler (madde madde, kısa)
2) Yorum (2-4 paragraf)
3) Yakın Dönem (7-14 gün) (madde madde)
4) Öneri & Denge (kısa)

Kural: Eğer görseller el değilse bunu dürüstçe söyle ve yeniden çekmesini iste.
"""

        user_prompt = f"""
Kullanıcı el falı istiyor.
Konu: {topic}
Odak: {focus_text or "(boş)"}
{who}
{ag}
"""

        content = [{"type": "input_text", "text": system_style.strip() + "\n\n" + user_prompt.strip()}]
        for (img_bytes, fname) in images:
            mime = self._guess_mime(fname)
            content.append({"type": "input_image", "image_url": _to_data_url(img_bytes, mime=mime)})

        resp = self.client.responses.create(
            model=self.model,
            input=[{"role": "user", "content": content}],
        )

        return (resp.output_text or "").strip()


# -------------------------------------------------------
# Backward-compatible wrapper functions (IMPORT FIX)
# routes_coffee.py eski importları patlatmasın diye
# -------------------------------------------------------
_ai_singleton: Optional[OpenAIService] = None


def _ai() -> OpenAIService:
    global _ai_singleton
    if _ai_singleton is None:
        _ai_singleton = OpenAIService()
    return _ai_singleton


def validate_coffee_images(images: List[Tuple[bytes, str | None]]) -> dict:
    return _ai().validate_coffee_images(images)


def generate_fortune(
    images: List[Tuple[bytes, str | None]],
    topic: str,
    focus_text: str,
    name: str | None,
    age: int | None,
) -> str:
    # kahve falı üretimi
    return _ai().generate_coffee_reading(
        images=images,
        topic=topic,
        focus_text=focus_text,
        name=name,
        age=age,
    )
