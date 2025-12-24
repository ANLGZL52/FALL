// lib/models/coffee_reading.dart
class CoffeeReading {
  final String id;
  final String name;
  final int? age;
  final String topic;
  final String question;
  final List<String> photos;
  final String status; // pending_photos|pending_payment|paid|processing|ready|rejected
  final String? comment;
  final int? rating;
  final String? paymentRef;
  final String createdAt;

  CoffeeReading({
    required this.id,
    required this.name,
    required this.age,
    required this.topic,
    required this.question,
    required this.photos,
    required this.status,
    required this.comment,
    required this.rating,
    required this.paymentRef,
    required this.createdAt,
  });

  factory CoffeeReading.fromJson(Map<String, dynamic> json) {
    return CoffeeReading(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      age: json['age'] == null ? null : int.tryParse(json['age'].toString()),
      topic: json['topic']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      photos: (json['photos'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      status: json['status']?.toString() ?? 'pending_photos',
      comment: json['comment']?.toString(),
      rating: json['rating'] == null ? null : int.tryParse(json['rating'].toString()),
      paymentRef: json['payment_ref']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  CoffeeReading copyWith({
    String? status,
    String? comment,
    int? rating,
    List<String>? photos,
    String? paymentRef,
  }) {
    return CoffeeReading(
      id: id,
      name: name,
      age: age,
      topic: topic,
      question: question,
      photos: photos ?? this.photos,
      status: status ?? this.status,
      comment: comment ?? this.comment,
      rating: rating ?? this.rating,
      paymentRef: paymentRef ?? this.paymentRef,
      createdAt: createdAt,
    );
  }
}
