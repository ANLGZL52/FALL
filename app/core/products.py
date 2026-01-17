from __future__ import annotations

from dataclasses import dataclass
from typing import Dict


@dataclass(frozen=True)
class SkuInfo:
    product: str       # coffee | hand | tarot | numerology | ...
    amount: float      # TRY


# ✅ TEK KAYNAK: Play Console Product ID'ler burada.
# Not: Product ID'ler küçük harf / rakam / altçizgi ile uyumlu kalsın.
SKU_CATALOG: Dict[str, SkuInfo] = {
    "fall_coffee_49": SkuInfo("coffee", 49.0),
    "fall_hand_39": SkuInfo("hand", 39.0),

    "fall_numerology_299": SkuInfo("numerology", 299.0),
    "fall_birthchart_299": SkuInfo("birthchart", 299.0),
    "fall_personality_399": SkuInfo("personality", 399.0),
    "fall_synastry_149": SkuInfo("synastry", 149.0),

    "fall_tarot_3_149": SkuInfo("tarot", 149.0),
    "fall_tarot_6_199": SkuInfo("tarot", 199.0),
    "fall_tarot_12_250": SkuInfo("tarot", 250.0),
}


def get_sku_info(sku: str) -> SkuInfo | None:
    sku = (sku or "").strip()
    return SKU_CATALOG.get(sku)
