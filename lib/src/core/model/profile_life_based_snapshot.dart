class ProfileLifeBasedSnapshot {
  static const String lifePathMetric = 'life_path_number';
  static const String expressionMetric = 'expression_number';
  static const String soulUrgeMetric = 'soul_urge_number';
  static const String personalityMetric = 'personality_number';
  static const String missionMetric = 'mission_number';

  const ProfileLifeBasedSnapshot({
    required this.computedAt,
    required this.metrics,
  });

  factory ProfileLifeBasedSnapshot.initial() {
    return ProfileLifeBasedSnapshot(
      computedAt: DateTime.fromMillisecondsSinceEpoch(0),
      metrics: const <String, int>{},
    );
  }

  final DateTime computedAt;
  final Map<String, int> metrics;

  int? valueOf(String key) {
    return metrics[key];
  }

  ProfileLifeBasedSnapshot upsertMetric({
    required String key,
    required int value,
  }) {
    final Map<String, int> next = Map<String, int>.from(metrics)..[key] = value;
    return ProfileLifeBasedSnapshot(computedAt: computedAt, metrics: next);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'computedAt': computedAt.toIso8601String(),
      'metrics': metrics,
    };
  }

  factory ProfileLifeBasedSnapshot.fromJson(Map<String, dynamic> json) {
    final DateTime computedAt =
        DateTime.tryParse(json['computedAt'] as String? ?? '') ??
        DateTime.now();
    final Map<String, int> metrics = <String, int>{};

    final Object? rawMetrics = json['metrics'];
    if (rawMetrics is Map<String, dynamic>) {
      for (final MapEntry<String, dynamic> entry in rawMetrics.entries) {
        final int? value = switch (entry.value) {
          final int v => v,
          final num v => v.toInt(),
          _ => null,
        };
        if (value != null) {
          metrics[entry.key] = value;
        }
      }
    }

    return ProfileLifeBasedSnapshot(computedAt: computedAt, metrics: metrics);
  }
}
