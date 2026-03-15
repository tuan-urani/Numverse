import 'package:test/src/core/model/app_session_snapshot.dart';
import 'package:test/src/core/model/cloud_login_result.dart';

abstract class ICloudAccountRepository {
  bool get isConfigured;

  Future<CloudLoginResult> loginAndSyncFirstTime({
    required String email,
    required String password,
    required String displayName,
    required AppSessionSnapshot localSnapshot,
  });

  Future<AppSessionSnapshot> fetchCloudSessionSnapshot({
    required String fallbackEmail,
    required String fallbackDisplayName,
  });

  Future<void> clearSession();
}
