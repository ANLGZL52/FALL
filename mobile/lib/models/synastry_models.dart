// lib/models/synastry_models.dart

class SynastryStartRequest {
  final String nameA;
  final String birthDateA; // YYYY-MM-DD
  final String? birthTimeA; // HH:MM optional
  final String birthCityA;
  final String birthCountryA;

  final String nameB;
  final String birthDateB;
  final String? birthTimeB;
  final String birthCityB;
  final String birthCountryB;

  final String topic;
  final String? question;

  const SynastryStartRequest({
    required this.nameA,
    required this.birthDateA,
    this.birthTimeA,
    required this.birthCityA,
    required this.birthCountryA,
    required this.nameB,
    required this.birthDateB,
    this.birthTimeB,
    required this.birthCityB,
    required this.birthCountryB,
    required this.topic,
    this.question,
  });

  Map<String, dynamic> toJson() => {
        "name_a": nameA,
        "birth_date_a": birthDateA,
        "birth_time_a": (birthTimeA ?? "").trim().isEmpty ? null : birthTimeA,
        "birth_city_a": birthCityA,
        "birth_country_a": birthCountryA,
        "name_b": nameB,
        "birth_date_b": birthDateB,
        "birth_time_b": (birthTimeB ?? "").trim().isEmpty ? null : birthTimeB,
        "birth_city_b": birthCityB,
        "birth_country_b": birthCountryB,
        "topic": topic,
        "question": (question ?? "").trim().isEmpty ? null : question,
      };
}

class SynastryStartResponse {
  final String readingId;

  const SynastryStartResponse({required this.readingId});

  factory SynastryStartResponse.fromJson(Map<String, dynamic> json) {
    // backend create() reading obj döndürüyor olabilir: {"id": "..."} veya {"reading_id": "..."}
    final id = (json["reading_id"] ?? json["id"] ?? "").toString();
    return SynastryStartResponse(readingId: id);
  }
}

class SynastryMarkPaidRequest {
  final String? paymentRef;

  const SynastryMarkPaidRequest({this.paymentRef});

  Map<String, dynamic> toJson() => {
        "payment_ref": (paymentRef ?? "").trim().isEmpty ? null : paymentRef,
      };
}

class SynastryStatusResponse {
  final String id;
  final String status; // created|paid|processing|done|error (senin repo'ya göre)
  final String? resultText;
  final String? error;

  const SynastryStatusResponse({
    required this.id,
    required this.status,
    this.resultText,
    this.error,
  });

  factory SynastryStatusResponse.fromJson(Map<String, dynamic> json) {
    return SynastryStatusResponse(
      id: (json["id"] ?? json["reading_id"] ?? "").toString(),
      status: (json["status"] ?? "").toString(),
      resultText: json["result_text"]?.toString(),
      error: json["error"]?.toString(),
    );
  }
}
