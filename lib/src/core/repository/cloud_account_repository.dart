import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:test/src/core/model/app_session_snapshot.dart';
import 'package:test/src/core/model/cloud_login_result.dart';
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
    final Uri loginUri = Uri.parse(
      '${_supabaseConfig.resolvedBaseUrl}/auth/v1/token?grant_type=password',
    );
    final String anonKey = _supabaseConfig.resolvedAnonKey;

    final Response<dynamic> response = await _dio.postUri(
      loginUri,
      data: <String, dynamic>{'email': normalizedEmail, 'password': password},
      options: Options(
        headers: <String, String>{
          'apikey': anonKey,
          'Content-Type': 'application/json',
        },
      ),
    );

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
