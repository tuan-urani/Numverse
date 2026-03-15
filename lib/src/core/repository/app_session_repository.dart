import 'dart:convert';
import 'dart:developer' as developer;

import 'package:test/src/core/model/app_session_snapshot.dart';
import 'package:test/src/core/repository/interface/i_app_session_repository.dart';
import 'package:test/src/utils/app_shared.dart';

class LocalAppSessionRepository implements IAppSessionRepository {
  LocalAppSessionRepository(this._appShared);

  final AppShared _appShared;

  @override
  Future<AppSessionSnapshot> loadSnapshot() async {
    final String? raw = _appShared.getSessionSnapshot();
    if (raw == null || raw.isEmpty) {
      return AppSessionSnapshot.initial();
    }

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return AppSessionSnapshot.initial();
      }
      return AppSessionSnapshot.fromJson(decoded);
    } catch (_) {
      return AppSessionSnapshot.initial();
    }
  }

  @override
  Future<void> saveSnapshot(AppSessionSnapshot snapshot) async {
    await _appShared.setSessionSnapshot(jsonEncode(snapshot.toJson()));
    _logSnapshotChanged(snapshot);
  }

  @override
  Future<void> clear() async {
    await _appShared.clearSessionSnapshot();
  }

  void _logSnapshotChanged(AppSessionSnapshot snapshot) {
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    final String payload = encoder.convert(snapshot.toJson());
    developer.log(
      'SessionSnapshot changed:\n$payload',
      name: 'LocalAppSessionRepository',
    );
  }
}
