abstract class IDailyAlarmNotificationService {
  Future<void> bootstrap({String? localeCode});

  Future<void> applyAlarmPreference({
    required bool enabled,
    String? localeCode,
  });

  Future<String> resolveCurrentTimezoneId();

  bool consumeOpenTodayIntent();
}
