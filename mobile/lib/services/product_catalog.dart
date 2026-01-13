// lib/services/product_catalog.dart

enum ProductType {
  coffee,
  hand,
  numerology,
  personality,
  birthchart,
  synastry,
  tarot,
}

class ProductSku {
  final String sku;
  final ProductType type;
  final String title;
  final double amount;
  final String currency;

  const ProductSku({
    required this.sku,
    required this.type,
    required this.title,
    required this.amount,
    this.currency = "TRY",
  });
}

class ProductCatalog {
  // Tek kaynak: SKU -> metadata
  static const Map<String, ProductSku> items = {
    // Numerology
    "fall_numerology_299": ProductSku(
      sku: "fall_numerology_299",
      type: ProductType.numerology,
      title: "Numeroloji Analizi",
      amount: 299.0,
    ),

    // Birthchart
    "fall_birthchart_299": ProductSku(
      sku: "fall_birthchart_299",
      type: ProductType.birthchart,
      title: "Doğum Haritası",
      amount: 299.0,
    ),

    // Personality
    "fall_personality_399": ProductSku(
      sku: "fall_personality_399",
      type: ProductType.personality,
      title: "Kişilik Analizi",
      amount: 399.0,
    ),

    // (İstersen buraya coffee/hand/tarot/synastry sku'larını da ekleriz)
  };

  static ProductSku get(String sku) {
    final p = items[sku];
    if (p == null) {
      throw Exception("SKU catalog'da yok: $sku");
    }
    return p;
  }
}
