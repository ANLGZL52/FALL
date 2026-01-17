class ProductCatalog {
  // ✅ Play Console Product ID = SKU
  static const String coffee49 = "fall_coffee_49";
  static const String hand39 = "fall_hand_39";

  static const String numerology299 = "fall_numerology_299";
  static const String birthchart299 = "fall_birthchart_299";
  static const String personality399 = "fall_personality_399";
  static const String synastry149 = "fall_synastry_149";

  // ✅ Tarot: Play Console’da hedeflediğin yeni ID’ler
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

  // ✅ Eski kodlarda ProductCatalog.all kullanıldığı için uyumluluk:
  static List<String> get all => allSkus.toList();
}
