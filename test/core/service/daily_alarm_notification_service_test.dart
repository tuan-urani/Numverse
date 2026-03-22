import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:test/src/core/service/daily_alarm_notification_service.dart';

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
  });

  group('DailyAlarmNotificationService.nextTriggerAt', () {
    test('returns same day at configured time when now is before trigger', () {
      final tz.TZDateTime now = tz.TZDateTime(tz.local, 2026, 3, 21, 7, 10);
      final tz.TZDateTime next = DailyAlarmNotificationService.nextTriggerAt(
        timeString: '08:00:00',
        now: now,
      );

      expect(next.year, 2026);
      expect(next.month, 3);
      expect(next.day, 21);
      expect(next.hour, 8);
      expect(next.minute, 0);
    });

    test('returns next day at configured time when now is after trigger', () {
      final tz.TZDateTime now = tz.TZDateTime(tz.local, 2026, 3, 21, 10, 0);
      final tz.TZDateTime next = DailyAlarmNotificationService.nextTriggerAt(
        timeString: '06:30:00',
        now: now,
      );

      expect(next.year, 2026);
      expect(next.month, 3);
      expect(next.day, 22);
      expect(next.hour, 6);
      expect(next.minute, 30);
    });

    test('returns next day when now is exactly at trigger time', () {
      final tz.TZDateTime now = tz.TZDateTime(tz.local, 2026, 3, 21, 8, 0);
      final tz.TZDateTime next = DailyAlarmNotificationService.nextTriggerAt(
        timeString: '08:00',
        now: now,
      );

      expect(next.day, 22);
      expect(next.hour, 8);
      expect(next.minute, 0);
    });

    test('falls back to 08:00 when input time is invalid', () {
      final tz.TZDateTime now = tz.TZDateTime(tz.local, 2026, 3, 21, 7, 59);
      final tz.TZDateTime next = DailyAlarmNotificationService.nextTriggerAt(
        timeString: 'abc',
        now: now,
      );

      expect(next.day, 21);
      expect(next.hour, 8);
      expect(next.minute, 0);
    });
  });
}
