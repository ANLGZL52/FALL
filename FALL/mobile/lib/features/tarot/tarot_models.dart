class TarotCard {
  final String id;

  final String nameTr;
  final String nameEn;

  /// 'major' | 'minor'
  final String arcana;

  /// minor için: 'wands' | 'cups' | 'swords' | 'pentacles'
  /// major için boş olabilir
  final String suit;

  /// '0'..'21' veya 'ace'/'2'..'10'/'page'/'knight'/'queen'/'king'
  final String rank;

  final List<String> keywordsTr;
  final String shortMeaningTr;

  /// UI/okuma için ters/düz
  final bool isReversed;

  const TarotCard({
    required this.id,
    required this.nameTr,
    required this.nameEn,
    required this.arcana,
    required this.suit,
    required this.rank,
    required this.keywordsTr,
    required this.shortMeaningTr,
    this.isReversed = false,
  });

  TarotCard copyWith({bool? isReversed}) {
    return TarotCard(
      id: id,
      nameTr: nameTr,
      nameEn: nameEn,
      arcana: arcana,
      suit: suit,
      rank: rank,
      keywordsTr: keywordsTr,
      shortMeaningTr: shortMeaningTr,
      isReversed: isReversed ?? this.isReversed,
    );
  }

  /// ✅ Uzantısız base path
  /// Örn: assets/tarot/cards/major_00_fool
  String get assetBasePath => 'assets/tarot/cards/$id';

  /// ✅ Back face (uzantısız)
  static const String backBasePath = 'assets/tarot/cards/_back';
}

enum TarotSpreadType { three, six, twelve }

extension TarotSpreadTypeX on TarotSpreadType {
  int get count {
    switch (this) {
      case TarotSpreadType.three:
        return 3;
      case TarotSpreadType.six:
        return 6;
      case TarotSpreadType.twelve:
        return 12;
    }
  }

  String get label {
    switch (this) {
      case TarotSpreadType.three:
        return '3 Kart Açılımı';
      case TarotSpreadType.six:
        return '6 Kart Açılımı';
      case TarotSpreadType.twelve:
        return '12 Kart Açılımı';
    }
  }

  String get title => label;

  List<String> get positionsTr {
    switch (this) {
      case TarotSpreadType.three:
        return ['Geçmiş', 'Şimdi', 'Yakın Gelecek'];
      case TarotSpreadType.six:
        return ['Sen', 'Karşı taraf', 'Aranız', 'Engel', 'Tavsiye', 'Sonuç'];
      case TarotSpreadType.twelve:
        return [
          'Genel enerji',
          'Kök sebep',
          'Bilinçaltı',
          'Geçmiş etkisi',
          'Şu an',
          'Yakın gelecek',
          'Senin tutumun',
          'Çevre',
          'Umut/Korku',
          'Sonuç',
          'Ek mesaj',
          'Kapanış'
        ];
    }
  }
}
