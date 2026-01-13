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
    // backend: {"id": "..."} veya {"reading_id": "..."} veya {"readingId": "..."}
    final id = (json["reading_id"] ?? json["readingId"] ?? json["id"] ?? "").toString();
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
  final String status; // created|paid|processing|done|error
  final String? resultText;
  final String? error;

  const SynastryStatusResponse({
    required this.id,
    required this.status,
    this.resultText,
    this.error,
  });

  static String? _pickString(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      final v = j[k];
      if (v == null) continue;
      final s = v.toString();
      if (s.trim().isNotEmpty) return s;
    }
    return null;
  }

  factory SynastryStatusResponse.fromJson(Map<String, dynamic> json) {
    final id = (json["id"] ?? json["reading_id"] ?? json["readingId"] ?? "").toString();

    // status bazen null/boş gelebiliyor: default "processing"
    final statusRaw = (json["status"] ?? "").toString().trim();
    final status = statusRaw.isEmpty ? "processing" : statusRaw;

    // result_text en yaygını; ama fallback’ler ekledik
    final resultText = _pickString(json, [
      "result_text",
      "resultText",
      "result",
      "output_text",
    ]);

    // error bazen detail/message
    final error = _pickString(json, [
      "error",
      "detail",
      "message",
    ]);

    return SynastryStatusResponse(
      id: id,
      status: status,
      resultText: resultText,
      error: error,
    );
  }
}
