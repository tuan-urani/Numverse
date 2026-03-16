import 'package:test/src/core/model/admin_ledger_content.dart';
import 'package:test/src/core/model/admin_ledger_release.dart';

abstract class IAdminLedgerRepository {
  bool get isConfigured;
  bool get hasActiveSession;

  Future<void> login({required String email, required String password});

  Future<void> logout();

  Future<List<AdminLedgerRelease>> getReleases({String? locale});

  Future<List<AdminLedgerContent>> getContents({
    required String releaseId,
    String? contentType,
    String? search,
    int limit = 300,
    int offset = 0,
  });

  Future<String> upsertContent({
    required String releaseId,
    required String contentType,
    required String numberKey,
    required Map<String, dynamic> payloadJsonb,
  });

  Future<String> createDraft({
    required String locale,
    required String version,
    String? notes,
    String? cloneFromReleaseId,
  });

  Future<void> publishRelease({required String releaseId});
}
