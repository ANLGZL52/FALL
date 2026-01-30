class ProfileMe {
  final String deviceId;
  final String displayName;
  final String? birthDate;
  final String? birthPlace;
  final String? birthTime;

  ProfileMe({
    required this.deviceId,
    required this.displayName,
    this.birthDate,
    this.birthPlace,
    this.birthTime,
  });

  factory ProfileMe.fromJson(Map<String, dynamic> json) {
    return ProfileMe(
      deviceId: (json['device_id'] ?? '').toString(),
      displayName: (json['display_name'] ?? 'Misafir').toString(),
      birthDate: json['birth_date']?.toString(),
      birthPlace: json['birth_place']?.toString(),
      birthTime: json['birth_time']?.toString(),
    );
  }
}

class ProfileUpsertRequest {
  final String displayName;
  final String? birthDate;
  final String? birthPlace;
  final String? birthTime;

  ProfileUpsertRequest({
    required this.displayName,
    this.birthDate,
    this.birthPlace,
    this.birthTime,
  });

  Map<String, dynamic> toJson() {
    return {
      "display_name": displayName,
      "birth_date": (birthDate ?? '').trim().isEmpty ? null : birthDate!.trim(),
      "birth_place": (birthPlace ?? '').trim().isEmpty ? null : birthPlace!.trim(),
      "birth_time": (birthTime ?? '').trim().isEmpty ? null : birthTime!.trim(),
    };
  }
}
