from __future__ import annotations

from dataclasses import dataclass
from typing import Dict


@dataclass(frozen=True)
class SkuInfo:
    product: str       # coffee | hand | tarot | numerology | ...
    amount: float      # TRY


# ✅ TEK KAYNAK: Store Product ID (SKU) -> ürün/ücret eşlemesi
# Hem eski fall_* id’leri hem yeni (console) id’leri desteklenir.
SKU_CATALOG: Dict[str, SkuInfo] = {
    # --- Coffee / Hand (ESKİ) ---
    "fall_coffee_49": SkuInfo("coffee", 49.0),
    "fall_hand_39": SkuInfo("hand", 39.0),

    # --- Coffee / Hand (YENİ / Play Console) ---
    "coffee_49": SkuInfo("coffee", 49.0),
    "hand_39": SkuInfo("hand", 39.0),

    # --- Other products (ESKİ) ---
    "fall_numerology_299": SkuInfo("numerology", 299.0),
    "fall_birthchart_299": SkuInfo("birthchart", 299.0),
    "fall_personality_399": SkuInfo("personality", 399.0),
    "fall_synastry_149": SkuInfo("synastry", 149.0),

    # --- Other products (YENİ / Play Console) ---
    "numerology_299": SkuInfo("numerology", 299.0),
    "birthchart_299": SkuInfo("birthchart", 299.0),
    "personality_399": SkuInfo("personality", 399.0),
    "synastry_149": SkuInfo("synastry", 149.0),

    # --- Tarot (ESKİ) ---
    "fall_tarot_3_149": SkuInfo("tarot", 149.0),
    "fall_tarot_6_199": SkuInfo("tarot", 199.0),
    "fall_tarot_12_250": SkuInfo("tarot", 250.0),

    # --- Tarot (YENİ / Play Console) ---
    "tarot_3_card_149": SkuInfo("tarot", 149.0),
    "tarot_6_card_199": SkuInfo("tarot", 199.0),
    "tarot_12_card_250": SkuInfo("tarot", 250.0),
}


def get_sku_info(sku: str) -> SkuInfo | None:
    sku = (sku or "").strip()
    return SKU_CATALOG.get(sku)
