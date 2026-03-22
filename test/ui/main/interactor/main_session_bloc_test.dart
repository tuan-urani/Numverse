import 'package:flutter_test/flutter_test.dart';

import 'package:test/src/core/model/app_session_snapshot.dart';
import 'package:test/src/core/model/cloud_ad_reward_grant_result.dart';
import 'package:test/src/core/model/cloud_ad_reward_status_result.dart';
import 'package:test/src/core/model/cloud_daily_checkin_result.dart';
import 'package:test/src/core/model/cloud_login_result.dart';
import 'package:test/src/core/model/cloud_numai_import_guest_history_result.dart';
import 'package:test/src/core/model/cloud_numai_send_message_result.dart';
import 'package:test/src/core/model/cloud_numai_thread_messages_result.dart';
import 'package:test/src/core/model/cloud_spend_soul_points_result.dart';
import 'package:test/src/core/model/comparison_profile.dart';
import 'package:test/src/core/model/compatibility_history_item.dart';
import 'package:test/src/core/model/daily_alarm_settings.dart';
import 'package:test/src/core/model/daily_alarm_template.dart';
import 'package:test/src/core/model/local_numai_guest_message.dart';
import 'package:test/src/core/model/profile_life_based_snapshot.dart';
import 'package:test/src/core/model/profile_time_life_snapshot.dart';
import 'package:test/src/core/model/session_auth_mode.dart';
import 'package:test/src/core/model/user_profile.dart';
import 'package:test/src/core/repository/interface/i_app_session_repository.dart';
import 'package:test/src/core/repository/interface/i_cloud_account_repository.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/widgets/app_state_view.dart';

void main() {
  group('MainSessionBloc initialize compatibility history', () {
    test(
      'keeps local history when cloud snapshot is empty and owner matches',
      () async {
        final UserProfile profile = _profile(id: 'profile-a', name: 'A');
        final CompatibilityHistoryItem localItem = _historyItem(
          id: 'local-1',
          requestId: 'req-local-1',
          primaryProfileId: profile.id,
          createdAt: DateTime(2026, 3, 20, 10),
        );
        final _FakeAppSessionRepository sessionRepository =
            _FakeAppSessionRepository(
              snapshot: _snapshot(
                cloudUserId: 'cloud-user-1',
                profiles: <UserProfile>[profile],
                currentProfileId: profile.id,
                compatibilityHistory: <CompatibilityHistoryItem>[localItem],
              ),
            );
        final _FakeCloudAccountRepository cloudRepository =
            _FakeCloudAccountRepository()
              ..cloudSnapshot = _snapshot(
                cloudUserId: 'cloud-user-1',
                profiles: <UserProfile>[profile],
                currentProfileId: profile.id,
                compatibilityHistory: const <CompatibilityHistoryItem>[],
              )
              ..compatibilityHistoryResult = const <CompatibilityHistoryItem>[];
        final MainSessionBloc bloc = MainSessionBloc(
          sessionRepository,
          cloudRepository,
        );
        addTearDown(bloc.close);

        await bloc.initialize();

        expect(bloc.state.viewState, AppViewStateStatus.success);
        expect(
          bloc.state.compatibilityHistory.map((item) => item.id),
          contains('local-1'),
        );
        expect(cloudRepository.fetchCompatibilityHistoryCallCount, 1);
      },
    );

    test('merges cloud history into local history on initialize', () async {
      final UserProfile profile = _profile(id: 'profile-a', name: 'A');
      final CompatibilityHistoryItem localItem = _historyItem(
        id: 'local-1',
        requestId: 'req-local-1',
        primaryProfileId: profile.id,
        createdAt: DateTime(2026, 3, 20, 10),
      );
      final CompatibilityHistoryItem cloudItem = _historyItem(
        id: 'cloud-1',
        requestId: 'req-cloud-1',
        primaryProfileId: profile.id,
        createdAt: DateTime(2026, 3, 20, 11),
      );
      final _FakeAppSessionRepository sessionRepository =
          _FakeAppSessionRepository(
            snapshot: _snapshot(
              cloudUserId: 'cloud-user-1',
              profiles: <UserProfile>[profile],
              currentProfileId: profile.id,
              compatibilityHistory: <CompatibilityHistoryItem>[localItem],
            ),
          );
      final _FakeCloudAccountRepository cloudRepository =
          _FakeCloudAccountRepository()
            ..cloudSnapshot = _snapshot(
              cloudUserId: 'cloud-user-1',
              profiles: <UserProfile>[profile],
              currentProfileId: profile.id,
              compatibilityHistory: const <CompatibilityHistoryItem>[],
            )
            ..compatibilityHistoryResult = <CompatibilityHistoryItem>[
              cloudItem,
            ];
      final MainSessionBloc bloc = MainSessionBloc(
        sessionRepository,
        cloudRepository,
      );
      addTearDown(bloc.close);

      await bloc.initialize();

      expect(
        bloc.state.compatibilityHistory.map((item) => item.id).toList(),
        <String>['cloud-1', 'local-1'],
      );
    });

    test('keeps local history when cloud history refresh fails', () async {
      final UserProfile profile = _profile(id: 'profile-a', name: 'A');
      final CompatibilityHistoryItem localItem = _historyItem(
        id: 'local-1',
        requestId: 'req-local-1',
        primaryProfileId: profile.id,
        createdAt: DateTime(2026, 3, 20, 10),
      );
      final _FakeAppSessionRepository sessionRepository =
          _FakeAppSessionRepository(
            snapshot: _snapshot(
              cloudUserId: 'cloud-user-1',
              profiles: <UserProfile>[profile],
              currentProfileId: profile.id,
              compatibilityHistory: <CompatibilityHistoryItem>[localItem],
            ),
          );
      final _FakeCloudAccountRepository cloudRepository =
          _FakeCloudAccountRepository()
            ..cloudSnapshot = _snapshot(
              cloudUserId: 'cloud-user-1',
              profiles: <UserProfile>[profile],
              currentProfileId: profile.id,
              compatibilityHistory: const <CompatibilityHistoryItem>[],
            )
            ..fetchCompatibilityHistoryError = StateError('network');
      final MainSessionBloc bloc = MainSessionBloc(
        sessionRepository,
        cloudRepository,
      );
      addTearDown(bloc.close);

      await bloc.initialize();

      expect(
        bloc.state.compatibilityHistory.map((item) => item.id),
        contains('local-1'),
      );
    });

    test('does not merge local history when cloud owner mismatches', () async {
      final UserProfile profile = _profile(id: 'profile-a', name: 'A');
      final CompatibilityHistoryItem localItem = _historyItem(
        id: 'local-1',
        requestId: 'req-local-1',
        primaryProfileId: profile.id,
        createdAt: DateTime(2026, 3, 20, 10),
      );
      final _FakeAppSessionRepository sessionRepository =
          _FakeAppSessionRepository(
            snapshot: _snapshot(
              cloudUserId: 'cloud-user-local',
              profiles: <UserProfile>[profile],
              currentProfileId: profile.id,
              compatibilityHistory: <CompatibilityHistoryItem>[localItem],
            ),
          );
      final _FakeCloudAccountRepository cloudRepository =
          _FakeCloudAccountRepository()
            ..cloudSnapshot = _snapshot(
              cloudUserId: 'cloud-user-remote',
              profiles: <UserProfile>[profile],
              currentProfileId: profile.id,
              compatibilityHistory: const <CompatibilityHistoryItem>[],
            )
            ..compatibilityHistoryResult = const <CompatibilityHistoryItem>[];
      final MainSessionBloc bloc = MainSessionBloc(
        sessionRepository,
        cloudRepository,
      );
      addTearDown(bloc.close);

      await bloc.initialize();

      expect(bloc.state.compatibilityHistory, isEmpty);
    });
  });

  group('MainSessionBloc delete user data', () {
    test(
      'deletes cloud account and bootstraps fresh anonymous session',
      () async {
        final UserProfile profile = _profile(id: 'profile-a', name: 'A');
        final _FakeAppSessionRepository sessionRepository =
            _FakeAppSessionRepository(
              snapshot: _snapshot(
                cloudUserId: 'cloud-user-1',
                profiles: <UserProfile>[profile],
                currentProfileId: profile.id,
                compatibilityHistory: const <CompatibilityHistoryItem>[],
              ),
            );
        final _FakeCloudAccountRepository cloudRepository =
            _FakeCloudAccountRepository()
              ..currentUserIdValue = 'cloud-user-1'
              ..cloudSnapshot = _snapshot(
                cloudUserId: 'cloud-user-1',
                profiles: <UserProfile>[profile],
                currentProfileId: profile.id,
                compatibilityHistory: const <CompatibilityHistoryItem>[],
              )
              ..cloudSnapshotAfterDelete = AppSessionSnapshot.initial()
                  .copyWith(
                    isAuthenticated: true,
                    authMode: SessionAuthMode.anonymous,
                    pendingAnonymousBootstrap: false,
                    cloudUserId: 'cloud-user-new',
                  );
        final MainSessionBloc bloc = MainSessionBloc(
          sessionRepository,
          cloudRepository,
        );
        addTearDown(bloc.close);

        await bloc.initialize();
        final int checkInCallsBeforeDelete =
            cloudRepository.claimDailyCheckInCallCount;
        final int adStatusCallsBeforeDelete =
            cloudRepository.getAdRewardStatusCallCount;
        final int historyCallsBeforeDelete =
            cloudRepository.fetchCompatibilityHistoryCallCount;
        await bloc.deleteUserData();

        expect(cloudRepository.deleteMyAccountCallCount, 1);
        expect(cloudRepository.clearSessionCallCount, 1);
        expect(
          cloudRepository.claimDailyCheckInCallCount,
          checkInCallsBeforeDelete,
        );
        expect(
          cloudRepository.getAdRewardStatusCallCount,
          adStatusCallsBeforeDelete,
        );
        expect(
          cloudRepository.fetchCompatibilityHistoryCallCount,
          historyCallsBeforeDelete,
        );
        expect(sessionRepository.clearCallCount, 1);
        expect(bloc.state.authMode, SessionAuthMode.anonymous);
        expect(bloc.state.hasCloudSession, isTrue);
        expect(bloc.state.profiles, isEmpty);
      },
    );
  });
}

class _FakeAppSessionRepository implements IAppSessionRepository {
  _FakeAppSessionRepository({required this.snapshot});

  AppSessionSnapshot snapshot;
  int clearCallCount = 0;

  @override
  Future<AppSessionSnapshot> loadSnapshot() async {
    return snapshot;
  }

  @override
  Future<void> saveSnapshot(AppSessionSnapshot nextSnapshot) async {
    snapshot = nextSnapshot;
  }

  @override
  Future<List<LocalNumAiGuestMessage>> loadNumAiGuestMessages({
    required String userKey,
  }) async {
    return const <LocalNumAiGuestMessage>[];
  }

  @override
  Future<void> saveNumAiGuestMessages({
    required String userKey,
    required List<LocalNumAiGuestMessage> messages,
  }) async {}

  @override
  Future<void> clearNumAiGuestMessages({required String userKey}) async {}

  @override
  Future<String?> loadLastNumAiGuestUserKey() async {
    return null;
  }

  @override
  Future<void> saveLastNumAiGuestUserKey({required String userKey}) async {}

  @override
  Future<void> clearLastNumAiGuestUserKey() async {}

  @override
  Future<void> clear() async {
    clearCallCount += 1;
  }
}

class _FakeCloudAccountRepository implements ICloudAccountRepository {
  bool configured = true;
  String? currentUserIdValue;
  int fetchCompatibilityHistoryCallCount = 0;
  Object? fetchCompatibilityHistoryError;
  List<CompatibilityHistoryItem> compatibilityHistoryResult =
      <CompatibilityHistoryItem>[];
  AppSessionSnapshot cloudSnapshot = AppSessionSnapshot.initial();
  AppSessionSnapshot? cloudSnapshotAfterDelete;
  Object? deleteMyAccountError;
  int deleteMyAccountCallCount = 0;
  int clearSessionCallCount = 0;
  int claimDailyCheckInCallCount = 0;
  int getAdRewardStatusCallCount = 0;

  @override
  bool get isConfigured => configured;

  @override
  String? get currentUserId => currentUserIdValue;

  @override
  Future<void> ensureAnonymousSession() async {}

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
    return cloudSnapshot;
  }

  @override
  Future<void> syncSessionSnapshot({
    required AppSessionSnapshot snapshot,
  }) async {
    cloudSnapshot = snapshot;
  }

  @override
  Future<DailyAlarmSettings> fetchDailyAlarmSettings() async {
    return DailyAlarmSettings.defaults();
  }

  @override
  Future<DailyAlarmSettings> updateDailyAlarmSettings({
    required bool enabled,
    required String time,
    required String timezone,
  }) async {
    return DailyAlarmSettings(enabled: enabled, time: time, timezone: timezone);
  }

  @override
  Future<DailyAlarmTemplate> fetchDailyAlarmTemplate({
    required String locale,
  }) async {
    return DailyAlarmTemplate.fallback(locale);
  }

  @override
  Future<CompatibilityHistoryItem> saveCompatibilityHistory({
    required CompatibilityHistoryItem item,
  }) async {
    return item;
  }

  @override
  Future<List<CompatibilityHistoryItem>> fetchCompatibilityHistory({
    int limit = 30,
  }) async {
    fetchCompatibilityHistoryCallCount += 1;
    if (fetchCompatibilityHistoryError != null) {
      throw fetchCompatibilityHistoryError!;
    }
    return compatibilityHistoryResult;
  }

  @override
  Future<CloudDailyCheckInResult> claimDailyCheckIn({String? requestId}) async {
    claimDailyCheckInCallCount += 1;
    return const CloudDailyCheckInResult(
      alreadyClaimed: true,
      rewardAwarded: 0,
      soulPoints: 0,
      currentStreak: 0,
      dailyEarnings: 0,
      lastCheckInAt: null,
    );
  }

  @override
  Future<CloudAdRewardStatusResult> getAdRewardStatus({
    String? placementCode,
  }) async {
    getAdRewardStatusCallCount += 1;
    return const CloudAdRewardStatusResult(
      placementCode: 'default_rewarded',
      rewardPerWatch: 5,
      dailyLimit: 50,
      todayEarned: 0,
      remaining: 50,
      canWatch: true,
      soulPoints: 0,
      lastRewardAt: null,
    );
  }

  @override
  Future<CloudAdRewardGrantResult> grantAdReward({
    required String requestId,
    required String placementCode,
    required int requestedAmount,
    String? adNetwork,
    Map<String, dynamic>? metadata,
  }) async {
    return const CloudAdRewardGrantResult(
      granted: true,
      idempotent: false,
      rewardAwarded: 5,
      rewardPerWatch: 5,
      dailyLimit: 50,
      todayEarned: 5,
      remaining: 45,
      soulPoints: 5,
    );
  }

  @override
  Future<CloudSpendSoulPointsResult> spendSoulPoints({
    required int amount,
    required String sourceType,
    String? requestId,
    Map<String, dynamic>? metadata,
  }) async {
    return const CloudSpendSoulPointsResult(
      applied: true,
      idempotent: false,
      insufficient: false,
      soulPoints: 0,
      required: 0,
      charged: 0,
    );
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
    deleteMyAccountCallCount += 1;
    if (deleteMyAccountError != null) {
      throw deleteMyAccountError!;
    }
    if (cloudSnapshotAfterDelete != null) {
      cloudSnapshot = cloudSnapshotAfterDelete!;
    }
  }

  @override
  Future<void> clearSession() async {
    clearSessionCallCount += 1;
  }
}

AppSessionSnapshot _snapshot({
  required String cloudUserId,
  required List<UserProfile> profiles,
  required String? currentProfileId,
  required List<CompatibilityHistoryItem> compatibilityHistory,
}) {
  return AppSessionSnapshot(
    isAuthenticated: true,
    authMode: SessionAuthMode.registered,
    pendingAnonymousBootstrap: false,
    cloudUserId: cloudUserId,
    userEmail: 'owner@numverse.app',
    userName: 'Owner',
    profiles: profiles,
    lifeBasedByProfileId: const <String, ProfileLifeBasedSnapshot>{},
    timeLifeByProfileId: const <String, ProfileTimeLifeSnapshot>{},
    currentProfileId: currentProfileId,
    soulPoints: 100,
    currentStreak: 0,
    dailyEarnings: 0,
    dailyAdEarnings: 0,
    dailyAdLimit: 50,
    dailyAngelNumber: null,
    dailyAngelRefreshAt: null,
    lastCheckInAt: null,
    lastAdRewardAt: null,
    compareProfiles: const <ComparisonProfile>[],
    selectedCompareProfileId: null,
    compatibilityHistory: compatibilityHistory,
  );
}

UserProfile _profile({required String id, required String name}) {
  return UserProfile(
    id: id,
    name: name,
    birthDate: DateTime(1990, 1, 1),
    createdAt: DateTime(2024, 1, 1),
  );
}

CompatibilityHistoryItem _historyItem({
  required String id,
  required String requestId,
  required String primaryProfileId,
  required DateTime createdAt,
}) {
  return CompatibilityHistoryItem(
    id: id,
    requestId: requestId,
    primaryProfileId: primaryProfileId,
    primaryName: 'Self',
    primaryBirthDate: DateTime(1990, 1, 1),
    primaryLifePath: 1,
    primarySoul: 2,
    primaryPersonality: 3,
    primaryExpression: 4,
    targetProfileId: 'target-$id',
    targetName: 'Target',
    targetRelation: 'friend',
    targetBirthDate: DateTime(1992, 2, 2),
    targetLifePath: 2,
    targetSoul: 3,
    targetPersonality: 4,
    targetExpression: 5,
    overallScore: 80,
    coreScore: 75,
    communicationScore: 82,
    soulScore: 79,
    personalityScore: 84,
    createdAt: createdAt,
  );
}
