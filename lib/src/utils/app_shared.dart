import 'package:shared_preferences/shared_preferences.dart';

class AppShared {
  AppShared(this._prefs);

  static const String _keySessionSnapshot = 'numverse_session_snapshot';
  static const String _keyHasVisited = 'numverse_has_visited';
  static const String _keyLedgerActivePrefix = 'numverse_ledger_active_';
  static const String _keyLedgerTempPrefix = 'numverse_ledger_temp_';
  static const String _keySupabaseUserId = 'numverse_supabase_user_id';
  static const String _keySupabaseAccessToken =
      'numverse_supabase_access_token';
  static const String _keySupabaseRefreshToken =
      'numverse_supabase_refresh_token';

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

  String? getNumerologyLedgerActive(String localeCode) {
    return _prefs.getString(
      '$_keyLedgerActivePrefix${_normalizeLocaleCode(localeCode)}',
    );
  }

  Future<void> setNumerologyLedgerActive({
    required String localeCode,
    required String value,
  }) async {
    await _prefs.setString(
      '$_keyLedgerActivePrefix${_normalizeLocaleCode(localeCode)}',
      value,
    );
  }

  Future<void> setNumerologyLedgerTemp({
    required String localeCode,
    required String value,
  }) async {
    await _prefs.setString(
      '$_keyLedgerTempPrefix${_normalizeLocaleCode(localeCode)}',
      value,
    );
  }

  Future<void> activateNumerologyLedgerTemp(String localeCode) async {
    final String normalizedLocaleCode = _normalizeLocaleCode(localeCode);
    final String tempKey = '$_keyLedgerTempPrefix$normalizedLocaleCode';
    final String activeKey = '$_keyLedgerActivePrefix$normalizedLocaleCode';
    final String? rawValue = _prefs.getString(tempKey);
    if (rawValue == null || rawValue.isEmpty) {
      return;
    }

    await _prefs.setString(activeKey, rawValue);
    await _prefs.remove(tempKey);
  }

  Future<void> clearNumerologyLedgerTemp(String localeCode) async {
    await _prefs.remove(
      '$_keyLedgerTempPrefix${_normalizeLocaleCode(localeCode)}',
    );
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

  Future<void> clearAll() async {
    await _prefs.clear();
  }

  String _normalizeLocaleCode(String localeCode) {
    return localeCode.trim().toLowerCase();
  }
}
