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
    final Map<String, dynamic> payload = _ensureJsonMap(response.data);
    final String accessToken = (payload['access_token'] as String? ?? '')
        .trim();
    final String refreshToken = (payload['refresh_token'] as String? ?? '')
        .trim();
    final Map<String, dynamic> user = _ensureJsonMap(payload['user']);
    final String userId = (user['id'] as String? ?? '').trim();
    if (accessToken.isEmpty || userId.isEmpty) {
      throw StateError('supabase_invalid_login_response');
    }

    await _appShared.setSupabaseAuthSession(
      userId: userId,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    final bool firstSyncPerformed = await _syncLocalSnapshotBootstrap(
      accessToken: accessToken,
      fallbackDisplayName: displayName,
      localSnapshot: localSnapshot.copyWith(
        userEmail: normalizedEmail,
        userName: displayName,
      ),
    );

    return CloudLoginResult(
      userId: userId,
      email: normalizedEmail,
      accessToken: accessToken,
      refreshToken: refreshToken,
      firstSyncPerformed: firstSyncPerformed,
    );
  }

  Uri get _loginUri => Uri.parse(
    '${_supabaseConfig.resolvedBaseUrl}/auth/v1/token?grant_type=password',
  );

  Uri get _signUpUri =>
      Uri.parse('${_supabaseConfig.resolvedBaseUrl}/auth/v1/signup');

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
    final String anonKey = _supabaseConfig.resolvedAnonKey;
    final Uri rpcUri = _supabaseConfig.rpcUri('sync_local_session_bootstrap');
    final Map<String, dynamic> snapshotPayload = localSnapshot.toJson();
    snapshotPayload['userName'] = (localSnapshot.userName ?? '').trim().isEmpty
        ? fallbackDisplayName
        : localSnapshot.userName;

    final Response<dynamic> response = await _dio.postUri(
      rpcUri,
      data: <String, dynamic>{'p_payload': snapshotPayload},
      options: Options(
        headers: <String, String>{
          'apikey': anonKey,
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      ),
    );
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
    final String accessToken = (_appShared.getSupabaseAccessToken() ?? '')
        .trim();
    if (accessToken.isEmpty) {
      throw StateError('supabase_missing_access_token');
    }
    final Uri rpcUri = _supabaseConfig.rpcUri('get_cloud_session_snapshot');
    final Response<dynamic> response = await _dio.postUri(
      rpcUri,
      data: const <String, dynamic>{},
      options: Options(
        headers: <String, String>{
          'apikey': _supabaseConfig.resolvedAnonKey,
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      ),
    );

    final Map<String, dynamic> payload = _ensureJsonMap(response.data);
    if (payload.isEmpty) {
      throw StateError('supabase_invalid_cloud_snapshot');
    }

    final String normalizedFallbackEmail = fallbackEmail.trim().toLowerCase();
    final String normalizedFallbackName = fallbackDisplayName.trim();
    final AppSessionSnapshot snapshot = AppSessionSnapshot.fromJson(payload);
    final String resolvedEmail = (snapshot.userEmail ?? '').trim().isEmpty
        ? normalizedFallbackEmail
        : snapshot.userEmail!.trim().toLowerCase();
    final String resolvedName = (snapshot.userName ?? '').trim().isEmpty
        ? normalizedFallbackName
        : snapshot.userName!.trim();

    return snapshot.copyWith(
      isAuthenticated: true,
      userEmail: resolvedEmail,
      userName: resolvedName,
    );
  }

  @override
  Future<void> syncSessionSnapshot({
    required AppSessionSnapshot snapshot,
  }) async {
    if (!isConfigured) {
      throw StateError('supabase_not_configured');
    }
    final String accessToken = (_appShared.getSupabaseAccessToken() ?? '')
        .trim();
    if (accessToken.isEmpty) {
      throw StateError('supabase_missing_access_token');
    }
    final Map<String, dynamic> payload = snapshot.toJson();
    final String? userName = snapshot.userName;
    final String fallbackName = (snapshot.userEmail ?? '').split('@').first;
    final String resolvedName = (userName ?? '').trim().isNotEmpty
        ? userName!.trim()
        : fallbackName.trim();
    payload['userName'] = resolvedName;

    final Uri rpcUri = _supabaseConfig.rpcUri('sync_local_session_snapshot');
    await _dio.postUri(
      rpcUri,
      data: <String, dynamic>{'p_payload': payload},
      options: Options(
        headers: <String, String>{
          'apikey': _supabaseConfig.resolvedAnonKey,
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  @override
  Future<CloudDailyCheckInResult> claimDailyCheckIn({String? requestId}) async {
    if (!isConfigured) {
      throw StateError('supabase_not_configured');
    }
    final String accessToken = (_appShared.getSupabaseAccessToken() ?? '')
        .trim();
    if (accessToken.isEmpty) {
      throw StateError('supabase_missing_access_token');
    }

    final Uri rpcUri = _supabaseConfig.rpcUri('claim_daily_checkin');
    final String cleanedRequestId = (requestId ?? '').trim();
    final Response<dynamic> response = await _dio.postUri(
      rpcUri,
      data: <String, dynamic>{
        if (cleanedRequestId.isNotEmpty) 'p_request_id': cleanedRequestId,
      },
      options: Options(
        headers: <String, String>{
          'apikey': _supabaseConfig.resolvedAnonKey,
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      ),
    );
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
    final String accessToken = (_appShared.getSupabaseAccessToken() ?? '')
        .trim();
    if (accessToken.isEmpty) {
      throw StateError('supabase_missing_access_token');
    }
    final String cleanRequestId = (requestId ?? '').trim();
    final Map<String, dynamic> cleanMetadata = Map<String, dynamic>.from(
      metadata ?? const <String, dynamic>{},
    );

    final Uri rpcUri = _supabaseConfig.rpcUri('spend_soul_points');
    final Response<dynamic> response = await _dio.postUri(
      rpcUri,
      data: <String, dynamic>{
        'p_amount': amount,
        'p_source_type': sourceType,
        if (cleanRequestId.isNotEmpty) 'p_request_id': cleanRequestId,
        if (cleanMetadata.isNotEmpty) 'p_metadata': cleanMetadata,
      },
      options: Options(
        headers: <String, String>{
          'apikey': _supabaseConfig.resolvedAnonKey,
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      ),
    );
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
