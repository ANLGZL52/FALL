class ProductCatalog {
  // ✅ Play Console Product ID = SKU (console’daki ile birebir)
  static const String coffee49 = "coffee_49";
  static const String hand39 = "hand_39";

  static const String numerology299 = "numerology_299";
  static const String birthchart299 = "birthchart_299";
  static const String personality399 = "personality_399";
  static const String synastry149 = "synastry_149";

  static const String tarot3_149 = "tarot_3_card_149";
  static const String tarot6_199 = "tarot_6_card_199";
  static const String tarot12_250 = "tarot_12_card_250";

  static const Set<String> allSkus = {
    coffee49,
    hand39,
    numerology299,
    birthchart299,
    personality399,
    synastry149,
    tarot3_149,
    tarot6_199,
    tarot12_250,
  };

  static List<String> get all => allSkus.toList();
}
