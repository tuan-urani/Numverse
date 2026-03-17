import 'package:test/src/core/model/app_session_snapshot.dart';
import 'package:test/src/core/model/cloud_ad_reward_grant_result.dart';
import 'package:test/src/core/model/cloud_ad_reward_status_result.dart';
import 'package:test/src/core/model/compatibility_history_item.dart';
import 'package:test/src/core/model/cloud_daily_checkin_result.dart';
import 'package:test/src/core/model/cloud_login_result.dart';
import 'package:test/src/core/model/cloud_spend_soul_points_result.dart';

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

  Future<void> clearSession();
}
