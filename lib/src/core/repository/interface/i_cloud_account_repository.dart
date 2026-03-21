import 'package:test/src/core/model/app_session_snapshot.dart';
import 'package:test/src/core/model/cloud_ad_reward_grant_result.dart';
import 'package:test/src/core/model/cloud_ad_reward_status_result.dart';
import 'package:test/src/core/model/compatibility_history_item.dart';
import 'package:test/src/core/model/cloud_daily_checkin_result.dart';
import 'package:test/src/core/model/cloud_login_result.dart';
import 'package:test/src/core/model/cloud_numai_import_guest_history_result.dart';
import 'package:test/src/core/model/cloud_numai_send_message_result.dart';
import 'package:test/src/core/model/cloud_numai_thread_messages_result.dart';
import 'package:test/src/core/model/cloud_spend_soul_points_result.dart';
import 'package:test/src/core/model/daily_alarm_settings.dart';
import 'package:test/src/core/model/daily_alarm_template.dart';
import 'package:test/src/core/model/local_numai_guest_message.dart';

abstract class ICloudAccountRepository {
  bool get isConfigured;
  String? get currentUserId;

  Future<void> ensureAnonymousSession();

  Future<bool> refreshAccessTokenIfNeeded();

  Future<void> upgradeAnonymousToEmail({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> signInExistingAccount({
    required String email,
    required String password,
  });

  Future<CloudLoginResult> loginAndSyncFirstTime({
    required String email,
    required String password,
    required String displayName,
    required AppSessionSnapshot localSnapshot,
  });

  Future<CloudLoginResult> registerAndSyncFirstTime({
    required String email,
    required String password,
    required String displayName,
    required AppSessionSnapshot localSnapshot,
  });

  Future<AppSessionSnapshot> fetchCloudSessionSnapshot({
    required String fallbackEmail,
    required String fallbackDisplayName,
  });

  Future<void> syncSessionSnapshot({required AppSessionSnapshot snapshot});

  Future<DailyAlarmSettings> fetchDailyAlarmSettings();

  Future<DailyAlarmSettings> updateDailyAlarmSettings({
    required bool enabled,
    required String time,
    required String timezone,
  });

  Future<DailyAlarmTemplate> fetchDailyAlarmTemplate({required String locale});

  Future<CompatibilityHistoryItem> saveCompatibilityHistory({
    required CompatibilityHistoryItem item,
  });

  Future<List<CompatibilityHistoryItem>> fetchCompatibilityHistory({
    int limit = 30,
  });

  Future<CloudDailyCheckInResult> claimDailyCheckIn({String? requestId});

  Future<CloudAdRewardStatusResult> getAdRewardStatus({String? placementCode});

  Future<CloudAdRewardGrantResult> grantAdReward({
    required String requestId,
    required String placementCode,
    required int requestedAmount,
    String? adNetwork,
    Map<String, dynamic>? metadata,
  });

  Future<CloudSpendSoulPointsResult> spendSoulPoints({
    required int amount,
    required String sourceType,
    String? requestId,
    Map<String, dynamic>? metadata,
  });

  Future<CloudNumAiSendMessageResult> sendNumAiMessage({
    required String profileId,
    required String messageText,
    String? threadId,
    String? locale,
  });

  Future<CloudNumAiSendMessageResult> sendNumAiGuestMessage({
    required String messageText,
    String? locale,
    List<Map<String, String>> recentMessages = const <Map<String, String>>[],
  });

  Future<CloudNumAiThreadMessagesResult> fetchNumAiThreadMessages({
    required String profileId,
    String? threadId,
    int limit = 50,
  });

  Future<CloudNumAiImportGuestHistoryResult> importGuestNumAiHistory({
    required String profileId,
    required List<LocalNumAiGuestMessage> messages,
    String? requestId,
  });

  Future<void> clearSession();
}
