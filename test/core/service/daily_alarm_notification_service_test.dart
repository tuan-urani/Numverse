import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:test/src/core/service/daily_alarm_notification_service.dart';

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
  });

  group('DailyAlarmNotificationService.nextEightAm', () {
    test('returns same day 08:00 when now is before 08:00', () {
      final tz.TZDateTime now = tz.TZDateTime(tz.local, 2026, 3, 21, 7, 10);
      final tz.TZDateTime next = DailyAlarmNotificationService.nextEightAm(now);

      expect(next.year, 2026);
      expect(next.month, 3);
      expect(next.day, 21);
      expect(next.hour, 8);
      expect(next.minute, 0);
    });

    test('returns next day 08:00 when now is after 08:00', () {
      final tz.TZDateTime now = tz.TZDateTime(tz.local, 2026, 3, 21, 10, 0);
      final tz.TZDateTime next = DailyAlarmNotificationService.nextEightAm(now);

      expect(next.year, 2026);
      expect(next.month, 3);
      expect(next.day, 22);
      expect(next.hour, 8);
      expect(next.minute, 0);
    });

    test('returns next day 08:00 when now is exactly 08:00', () {
      final tz.TZDateTime now = tz.TZDateTime(tz.local, 2026, 3, 21, 8, 0);
      final tz.TZDateTime next = DailyAlarmNotificationService.nextEightAm(now);

      expect(next.day, 22);
      expect(next.hour, 8);
      expect(next.minute, 0);
    });
  });
}
