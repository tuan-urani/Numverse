import 'package:test/src/core/model/daily_alarm_settings.dart';

abstract class IDailyAlarmNotificationService {
  Future<void> bootstrap({String? localeCode});

  Future<void> applyAlarmPreference({
    required DailyAlarmSettings settings,
    String? localeCode,
  });

  Future<String> resolveCurrentTimezoneId();

  bool consumeOpenTodayIntent();
}
