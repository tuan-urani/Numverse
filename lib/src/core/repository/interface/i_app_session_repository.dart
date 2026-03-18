import 'package:test/src/core/model/app_session_snapshot.dart';
import 'package:test/src/core/model/local_numai_guest_message.dart';

abstract class IAppSessionRepository {
  Future<AppSessionSnapshot> loadSnapshot();
  Future<void> saveSnapshot(AppSessionSnapshot snapshot);
  Future<List<LocalNumAiGuestMessage>> loadNumAiGuestMessages({
    required String userKey,
  });
  Future<void> saveNumAiGuestMessages({
    required String userKey,
    required List<LocalNumAiGuestMessage> messages,
  });
  Future<void> clearNumAiGuestMessages({required String userKey});
  Future<void> clear();
}
