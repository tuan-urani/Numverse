class TimeLifeMetricSnapshot {
  const TimeLifeMetricSnapshot({
    required this.value,
    required this.computedAt,
    required this.refreshAt,
  });

  final int value;
  final DateTime computedAt;
  final DateTime refreshAt;

  TimeLifeMetricSnapshot copyWith({
    int? value,
    DateTime? computedAt,
    DateTime? refreshAt,
  }) {
    return TimeLifeMetricSnapshot(
      value: value ?? this.value,
      computedAt: computedAt ?? this.computedAt,
      refreshAt: refreshAt ?? this.refreshAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'value': value,
      'computedAt': computedAt.toIso8601String(),
      'refreshAt': refreshAt.toIso8601String(),
    };
  }

  factory TimeLifeMetricSnapshot.fromJson(Map<String, dynamic> json) {
    final DateTime now = DateTime.now();
    return TimeLifeMetricSnapshot(
      value: json['value'] as int? ?? 0,
      computedAt: DateTime.tryParse(json['computedAt'] as String? ?? '') ?? now,
      refreshAt: DateTime.tryParse(json['refreshAt'] as String? ?? '') ?? now,
    );
  }
}

class ProfileTimeLifeSnapshot {
  static const String guestProfileId = '__guest__';

  static const String universalDayMetric = 'universal_day';
  static const String luckyNumberMetric = 'lucky_number';
  static const String dailyMessageNumberMetric = 'daily_message_number';
  static const String personalDayMetric = 'personal_day_number';
  static const String personalMonthMetric = 'personal_month_number';
  static const String personalYearMetric = 'personal_year_number';

  const ProfileTimeLifeSnapshot({required this.metrics});

  factory ProfileTimeLifeSnapshot.initial() {
    return const ProfileTimeLifeSnapshot(
      metrics: <String, TimeLifeMetricSnapshot>{},
    );
  }

  final Map<String, TimeLifeMetricSnapshot> metrics;

  TimeLifeMetricSnapshot? metricOf(String key) {
    return metrics[key];
  }

  int? valueOf(String key) {
    return metrics[key]?.value;
  }

  bool needsRefresh(String key, DateTime now) {
    final TimeLifeMetricSnapshot? metric = metrics[key];
    if (metric == null) {
      return true;
    }
    return !now.isBefore(metric.refreshAt);
  }

  ProfileTimeLifeSnapshot upsertMetric({
    required String key,
    required TimeLifeMetricSnapshot snapshot,
  }) {
    final Map<String, TimeLifeMetricSnapshot> next =
        Map<String, TimeLifeMetricSnapshot>.from(metrics)..[key] = snapshot;
    return ProfileTimeLifeSnapshot(metrics: next);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'metrics': metrics.map((String key, TimeLifeMetricSnapshot value) {
        return MapEntry<String, dynamic>(key, value.toJson());
      }),
    };
  }

  factory ProfileTimeLifeSnapshot.fromJson(Map<String, dynamic> json) {
    final Map<String, TimeLifeMetricSnapshot> metrics =
        <String, TimeLifeMetricSnapshot>{};

    final Object? rawMetrics = json['metrics'];
    if (rawMetrics is Map<String, dynamic>) {
      for (final MapEntry<String, dynamic> entry in rawMetrics.entries) {
        if (entry.value is! Map<String, dynamic>) {
          continue;
        }
        try {
          metrics[entry.key] = TimeLifeMetricSnapshot.fromJson(
            entry.value as Map<String, dynamic>,
          );
        } catch (_) {
          continue;
        }
      }
    }

    if (metrics.isNotEmpty) {
      return ProfileTimeLifeSnapshot(metrics: metrics);
    }

    return _migrateLegacyShape(json);
  }

  static ProfileTimeLifeSnapshot _migrateLegacyShape(
    Map<String, dynamic> json,
  ) {
    final DateTime now = DateTime.now();
    final DateTime computedAt =
        DateTime.tryParse(json['computedAt'] as String? ?? '') ?? now;
    final DateTime refreshAt =
        DateTime.tryParse(json['refreshAt'] as String? ?? '') ?? now;

    final Map<String, TimeLifeMetricSnapshot> metrics =
        <String, TimeLifeMetricSnapshot>{};

    final int? universalDay = json['universalDay'] as int?;
    if (universalDay != null) {
      metrics[universalDayMetric] = TimeLifeMetricSnapshot(
        value: universalDay,
        computedAt: computedAt,
        refreshAt: refreshAt,
      );
    }

    final int? luckyNumber = json['luckyNumber'] as int?;
    if (luckyNumber != null) {
      metrics[luckyNumberMetric] = TimeLifeMetricSnapshot(
        value: luckyNumber,
        computedAt: computedAt,
        refreshAt: refreshAt,
      );
    }

    final int? dailyMessageNumber = json['dailyMessageNumber'] as int?;
    if (dailyMessageNumber != null) {
      metrics[dailyMessageNumberMetric] = TimeLifeMetricSnapshot(
        value: dailyMessageNumber,
        computedAt: computedAt,
        refreshAt: refreshAt,
      );
    }

    return ProfileTimeLifeSnapshot(metrics: metrics);
  }
}
