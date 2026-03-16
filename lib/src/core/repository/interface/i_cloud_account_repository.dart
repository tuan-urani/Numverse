import 'package:test/src/core/model/app_session_snapshot.dart';
import 'package:test/src/core/model/cloud_daily_checkin_result.dart';
import 'package:test/src/core/model/cloud_login_result.dart';
import 'package:test/src/core/model/cloud_spend_soul_points_result.dart';

abstract class ICloudAccountRepository {
  bool get isConfigured;

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

  Future<CloudDailyCheckInResult> claimDailyCheckIn({String? requestId});

  Future<CloudSpendSoulPointsResult> spendSoulPoints({
    required int amount,
    required String sourceType,
    String? requestId,
    Map<String, dynamic>? metadata,
  });

  Future<void> clearSession();
}
