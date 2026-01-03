# app/services/pdf_service.py
from __future__ import annotations

import os
import re
from datetime import datetime
from functools import lru_cache
from typing import Optional, Tuple, List, Dict, Any

from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont


def _safe_filename(s: str) -> str:
    s = re.sub(r"[^a-zA-Z0-9_\-]+", "_", (s or "").strip())
    return s[:60] or "report"


def _project_root() -> str:
    return os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


@lru_cache(maxsize=1)
def _find_font_files() -> Tuple[Optional[str], Optional[str]]:
    root = _project_root()

    candidates_regular = [
        os.path.join(root, "app", "assets", "fonts", "DejaVuSans.ttf"),
        os.path.join(root, "assets", "fonts", "DejaVuSans.ttf"),
    ]
    candidates_bold = [
        os.path.join(root, "app", "assets", "fonts", "DejaVuSans-Bold.ttf"),
        os.path.join(root, "assets", "fonts", "DejaVuSans-Bold.ttf"),
    ]

    reg = next((p for p in candidates_regular if os.path.exists(p)), None)
    bold = next((p for p in candidates_bold if os.path.exists(p)), None)

    if reg and bold:
        return reg, bold

    found_reg = reg
    found_bold = bold

    for dirpath, _, filenames in os.walk(root):
        for fn in filenames:
            if fn == "DejaVuSans.ttf" and not found_reg:
                found_reg = os.path.join(dirpath, fn)
            elif fn == "DejaVuSans-Bold.ttf" and not found_bold:
                found_bold = os.path.join(dirpath, fn)
        if found_reg and found_bold:
            break

    return found_reg, found_bold


@lru_cache(maxsize=1)
def _register_turkish_fonts() -> Tuple[str, str]:
    reg_path, bold_path = _find_font_files()
    if not reg_path:
        raise FileNotFoundError(
            "DejaVuSans.ttf bulunamadı. Şuraya koy:\n"
            "  app/assets/fonts/DejaVuSans.ttf\n"
            "Ayrıca mümkünse:\n"
            "  app/assets/fonts/DejaVuSans-Bold.ttf\n"
            f"Project root: {_project_root()}"
        )

    font_regular = "DejaVuSans"
    font_bold = "DejaVuSans-Bold"

    try:
        pdfmetrics.registerFont(TTFont(font_regular, reg_path))
    except Exception:
        pass

    if bold_path:
        try:
            pdfmetrics.registerFont(TTFont(font_bold, bold_path))
        except Exception:
            font_bold = font_regular
    else:
        font_bold = font_regular

    return font_regular, font_bold


def _esc(s: str) -> str:
    return (s or "").replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def _build_pdf_bytes(
    *,
    title: str,
    meta_lines: List[str],
    result_text: str,
    author: str = "FALL",
) -> bytes:
    font_regular, font_bold = _register_turkish_fonts()

    from io import BytesIO
    buffer = BytesIO()

    doc = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        leftMargin=42,
        rightMargin=42,
        topMargin=42,
        bottomMargin=42,
        title=title,
        author=author,
    )

    styles = getSampleStyleSheet()

    style_title = ParagraphStyle(
        "TRTitle",
        parent=styles["Title"],
        fontName=font_bold,
        fontSize=16,
        leading=20,
        spaceAfter=10,
    )

    style_meta = ParagraphStyle(
        "TRMeta",
        parent=styles["Normal"],
        fontName=font_regular,
        fontSize=10,
        leading=13,
        spaceAfter=6,
    )

    style_h2 = ParagraphStyle(
        "TRH2",
        parent=styles["Heading2"],
        fontName=font_bold,
        fontSize=12,
        leading=16,
        spaceBefore=10,
        spaceAfter=6,
    )

    style_body = ParagraphStyle(
        "TRBody",
        parent=styles["Normal"],
        fontName=font_regular,
        fontSize=10.5,
        leading=15,
        spaceAfter=8,
    )

    story = []
    story.append(Paragraph(_esc(title), style_title))
    story.append(Paragraph("<br/>".join([_esc(x) for x in meta_lines]), style_meta))
    story.append(Spacer(1, 8))
    story.append(Paragraph("AI Analiz", style_h2))

    raw = (result_text or "").strip() or "Sonuç metni boş."

    for block in raw.split("\n"):
        block = block.strip()
        if not block:
            story.append(Spacer(1, 6))
            continue
        story.append(Paragraph(_esc(block), style_body))

    doc.build(story)
    return buffer.getvalue()


# -------------------------
# ✅ Personality PDF (mevcut fonksiyonun)
# -------------------------

def build_personality_pdf_bytes(
    *,
    title: str,
    name: str,
    birth_date: str,
    birth_time: Optional[str],
    birth_city: str,
    birth_country: str,
    topic: str,
    question: Optional[str],
    result_text: str,
) -> bytes:
    created = datetime.utcnow().strftime("%Y-%m-%d %H:%M UTC")

    meta_lines = [
        f"İsim: {name}",
        f"Doğum: {birth_date}  Saat: {birth_time or '—'}",
        f"Yer: {birth_city}, {birth_country}",
        f"Konu: {topic}",
        f"Soru: {question or '—'}",
        f"Oluşturma: {created}",
    ]

    return _build_pdf_bytes(
        title=title,
        meta_lines=meta_lines,
        result_text=result_text,
        author=name or "FALL",
    )


# -------------------------
# ✅ NEW: Synastry PDF
# routes_synastry.py bunu import ediyor.
# -------------------------

def build_synastry_pdf_bytes(
    *,
    title: str,
    reading: Dict[str, Any],
) -> bytes:
    created = datetime.utcnow().strftime("%Y-%m-%d %H:%M UTC")

    meta_lines = [
        f"Kişi A: {reading.get('name_a', '—')}",
        f"Doğum A: {reading.get('birth_date_a', '—')}  Saat: {reading.get('birth_time_a') or '—'}",
        f"Yer A: {reading.get('birth_city_a', '—')}, {reading.get('birth_country_a', '—')}",
        "",
        f"Kişi B: {reading.get('name_b', '—')}",
        f"Doğum B: {reading.get('birth_date_b', '—')}  Saat: {reading.get('birth_time_b') or '—'}",
        f"Yer B: {reading.get('birth_city_b', '—')}, {reading.get('birth_country_b', '—')}",
        "",
        f"Odak: {reading.get('topic', 'Genel')}",
        f"Soru: {reading.get('question') or '—'}",
        f"Oluşturma: {created}",
    ]

    result_text = (reading.get("result_text") or "").strip()

    return _build_pdf_bytes(
        title=title,
        meta_lines=meta_lines,
        result_text=result_text,
        author=(reading.get("name_a") or "FALL"),
    )
