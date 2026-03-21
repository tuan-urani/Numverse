class DailyAlarmSettings {
  const DailyAlarmSettings({
    required this.enabled,
    required this.time,
    required this.timezone,
  });

  static const String defaultTime = '08:00:00';
  static const String defaultTimezone = 'Asia/Ho_Chi_Minh';

  factory DailyAlarmSettings.defaults() {
    return const DailyAlarmSettings(
      enabled: true,
      time: defaultTime,
      timezone: defaultTimezone,
    );
  }

  factory DailyAlarmSettings.fromJson(Map<String, dynamic> json) {
    final bool enabled = switch (json['enabled']) {
      bool() => json['enabled'] as bool,
      int() => (json['enabled'] as int) != 0,
      String() => (json['enabled'] as String).trim().toLowerCase() == 'true',
      _ => true,
    };
    final String time = (json['time'] as String? ?? '').trim();
    final String timezone = (json['timezone'] as String? ?? '').trim();

    return DailyAlarmSettings(
      enabled: enabled,
      time: time.isEmpty ? defaultTime : time,
      timezone: timezone.isEmpty ? defaultTimezone : timezone,
    );
  }

  final bool enabled;
  final String time;
  final String timezone;

  DailyAlarmSettings copyWith({bool? enabled, String? time, String? timezone}) {
    return DailyAlarmSettings(
      enabled: enabled ?? this.enabled,
      time: (time ?? this.time).trim(),
      timezone: (timezone ?? this.timezone).trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'enabled': enabled,
      'time': time,
      'timezone': timezone,
    };
  }
}
