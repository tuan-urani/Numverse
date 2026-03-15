import 'package:test/src/core/model/app_session_snapshot.dart';

abstract class IAppSessionRepository {
  Future<AppSessionSnapshot> loadSnapshot();
  Future<void> saveSnapshot(AppSessionSnapshot snapshot);
  Future<void> clear();
}
