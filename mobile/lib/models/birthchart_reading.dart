class BirthChartReading {
  final String id;
  final String topic;
  final String? question;

  final String name;
  final String birthDate;     // YYYY-MM-DD
  final String? birthTime;    // HH:MM (opsiyonel)
  final String birthCity;
  final String birthCountry;

  final String status;        // started / paid / processing / completed
  final String? resultText;

  final bool isPaid;
  final String? paymentRef;

  BirthChartReading({
    required this.id,
    required this.topic,
    required this.question,
    required this.name,
    required this.birthDate,
    required this.birthTime,
    required this.birthCity,
    required this.birthCountry,
    required this.status,
    required this.resultText,
    required this.isPaid,
    required this.paymentRef,
  });

  factory BirthChartReading.fromJson(Map<String, dynamic> j) {
    return BirthChartReading(
      id: (j["id"] ?? "").toString(),
      topic: (j["topic"] ?? "genel").toString(),
      question: j["question"]?.toString(),
      name: (j["name"] ?? "").toString(),
      birthDate: (j["birth_date"] ?? "").toString(),
      birthTime: j["birth_time"]?.toString(),
      birthCity: (j["birth_city"] ?? "").toString(),
      birthCountry: (j["birth_country"] ?? "TR").toString(),
      status: (j["status"] ?? "").toString(),
      resultText: j["result_text"]?.toString(),
      isPaid: (j["is_paid"] ?? false) == true,
      paymentRef: j["payment_ref"]?.toString(),
    );
  }
}
