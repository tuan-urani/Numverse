import 'package:flutter_test/flutter_test.dart';

import 'package:test/src/core/model/daily_alarm_settings.dart';
import 'package:test/src/core/model/daily_alarm_template.dart';

void main() {
  group('DailyAlarmSettings', () {
    test('fromJson uses defaults when fields are missing', () {
      final DailyAlarmSettings settings = DailyAlarmSettings.fromJson(
        const <String, dynamic>{},
      );

      expect(settings.enabled, isTrue);
      expect(settings.time, DailyAlarmSettings.defaultTime);
      expect(settings.timezone, DailyAlarmSettings.defaultTimezone);
    });

    test('fromJson parses explicit values', () {
      final DailyAlarmSettings settings = DailyAlarmSettings.fromJson(
        const <String, dynamic>{
          'enabled': false,
          'time': '08:00:00',
          'timezone': 'Asia/Tokyo',
        },
      );

      expect(settings.enabled, isFalse);
      expect(settings.time, '08:00:00');
      expect(settings.timezone, 'Asia/Tokyo');
    });
  });

  group('DailyAlarmTemplate', () {
    test('fromJson falls back when title/body are invalid', () {
      final DailyAlarmTemplate template = DailyAlarmTemplate.fromJson(
        const <String, dynamic>{'locale': 'en_US', 'title': '', 'body': ''},
      );

      expect(template.locale, 'en');
      expect(template.title, isNotEmpty);
      expect(template.body, isNotEmpty);
    });

    test('fromJson maps locale and keeps server content', () {
      final DailyAlarmTemplate template = DailyAlarmTemplate.fromJson(
        const <String, dynamic>{'locale': 'ja_JP', 'title': 'T', 'body': 'B'},
      );

      expect(template.locale, 'ja');
      expect(template.title, 'T');
      expect(template.body, 'B');
    });
  });
}
