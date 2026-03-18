import 'dart:convert';
import 'dart:developer' as developer;

import 'package:test/src/core/model/app_session_snapshot.dart';
import 'package:test/src/core/model/local_numai_guest_message.dart';
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
    await _appShared.clearAll();
  }

  @override
  Future<List<LocalNumAiGuestMessage>> loadNumAiGuestMessages({
    required String userKey,
  }) async {
    final String? raw = _appShared.getNumAiGuestHistory(userKey);
    if (raw == null || raw.isEmpty) {
      return const <LocalNumAiGuestMessage>[];
    }

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <LocalNumAiGuestMessage>[];
      }
      final List<LocalNumAiGuestMessage> messages = decoded
          .whereType<Map>()
          .map(
            (Map<dynamic, dynamic> item) => LocalNumAiGuestMessage.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return messages;
    } catch (_) {
      return const <LocalNumAiGuestMessage>[];
    }
  }

  @override
  Future<void> saveNumAiGuestMessages({
    required String userKey,
    required List<LocalNumAiGuestMessage> messages,
  }) async {
    final List<Map<String, dynamic>> payload = messages
        .map((LocalNumAiGuestMessage item) => item.toJson())
        .toList();
    await _appShared.setNumAiGuestHistory(
      userKey: userKey,
      value: jsonEncode(payload),
    );
  }

  @override
  Future<void> clearNumAiGuestMessages({required String userKey}) async {
    await _appShared.clearNumAiGuestHistory(userKey);
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
