class TarotReading {
  final String id;
  final String topic;
  final String question;
  final String name;
  final int? age;

  final String spreadType; // "three" | "six" | "twelve"
  final List<String> selectedCardIds;

  final String? resultText;
  final String status; // created|processing|done|failed
  final DateTime createdAt;

  const TarotReading({
    required this.id,
    required this.topic,
    required this.question,
    required this.name,
    required this.age,
    required this.spreadType,
    required this.selectedCardIds,
    required this.resultText,
    required this.status,
    required this.createdAt,
  });
}
