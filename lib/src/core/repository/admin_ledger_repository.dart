import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:test/src/core/model/admin_ledger_content.dart';
import 'package:test/src/core/model/admin_ledger_release.dart';
import 'package:test/src/core/repository/interface/i_admin_ledger_repository.dart';
import 'package:test/src/utils/app_shared.dart';
import 'package:test/src/utils/app_supabase_config.dart';

class AdminLedgerRepository implements IAdminLedgerRepository {
  AdminLedgerRepository({
    required AppShared appShared,
    Dio? dio,
    AppSupabaseConfig? supabaseConfig,
  }) : _appShared = appShared,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 8),
               receiveTimeout: const Duration(seconds: 8),
             ),
           ),
       _supabaseConfig = supabaseConfig ?? const AppSupabaseConfig();

  final AppShared _appShared;
  final Dio _dio;
  final AppSupabaseConfig _supabaseConfig;

  @override
  bool get isConfigured => _supabaseConfig.isConfigured;

  @override
  bool get hasActiveSession {
    return (_appShared.getSupabaseAccessToken() ?? '').trim().isNotEmpty;
  }

  @override
  Future<void> login({required String email, required String password}) async {
    if (!isConfigured) {
      throw StateError('supabase_not_configured');
    }

    final String normalizedEmail = email.trim().toLowerCase();
    final Uri loginUri = Uri.parse(
      '${_supabaseConfig.resolvedBaseUrl}/auth/v1/token?grant_type=password',
    );
    final Response<dynamic> response = await _dio.postUri(
      loginUri,
      data: <String, dynamic>{'email': normalizedEmail, 'password': password},
      options: Options(
        headers: <String, String>{
          'apikey': _supabaseConfig.resolvedAnonKey,
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

    try {
      await getReleases();
    } catch (_) {
      await _appShared.clearSupabaseAuthSession();
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await _appShared.clearSupabaseAuthSession();
  }

  @override
  Future<List<AdminLedgerRelease>> getReleases({String? locale}) async {
    final Object? data = await _postRpc(
      functionName: 'admin_get_ledger_releases',
      payload: <String, dynamic>{'p_locale': locale},
      requiresAuth: true,
    );
    return _ensureJsonList(data)
        .map(AdminLedgerRelease.fromJson)
        .where((AdminLedgerRelease release) => release.id.isNotEmpty)
        .toList();
  }

  @override
  Future<List<AdminLedgerContent>> getContents({
    required String releaseId,
    String? contentType,
    String? search,
    int limit = 300,
    int offset = 0,
  }) async {
    final Object? data = await _postRpc(
      functionName: 'admin_get_ledger_contents',
      payload: <String, dynamic>{
        'p_release_id': releaseId,
        'p_content_type': contentType,
        'p_search': search,
        'p_limit': limit,
        'p_offset': offset,
      },
      requiresAuth: true,
    );
    return _ensureJsonList(data)
        .map(AdminLedgerContent.fromJson)
        .where((AdminLedgerContent content) => content.id.isNotEmpty)
        .toList();
  }

  @override
  Future<String> upsertContent({
    required String releaseId,
    required String contentType,
    required String numberKey,
    required Map<String, dynamic> payloadJsonb,
  }) async {
    final Object? data = await _postRpc(
      functionName: 'admin_upsert_ledger_content',
      payload: <String, dynamic>{
        'p_release_id': releaseId,
        'p_content_type': contentType,
        'p_number_key': numberKey,
        'p_payload_jsonb': payloadJsonb,
      },
      requiresAuth: true,
    );
    return _extractScalarString(data);
  }

  @override
  Future<String> createDraft({
    required String locale,
    required String version,
    String? notes,
    String? cloneFromReleaseId,
  }) async {
    final Object? data = await _postRpc(
      functionName: 'admin_create_ledger_release_draft',
      payload: <String, dynamic>{
        'p_locale': locale,
        'p_version': version,
        'p_notes': notes,
        'p_clone_from_release_id': cloneFromReleaseId,
      },
      requiresAuth: true,
    );
    return _extractScalarString(data);
  }

  @override
  Future<void> publishRelease({required String releaseId}) async {
    await _postRpc(
      functionName: 'admin_publish_ledger_release',
      payload: <String, dynamic>{'p_release_id': releaseId},
      requiresAuth: true,
    );
  }

  Future<Object?> _postRpc({
    required String functionName,
    required Map<String, dynamic> payload,
    required bool requiresAuth,
  }) async {
    if (!isConfigured) {
      throw StateError('supabase_not_configured');
    }
    final String? accessToken = requiresAuth
        ? (_appShared.getSupabaseAccessToken() ?? '').trim()
        : null;
    if (requiresAuth && (accessToken == null || accessToken.isEmpty)) {
      throw StateError('supabase_missing_access_token');
    }

    try {
      final Response<dynamic> response = await _dio.postUri(
        _supabaseConfig.rpcUri(functionName),
        data: payload,
        options: Options(
          headers: <String, String>{
            'apikey': _supabaseConfig.resolvedAnonKey,
            if (requiresAuth && accessToken != null)
              'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );
      return response.data;
    } on DioException catch (exception) {
      throw StateError(_resolveDioError(exception));
    }
  }

  List<Map<String, dynamic>> _ensureJsonList(Object? value) {
    if (value is List<dynamic>) {
      return value.whereType<Map<String, dynamic>>().toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      final Object? decoded = jsonDecode(value);
      if (decoded is List<dynamic>) {
        return decoded.whereType<Map<String, dynamic>>().toList();
      }
    }
    return <Map<String, dynamic>>[];
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

  String _extractScalarString(Object? value) {
    if (value is String) {
      return value.trim();
    }
    if (value is Map<String, dynamic>) {
      for (final Object? fieldValue in value.values) {
        if (fieldValue is String && fieldValue.trim().isNotEmpty) {
          return fieldValue.trim();
        }
      }
    }
    return '';
  }

  String _resolveDioError(DioException exception) {
    final Object? payload = exception.response?.data;
    if (payload is Map<String, dynamic>) {
      final String message = (payload['message'] as String? ?? '').trim();
      if (message.isNotEmpty) {
        return message;
      }
      final String error = (payload['error'] as String? ?? '').trim();
      if (error.isNotEmpty) {
        return error;
      }
      final String hint = (payload['hint'] as String? ?? '').trim();
      if (hint.isNotEmpty) {
        return hint;
      }
    }
    return exception.message ?? 'unknown_error';
  }
}
