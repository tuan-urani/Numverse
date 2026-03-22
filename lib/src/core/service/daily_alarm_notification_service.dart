import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:test/src/core/model/daily_alarm_settings.dart';
import 'package:test/src/core/model/daily_alarm_template.dart';
import 'package:test/src/core/repository/interface/i_cloud_account_repository.dart';
import 'package:test/src/core/service/interface/i_daily_alarm_notification_service.dart';
import 'package:test/src/utils/app_pages.dart';
import 'package:test/src/utils/app_shared.dart';

class DailyAlarmNotificationService implements IDailyAlarmNotificationService {
  DailyAlarmNotificationService({
    required ICloudAccountRepository cloudAccountRepository,
    required AppShared appShared,
    FlutterLocalNotificationsPlugin? notificationsPlugin,
  }) : _cloudAccountRepository = cloudAccountRepository,
       _appShared = appShared,
       _notificationsPlugin =
           notificationsPlugin ?? FlutterLocalNotificationsPlugin();

  static const int _notificationId = 2026032108;
  static const String _payloadOpenToday = 'open_today_tab';

  final ICloudAccountRepository _cloudAccountRepository;
  final AppShared _appShared;
  final FlutterLocalNotificationsPlugin _notificationsPlugin;

  bool _initialized = false;
  bool _permissionRequested = false;
  bool _pendingOpenTodayIntent = false;
  String _currentTimezoneId = DailyAlarmSettings.defaultTimezone;

  @override
  Future<void> bootstrap({String? localeCode}) async {
    await _initializeIfNeeded();
    await _requestPermission();
    await _resolveAndApplyLocalTimezone();

    DailyAlarmSettings settings = _loadCachedSettings();
    if (_cloudAccountRepository.isConfigured) {
      try {
        settings = await _cloudAccountRepository.fetchDailyAlarmSettings();
        await _cacheSettings(settings);
      } catch (_) {
        // Keep local cache value when cloud settings fail.
      }
    }

    await applyAlarmPreference(settings: settings, localeCode: localeCode);
  }

  @override
  Future<void> applyAlarmPreference({
    required DailyAlarmSettings settings,
    String? localeCode,
  }) async {
    await _initializeIfNeeded();
    await _resolveAndApplyLocalTimezone();
    await _cacheSettings(settings);

    if (!settings.enabled) {
      await _notificationsPlugin.cancel(_notificationId);
      return;
    }

    final String resolvedLocale = _normalizeLocale(localeCode);
    final DailyAlarmTemplate template = await _resolveTemplate(
      localeCode: resolvedLocale,
    );
    await _scheduleDailyAlarm(template: template, timeString: settings.time);
  }

  @override
  bool consumeOpenTodayIntent() {
    final bool hasPendingIntent = _pendingOpenTodayIntent;
    _pendingOpenTodayIntent = false;
    return hasPendingIntent;
  }

  @override
  Future<String> resolveCurrentTimezoneId() async {
    await _initializeIfNeeded();
    await _resolveAndApplyLocalTimezone();
    return _currentTimezoneId;
  }

  Future<void> _initializeIfNeeded() async {
    if (_initialized) {
      return;
    }

    tz_data.initializeTimeZones();
    await _resolveAndApplyLocalTimezone();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings darwinSettings =
        DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );

    final NotificationAppLaunchDetails? launchDetails =
        await _notificationsPlugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true &&
        launchDetails?.notificationResponse?.payload == _payloadOpenToday) {
      _pendingOpenTodayIntent = true;
    }

    _initialized = true;
  }

  Future<void> _resolveAndApplyLocalTimezone() async {
    try {
      final String rawTimezone = await FlutterTimezone.getLocalTimezone();
      final String normalizedTimezone = rawTimezone.trim();
      if (normalizedTimezone.isNotEmpty) {
        _currentTimezoneId = normalizedTimezone;
      }
    } catch (_) {
      // Fallback keeps default timezone id.
    }

    try {
      tz.setLocalLocation(tz.getLocation(_currentTimezoneId));
    } catch (_) {
      _currentTimezoneId = DailyAlarmSettings.defaultTimezone;
      tz.setLocalLocation(tz.getLocation(_currentTimezoneId));
    }
  }

  Future<void> _requestPermission() async {
    if (_permissionRequested) {
      return;
    }
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await androidPlugin?.requestNotificationsPermission();
    final bool canScheduleExact = await _canScheduleExactNotifications();
    if (!canScheduleExact) {
      await androidPlugin?.requestExactAlarmsPermission();
    }
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    _permissionRequested = true;
  }

  Future<DailyAlarmTemplate> _resolveTemplate({
    required String localeCode,
  }) async {
    if (_cloudAccountRepository.isConfigured) {
      try {
        final DailyAlarmTemplate template = await _cloudAccountRepository
            .fetchDailyAlarmTemplate(locale: localeCode);
        await _cacheTemplate(localeCode: localeCode, template: template);
        return template;
      } catch (_) {
        // Fall back to cached/local template.
      }
    }

    final DailyAlarmTemplate? cachedTemplate = _loadCachedTemplate(localeCode);
    if (cachedTemplate != null) {
      return cachedTemplate;
    }
    return DailyAlarmTemplate.fallback(localeCode);
  }

  Future<void> _cacheTemplate({
    required String localeCode,
    required DailyAlarmTemplate template,
  }) async {
    await _appShared.setDailyAlarmTemplate(
      localeCode: localeCode,
      value: jsonEncode(template.toJson()),
    );
  }

  Future<void> _cacheSettings(DailyAlarmSettings settings) async {
    await _appShared.setDailyAlarmEnabled(settings.enabled);
    await _appShared.setDailyAlarmTime(settings.time);
    await _appShared.setDailyAlarmTimezone(settings.timezone);
  }

  DailyAlarmSettings _loadCachedSettings() {
    final String cachedTime =
        _appShared.getDailyAlarmTime() ?? DailyAlarmSettings.defaultTime;
    final String cachedTimezone =
        _appShared.getDailyAlarmTimezone() ?? _currentTimezoneId;
    return DailyAlarmSettings(
      enabled: _appShared.getDailyAlarmEnabled(),
      time: cachedTime,
      timezone: cachedTimezone,
    );
  }

  DailyAlarmTemplate? _loadCachedTemplate(String localeCode) {
    final String? raw = _appShared.getDailyAlarmTemplate(localeCode);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return DailyAlarmTemplate.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> _scheduleDailyAlarm({
    required DailyAlarmTemplate template,
    required String timeString,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'daily_energy_alarm_channel',
          'Daily Energy Alarm',
          channelDescription: 'Daily energy reminder notifications',
          importance: Importance.max,
          priority: Priority.high,
        );
    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails();
    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    final AndroidScheduleMode scheduleMode =
        await _resolveAndroidScheduleMode();
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final tz.TZDateTime nextDateTime = nextTriggerAt(
      timeString: timeString,
      now: now,
    );

    await _notificationsPlugin.zonedSchedule(
      _notificationId,
      template.title,
      template.body,
      nextDateTime,
      details,
      payload: _payloadOpenToday,
      androidScheduleMode: scheduleMode,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime nextTriggerAt({
    required String timeString,
    required tz.TZDateTime now,
  }) {
    final ({int hour, int minute, int second}) parsed = _parseScheduledTime(
      timeString,
    );
    tz.TZDateTime candidate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
    );
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  static ({int hour, int minute, int second}) _parseScheduledTime(
    String rawTime,
  ) {
    final List<String> parts = rawTime.trim().split(':');
    if (parts.length < 2) {
      return (hour: 8, minute: 0, second: 0);
    }

    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);
    final int? second = parts.length > 2 ? int.tryParse(parts[2]) : 0;
    if (hour == null || minute == null || second == null) {
      return (hour: 8, minute: 0, second: 0);
    }
    if (hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59 ||
        second < 0 ||
        second > 59) {
      return (hour: 8, minute: 0, second: 0);
    }
    return (hour: hour, minute: minute, second: second);
  }

  Future<bool> _canScheduleExactNotifications() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (androidPlugin == null) {
      return false;
    }
    final bool? allowed = await androidPlugin.canScheduleExactNotifications();
    return allowed == true;
  }

  Future<AndroidScheduleMode> _resolveAndroidScheduleMode() async {
    final bool canScheduleExact = await _canScheduleExactNotifications();
    if (canScheduleExact) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  void _onNotificationResponse(NotificationResponse response) {
    if (response.payload != _payloadOpenToday) {
      return;
    }
    _pendingOpenTodayIntent = true;
    _tryOpenTodayRoute();
  }

  void _tryOpenTodayRoute() {
    Future<void>.microtask(() {
      if (!_pendingOpenTodayIntent || Get.key.currentContext == null) {
        return;
      }
      Get.offAllNamed(AppPages.today);
      _pendingOpenTodayIntent = false;
    });
  }

  String _normalizeLocale(String? rawLocaleCode) {
    final String normalized = (rawLocaleCode ?? '')
        .trim()
        .toLowerCase()
        .replaceAll('-', '_');
    if (normalized.startsWith('ja')) {
      return 'ja';
    }
    if (normalized.startsWith('en')) {
      return 'en';
    }
    return 'vi';
  }
}

@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse _) {
  // No-op: launch intent is handled by getNotificationAppLaunchDetails on app boot.
}
