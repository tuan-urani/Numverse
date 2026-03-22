import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:test/src/core/model/app_session_snapshot.dart';
import 'package:test/src/core/model/cloud_ad_reward_grant_result.dart';
import 'package:test/src/core/model/cloud_ad_reward_status_result.dart';
import 'package:test/src/core/model/cloud_daily_checkin_result.dart';
import 'package:test/src/core/model/cloud_login_result.dart';
import 'package:test/src/core/model/cloud_numai_import_guest_history_result.dart';
import 'package:test/src/core/model/cloud_numai_send_message_result.dart';
import 'package:test/src/core/model/cloud_numai_thread_messages_result.dart';
import 'package:test/src/core/model/cloud_spend_soul_points_result.dart';
import 'package:test/src/core/model/compatibility_history_item.dart';
import 'package:test/src/core/model/daily_alarm_settings.dart';
import 'package:test/src/core/model/daily_alarm_template.dart';
import 'package:test/src/core/model/local_numai_guest_message.dart';
import 'package:test/src/core/repository/interface/i_cloud_account_repository.dart';
import 'package:test/src/core/service/interface/i_daily_alarm_notification_service.dart';
import 'package:test/src/ui/settings/interactor/settings_bloc.dart';
import 'package:test/src/ui/settings/interactor/settings_event.dart';
import 'package:test/src/utils/app_shared.dart';

class _FakeCloudAccountRepository implements ICloudAccountRepository {
  bool configured = true;
  DailyAlarmSettings fetchSettingsResult = DailyAlarmSettings.defaults();
  DailyAlarmSettings updateSettingsResult = DailyAlarmSettings.defaults();
  Object? fetchSettingsError;
  Object? updateSettingsError;
  int updateCallCount = 0;
  bool? lastUpdateEnabled;
  String? lastUpdateTime;
  String? lastUpdateTimezone;

  @override
  bool get isConfigured => configured;

  @override
  String? get currentUserId => 'uid';

  @override
  Future<DailyAlarmSettings> fetchDailyAlarmSettings() async {
    if (fetchSettingsError != null) {
      throw fetchSettingsError!;
    }
    return fetchSettingsResult;
  }

  @override
  Future<DailyAlarmTemplate> fetchDailyAlarmTemplate({
    required String locale,
  }) async {
    return DailyAlarmTemplate.fallback(locale);
  }

  @override
  Future<DailyAlarmSettings> updateDailyAlarmSettings({
    required bool enabled,
    required String time,
    required String timezone,
  }) async {
    updateCallCount += 1;
    lastUpdateEnabled = enabled;
    lastUpdateTime = time;
    lastUpdateTimezone = timezone;
    if (updateSettingsError != null) {
      throw updateSettingsError!;
    }
    return updateSettingsResult.copyWith(
      enabled: enabled,
      time: time,
      timezone: timezone,
    );
  }

  @override
  Future<void> ensureAnonymousSession() async {
    throw UnimplementedError();
  }

  @override
  Future<bool> refreshAccessTokenIfNeeded() async {
    throw UnimplementedError();
  }

  @override
  Future<void> upgradeAnonymousToEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signInExistingAccount({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<CloudLoginResult> loginAndSyncFirstTime({
    required String email,
    required String password,
    required String displayName,
    required AppSessionSnapshot localSnapshot,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<CloudLoginResult> registerAndSyncFirstTime({
    required String email,
    required String password,
    required String displayName,
    required AppSessionSnapshot localSnapshot,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AppSessionSnapshot> fetchCloudSessionSnapshot({
    required String fallbackEmail,
    required String fallbackDisplayName,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> syncSessionSnapshot({
    required AppSessionSnapshot snapshot,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<CompatibilityHistoryItem> saveCompatibilityHistory({
    required CompatibilityHistoryItem item,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<CompatibilityHistoryItem>> fetchCompatibilityHistory({
    int limit = 30,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<CloudDailyCheckInResult> claimDailyCheckIn({String? requestId}) async {
    throw UnimplementedError();
  }

  @override
  Future<CloudAdRewardStatusResult> getAdRewardStatus({
    String? placementCode,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<CloudAdRewardGrantResult> grantAdReward({
    required String requestId,
    required String placementCode,
    required int requestedAmount,
    String? adNetwork,
    Map<String, dynamic>? metadata,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<CloudSpendSoulPointsResult> spendSoulPoints({
    required int amount,
    required String sourceType,
    String? requestId,
    Map<String, dynamic>? metadata,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<CloudNumAiSendMessageResult> sendNumAiMessage({
    required String profileId,
    required String messageText,
    String? threadId,
    String? locale,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<CloudNumAiSendMessageResult> sendNumAiGuestMessage({
    required String messageText,
    String? locale,
    List<Map<String, String>> recentMessages = const <Map<String, String>>[],
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<CloudNumAiThreadMessagesResult> fetchNumAiThreadMessages({
    required String profileId,
    String? threadId,
    int limit = 50,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<CloudNumAiImportGuestHistoryResult> importGuestNumAiHistory({
    required String profileId,
    required List<LocalNumAiGuestMessage> messages,
    String? requestId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteMyAccount() async {
    throw UnimplementedError();
  }

  @override
  Future<void> clearSession() async {
    throw UnimplementedError();
  }
}

class _FakeDailyAlarmNotificationService
    implements IDailyAlarmNotificationService {
  final List<DailyAlarmSettings> applyCalls = <DailyAlarmSettings>[];
  String timezoneId = 'Asia/Ho_Chi_Minh';

  @override
  Future<void> applyAlarmPreference({
    required DailyAlarmSettings settings,
    String? localeCode,
  }) async {
    applyCalls.add(settings);
  }

  @override
  Future<void> bootstrap({String? localeCode}) async {}

  @override
  bool consumeOpenTodayIntent() => false;

  @override
  Future<String> resolveCurrentTimezoneId() async {
    return timezoneId;
  }
}

Future<void> _waitForMicrotasks() async {
  await Future<void>.delayed(const Duration(milliseconds: 20));
}

void main() {
  group('SettingsBloc daily alarm', () {
    test('initializes from cloud settings and applies schedule', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'numverse_daily_alarm_enabled': false,
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppShared appShared = AppShared(prefs);
      final _FakeCloudAccountRepository cloudRepository =
          _FakeCloudAccountRepository()
            ..fetchSettingsResult = DailyAlarmSettings.defaults().copyWith(
              enabled: true,
              time: '06:30:00',
              timezone: 'Asia/Tokyo',
            );
      final _FakeDailyAlarmNotificationService notificationService =
          _FakeDailyAlarmNotificationService();

      final SettingsBloc bloc = SettingsBloc(
        cloudAccountRepository: cloudRepository,
        appShared: appShared,
        dailyAlarmNotificationService: notificationService,
        localeCodeProvider: () => 'vi',
      );

      await _waitForMicrotasks();

      expect(bloc.state.dailyAlarmEnabled, isTrue);
      expect(bloc.state.dailyAlarmTime, '06:30:00');
      expect(bloc.state.dailyAlarmTimezone, 'Asia/Tokyo');
      expect(appShared.getDailyAlarmEnabled(), isTrue);
      expect(appShared.getDailyAlarmTime(), '06:30:00');
      expect(appShared.getDailyAlarmTimezone(), 'Asia/Tokyo');
      expect(notificationService.applyCalls, isNotEmpty);
      expect(notificationService.applyCalls.last.enabled, isTrue);
      expect(notificationService.applyCalls.last.time, '06:30:00');

      await bloc.close();
    });

    test('toggle success updates cloud and keeps next state', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'numverse_daily_alarm_enabled': true,
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppShared appShared = AppShared(prefs);
      final _FakeCloudAccountRepository cloudRepository =
          _FakeCloudAccountRepository()
            ..fetchSettingsResult = DailyAlarmSettings.defaults().copyWith(
              time: '06:30:00',
              timezone: 'Asia/Tokyo',
            );
      final _FakeDailyAlarmNotificationService notificationService =
          _FakeDailyAlarmNotificationService();

      final SettingsBloc bloc = SettingsBloc(
        cloudAccountRepository: cloudRepository,
        appShared: appShared,
        dailyAlarmNotificationService: notificationService,
        localeCodeProvider: () => 'en',
      );
      await _waitForMicrotasks();
      notificationService.applyCalls.clear();

      final Future<void> done = bloc.stream
          .firstWhere((state) => !state.dailyAlarmSyncing)
          .then((_) {});
      bloc.add(const SettingsDailyAlarmToggled());
      await done;

      expect(bloc.state.dailyAlarmEnabled, isFalse);
      expect(bloc.state.dailyAlarmTime, '06:30:00');
      expect(cloudRepository.updateCallCount, 1);
      expect(cloudRepository.lastUpdateEnabled, isFalse);
      expect(cloudRepository.lastUpdateTime, '06:30:00');
      expect(cloudRepository.lastUpdateTimezone, 'Asia/Ho_Chi_Minh');
      expect(notificationService.applyCalls.first.enabled, isFalse);
      expect(appShared.getDailyAlarmEnabled(), isFalse);
      expect(appShared.getDailyAlarmTime(), '06:30:00');

      await bloc.close();
    });

    test('toggle failure reverts local state and schedule', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'numverse_daily_alarm_enabled': true,
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppShared appShared = AppShared(prefs);
      final _FakeCloudAccountRepository cloudRepository =
          _FakeCloudAccountRepository()
            ..fetchSettingsResult = DailyAlarmSettings.defaults().copyWith(
              time: '20:15:00',
              timezone: 'Asia/Tokyo',
            )
            ..updateSettingsError = StateError('sync_failed');
      final _FakeDailyAlarmNotificationService notificationService =
          _FakeDailyAlarmNotificationService();

      final SettingsBloc bloc = SettingsBloc(
        cloudAccountRepository: cloudRepository,
        appShared: appShared,
        dailyAlarmNotificationService: notificationService,
        localeCodeProvider: () => 'ja',
      );
      await _waitForMicrotasks();
      notificationService.applyCalls.clear();

      final Future<void> done = bloc.stream
          .firstWhere((state) => !state.dailyAlarmSyncing)
          .then((_) {});
      bloc.add(const SettingsDailyAlarmToggled());
      await done;

      expect(bloc.state.dailyAlarmEnabled, isTrue);
      expect(bloc.state.dailyAlarmTime, '20:15:00');
      expect(notificationService.applyCalls.map((e) => e.enabled), <bool>[
        false,
        true,
      ]);
      expect(appShared.getDailyAlarmEnabled(), isTrue);
      expect(appShared.getDailyAlarmTime(), '20:15:00');

      await bloc.close();
    });
  });
}
