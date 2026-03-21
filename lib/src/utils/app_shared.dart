import 'package:shared_preferences/shared_preferences.dart';

class AppShared {
  AppShared(this._prefs);

  static const String _keySessionSnapshot = 'numverse_session_snapshot';
  static const String _keyHasVisited = 'numverse_has_visited';
  static const String _keySupabaseUserId = 'numverse_supabase_user_id';
  static const String _keySupabaseAccessToken =
      'numverse_supabase_access_token';
  static const String _keySupabaseRefreshToken =
      'numverse_supabase_refresh_token';
  static const String _keyNumAiGuestHistoryPrefix =
      'numverse_numai_guest_history_';
  static const String _keyNumAiLastGuestUserKey =
      'numverse_numai_last_guest_user_key';
  static const String _keyDailyAlarmEnabled = 'numverse_daily_alarm_enabled';
  static const String _keyDailyAlarmTemplatePrefix =
      'numverse_daily_alarm_template_';

  final SharedPreferences _prefs;

  String? getSessionSnapshot() {
    return _prefs.getString(_keySessionSnapshot);
  }

  Future<void> setSessionSnapshot(String value) async {
    await _prefs.setString(_keySessionSnapshot, value);
  }

  Future<void> clearSessionSnapshot() async {
    await _prefs.remove(_keySessionSnapshot);
  }

  bool getHasVisited() {
    return _prefs.getBool(_keyHasVisited) ?? false;
  }

  Future<void> setHasVisited(bool value) async {
    await _prefs.setBool(_keyHasVisited, value);
  }

  Future<void> setSupabaseAuthSession({
    required String userId,
    required String accessToken,
    required String refreshToken,
  }) async {
    await _prefs.setString(_keySupabaseUserId, userId);
    await _prefs.setString(_keySupabaseAccessToken, accessToken);
    await _prefs.setString(_keySupabaseRefreshToken, refreshToken);
  }

  String? getSupabaseUserId() {
    return _prefs.getString(_keySupabaseUserId);
  }

  String? getSupabaseAccessToken() {
    return _prefs.getString(_keySupabaseAccessToken);
  }

  String? getSupabaseRefreshToken() {
    return _prefs.getString(_keySupabaseRefreshToken);
  }

  Future<void> clearSupabaseAuthSession() async {
    await _prefs.remove(_keySupabaseUserId);
    await _prefs.remove(_keySupabaseAccessToken);
    await _prefs.remove(_keySupabaseRefreshToken);
  }

  String? getNumAiGuestHistory(String userKey) {
    return _prefs.getString(_numAiGuestHistoryKey(userKey));
  }

  Future<void> setNumAiGuestHistory({
    required String userKey,
    required String value,
  }) async {
    await _prefs.setString(_numAiGuestHistoryKey(userKey), value);
  }

  Future<void> clearNumAiGuestHistory(String userKey) async {
    await _prefs.remove(_numAiGuestHistoryKey(userKey));
  }

  String? getNumAiLastGuestUserKey() {
    return _prefs.getString(_keyNumAiLastGuestUserKey);
  }

  Future<void> setNumAiLastGuestUserKey(String userKey) async {
    final String normalized = userKey.trim().toLowerCase();
    if (normalized.isEmpty) {
      await _prefs.remove(_keyNumAiLastGuestUserKey);
      return;
    }
    await _prefs.setString(_keyNumAiLastGuestUserKey, normalized);
  }

  Future<void> clearNumAiLastGuestUserKey() async {
    await _prefs.remove(_keyNumAiLastGuestUserKey);
  }

  bool getDailyAlarmEnabled() {
    return _prefs.getBool(_keyDailyAlarmEnabled) ?? true;
  }

  Future<void> setDailyAlarmEnabled(bool value) async {
    await _prefs.setBool(_keyDailyAlarmEnabled, value);
  }

  String? getDailyAlarmTemplate(String localeCode) {
    return _prefs.getString(_dailyAlarmTemplateKey(localeCode));
  }

  Future<void> setDailyAlarmTemplate({
    required String localeCode,
    required String value,
  }) async {
    await _prefs.setString(_dailyAlarmTemplateKey(localeCode), value);
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }

  String _numAiGuestHistoryKey(String userKey) {
    final String normalized = userKey.trim().toLowerCase();
    final String safeKey = normalized.isEmpty ? 'local' : normalized;
    return '$_keyNumAiGuestHistoryPrefix$safeKey';
  }

  String _dailyAlarmTemplateKey(String localeCode) {
    final String normalized = localeCode.trim().toLowerCase().replaceAll(
      '-',
      '_',
    );
    final String safeKey = normalized.isEmpty ? 'vi' : normalized;
    return '$_keyDailyAlarmTemplatePrefix$safeKey';
  }
}
