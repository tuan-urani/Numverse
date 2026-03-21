import 'package:dio/dio.dart';
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
import 'package:test/src/core/model/compatibility_history_item.dart';
import 'package:test/src/core/model/daily_alarm_settings.dart';
import 'package:test/src/core/model/daily_alarm_template.dart';
import 'package:test/src/core/model/local_numai_guest_message.dart';
import 'package:test/src/core/repository/interface/i_app_session_repository.dart';
import 'package:test/src/core/repository/interface/i_cloud_account_repository.dart';
import 'package:test/src/ui/numai_chat/interactor/numai_chat_bloc.dart';
import 'package:test/src/ui/numai_chat/interactor/numai_chat_state.dart';

class _FakeCloudAccountRepository implements ICloudAccountRepository {
  _FakeCloudAccountRepository({this.configured = true});

  bool configured;
  String? currentUserIdValue = 'u1';

  CloudNumAiSendMessageResult? guestSendResult;
  Object? guestSendError;
  CloudNumAiSendMessageResult? profileSendResult;
  Object? profileSendError;
  CloudNumAiThreadMessagesResult fetchThreadMessagesResult =
      const CloudNumAiThreadMessagesResult(
        threadId: '',
        messages: <CloudNumAiThreadMessage>[],
      );
  Object? fetchThreadMessagesError;
  final List<Object> fetchThreadMessagesErrorQueue = <Object>[];
  int fetchThreadMessagesCallCount = 0;
  Object? importGuestHistoryError;
  int importGuestHistoryCallCount = 0;
  int ensureAnonymousSessionCallCount = 0;

  @override
  bool get isConfigured => configured;

  @override
  String? get currentUserId => currentUserIdValue;

  @override
  Future<void> ensureAnonymousSession() async {
    ensureAnonymousSessionCallCount += 1;
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
    if (profileSendError != null) {
      throw profileSendError!;
    }
    if (profileSendResult == null) {
      throw StateError('missing_profile_send_result');
    }
    return profileSendResult!;
  }

  @override
  Future<CloudNumAiSendMessageResult> sendNumAiGuestMessage({
    required String messageText,
    String? locale,
    List<Map<String, String>> recentMessages = const <Map<String, String>>[],
  }) async {
    if (guestSendError != null) {
      throw guestSendError!;
    }
    if (guestSendResult == null) {
      throw StateError('missing_guest_send_result');
    }
    return guestSendResult!;
  }

  @override
  Future<CloudNumAiThreadMessagesResult> fetchNumAiThreadMessages({
    required String profileId,
    String? threadId,
    int limit = 50,
  }) async {
    fetchThreadMessagesCallCount += 1;
    if (fetchThreadMessagesErrorQueue.isNotEmpty) {
      throw fetchThreadMessagesErrorQueue.removeAt(0);
    }
    if (fetchThreadMessagesError != null) {
      throw fetchThreadMessagesError!;
    }
    return fetchThreadMessagesResult;
  }

  @override
  Future<CloudNumAiImportGuestHistoryResult> importGuestNumAiHistory({
    required String profileId,
    required List<LocalNumAiGuestMessage> messages,
    String? requestId,
  }) async {
    importGuestHistoryCallCount += 1;
    if (importGuestHistoryError != null) {
      throw importGuestHistoryError!;
    }
    return const CloudNumAiImportGuestHistoryResult(
      threadId: 'thread-1',
      importedCount: 1,
      skippedCount: 0,
    );
  }

  @override
  Future<void> clearSession() async {
    throw UnimplementedError();
  }
}

class _FakeAppSessionRepository implements IAppSessionRepository {
  final Map<String, List<LocalNumAiGuestMessage>> guestMessagesByUserKey =
      <String, List<LocalNumAiGuestMessage>>{};
  int saveGuestMessagesCallCount = 0;
  int clearGuestMessagesCallCount = 0;
  String? lastClearedUserKey;
  String? lastGuestUserKey;

  @override
  Future<AppSessionSnapshot> loadSnapshot() async {
    throw UnimplementedError();
  }

  @override
  Future<void> saveSnapshot(AppSessionSnapshot snapshot) async {
    throw UnimplementedError();
  }

  @override
  Future<List<LocalNumAiGuestMessage>> loadNumAiGuestMessages({
    required String userKey,
  }) async {
    return List<LocalNumAiGuestMessage>.from(
      guestMessagesByUserKey[userKey] ?? const <LocalNumAiGuestMessage>[],
    );
  }

  @override
  Future<void> saveNumAiGuestMessages({
    required String userKey,
    required List<LocalNumAiGuestMessage> messages,
  }) async {
    saveGuestMessagesCallCount += 1;
    guestMessagesByUserKey[userKey] = List<LocalNumAiGuestMessage>.from(
      messages,
    );
  }

  @override
  Future<void> clearNumAiGuestMessages({required String userKey}) async {
    clearGuestMessagesCallCount += 1;
    lastClearedUserKey = userKey;
    guestMessagesByUserKey.remove(userKey);
  }

  @override
  Future<String?> loadLastNumAiGuestUserKey() async {
    return lastGuestUserKey;
  }

  @override
  Future<void> saveLastNumAiGuestUserKey({required String userKey}) async {
    lastGuestUserKey = userKey;
  }

  @override
  Future<void> clearLastNumAiGuestUserKey() async {
    lastGuestUserKey = null;
  }

  @override
  Future<void> clear() async {
    throw UnimplementedError();
  }
}

Future<void> _loadHistoryAndWait({
  required NumAiChatBloc bloc,
  required bool hasCloudSession,
  required bool isAnonymousUser,
  required String? profileId,
  required String? cloudUserId,
}) async {
  final Future<NumAiChatState> done = bloc.stream.firstWhere(
    (NumAiChatState state) => !state.isLoading,
  );
  bloc.loadCloudHistory(
    hasCloudSession: hasCloudSession,
    isAnonymousUser: isAnonymousUser,
    profileId: profileId,
    cloudUserId: cloudUserId,
    forceRefresh: true,
  );
  await done;
}

CloudNumAiSendMessageResult _buildSendResult({
  required String assistantText,
  String threadId = 'thread-1',
  int walletBalance = 10,
}) {
  return CloudNumAiSendMessageResult(
    threadId: threadId,
    assistantText: assistantText,
    suggestions: const <String>['next'],
    chargedSoulPoints: 3,
    walletBalance: walletBalance,
    fallbackReason: null,
    requiresProfileInfo: false,
  );
}

DioException _offlineDioError() {
  return DioException(
    requestOptions: RequestOptions(path: '/numai'),
    type: DioExceptionType.connectionError,
  );
}

Future<bool> _deductShouldNotBeCalled(int _) async {
  fail('deductSoulPoints must not be called in cloud chat path');
}

Future<void> _syncNoop(int _) async {}

void main() {
  group('NumAiChatBloc cloud-only send flow', () {
    test(
      'guest send success appends user+assistant and persists local',
      () async {
        final _FakeCloudAccountRepository cloudRepository =
            _FakeCloudAccountRepository()
              ..guestSendResult = _buildSendResult(
                assistantText: 'assistant reply',
                walletBalance: 17,
              );
        final _FakeAppSessionRepository appSessionRepository =
            _FakeAppSessionRepository();
        final NumAiChatBloc bloc = NumAiChatBloc(
          cloudAccountRepository: cloudRepository,
          appSessionRepository: appSessionRepository,
        );

        int? syncedSoulPoints;
        final bool sent = await bloc.sendMessage(
          rawMessage: 'hello',
          hasProfile: false,
          hasCloudSession: true,
          isAnonymousUser: true,
          profileId: null,
          cloudUserId: 'u1',
          locale: 'vi',
          deductSoulPoints: _deductShouldNotBeCalled,
          syncSoulPoints: (int value) async {
            syncedSoulPoints = value;
          },
        );

        expect(sent, isTrue);
        expect(bloc.state.messages.length, 2);
        expect(bloc.state.messages.first.role, NumAiChatMessageRole.user);
        expect(bloc.state.messages.first.content, 'hello');
        expect(bloc.state.messages.last.role, NumAiChatMessageRole.assistant);
        expect(bloc.state.messages.last.content, 'assistant reply');
        expect(appSessionRepository.saveGuestMessagesCallCount, 2);
        expect(appSessionRepository.lastGuestUserKey, 'u1');
        expect(syncedSoulPoints, 17);

        await bloc.close();
      },
    );

    test(
      'completeTypingMessage clears typingMessageId when messageId matches',
      () async {
        final _FakeCloudAccountRepository cloudRepository =
            _FakeCloudAccountRepository()
              ..guestSendResult = _buildSendResult(
                assistantText: 'assistant reply',
              );
        final _FakeAppSessionRepository appSessionRepository =
            _FakeAppSessionRepository();
        final NumAiChatBloc bloc = NumAiChatBloc(
          cloudAccountRepository: cloudRepository,
          appSessionRepository: appSessionRepository,
        );

        final bool sent = await bloc.sendMessage(
          rawMessage: 'hello',
          hasProfile: false,
          hasCloudSession: true,
          isAnonymousUser: true,
          profileId: null,
          cloudUserId: 'u1',
          locale: 'vi',
          deductSoulPoints: _deductShouldNotBeCalled,
          syncSoulPoints: _syncNoop,
        );

        expect(sent, isTrue);
        final String typingMessageId = bloc.state.typingMessageId ?? '';
        expect(typingMessageId, isNotEmpty);

        final Future<NumAiChatState> clearedState = bloc.stream.firstWhere(
          (NumAiChatState state) => state.typingMessageId == null,
        );
        bloc.completeTypingMessage(typingMessageId);
        await clearedState;

        expect(bloc.state.typingMessageId, isNull);

        await bloc.close();
      },
    );

    test(
      'completeTypingMessage keeps state when messageId does not match',
      () async {
        final _FakeCloudAccountRepository cloudRepository =
            _FakeCloudAccountRepository()
              ..guestSendResult = _buildSendResult(
                assistantText: 'assistant reply',
              );
        final _FakeAppSessionRepository appSessionRepository =
            _FakeAppSessionRepository();
        final NumAiChatBloc bloc = NumAiChatBloc(
          cloudAccountRepository: cloudRepository,
          appSessionRepository: appSessionRepository,
        );

        final bool sent = await bloc.sendMessage(
          rawMessage: 'hello',
          hasProfile: false,
          hasCloudSession: true,
          isAnonymousUser: true,
          profileId: null,
          cloudUserId: 'u1',
          locale: 'vi',
          deductSoulPoints: _deductShouldNotBeCalled,
          syncSoulPoints: _syncNoop,
        );

        expect(sent, isTrue);
        final String typingMessageId = bloc.state.typingMessageId ?? '';
        expect(typingMessageId, isNotEmpty);

        bloc.completeTypingMessage('non-matching-id');
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state.typingMessageId, typingMessageId);

        await bloc.close();
      },
    );

    test(
      'completeTypingMessage is idempotent when called multiple times',
      () async {
        final _FakeCloudAccountRepository cloudRepository =
            _FakeCloudAccountRepository()
              ..guestSendResult = _buildSendResult(
                assistantText: 'assistant reply',
              );
        final _FakeAppSessionRepository appSessionRepository =
            _FakeAppSessionRepository();
        final NumAiChatBloc bloc = NumAiChatBloc(
          cloudAccountRepository: cloudRepository,
          appSessionRepository: appSessionRepository,
        );

        final bool sent = await bloc.sendMessage(
          rawMessage: 'hello',
          hasProfile: false,
          hasCloudSession: true,
          isAnonymousUser: true,
          profileId: null,
          cloudUserId: 'u1',
          locale: 'vi',
          deductSoulPoints: _deductShouldNotBeCalled,
          syncSoulPoints: _syncNoop,
        );

        expect(sent, isTrue);
        final String typingMessageId = bloc.state.typingMessageId ?? '';
        expect(typingMessageId, isNotEmpty);

        final Future<NumAiChatState> clearedState = bloc.stream.firstWhere(
          (NumAiChatState state) => state.typingMessageId == null,
        );
        bloc.completeTypingMessage(typingMessageId);
        await clearedState;
        expect(bloc.state.typingMessageId, isNull);

        bloc.completeTypingMessage(typingMessageId);
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.typingMessageId, isNull);

        await bloc.close();
      },
    );

    test('guest send offline error rolls back and returns false', () async {
      final DateTime seededAt = DateTime.now().subtract(
        const Duration(minutes: 2),
      );
      final _FakeCloudAccountRepository cloudRepository =
          _FakeCloudAccountRepository()..guestSendError = _offlineDioError();
      final _FakeAppSessionRepository appSessionRepository =
          _FakeAppSessionRepository()
            ..guestMessagesByUserKey['u1'] = <LocalNumAiGuestMessage>[
              LocalNumAiGuestMessage(
                id: 'guest-1',
                senderType: 'assistant',
                messageText: 'old assistant',
                createdAt: seededAt,
                followUpSuggestions: const <String>[],
                requiresProfileInfo: false,
              ),
            ];
      final NumAiChatBloc bloc = NumAiChatBloc(
        cloudAccountRepository: cloudRepository,
        appSessionRepository: appSessionRepository,
      );

      await _loadHistoryAndWait(
        bloc: bloc,
        hasCloudSession: true,
        isAnonymousUser: true,
        profileId: null,
        cloudUserId: 'u1',
      );
      final List<NumAiChatMessage> previousMessages =
          List<NumAiChatMessage>.from(bloc.state.messages);

      final bool sent = await bloc.sendMessage(
        rawMessage: 'new message',
        hasProfile: false,
        hasCloudSession: true,
        isAnonymousUser: true,
        profileId: null,
        cloudUserId: 'u1',
        locale: 'vi',
        deductSoulPoints: _deductShouldNotBeCalled,
        syncSoulPoints: _syncNoop,
      );

      expect(sent, isFalse);
      expect(bloc.state.messages, previousMessages);
      expect(appSessionRepository.saveGuestMessagesCallCount, 0);

      await bloc.close();
    });

    test('profile send offline error rolls back and returns false', () async {
      final DateTime seededAt = DateTime.now().subtract(
        const Duration(minutes: 3),
      );
      final _FakeCloudAccountRepository cloudRepository =
          _FakeCloudAccountRepository()
            ..profileSendError = _offlineDioError()
            ..fetchThreadMessagesResult = CloudNumAiThreadMessagesResult(
              threadId: 'thread-9',
              messages: <CloudNumAiThreadMessage>[
                CloudNumAiThreadMessage(
                  id: 'cloud-1',
                  senderType: 'assistant',
                  messageText: 'profile old message',
                  createdAt: seededAt,
                  followUpSuggestions: const <String>[],
                  fallbackReason: null,
                  requiresProfileInfo: false,
                ),
              ],
            );
      final _FakeAppSessionRepository appSessionRepository =
          _FakeAppSessionRepository();
      final NumAiChatBloc bloc = NumAiChatBloc(
        cloudAccountRepository: cloudRepository,
        appSessionRepository: appSessionRepository,
      );

      await _loadHistoryAndWait(
        bloc: bloc,
        hasCloudSession: true,
        isAnonymousUser: false,
        profileId: 'profile-1',
        cloudUserId: 'u1',
      );
      final List<NumAiChatMessage> previousMessages =
          List<NumAiChatMessage>.from(bloc.state.messages);

      final bool sent = await bloc.sendMessage(
        rawMessage: 'ask profile',
        hasProfile: true,
        hasCloudSession: true,
        isAnonymousUser: false,
        profileId: 'profile-1',
        cloudUserId: 'u1',
        locale: 'vi',
        deductSoulPoints: _deductShouldNotBeCalled,
        syncSoulPoints: _syncNoop,
      );

      expect(sent, isFalse);
      expect(bloc.state.messages, previousMessages);
      expect(bloc.state.activeProfileId, 'profile-1');

      await bloc.close();
    });

    test(
      'guest send with insufficient points keeps warning and returns false',
      () async {
        final _FakeCloudAccountRepository cloudRepository =
            _FakeCloudAccountRepository()
              ..guestSendError = StateError('insufficient_soul_points');
        final _FakeAppSessionRepository appSessionRepository =
            _FakeAppSessionRepository();
        final NumAiChatBloc bloc = NumAiChatBloc(
          cloudAccountRepository: cloudRepository,
          appSessionRepository: appSessionRepository,
        );

        final bool sent = await bloc.sendMessage(
          rawMessage: 'ask',
          hasProfile: false,
          hasCloudSession: true,
          isAnonymousUser: true,
          profileId: null,
          cloudUserId: 'u1',
          locale: 'vi',
          deductSoulPoints: _deductShouldNotBeCalled,
          syncSoulPoints: _syncNoop,
        );

        expect(sent, isFalse);
        expect(bloc.state.messages, isEmpty);
        expect(bloc.state.showInsufficientPointsWarning, isTrue);

        await bloc.close();
      },
    );

    test('migrate guest history success imports then clears local', () async {
      final DateTime guestAt = DateTime.now().subtract(const Duration(days: 1));
      final _FakeCloudAccountRepository cloudRepository =
          _FakeCloudAccountRepository();
      final _FakeAppSessionRepository appSessionRepository =
          _FakeAppSessionRepository()
            ..guestMessagesByUserKey['u1'] = <LocalNumAiGuestMessage>[
              LocalNumAiGuestMessage(
                id: 'guest-local-1',
                senderType: 'user',
                messageText: 'guest pending',
                createdAt: guestAt,
                followUpSuggestions: const <String>[],
                requiresProfileInfo: false,
              ),
            ];
      final NumAiChatBloc bloc = NumAiChatBloc(
        cloudAccountRepository: cloudRepository,
        appSessionRepository: appSessionRepository,
      );

      await _loadHistoryAndWait(
        bloc: bloc,
        hasCloudSession: true,
        isAnonymousUser: true,
        profileId: 'profile-1',
        cloudUserId: 'u1',
      );

      expect(cloudRepository.importGuestHistoryCallCount, 1);
      expect(
        appSessionRepository.clearGuestMessagesCallCount,
        greaterThanOrEqualTo(2),
      );
      expect(appSessionRepository.guestMessagesByUserKey['u1'], isNull);
      expect(appSessionRepository.guestMessagesByUserKey['local'], isNull);

      await bloc.close();
    });

    test('migrate guest history fail keeps local for next retry', () async {
      final DateTime guestAt = DateTime.now().subtract(const Duration(days: 1));
      final _FakeCloudAccountRepository cloudRepository =
          _FakeCloudAccountRepository()
            ..importGuestHistoryError = StateError('import_failed');
      final _FakeAppSessionRepository appSessionRepository =
          _FakeAppSessionRepository()
            ..guestMessagesByUserKey['u1'] = <LocalNumAiGuestMessage>[
              LocalNumAiGuestMessage(
                id: 'guest-local-2',
                senderType: 'assistant',
                messageText: 'guest pending answer',
                createdAt: guestAt,
                followUpSuggestions: const <String>[],
                requiresProfileInfo: false,
              ),
            ];
      final NumAiChatBloc bloc = NumAiChatBloc(
        cloudAccountRepository: cloudRepository,
        appSessionRepository: appSessionRepository,
      );

      await _loadHistoryAndWait(
        bloc: bloc,
        hasCloudSession: true,
        isAnonymousUser: true,
        profileId: 'profile-1',
        cloudUserId: 'u1',
      );

      expect(cloudRepository.importGuestHistoryCallCount, 1);
      expect(appSessionRepository.clearGuestMessagesCallCount, 0);
      expect(appSessionRepository.guestMessagesByUserKey['u1'], isNotEmpty);

      await bloc.close();
    });

    test(
      'returns false and blocks send when cloud is not configured',
      () async {
        final _FakeCloudAccountRepository cloudRepository =
            _FakeCloudAccountRepository(configured: false);
        final _FakeAppSessionRepository appSessionRepository =
            _FakeAppSessionRepository();
        final NumAiChatBloc bloc = NumAiChatBloc(
          cloudAccountRepository: cloudRepository,
          appSessionRepository: appSessionRepository,
        );

        bool deductCalled = false;
        final bool sent = await bloc.sendMessage(
          rawMessage: 'blocked',
          hasProfile: false,
          hasCloudSession: true,
          isAnonymousUser: true,
          profileId: null,
          cloudUserId: 'u1',
          locale: 'vi',
          deductSoulPoints: (int _) async {
            deductCalled = true;
            return true;
          },
          syncSoulPoints: _syncNoop,
        );

        expect(sent, isFalse);
        expect(deductCalled, isFalse);
        expect(bloc.state.messages, isEmpty);
        expect(appSessionRepository.saveGuestMessagesCallCount, 0);

        await bloc.close();
      },
    );

    test('guest history merges canonical local + last guest key', () async {
      final DateTime now = DateTime.now();
      final _FakeCloudAccountRepository cloudRepository =
          _FakeCloudAccountRepository();
      final _FakeAppSessionRepository appSessionRepository =
          _FakeAppSessionRepository()
            ..lastGuestUserKey = 'old-key'
            ..guestMessagesByUserKey['local'] = <LocalNumAiGuestMessage>[
              LocalNumAiGuestMessage(
                id: 'm-local',
                senderType: 'user',
                messageText: 'from local',
                createdAt: now.subtract(const Duration(minutes: 2)),
                followUpSuggestions: const <String>[],
                requiresProfileInfo: false,
              ),
            ]
            ..guestMessagesByUserKey['old-key'] = <LocalNumAiGuestMessage>[
              LocalNumAiGuestMessage(
                id: 'm-old',
                senderType: 'assistant',
                messageText: 'from old key',
                createdAt: now.subtract(const Duration(minutes: 1)),
                followUpSuggestions: const <String>[],
                requiresProfileInfo: false,
              ),
            ];
      final NumAiChatBloc bloc = NumAiChatBloc(
        cloudAccountRepository: cloudRepository,
        appSessionRepository: appSessionRepository,
      );

      await _loadHistoryAndWait(
        bloc: bloc,
        hasCloudSession: true,
        isAnonymousUser: true,
        profileId: null,
        cloudUserId: 'new-key',
      );

      expect(bloc.state.messages.length, 2);
      expect(bloc.state.messages.first.content, 'from local');
      expect(bloc.state.messages.last.content, 'from old key');

      await bloc.close();
    });

    test(
      'profile history keeps local fallback when cloud fetch fails',
      () async {
        final DateTime now = DateTime.now();
        final _FakeCloudAccountRepository cloudRepository =
            _FakeCloudAccountRepository()
              ..fetchThreadMessagesError = StateError('network_error');
        final _FakeAppSessionRepository appSessionRepository =
            _FakeAppSessionRepository()
              ..guestMessagesByUserKey['local'] = <LocalNumAiGuestMessage>[
                LocalNumAiGuestMessage(
                  id: 'fallback-1',
                  senderType: 'assistant',
                  messageText: 'fallback local message',
                  createdAt: now.subtract(const Duration(minutes: 1)),
                  followUpSuggestions: const <String>[],
                  requiresProfileInfo: false,
                ),
              ];
        final NumAiChatBloc bloc = NumAiChatBloc(
          cloudAccountRepository: cloudRepository,
          appSessionRepository: appSessionRepository,
        );

        await _loadHistoryAndWait(
          bloc: bloc,
          hasCloudSession: true,
          isAnonymousUser: true,
          profileId: 'profile-1',
          cloudUserId: 'u1',
        );

        expect(bloc.state.messages, isNotEmpty);
        expect(bloc.state.messages.first.content, 'fallback local message');

        await bloc.close();
      },
    );

    test(
      'anonymous profile history retries after unauthorized with ensureAnonymousSession',
      () async {
        final DateTime now = DateTime.now();
        final _FakeCloudAccountRepository cloudRepository =
            _FakeCloudAccountRepository()
              ..fetchThreadMessagesErrorQueue.add(StateError('unauthorized'))
              ..fetchThreadMessagesResult = CloudNumAiThreadMessagesResult(
                threadId: 'thread-ok',
                messages: <CloudNumAiThreadMessage>[
                  CloudNumAiThreadMessage(
                    id: 'cloud-ok',
                    senderType: 'assistant',
                    messageText: 'cloud recovered',
                    createdAt: now,
                    followUpSuggestions: const <String>[],
                    fallbackReason: null,
                    requiresProfileInfo: false,
                  ),
                ],
              );
        final _FakeAppSessionRepository appSessionRepository =
            _FakeAppSessionRepository();
        final NumAiChatBloc bloc = NumAiChatBloc(
          cloudAccountRepository: cloudRepository,
          appSessionRepository: appSessionRepository,
        );

        await _loadHistoryAndWait(
          bloc: bloc,
          hasCloudSession: true,
          isAnonymousUser: true,
          profileId: 'profile-1',
          cloudUserId: 'u1',
        );

        expect(cloudRepository.ensureAnonymousSessionCallCount, 1);
        expect(cloudRepository.fetchThreadMessagesCallCount, 2);
        expect(bloc.state.messages.last.content, 'cloud recovered');

        await bloc.close();
      },
    );

    test(
      'profile to profile transition clears A history when B fetch fails',
      () async {
        final DateTime now = DateTime.now();
        final _FakeCloudAccountRepository cloudRepository =
            _FakeCloudAccountRepository()
              ..fetchThreadMessagesResult = CloudNumAiThreadMessagesResult(
                threadId: 'thread-a',
                messages: <CloudNumAiThreadMessage>[
                  CloudNumAiThreadMessage(
                    id: 'a-1',
                    senderType: 'assistant',
                    messageText: 'history of profile A',
                    createdAt: now.subtract(const Duration(minutes: 1)),
                    followUpSuggestions: const <String>[],
                    fallbackReason: null,
                    requiresProfileInfo: false,
                  ),
                ],
              );
        final _FakeAppSessionRepository appSessionRepository =
            _FakeAppSessionRepository();
        final NumAiChatBloc bloc = NumAiChatBloc(
          cloudAccountRepository: cloudRepository,
          appSessionRepository: appSessionRepository,
        );

        await _loadHistoryAndWait(
          bloc: bloc,
          hasCloudSession: true,
          isAnonymousUser: false,
          profileId: 'profile-a',
          cloudUserId: 'u1',
        );
        expect(bloc.state.messages.length, 1);
        expect(bloc.state.messages.first.content, 'history of profile A');

        cloudRepository.fetchThreadMessagesError = StateError('network_error');
        await _loadHistoryAndWait(
          bloc: bloc,
          hasCloudSession: true,
          isAnonymousUser: false,
          profileId: 'profile-b',
          cloudUserId: 'u1',
        );

        expect(bloc.state.activeProfileId, 'profile-b');
        expect(bloc.state.messages, isEmpty);

        await bloc.close();
      },
    );
  });
}
