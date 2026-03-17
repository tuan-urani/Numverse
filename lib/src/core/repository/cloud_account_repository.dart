import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:test/src/core/model/app_session_snapshot.dart';
import 'package:test/src/core/model/cloud_daily_checkin_result.dart';
import 'package:test/src/core/model/cloud_login_result.dart';
import 'package:test/src/core/model/cloud_spend_soul_points_result.dart';
import 'package:test/src/core/repository/interface/i_cloud_account_repository.dart';
import 'package:test/src/utils/app_shared.dart';
import 'package:test/src/utils/app_supabase_config.dart';

class CloudAccountRepository implements ICloudAccountRepository {
  CloudAccountRepository({
    required AppShared appShared,
    Dio? dio,
    AppSupabaseConfig? supabaseConfig,
  }) : _appShared = appShared,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 6),
               receiveTimeout: const Duration(seconds: 6),
             ),
           ),
       _supabaseConfig = supabaseConfig ?? const AppSupabaseConfig();

  final AppShared _appShared;
  final Dio _dio;
  final AppSupabaseConfig _supabaseConfig;

  @override
  bool get isConfigured => _supabaseConfig.isConfigured;

  @override
  String? get currentUserId => _appShared.getSupabaseUserId();

  @override
  Future<void> ensureAnonymousSession() async {
    if (!isConfigured) {
      throw StateError('supabase_not_configured');
    }

    final bool hasValidSession = await _hasValidSession();
    if (hasValidSession) {
      return;
    }

    final String anonKey = _supabaseConfig.resolvedAnonKey;
    final Response<dynamic> response = await _dio.postUri(
      _signUpUri,
      data: <String, dynamic>{
        'data': <String, dynamic>{'auth_mode': 'anonymous'},
      },
      options: Options(
        headers: <String, String>{
          'apikey': anonKey,
          'Content-Type': 'application/json',
        },
      ),
    );
    await _saveSessionFromAuthPayload(response.data);
  }

  @override
  Future<bool> refreshAccessTokenIfNeeded() async {
    return _refreshSession();
  }

  @override
  Future<void> signInExistingAccount({
    required String email,
    required String password,
  }) async {
    if (!isConfigured) {
      throw StateError('supabase_not_configured');
    }
    final String normalizedEmail = email.trim().toLowerCase();
    final String anonKey = _supabaseConfig.resolvedAnonKey;
    final Response<dynamic> response = await _signIn(
      loginUri: _loginUri,
      anonKey: anonKey,
      email: normalizedEmail,
      password: password,
    );
    await _saveSessionFromAuthPayload(response.data);
  }

  @override
  Future<void> upgradeAnonymousToEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (!isConfigured) {
      throw StateError('supabase_not_configured');
    }
    await _ensureAuthenticatedRequest((String accessToken) {
      return _dio.putUri(
        _userUri,
        data: <String, dynamic>{
          'email': email.trim().toLowerCase(),
          'password': password,
          'data': <String, dynamic>{
            'display_name': displayName,
            'name': displayName,
          },
        },
        options: Options(headers: _authHeaders(accessToken: accessToken)),
      );
    });
  }

  @override
  Future<CloudLoginResult> loginAndSyncFirstTime({
    required String email,
    required String password,
    required String displayName,
    required AppSessionSnapshot localSnapshot,
  }) async {
    if (!isConfigured) {
      throw StateError('supabase_not_configured');
    }
    final String normalizedEmail = email.trim().toLowerCase();
    final Uri loginUri = _loginUri;
    final String anonKey = _supabaseConfig.resolvedAnonKey;
    final Response<dynamic> response = await _signIn(
      loginUri: loginUri,
      anonKey: anonKey,
      email: normalizedEmail,
      password: password,
    );
    return _completeAuthAndSync(
      response: response,
      normalizedEmail: normalizedEmail,
      displayName: displayName,
      localSnapshot: localSnapshot,
    );
  }

  @override
  Future<CloudLoginResult> registerAndSyncFirstTime({
    required String email,
    required String password,
    required String displayName,
    required AppSessionSnapshot localSnapshot,
  }) async {
    if (!isConfigured) {
      throw StateError('supabase_not_configured');
    }
    final String normalizedEmail = email.trim().toLowerCase();
    final String anonKey = _supabaseConfig.resolvedAnonKey;
    await _signUp(
      anonKey: anonKey,
      email: normalizedEmail,
      password: password,
      displayName: displayName,
    );
    final Response<dynamic> response = await _signIn(
      loginUri: _loginUri,
      anonKey: anonKey,
      email: normalizedEmail,
      password: password,
    );
    return _completeAuthAndSync(
      response: response,
      normalizedEmail: normalizedEmail,
      displayName: displayName,
      localSnapshot: localSnapshot,
    );
  }

  Future<CloudLoginResult> _completeAuthAndSync({
    required Response<dynamic> response,
    required String normalizedEmail,
    required String displayName,
    required AppSessionSnapshot localSnapshot,
  }) async {
    final ({String accessToken, String refreshToken, String userId}) session =
        _extractSession(response.data);
    await _appShared.setSupabaseAuthSession(
      userId: session.userId,
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );

    final bool firstSyncPerformed = await _syncLocalSnapshotBootstrap(
      accessToken: session.accessToken,
      fallbackDisplayName: displayName,
      localSnapshot: localSnapshot.copyWith(
        userEmail: normalizedEmail,
        userName: displayName,
      ),
    );

    return CloudLoginResult(
      userId: session.userId,
      email: normalizedEmail,
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      firstSyncPerformed: firstSyncPerformed,
    );
  }

  Uri get _loginUri => Uri.parse(
    '${_supabaseConfig.resolvedBaseUrl}/auth/v1/token?grant_type=password',
  );

  Uri get _signUpUri =>
      Uri.parse('${_supabaseConfig.resolvedBaseUrl}/auth/v1/signup');

  Uri get _userUri =>
      Uri.parse('${_supabaseConfig.resolvedBaseUrl}/auth/v1/user');

  Future<Response<dynamic>> _signIn({
    required Uri loginUri,
    required String anonKey,
    required String email,
    required String password,
  }) {
    return _dio.postUri(
      loginUri,
      data: <String, dynamic>{'email': email, 'password': password},
      options: Options(
        headers: <String, String>{
          'apikey': anonKey,
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  Future<void> _signUp({
    required String anonKey,
    required String email,
    required String password,
    required String displayName,
  }) async {
    await _dio.postUri(
      _signUpUri,
      data: <String, dynamic>{
        'email': email,
        'password': password,
        'data': <String, dynamic>{
          'display_name': displayName,
          'name': displayName,
        },
      },
      options: Options(
        headers: <String, String>{
          'apikey': anonKey,
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  Future<bool> _syncLocalSnapshotBootstrap({
    required String accessToken,
    required String fallbackDisplayName,
    required AppSessionSnapshot localSnapshot,
  }) async {
    final Uri rpcUri = _supabaseConfig.rpcUri('sync_local_session_bootstrap');
    final Map<String, dynamic> snapshotPayload = localSnapshot.toJson();
    snapshotPayload['userName'] = (localSnapshot.userName ?? '').trim().isEmpty
        ? fallbackDisplayName
        : localSnapshot.userName;

    final Response<dynamic> response = await _ensureAuthenticatedRequest((
      String token,
    ) {
      return _dio.postUri(
        rpcUri,
        data: <String, dynamic>{'p_payload': snapshotPayload},
        options: Options(headers: _authHeaders(accessToken: token)),
      );
    }, initialAccessToken: accessToken);
    final Map<String, dynamic> result = _ensureJsonMap(response.data);
    return result['already_synced'] != true;
  }

  @override
  Future<AppSessionSnapshot> fetchCloudSessionSnapshot({
    required String fallbackEmail,
    required String fallbackDisplayName,
  }) async {
    if (!isConfigured) {
      throw StateError('supabase_not_configured');
    }
    final String accessToken = _requireAccessToken();
    final Uri rpcUri = _supabaseConfig.rpcUri('get_cloud_session_snapshot');
    final Response<dynamic> response = await _ensureAuthenticatedRequest((
      String token,
    ) {
      return _dio.postUri(
        rpcUri,
        data: const <String, dynamic>{},
        options: Options(headers: _authHeaders(accessToken: token)),
      );
    }, initialAccessToken: accessToken);

    final Map<String, dynamic> payload = _ensureJsonMap(response.data);
    if (payload.isEmpty) {
      throw StateError('supabase_invalid_cloud_snapshot');
    }

    final String normalizedFallbackEmail = fallbackEmail.trim().toLowerCase();
    final String normalizedFallbackName = fallbackDisplayName.trim();
    final AppSessionSnapshot snapshot = AppSessionSnapshot.fromJson(payload);
    final String resolvedEmail = (snapshot.userEmail ?? '').trim().isNotEmpty
        ? snapshot.userEmail!.trim().toLowerCase()
        : normalizedFallbackEmail;
    final String resolvedName = (snapshot.userName ?? '').trim().isNotEmpty
        ? snapshot.userName!.trim()
        : normalizedFallbackName;
    final String resolvedCloudUserId =
        (snapshot.cloudUserId ?? currentUserId ?? '').trim();

    return snapshot.copyWith(
      isAuthenticated: true,
      authMode: snapshot.authMode,
      pendingAnonymousBootstrap: false,
      cloudUserId: resolvedCloudUserId.isEmpty ? null : resolvedCloudUserId,
      userEmail: resolvedEmail.isEmpty ? null : resolvedEmail,
      userName: resolvedName.isEmpty ? null : resolvedName,
    );
  }

  @override
  Future<void> syncSessionSnapshot({
    required AppSessionSnapshot snapshot,
  }) async {
    if (!isConfigured) {
      throw StateError('supabase_not_configured');
    }
    final String accessToken = _requireAccessToken();
    final String? userName = snapshot.userName;
    final String fallbackName = (snapshot.userEmail ?? '').split('@').first;
    final String resolvedName = (userName ?? '').trim().isNotEmpty
        ? userName!.trim()
        : fallbackName.trim();
    final List<Map<String, dynamic>> profilePayload = snapshot.profiles.map((
      profile,
    ) {
      return <String, dynamic>{
        'id': profile.id,
        'name': profile.name,
        'birthDate': profile.birthDate.toIso8601String(),
      };
    }).toList();
    final Map<String, dynamic> payload = <String, dynamic>{
      'userName': resolvedName,
      'userEmail': snapshot.userEmail,
      'currentProfileId': snapshot.currentProfileId,
      'profiles': profilePayload,
    };

    final Uri rpcUri = _supabaseConfig.rpcUri('sync_local_session_snapshot');
    await _ensureAuthenticatedRequest((String token) {
      return _dio.postUri(
        rpcUri,
        data: <String, dynamic>{'p_payload': payload},
        options: Options(headers: _authHeaders(accessToken: token)),
      );
    }, initialAccessToken: accessToken);
  }

  @override
  Future<CloudDailyCheckInResult> claimDailyCheckIn({String? requestId}) async {
    if (!isConfigured) {
      throw StateError('supabase_not_configured');
    }
    final String accessToken = _requireAccessToken();

    final Uri rpcUri = _supabaseConfig.rpcUri('claim_daily_checkin');
    final String cleanedRequestId = (requestId ?? '').trim();
    final Response<dynamic> response = await _ensureAuthenticatedRequest((
      String token,
    ) {
      return _dio.postUri(
        rpcUri,
        data: <String, dynamic>{
          if (cleanedRequestId.isNotEmpty) 'p_request_id': cleanedRequestId,
        },
        options: Options(headers: _authHeaders(accessToken: token)),
      );
    }, initialAccessToken: accessToken);
    final Map<String, dynamic> payload = _ensureJsonMap(response.data);
    if (payload.isEmpty) {
      throw StateError('supabase_invalid_checkin_response');
    }
    return CloudDailyCheckInResult.fromJson(payload);
  }

  @override
  Future<CloudSpendSoulPointsResult> spendSoulPoints({
    required int amount,
    required String sourceType,
    String? requestId,
    Map<String, dynamic>? metadata,
  }) async {
    if (!isConfigured) {
      throw StateError('supabase_not_configured');
    }
    final String accessToken = _requireAccessToken();
    final String cleanRequestId = (requestId ?? '').trim();
    final Map<String, dynamic> cleanMetadata = Map<String, dynamic>.from(
      metadata ?? const <String, dynamic>{},
    );

    final Uri rpcUri = _supabaseConfig.rpcUri('spend_soul_points');
    final Response<dynamic> response = await _ensureAuthenticatedRequest((
      String token,
    ) {
      return _dio.postUri(
        rpcUri,
        data: <String, dynamic>{
          'p_amount': amount,
          'p_source_type': sourceType,
          if (cleanRequestId.isNotEmpty) 'p_request_id': cleanRequestId,
          if (cleanMetadata.isNotEmpty) 'p_metadata': cleanMetadata,
        },
        options: Options(headers: _authHeaders(accessToken: token)),
      );
    }, initialAccessToken: accessToken);
    final Map<String, dynamic> payload = _ensureJsonMap(response.data);
    if (payload.isEmpty) {
      throw StateError('supabase_invalid_spend_response');
    }
    return CloudSpendSoulPointsResult.fromJson(payload);
  }

  @override
  Future<void> clearSession() async {
    await _appShared.clearSupabaseAuthSession();
  }

  Uri get _refreshUri => Uri.parse(
    '${_supabaseConfig.resolvedBaseUrl}/auth/v1/token?grant_type=refresh_token',
  );

  String _requireAccessToken() {
    final String accessToken = (_appShared.getSupabaseAccessToken() ?? '')
        .trim();
    if (accessToken.isEmpty) {
      throw StateError('supabase_missing_access_token');
    }
    return accessToken;
  }

  Map<String, String> _authHeaders({required String accessToken}) {
    return <String, String>{
      'apikey': _supabaseConfig.resolvedAnonKey,
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };
  }

  Future<Response<dynamic>> _ensureAuthenticatedRequest(
    Future<Response<dynamic>> Function(String accessToken) request, {
    String? initialAccessToken,
  }) async {
    final String token =
        (initialAccessToken ?? _appShared.getSupabaseAccessToken() ?? '')
            .trim();
    if (token.isEmpty) {
      throw StateError('supabase_missing_access_token');
    }
    try {
      return await request(token);
    } on DioException catch (error) {
      if (!_isUnauthorized(error)) {
        rethrow;
      }
      final bool refreshed = await _refreshSession();
      if (!refreshed) {
        rethrow;
      }
      final String retryToken = _requireAccessToken();
      return request(retryToken);
    }
  }

  bool _isUnauthorized(DioException error) {
    return error.response?.statusCode == 401;
  }

  Future<bool> _refreshSession() async {
    final String refreshToken = (_appShared.getSupabaseRefreshToken() ?? '')
        .trim();
    if (refreshToken.isEmpty) {
      return false;
    }
    try {
      final Response<dynamic> response = await _dio.postUri(
        _refreshUri,
        data: <String, dynamic>{'refresh_token': refreshToken},
        options: Options(
          headers: <String, String>{
            'apikey': _supabaseConfig.resolvedAnonKey,
            'Content-Type': 'application/json',
          },
        ),
      );
      await _saveSessionFromAuthPayload(response.data);
      return true;
    } catch (_) {
      await _appShared.clearSupabaseAuthSession();
      return false;
    }
  }

  Future<Map<String, dynamic>> _fetchCurrentUserMap() async {
    final String accessToken = _requireAccessToken();
    final Response<dynamic> response = await _ensureAuthenticatedRequest((
      String token,
    ) {
      return _dio.getUri(
        _userUri,
        options: Options(headers: _authHeaders(accessToken: token)),
      );
    }, initialAccessToken: accessToken);
    return _ensureJsonMap(response.data);
  }

  Future<bool> _hasValidSession() async {
    final String accessToken = (_appShared.getSupabaseAccessToken() ?? '')
        .trim();
    if (accessToken.isEmpty) {
      return await _refreshSession();
    }
    try {
      final Map<String, dynamic> user = await _fetchCurrentUserMap();
      return (user['id'] as String?)?.trim().isNotEmpty == true;
    } catch (_) {
      return await _refreshSession();
    }
  }

  Future<void> _saveSessionFromAuthPayload(Object? data) async {
    final ({String accessToken, String refreshToken, String userId}) session =
        _extractSession(data);
    await _appShared.setSupabaseAuthSession(
      userId: session.userId,
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
  }

  ({String accessToken, String refreshToken, String userId}) _extractSession(
    Object? payloadRaw,
  ) {
    final Map<String, dynamic> payload = _ensureJsonMap(payloadRaw);
    final String accessToken = (payload['access_token'] as String? ?? '')
        .trim();
    final String refreshToken = (payload['refresh_token'] as String? ?? '')
        .trim();
    final Map<String, dynamic> user = _ensureJsonMap(payload['user']);
    final String userId = (user['id'] as String? ?? '').trim();
    if (accessToken.isEmpty || refreshToken.isEmpty || userId.isEmpty) {
      throw StateError('supabase_invalid_login_response');
    }
    return (
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
    );
  }

  Map<String, dynamic> _ensureJsonMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is String && value.trim().isNotEmpty) {
      final Object? decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }
    return <String, dynamic>{};
  }
}
