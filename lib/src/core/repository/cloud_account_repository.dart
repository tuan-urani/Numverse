import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:test/src/core/model/app_session_snapshot.dart';
import 'package:test/src/core/model/cloud_ad_reward_grant_result.dart';
import 'package:test/src/core/model/cloud_ad_reward_status_result.dart';
import 'package:test/src/core/model/compatibility_history_item.dart';
import 'package:test/src/core/model/cloud_daily_checkin_result.dart';
import 'package:test/src/core/model/cloud_login_result.dart';
import 'package:test/src/core/model/cloud_numai_import_guest_history_result.dart';
import 'package:test/src/core/model/cloud_numai_send_message_result.dart';
import 'package:test/src/core/model/cloud_numai_thread_messages_result.dart';
import 'package:test/src/core/model/cloud_spend_soul_points_result.dart';
import 'package:test/src/core/model/local_numai_guest_message.dart';
import 'package:test/src/core/model/profile_life_based_snapshot.dart';
import 'package:test/src/core/model/user_profile.dart';
import 'package:test/src/core/repository/interface/i_cloud_account_repository.dart';
import 'package:test/src/helper/numerology_helper.dart';
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
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 10),
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

    final List<Map<String, dynamic>> snapshotPayloads =
        _buildNumAiSnapshotPayloads(snapshot);
    if (snapshotPayloads.isEmpty) {
      return;
    }

    final Uri functionUri = _supabaseConfig.edgeFunctionUri(
      'numverse-api',
      queryParameters: const <String, String>{'action': 'sync-numai-snapshots'},
    );

    try {
      await _ensureAuthenticatedRequest((String token) {
        return _dio.postUri(
          functionUri,
          data: <String, dynamic>{'snapshots': snapshotPayloads},
          options: Options(
            headers: _authHeaders(accessToken: token),
            receiveTimeout: const Duration(seconds: 30),
          ),
        );
      }, initialAccessToken: accessToken);
    } on DioException catch (error) {
      final Map<String, dynamic> errorPayload = _ensureJsonMap(
        error.response?.data,
      );
      final String serverErrorCode = (errorPayload['error'] as String? ?? '')
          .trim();
      if (serverErrorCode.isNotEmpty) {
        throw StateError(serverErrorCode);
      }
      rethrow;
    }
  }

  List<Map<String, dynamic>> _buildNumAiSnapshotPayloads(
    AppSessionSnapshot snapshot,
  ) {
    final List<Map<String, dynamic>> payloads = <Map<String, dynamic>>[];
    final DateTime calculatedAt = DateTime.now().toUtc();

    for (final UserProfile profile in snapshot.profiles) {
      final String cleanProfileId = profile.id.trim();
      final String cleanName = profile.name.trim();
      if (cleanProfileId.isEmpty || cleanName.isEmpty) {
        continue;
      }

      final ProfileLifeBasedSnapshot? lifeBasedSnapshot =
          snapshot.lifeBasedByProfileId[cleanProfileId];
      final int lifePathNumber =
          lifeBasedSnapshot?.valueOf(ProfileLifeBasedSnapshot.lifePathMetric) ??
          NumerologyHelper.getLifePathNumber(profile.birthDate);
      final int expressionNumber =
          lifeBasedSnapshot?.valueOf(
            ProfileLifeBasedSnapshot.expressionMetric,
          ) ??
          NumerologyHelper.getExpressionNumber(cleanName);
      final int soulUrgeNumber =
          lifeBasedSnapshot?.valueOf(ProfileLifeBasedSnapshot.soulUrgeMetric) ??
          NumerologyHelper.getSoulUrgeNumber(cleanName);
      final int personalityNumber =
          lifeBasedSnapshot?.valueOf(
            ProfileLifeBasedSnapshot.personalityMetric,
          ) ??
          NumerologyHelper.getPersonalityNumber(cleanName);
      final int missionNumber =
          lifeBasedSnapshot?.valueOf(ProfileLifeBasedSnapshot.missionMetric) ??
          NumerologyHelper.getMissionNumber(profile.birthDate, cleanName);

      final birthChart = NumerologyHelper.calculateBirthChart(
        profile.birthDate,
      );
      final birthAxes = NumerologyHelper.analyzeBirthChartAxes(birthChart);
      final birthArrows = NumerologyHelper.analyzeBirthChartArrows(birthChart);
      final dominantNumbers = NumerologyHelper.getDominantNumbers(birthChart);
      final int currentAge = NumerologyHelper.calculateAge(profile.birthDate);
      final pinnacles = NumerologyHelper.calculatePinnacles(
        profile.birthDate,
        currentAge,
      );
      final challenges = NumerologyHelper.calculateChallenges(
        profile.birthDate,
        currentAge,
      );

      payloads.add(<String, dynamic>{
        'primary_profile_id': cleanProfileId,
        'engine_version': 'mobile_local_v1',
        'calculated_at': calculatedAt.toIso8601String(),
        'raw_input': <String, dynamic>{
          'profile_id': cleanProfileId,
          'display_name': cleanName,
          'full_name_for_reading': cleanName,
          'birth_date': _formatDateOnly(profile.birthDate),
          'source': 'mobile_local_sync',
        },
        'core_numbers': <String, dynamic>{
          'life_path_number': lifePathNumber,
          'expression_number': expressionNumber,
          'soul_urge_number': soulUrgeNumber,
          'personality_number': personalityNumber,
          'mission_number': missionNumber,
        },
        'birth_matrix': <String, dynamic>{
          'numbers': _intMapToStringKeyMap(birthChart.numbers),
          'present_numbers': birthChart.presentNumbers,
          'missing_numbers': birthChart.missingNumbers,
        },
        'matrix_aspects': <String, dynamic>{
          'axes': <String, dynamic>{
            'physical': _toAxisPayload(
              present: birthAxes.physical.present,
              numbers: birthAxes.physical.numbers,
              count: birthAxes.physical.count,
            ),
            'mental': _toAxisPayload(
              present: birthAxes.mental.present,
              numbers: birthAxes.mental.numbers,
              count: birthAxes.mental.count,
            ),
            'emotional': _toAxisPayload(
              present: birthAxes.emotional.present,
              numbers: birthAxes.emotional.numbers,
              count: birthAxes.emotional.count,
            ),
          },
          'arrows': <String, dynamic>{
            'determination': _toArrowPayload(
              present: birthArrows.determination.present,
              numbers: birthArrows.determination.numbers,
            ),
            'planning': _toArrowPayload(
              present: birthArrows.planning.present,
              numbers: birthArrows.planning.numbers,
            ),
            'willpower': _toArrowPayload(
              present: birthArrows.willpower.present,
              numbers: birthArrows.willpower.numbers,
            ),
            'activity': _toArrowPayload(
              present: birthArrows.activity.present,
              numbers: birthArrows.activity.numbers,
            ),
            'sensitivity': _toArrowPayload(
              present: birthArrows.sensitivity.present,
              numbers: birthArrows.sensitivity.numbers,
            ),
            'frustration': _toArrowPayload(
              present: birthArrows.frustration.present,
              numbers: birthArrows.frustration.numbers,
            ),
            'success': _toArrowPayload(
              present: birthArrows.success.present,
              numbers: birthArrows.success.numbers,
            ),
            'spirituality': _toArrowPayload(
              present: birthArrows.spirituality.present,
              numbers: birthArrows.spirituality.numbers,
            ),
          },
          'dominant_numbers': dominantNumbers.map((item) {
            return <String, dynamic>{
              'number': item.number,
              'count': item.count,
            };
          }).toList(),
        },
        'life_cycles': <String, dynamic>{
          'current_age': currentAge,
          'pinnacles': pinnacles.map((item) {
            return <String, dynamic>{
              'number': item.number,
              'start_age': item.startAge,
              'end_age': item.endAge,
              'period': item.period,
              'status': item.status.name,
            };
          }).toList(),
          'challenges': challenges.map((item) {
            return <String, dynamic>{
              'number': item.number,
              'start_age': item.startAge,
              'end_age': item.endAge,
              'period': item.period,
              'status': item.status.name,
            };
          }).toList(),
        },
      });
    }

    return payloads;
  }

  Map<String, dynamic> _toAxisPayload({
    required bool present,
    required List<int> numbers,
    required int count,
  }) {
    return <String, dynamic>{
      'present': present,
      'numbers': numbers,
      'count': count,
    };
  }

  Map<String, dynamic> _toArrowPayload({
    required bool present,
    required List<int> numbers,
  }) {
    return <String, dynamic>{'present': present, 'numbers': numbers};
  }

  Map<String, int> _intMapToStringKeyMap(Map<int, int> map) {
    return <String, int>{
      for (final MapEntry<int, int> entry in map.entries)
        entry.key.toString(): entry.value,
    };
  }

  String _formatDateOnly(DateTime value) {
    final String year = value.year.toString().padLeft(4, '0');
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  Future<CompatibilityHistoryItem> saveCompatibilityHistory({
    required CompatibilityHistoryItem item,
  }) async {
    if (!isConfigured) {
      throw StateError('supabase_not_configured');
    }
    final String accessToken = _requireAccessToken();
    final Uri rpcUri = _supabaseConfig.rpcUri('save_compatibility_history');
    final Response<dynamic> response = await _ensureAuthenticatedRequest((
      String token,
    ) {
      return _dio.postUri(
        rpcUri,
        data: <String, dynamic>{
          'p_payload': item.toJson(),
          if (item.requestId.trim().isNotEmpty) 'p_request_id': item.requestId,
        },
        options: Options(headers: _authHeaders(accessToken: token)),
      );
    }, initialAccessToken: accessToken);
    final Map<String, dynamic> payload = _ensureJsonMap(response.data);
    if (payload.isEmpty) {
      throw StateError('supabase_invalid_compatibility_history_response');
    }
    return CompatibilityHistoryItem.fromJson(payload);
  }

  @override
  Future<List<CompatibilityHistoryItem>> fetchCompatibilityHistory({
    int limit = 30,
  }) async {
    if (!isConfigured) {
      throw StateError('supabase_not_configured');
    }
    final String accessToken = _requireAccessToken();
    final Uri rpcUri = _supabaseConfig.rpcUri('get_compatibility_history');
    final int sanitizedLimit = limit.clamp(1, 100);
    final Response<dynamic> response = await _ensureAuthenticatedRequest((
      String token,
    ) {
      return _dio.postUri(
        rpcUri,
        data: <String, dynamic>{'p_limit': sanitizedLimit},
        options: Options(headers: _authHeaders(accessToken: token)),
      );
    }, initialAccessToken: accessToken);

    final List<Map<String, dynamic>> list = _ensureJsonList(response.data);
    return list.map(CompatibilityHistoryItem.fromJson).toList();
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
  Future<CloudAdRewardStatusResult> getAdRewardStatus({
    String? placementCode,
  }) async {
    if (!isConfigured) {
      throw StateError('supabase_not_configured');
    }
    final String accessToken = _requireAccessToken();
    final String cleanPlacementCode = (placementCode ?? '').trim();
    final Uri rpcUri = _supabaseConfig.rpcUri('get_ad_reward_status');
    final Response<dynamic> response = await _ensureAuthenticatedRequest((
      String token,
    ) {
      return _dio.postUri(
        rpcUri,
        data: <String, dynamic>{
          if (cleanPlacementCode.isNotEmpty)
            'p_placement_code': cleanPlacementCode,
        },
        options: Options(headers: _authHeaders(accessToken: token)),
      );
    }, initialAccessToken: accessToken);
    final Map<String, dynamic> payload = _ensureJsonMap(response.data);
    if (payload.isEmpty) {
      throw StateError('supabase_invalid_ad_reward_status_response');
    }
    return CloudAdRewardStatusResult.fromJson(payload);
  }

  @override
  Future<CloudAdRewardGrantResult> grantAdReward({
    required String requestId,
    required String placementCode,
    required int requestedAmount,
    String? adNetwork,
    Map<String, dynamic>? metadata,
  }) async {
    if (!isConfigured) {
      throw StateError('supabase_not_configured');
    }
    final String accessToken = _requireAccessToken();
    final String cleanRequestId = requestId.trim();
    final String cleanPlacementCode = placementCode.trim();
    final String cleanAdNetwork = (adNetwork ?? '').trim();
    final Map<String, dynamic> cleanMetadata = Map<String, dynamic>.from(
      metadata ?? const <String, dynamic>{},
    );
    if (cleanRequestId.isEmpty) {
      throw StateError('supabase_missing_ad_reward_request_id');
    }
    if (cleanPlacementCode.isEmpty) {
      throw StateError('supabase_missing_ad_reward_placement_code');
    }

    final Uri rpcUri = _supabaseConfig.rpcUri('grant_ad_reward');
    final Response<dynamic> response = await _ensureAuthenticatedRequest((
      String token,
    ) {
      return _dio.postUri(
        rpcUri,
        data: <String, dynamic>{
          'p_reward_amount': requestedAmount,
          'p_request_id': cleanRequestId,
          'p_placement_code': cleanPlacementCode,
          if (cleanAdNetwork.isNotEmpty) 'p_ad_network': cleanAdNetwork,
          if (cleanMetadata.isNotEmpty) 'p_metadata': cleanMetadata,
        },
        options: Options(headers: _authHeaders(accessToken: token)),
      );
    }, initialAccessToken: accessToken);
    final Map<String, dynamic> payload = _ensureJsonMap(response.data);
    if (payload.isEmpty) {
      throw StateError('supabase_invalid_ad_reward_grant_response');
    }
    return CloudAdRewardGrantResult.fromJson(payload);
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
  Future<CloudNumAiSendMessageResult> sendNumAiMessage({
    required String profileId,
    required String messageText,
    String? threadId,
    String? locale,
  }) async {
    if (!isConfigured) {
      throw StateError('supabase_not_configured');
    }

    final String accessToken = _requireAccessToken();
    final String cleanProfileId = profileId.trim();
    final String cleanMessageText = messageText.trim();
    final String cleanThreadId = (threadId ?? '').trim();
    final String cleanLocale = (locale ?? '').trim();
    if (cleanProfileId.isEmpty) {
      throw StateError('numai_profile_required');
    }
    if (cleanMessageText.isEmpty) {
      throw StateError('numai_message_required');
    }

    final Uri functionUri = _supabaseConfig.edgeFunctionUri(
      'numverse-api',
      queryParameters: const <String, String>{'action': 'send-numai-message'},
    );

    try {
      final Response<dynamic> response = await _ensureAuthenticatedRequest((
        String token,
      ) {
        return _dio.postUri(
          functionUri,
          data: <String, dynamic>{
            'primary_profile_id': cleanProfileId,
            'message_text': cleanMessageText,
            if (cleanThreadId.isNotEmpty) 'thread_id': cleanThreadId,
            if (cleanLocale.isNotEmpty) 'locale': cleanLocale,
          },
          options: Options(
            headers: _authHeaders(accessToken: token),
            receiveTimeout: const Duration(seconds: 45),
          ),
        );
      }, initialAccessToken: accessToken);

      final Map<String, dynamic> payload = _ensureJsonMap(response.data);
      if (payload['ok'] != true) {
        throw StateError('supabase_invalid_numai_response');
      }
      final CloudNumAiSendMessageResult result =
          CloudNumAiSendMessageResult.fromEnvelope(payload);
      if (result.assistantText.isEmpty) {
        throw StateError('supabase_invalid_numai_response');
      }
      return result;
    } on DioException catch (error) {
      final Map<String, dynamic> payload = _ensureJsonMap(error.response?.data);
      final String serverErrorCode = (payload['error'] as String? ?? '').trim();
      if (serverErrorCode.isNotEmpty) {
        throw StateError(serverErrorCode);
      }
      rethrow;
    }
  }

  @override
  Future<CloudNumAiSendMessageResult> sendNumAiGuestMessage({
    required String messageText,
    String? locale,
    List<Map<String, String>> recentMessages = const <Map<String, String>>[],
  }) async {
    if (!isConfigured) {
      throw StateError('supabase_not_configured');
    }

    final String accessToken = _requireAccessToken();
    final String cleanMessageText = messageText.trim();
    final String cleanLocale = (locale ?? '').trim();
    if (cleanMessageText.isEmpty) {
      throw StateError('numai_message_required');
    }

    final List<Map<String, String>> payloadRecentMessages = recentMessages
        .map(
          (Map<String, String> raw) => <String, String>{
            'role': (raw['role'] ?? '').trim().toLowerCase(),
            'text': (raw['text'] ?? '').trim(),
          },
        )
        .where(
          (Map<String, String> item) =>
              (item['text'] ?? '').isNotEmpty &&
              ((item['role'] ?? '') == 'user' ||
                  (item['role'] ?? '') == 'assistant'),
        )
        .take(20)
        .toList();

    final Uri functionUri = _supabaseConfig.edgeFunctionUri('numai-guest-chat');

    try {
      final Response<dynamic> response = await _ensureAuthenticatedRequest((
        String token,
      ) {
        return _dio.postUri(
          functionUri,
          data: <String, dynamic>{
            'message_text': cleanMessageText,
            if (cleanLocale.isNotEmpty) 'locale': cleanLocale,
            if (payloadRecentMessages.isNotEmpty)
              'recent_messages': payloadRecentMessages,
          },
          options: Options(
            headers: _authHeaders(accessToken: token),
            receiveTimeout: const Duration(seconds: 45),
          ),
        );
      }, initialAccessToken: accessToken);

      final Map<String, dynamic> payload = _ensureJsonMap(response.data);
      if (payload['ok'] != true) {
        throw StateError('supabase_invalid_numai_response');
      }
      final CloudNumAiSendMessageResult result =
          CloudNumAiSendMessageResult.fromEnvelope(payload);
      if (result.assistantText.isEmpty) {
        throw StateError('supabase_invalid_numai_response');
      }
      return result;
    } on DioException catch (error) {
      final Map<String, dynamic> payload = _ensureJsonMap(error.response?.data);
      final String serverErrorCode = (payload['error'] as String? ?? '').trim();
      if (serverErrorCode.isNotEmpty) {
        throw StateError(serverErrorCode);
      }
      rethrow;
    }
  }

  @override
  Future<CloudNumAiThreadMessagesResult> fetchNumAiThreadMessages({
    required String profileId,
    String? threadId,
    int limit = 50,
  }) async {
    if (!isConfigured) {
      throw StateError('supabase_not_configured');
    }

    final String accessToken = _requireAccessToken();
    final String cleanProfileId = profileId.trim();
    final String cleanThreadId = (threadId ?? '').trim();
    if (cleanProfileId.isEmpty && cleanThreadId.isEmpty) {
      throw StateError('numai_profile_required');
    }

    final int sanitizedLimit = limit.clamp(1, 100);
    final Uri functionUri = _supabaseConfig.edgeFunctionUri(
      'numverse-api',
      queryParameters: const <String, String>{'action': 'list-numai-messages'},
    );

    try {
      final Response<dynamic> response = await _ensureAuthenticatedRequest((
        String token,
      ) {
        return _dio.postUri(
          functionUri,
          data: <String, dynamic>{
            if (cleanProfileId.isNotEmpty) 'primary_profile_id': cleanProfileId,
            if (cleanThreadId.isNotEmpty) 'thread_id': cleanThreadId,
            'limit': sanitizedLimit,
          },
          options: Options(
            headers: _authHeaders(accessToken: token),
            receiveTimeout: const Duration(seconds: 20),
          ),
        );
      }, initialAccessToken: accessToken);

      final Map<String, dynamic> payload = _ensureJsonMap(response.data);
      if (payload['ok'] != true) {
        throw StateError('supabase_invalid_numai_history_response');
      }
      return CloudNumAiThreadMessagesResult.fromEnvelope(payload);
    } on DioException catch (error) {
      final Map<String, dynamic> payload = _ensureJsonMap(error.response?.data);
      final String serverErrorCode = (payload['error'] as String? ?? '').trim();
      if (serverErrorCode.isNotEmpty) {
        throw StateError(serverErrorCode);
      }
      rethrow;
    }
  }

  @override
  Future<CloudNumAiImportGuestHistoryResult> importGuestNumAiHistory({
    required String profileId,
    required List<LocalNumAiGuestMessage> messages,
    String? requestId,
  }) async {
    if (!isConfigured) {
      throw StateError('supabase_not_configured');
    }

    final String accessToken = _requireAccessToken();
    final String cleanProfileId = profileId.trim();
    final String cleanRequestId = (requestId ?? '').trim();
    if (cleanProfileId.isEmpty) {
      throw StateError('numai_profile_required');
    }

    final List<Map<String, dynamic>> payloadMessages = messages
        .map(
          (LocalNumAiGuestMessage item) => <String, dynamic>{
            'local_id': item.id.trim(),
            'sender_type': item.senderType.trim(),
            'message_text': item.messageText.trim(),
            'created_at': item.createdAt.toUtc().toIso8601String(),
            'created_at_epoch_ms': item.createdAt.millisecondsSinceEpoch,
            if (item.followUpSuggestions.isNotEmpty)
              'follow_up_suggestions': item.followUpSuggestions,
          },
        )
        .where(
          (Map<String, dynamic> item) =>
              (item['local_id'] as String? ?? '').isNotEmpty &&
              (item['message_text'] as String? ?? '').isNotEmpty,
        )
        .toList();

    if (payloadMessages.isEmpty) {
      return const CloudNumAiImportGuestHistoryResult(
        threadId: '',
        importedCount: 0,
        skippedCount: 0,
      );
    }

    final Uri functionUri = _supabaseConfig.edgeFunctionUri(
      'numai-import-guest-history',
    );

    try {
      final Response<dynamic> response = await _ensureAuthenticatedRequest((
        String token,
      ) {
        return _dio.postUri(
          functionUri,
          data: <String, dynamic>{
            'primary_profile_id': cleanProfileId,
            if (cleanRequestId.isNotEmpty) 'request_id': cleanRequestId,
            'messages': payloadMessages,
          },
          options: Options(
            headers: _authHeaders(accessToken: token),
            receiveTimeout: const Duration(seconds: 20),
          ),
        );
      }, initialAccessToken: accessToken);

      final Map<String, dynamic> payload = _ensureJsonMap(response.data);
      if (payload['ok'] != true) {
        throw StateError('supabase_invalid_numai_import_response');
      }
      return CloudNumAiImportGuestHistoryResult.fromEnvelope(payload);
    } on DioException catch (error) {
      final Map<String, dynamic> payload = _ensureJsonMap(error.response?.data);
      final String serverErrorCode = (payload['error'] as String? ?? '').trim();
      if (serverErrorCode.isNotEmpty) {
        throw StateError(serverErrorCode);
      }
      rethrow;
    }
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
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    if (value is String && value.trim().isNotEmpty) {
      final Object? decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _ensureJsonList(Object? value) {
    if (value is List) {
      return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
    }
    if (value is Map<String, dynamic>) {
      final Object? rawItems = value['items'];
      if (rawItems is List) {
        return rawItems
            .whereType<Map>()
            .map(Map<String, dynamic>.from)
            .toList();
      }
      return <Map<String, dynamic>>[];
    }
    if (value is String && value.trim().isNotEmpty) {
      final Object? decoded = jsonDecode(value);
      return _ensureJsonList(decoded);
    }
    return <Map<String, dynamic>>[];
  }
}
