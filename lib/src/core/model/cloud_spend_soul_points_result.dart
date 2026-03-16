class CloudSpendSoulPointsResult {
  const CloudSpendSoulPointsResult({
    required this.applied,
    required this.idempotent,
    required this.insufficient,
    required this.soulPoints,
    required this.required,
    required this.charged,
  });

  final bool applied;
  final bool idempotent;
  final bool insufficient;
  final int soulPoints;
  final int required;
  final int charged;

  factory CloudSpendSoulPointsResult.fromJson(Map<String, dynamic> json) {
    return CloudSpendSoulPointsResult(
      applied: json['applied'] == true,
      idempotent: json['idempotent'] == true,
      insufficient: json['insufficient'] == true,
      soulPoints: (json['soulPoints'] as num?)?.toInt() ?? 0,
      required: (json['required'] as num?)?.toInt() ?? 0,
      charged: (json['charged'] as num?)?.toInt() ?? 0,
    );
  }
}
