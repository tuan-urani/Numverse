import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import 'package:test/src/core/model/compatibility_aspect.dart';
import 'package:test/src/core/model/numerology_content_models.dart';
import 'package:test/src/core/model/numerology_reading_models.dart';
import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/core/service/supabase_offline_coordinator.dart';
import 'package:test/src/core/service/supabase_offline_interceptor.dart';
import 'package:test/src/helper/numerology_reading_data.dart';
import 'package:test/src/utils/app_supabase_config.dart';

class AssetNumerologyContentRepository implements INumerologyContentRepository {
  AssetNumerologyContentRepository({
    Dio? dio,
    AppSupabaseConfig? supabaseConfig,
    SupabaseOfflineCoordinator? offlineCoordinator,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 3),
               receiveTimeout: const Duration(seconds: 3),
             ),
           ),
       _supabaseConfig = supabaseConfig ?? const AppSupabaseConfig(),
       _offlineCoordinator =
           offlineCoordinator ??
           SupabaseOfflineCoordinator(dialogsEnabled: false) {
    _dio.interceptors.add(
      SupabaseOfflineInterceptor(dio: _dio, coordinator: _offlineCoordinator),
    );
  }

  static const String _fallbackLanguageCode = 'vi';
  static const Set<String> _supportedLanguages = <String>{'vi', 'en'};
  static const String _typeUniversalDay = 'universal_day';
  static const String _typeLuckyNumber = 'lucky_number';
  static const String _typeDailyMessage = 'daily_message';
  static const String _typeAngelNumber = 'angel_number';
  static const String _typeTodayPersonalNumber = 'todaypersonalnumber';
  static const String _typePersonalMonth = 'month_personal_number';
  static const String _typePersonalYear = 'year_personal_number';
  static const String _typeLifePathNumber = 'life_path_number';
  static const String _typeExpressionNumber = 'expression_number';
  static const String _typeSoulUrgeNumber = 'soul_urge_number';
  static const String _typeMissionNumber = 'mission_number';
  static const String _typeBirthdayMatrix = 'birthday_matrix';
  static const String _typeNameMatrix = 'name_matrix';
  static const String _typeLifePinnacle = 'life_pinnacle';
  static const String _typeLifeChallenge = 'life_challenge';
  static const String _typeCompatibilityContent = 'compatibility_content';
  final SupabaseOfflineCoordinator _offlineCoordinator;
  static const List<int> _fallbackNumberLibraryBasicNumbers = <int>[
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
  ];
  static const List<int> _fallbackNumberLibraryMasterNumbers = <int>[
    11,
    22,
    33,
  ];
  final Dio _dio;
  final AppSupabaseConfig _supabaseConfig;
  final Map<String, Map<int, NumerologyUniversalDayContent>>
  _universalDayByLanguage = <String, Map<int, NumerologyUniversalDayContent>>{};
  final Map<String, Map<int, List<NumerologyDailyMessageTemplate>>>
  _dailyMessageByLanguage =
      <String, Map<int, List<NumerologyDailyMessageTemplate>>>{};
  final Map<String, Map<int, NumerologyLuckyNumberContent>>
  _luckyNumberByLanguage = <String, Map<int, NumerologyLuckyNumberContent>>{};
  final Map<String, Map<String, NumerologyAngelNumberContent>>
  _angelNumberByLanguage =
      <String, Map<String, NumerologyAngelNumberContent>>{};
  final Map<String, List<String>> _angelNumberPopularByLanguage =
      <String, List<String>>{};
  final Map<String, Map<int, NumerologyNumberLibraryContent>>
  _numberLibraryByLanguage =
      <String, Map<int, NumerologyNumberLibraryContent>>{};
  final Map<String, List<int>> _numberLibraryBasicByLanguage =
      <String, List<int>>{};
  final Map<String, List<int>> _numberLibraryMasterByLanguage =
      <String, List<int>>{};
  final Map<String, Map<int, NumerologyTodayPersonalNumberContent>>
  _todayPersonalNumberByLanguage =
      <String, Map<int, NumerologyTodayPersonalNumberContent>>{};
  final Map<String, Map<int, NumerologyPersonalMonthContent>>
  _personalMonthByLanguage =
      <String, Map<int, NumerologyPersonalMonthContent>>{};
  final Map<String, Map<int, NumerologyPersonalYearContent>>
  _personalYearByLanguage = <String, Map<int, NumerologyPersonalYearContent>>{};
  final Map<String, Map<int, CoreNumberContent>> _lifePathNumberByLanguage =
      <String, Map<int, CoreNumberContent>>{};
  final Map<String, Map<int, CoreNumberContent>> _expressionNumberByLanguage =
      <String, Map<int, CoreNumberContent>>{};
  final Map<String, Map<int, CoreNumberContent>> _soulUrgeNumberByLanguage =
      <String, Map<int, CoreNumberContent>>{};
  final Map<String, Map<int, CoreNumberContent>> _missionNumberByLanguage =
      <String, Map<int, CoreNumberContent>>{};
  final Map<String, BirthChartDataSet> _birthdayMatrixByLanguage =
      <String, BirthChartDataSet>{};
  final Map<String, BirthChartDataSet> _nameMatrixByLanguage =
      <String, BirthChartDataSet>{};
  final Map<String, Map<int, LifeCycleContent>> _lifePinnacleByLanguage =
      <String, Map<int, LifeCycleContent>>{};
  final Map<String, Map<int, LifeCycleContent>> _lifeChallengeByLanguage =
      <String, Map<int, LifeCycleContent>>{};
  final Map<String, Map<String, NumerologyCompatibilityContent>>
  _compatibilityByLanguage =
      <String, Map<String, NumerologyCompatibilityContent>>{};
  final Map<String, Map<String, dynamic>> _ledgerPayloadByLanguage =
      <String, Map<String, dynamic>>{};

  bool _isWarmedUp = false;
  int _lastResolvedVariantDayOfYear = -1;

  @override
  Future<void> warmUp() async {
    if (_isWarmedUp) {
      return;
    }

    _clearLoadedContent();
    await _syncLedgerFromServer();

    _lastResolvedVariantDayOfYear = _currentDayOfYear();
    _isWarmedUp = true;
  }

  void _clearLoadedContent() {
    _universalDayByLanguage.clear();
    _dailyMessageByLanguage.clear();
    _luckyNumberByLanguage.clear();
    _angelNumberByLanguage.clear();
    _angelNumberPopularByLanguage.clear();
    _numberLibraryByLanguage.clear();
    _numberLibraryBasicByLanguage.clear();
    _numberLibraryMasterByLanguage.clear();
    _todayPersonalNumberByLanguage.clear();
    _personalMonthByLanguage.clear();
    _personalYearByLanguage.clear();
    _lifePathNumberByLanguage.clear();
    _expressionNumberByLanguage.clear();
    _soulUrgeNumberByLanguage.clear();
    _missionNumberByLanguage.clear();
    _birthdayMatrixByLanguage.clear();
    _nameMatrixByLanguage.clear();
    _lifePinnacleByLanguage.clear();
    _lifeChallengeByLanguage.clear();
    _compatibilityByLanguage.clear();
    _ledgerPayloadByLanguage.clear();
  }

  Future<void> _syncLedgerFromServer() async {
    if (!_supabaseConfig.isConfigured) {
      throw StateError('supabase_not_configured');
    }

    for (final String languageCode in _supportedLanguages) {
      final Map<String, dynamic> response = await _fetchLedgerFromServer(
        localeCode: languageCode,
      );
      if (response['not_modified'] == true) {
        throw StateError('supabase_ledger_not_modified_without_cache');
      }
      final ({String version, String checksum, Map<String, dynamic> ledger})?
      remoteEnvelope = _parseRemoteEnvelope(response);
      if (remoteEnvelope == null) {
        throw StateError('supabase_invalid_ledger_response');
      }

      _ledgerPayloadByLanguage[languageCode] = Map<String, dynamic>.from(
        remoteEnvelope.ledger,
      );
      _applyLedgerPayload(
        languageCode: languageCode,
        ledger: remoteEnvelope.ledger,
      );
      _ensureLedgerCoverage(languageCode);
    }
  }

  Future<Map<String, dynamic>> _fetchLedgerFromServer({
    required String localeCode,
  }) async {
    final String anonKey = _supabaseConfig.resolvedAnonKey;
    final Response<dynamic> response = await _dio.postUri(
      _supabaseConfig.rpcUri('get_ledger'),
      data: <String, dynamic>{'p_locale': localeCode},
      options: Options(
        headers: <String, String>{
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
          'Content-Type': 'application/json',
        },
      ),
    );
    final dynamic rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      return rawData;
    }
    if (rawData is String && rawData.trim().isNotEmpty) {
      final Object? decoded = jsonDecode(rawData);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }
    throw StateError('supabase_invalid_ledger_response');
  }

  void _ensureLedgerCoverage(String languageCode) {
    final List<String> missingTypes = <String>[];
    if ((_universalDayByLanguage[languageCode] ?? const {}).isEmpty) {
      missingTypes.add(_typeUniversalDay);
    }
    if ((_dailyMessageByLanguage[languageCode] ?? const {}).isEmpty) {
      missingTypes.add(_typeDailyMessage);
    }
    if ((_luckyNumberByLanguage[languageCode] ?? const {}).isEmpty) {
      missingTypes.add(_typeLuckyNumber);
    }
    if ((_angelNumberByLanguage[languageCode] ?? const {}).isEmpty) {
      missingTypes.add(_typeAngelNumber);
    }
    if ((_todayPersonalNumberByLanguage[languageCode] ?? const {}).isEmpty) {
      missingTypes.add(_typeTodayPersonalNumber);
    }
    if ((_personalMonthByLanguage[languageCode] ?? const {}).isEmpty) {
      missingTypes.add(_typePersonalMonth);
    }
    if ((_personalYearByLanguage[languageCode] ?? const {}).isEmpty) {
      missingTypes.add(_typePersonalYear);
    }
    if ((_lifePathNumberByLanguage[languageCode] ?? const {}).isEmpty) {
      missingTypes.add(_typeLifePathNumber);
    }
    if ((_expressionNumberByLanguage[languageCode] ?? const {}).isEmpty) {
      missingTypes.add(_typeExpressionNumber);
    }
    if ((_soulUrgeNumberByLanguage[languageCode] ?? const {}).isEmpty) {
      missingTypes.add(_typeSoulUrgeNumber);
    }
    if ((_missionNumberByLanguage[languageCode] ?? const {}).isEmpty) {
      missingTypes.add(_typeMissionNumber);
    }
    if (_birthdayMatrixByLanguage[languageCode] == null) {
      missingTypes.add(_typeBirthdayMatrix);
    }
    if (_nameMatrixByLanguage[languageCode] == null) {
      missingTypes.add(_typeNameMatrix);
    }
    if ((_lifePinnacleByLanguage[languageCode] ?? const {}).isEmpty) {
      missingTypes.add(_typeLifePinnacle);
    }
    if ((_lifeChallengeByLanguage[languageCode] ?? const {}).isEmpty) {
      missingTypes.add(_typeLifeChallenge);
    }
    if ((_compatibilityByLanguage[languageCode] ?? const {}).isEmpty) {
      missingTypes.add(_typeCompatibilityContent);
    }
    if (missingTypes.isNotEmpty) {
      throw StateError(
        'supabase_ledger_missing_content:$languageCode:${missingTypes.join(',')}',
      );
    }
  }

  ({String version, String checksum, Map<String, dynamic> ledger})?
  _parseRemoteEnvelope(Map<String, dynamic> json) {
    final String version = (json['version'] as String? ?? '').trim();
    final String checksum = (json['checksum'] as String? ?? '').trim();
    final Object? rawLedger = json['ledger'];
    if (version.isEmpty || rawLedger is! Map<String, dynamic>) {
      return null;
    }
    return (version: version, checksum: checksum, ledger: rawLedger);
  }

  void _applyLedgerPayload({
    required String languageCode,
    required Map<String, dynamic> ledger,
  }) {
    final Map<String, dynamic>? universalDayRaw = _asJsonMap(
      ledger[_typeUniversalDay],
    );
    if (universalDayRaw != null && universalDayRaw.isNotEmpty) {
      final Map<int, NumerologyUniversalDayContent> map =
          _parseUniversalDayEntries(universalDayRaw);
      if (map.isNotEmpty) {
        _universalDayByLanguage[languageCode] = map;
      }
    }

    final Map<String, dynamic>? dailyMessageRaw = _asJsonMap(
      ledger[_typeDailyMessage],
    );
    if (dailyMessageRaw != null && dailyMessageRaw.isNotEmpty) {
      final Map<int, List<NumerologyDailyMessageTemplate>> map =
          _parseDailyMessageEntries(dailyMessageRaw);
      if (map.isNotEmpty) {
        _dailyMessageByLanguage[languageCode] = map;
      }
    }

    final Map<String, dynamic>? luckyNumberRaw = _asJsonMap(
      ledger[_typeLuckyNumber],
    );
    if (luckyNumberRaw != null && luckyNumberRaw.isNotEmpty) {
      final Map<int, NumerologyLuckyNumberContent> map =
          _parseLuckyNumberEntries(luckyNumberRaw);
      if (map.isNotEmpty) {
        _luckyNumberByLanguage[languageCode] = map;
      }
    }

    final Map<String, dynamic>? angelNumberRaw = _asJsonMap(
      ledger[_typeAngelNumber],
    );
    if (angelNumberRaw != null && angelNumberRaw.isNotEmpty) {
      final Map<String, NumerologyAngelNumberContent> map =
          _parseAngelNumberEntries(angelNumberRaw);
      if (map.isNotEmpty) {
        _angelNumberByLanguage[languageCode] = map;
        _angelNumberPopularByLanguage[languageCode] =
            _extractAngelPopularNumbersFromLedger(
              rawEntries: angelNumberRaw,
              parsedMap: map,
            );
      }
    }

    final Map<String, dynamic>? todayPersonalRaw = _asJsonMap(
      ledger[_typeTodayPersonalNumber],
    );
    if (todayPersonalRaw != null && todayPersonalRaw.isNotEmpty) {
      final Map<int, NumerologyTodayPersonalNumberContent> map =
          _parseTodayPersonalEntries(todayPersonalRaw);
      if (map.isNotEmpty) {
        _todayPersonalNumberByLanguage[languageCode] = map;
      }
    }

    final Map<String, dynamic>? personalMonthRaw = _asJsonMap(
      ledger[_typePersonalMonth],
    );
    if (personalMonthRaw != null && personalMonthRaw.isNotEmpty) {
      final Map<int, NumerologyPersonalMonthContent> map =
          _parsePersonalMonthEntries(personalMonthRaw);
      if (map.isNotEmpty) {
        _personalMonthByLanguage[languageCode] = map;
      }
    }

    final Map<String, dynamic>? personalYearRaw = _asJsonMap(
      ledger[_typePersonalYear],
    );
    if (personalYearRaw != null && personalYearRaw.isNotEmpty) {
      final Map<int, NumerologyPersonalYearContent> map =
          _parsePersonalYearEntries(personalYearRaw);
      if (map.isNotEmpty) {
        _personalYearByLanguage[languageCode] = map;
      }
    }

    final Map<String, dynamic>? lifePathRaw =
        _asJsonMap(ledger[_typeLifePathNumber]) ??
        _asJsonMap(ledger['life_path']);
    if (lifePathRaw != null && lifePathRaw.isNotEmpty) {
      final Map<int, CoreNumberContent> map = _parseCoreNumberEntries(
        lifePathRaw,
      );
      if (map.isNotEmpty) {
        _lifePathNumberByLanguage[languageCode] = map;
      }
    }

    final Map<String, dynamic>? expressionRaw =
        _asJsonMap(ledger[_typeExpressionNumber]) ??
        _asJsonMap(ledger['personality_number']);
    if (expressionRaw != null && expressionRaw.isNotEmpty) {
      final Map<int, CoreNumberContent> map = _parseCoreNumberEntries(
        expressionRaw,
      );
      if (map.isNotEmpty) {
        _expressionNumberByLanguage[languageCode] = map;
      }
    }

    final Map<String, dynamic>? soulUrgeRaw = _asJsonMap(
      ledger[_typeSoulUrgeNumber],
    );
    if (soulUrgeRaw != null && soulUrgeRaw.isNotEmpty) {
      final Map<int, CoreNumberContent> map = _parseCoreNumberEntries(
        soulUrgeRaw,
      );
      if (map.isNotEmpty) {
        _soulUrgeNumberByLanguage[languageCode] = map;
      }
    }

    final Map<String, dynamic>? missionRaw = _asJsonMap(
      ledger[_typeMissionNumber],
    );
    if (missionRaw != null && missionRaw.isNotEmpty) {
      final Map<int, CoreNumberContent> map = _parseCoreNumberEntries(
        missionRaw,
      );
      if (map.isNotEmpty) {
        _missionNumberByLanguage[languageCode] = map;
      }
    }

    final Map<String, dynamic>? birthdayMatrixRaw =
        _asJsonMap(ledger[_typeBirthdayMatrix]) ??
        _asJsonMap(ledger['birday_matrix']);
    if (birthdayMatrixRaw != null && birthdayMatrixRaw.isNotEmpty) {
      final BirthChartDataSet? dataSet = _parseMatrixDataSet(birthdayMatrixRaw);
      if (dataSet != null) {
        _birthdayMatrixByLanguage[languageCode] = dataSet;
      }
    }

    final Map<String, dynamic>? nameMatrixRaw = _asJsonMap(
      ledger[_typeNameMatrix],
    );
    if (nameMatrixRaw != null && nameMatrixRaw.isNotEmpty) {
      final BirthChartDataSet? dataSet = _parseMatrixDataSet(nameMatrixRaw);
      if (dataSet != null) {
        _nameMatrixByLanguage[languageCode] = _ensureNameMatrixArrows(dataSet);
      }
    }

    final Map<String, dynamic>? lifePinnacleRaw =
        _asJsonMap(ledger[_typeLifePinnacle]) ??
        _asJsonMap(ledger['life_peaks']);
    if (lifePinnacleRaw != null && lifePinnacleRaw.isNotEmpty) {
      final Map<int, LifeCycleContent> map = _parseLifeCycleEntries(
        lifePinnacleRaw,
      );
      if (map.isNotEmpty) {
        _lifePinnacleByLanguage[languageCode] = map;
      }
    }

    final Map<String, dynamic>? lifeChallengeRaw =
        _asJsonMap(ledger[_typeLifeChallenge]) ??
        _asJsonMap(ledger['life_challenges']);
    if (lifeChallengeRaw != null && lifeChallengeRaw.isNotEmpty) {
      final Map<int, LifeCycleContent> map = _parseLifeCycleEntries(
        lifeChallengeRaw,
      );
      if (map.isNotEmpty) {
        _lifeChallengeByLanguage[languageCode] = map;
      }
    }

    final Map<String, dynamic>? compatibilityRaw = _asJsonMap(
      ledger[_typeCompatibilityContent],
    );
    if (compatibilityRaw != null && compatibilityRaw.isNotEmpty) {
      final Map<String, NumerologyCompatibilityContent> map =
          _parseCompatibilityEntries(compatibilityRaw);
      if (map.isNotEmpty) {
        _compatibilityByLanguage[languageCode] = map;
      }
    }
  }

  Map<String, dynamic>? _asJsonMap(Object? value) {
    return switch (value) {
      Map<String, dynamic>() => value,
      _ => null,
    };
  }

  @override
  NumerologyUniversalDayContent getUniversalDayContent({
    required int number,
    required String languageCode,
  }) {
    _refreshDynamicVariantsIfNeeded();
    final Map<int, NumerologyUniversalDayContent> map = _resolveUniversalDayMap(
      languageCode,
    );
    return _requireContent(
      map[number] ?? map[1],
      'supabase_ledger_missing_universal_day:$languageCode:$number',
    );
  }

  @override
  NumerologyDailyMessageTemplate getDailyMessageTemplate({
    required int number,
    required int dayOfYear,
    required String languageCode,
  }) {
    final Map<int, List<NumerologyDailyMessageTemplate>> map =
        _resolveDailyMessageMap(languageCode);
    final List<NumerologyDailyMessageTemplate> templates =
        map[number] ?? map[1] ?? <NumerologyDailyMessageTemplate>[];
    if (templates.isEmpty) {
      throw StateError(
        'supabase_ledger_missing_daily_message:$languageCode:$number',
      );
    }

    final int index = dayOfYear % templates.length;
    return templates[index];
  }

  @override
  NumerologyLuckyNumberContent getLuckyNumberContent({
    required int number,
    required String languageCode,
  }) {
    _refreshDynamicVariantsIfNeeded();
    final Map<int, NumerologyLuckyNumberContent> map = _resolveLuckyNumberMap(
      languageCode,
    );
    return _requireContent(
      map[number] ?? map[1],
      'supabase_ledger_missing_lucky_number:$languageCode:$number',
    );
  }

  @override
  NumerologyAngelNumberContent? findAngelNumberContent({
    required String number,
    required String languageCode,
  }) {
    _refreshDynamicVariantsIfNeeded();
    final String normalized = number.trim();
    if (normalized.isEmpty) {
      return null;
    }
    final Map<String, NumerologyAngelNumberContent> map =
        _resolveAngelNumberMap(languageCode);
    return map[normalized];
  }

  @override
  List<String> getAngelNumberPopularNumbers({required String languageCode}) {
    _refreshDynamicVariantsIfNeeded();
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    final List<String> list =
        _angelNumberPopularByLanguage[normalizedLanguageCode] ??
        _angelNumberPopularByLanguage[_fallbackLanguageCode] ??
        const <String>[];
    if (list.isEmpty) {
      throw StateError('supabase_ledger_missing_angel_popular:$languageCode');
    }
    return list;
  }

  @override
  NumerologyNumberLibraryContent getNumberLibraryContent({
    required int number,
    required String languageCode,
  }) {
    final Map<int, NumerologyNumberLibraryContent> map =
        _resolveNumberLibraryMap(languageCode);
    return _requireContent(
      map[number] ?? map[1],
      'supabase_ledger_missing_number_library:$languageCode:$number',
    );
  }

  @override
  NumerologyTodayPersonalNumberContent getTodayPersonalNumberContent({
    required int number,
    required String languageCode,
  }) {
    _refreshDynamicVariantsIfNeeded();
    final Map<int, NumerologyTodayPersonalNumberContent> map =
        _resolveTodayPersonalNumberMap(languageCode);
    return _requireContent(
      map[number] ?? map[1],
      'supabase_ledger_missing_today_personal:$languageCode:$number',
    );
  }

  @override
  NumerologyPersonalMonthContent getPersonalMonthContent({
    required int number,
    required String languageCode,
  }) {
    _refreshDynamicVariantsIfNeeded();
    final Map<int, NumerologyPersonalMonthContent> map =
        _resolvePersonalMonthMap(languageCode);
    return _requireContent(
      map[number] ?? map[1],
      'supabase_ledger_missing_personal_month:$languageCode:$number',
    );
  }

  @override
  NumerologyPersonalYearContent getPersonalYearContent({
    required int number,
    required String languageCode,
  }) {
    _refreshDynamicVariantsIfNeeded();
    final Map<int, NumerologyPersonalYearContent> map = _resolvePersonalYearMap(
      languageCode,
    );
    return _requireContent(
      map[number] ?? map[1],
      'supabase_ledger_missing_personal_year:$languageCode:$number',
    );
  }

  @override
  List<int> getNumberLibraryBasicNumbers({required String languageCode}) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    final List<int> list =
        _numberLibraryBasicByLanguage[normalizedLanguageCode] ??
        _numberLibraryBasicByLanguage[_fallbackLanguageCode] ??
        _fallbackNumberLibraryBasicNumbers;
    return list;
  }

  @override
  List<int> getNumberLibraryMasterNumbers({required String languageCode}) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    final List<int> list =
        _numberLibraryMasterByLanguage[normalizedLanguageCode] ??
        _numberLibraryMasterByLanguage[_fallbackLanguageCode] ??
        _fallbackNumberLibraryMasterNumbers;
    return list;
  }

  @override
  CoreNumberContent getLifePathNumberContent({
    required int number,
    required String languageCode,
  }) {
    _refreshDynamicVariantsIfNeeded();
    final Map<int, CoreNumberContent> map = _resolveLifePathNumberMap(
      languageCode,
    );
    return _requireContent(
      map[number] ?? map[1],
      'supabase_ledger_missing_life_path:$languageCode:$number',
    );
  }

  @override
  CoreNumberContent getExpressionNumberContent({
    required int number,
    required String languageCode,
  }) {
    _refreshDynamicVariantsIfNeeded();
    final Map<int, CoreNumberContent> map = _resolveExpressionNumberMap(
      languageCode,
    );
    return _requireContent(
      map[number] ?? map[1],
      'supabase_ledger_missing_expression:$languageCode:$number',
    );
  }

  @override
  CoreNumberContent getSoulUrgeNumberContent({
    required int number,
    required String languageCode,
  }) {
    _refreshDynamicVariantsIfNeeded();
    final Map<int, CoreNumberContent> map = _resolveSoulUrgeNumberMap(
      languageCode,
    );
    return _requireContent(
      map[number] ?? map[1],
      'supabase_ledger_missing_soul_urge:$languageCode:$number',
    );
  }

  @override
  CoreNumberContent getMissionNumberContent({
    required int number,
    required String languageCode,
  }) {
    _refreshDynamicVariantsIfNeeded();
    final Map<int, CoreNumberContent> map = _resolveMissionNumberMap(
      languageCode,
    );
    return _requireContent(
      map[number] ?? map[1],
      'supabase_ledger_missing_mission:$languageCode:$number',
    );
  }

  @override
  BirthChartDataSet getBirthdayMatrixContent({required String languageCode}) {
    _refreshDynamicVariantsIfNeeded();
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    return _requireContent(
      _birthdayMatrixByLanguage[normalizedLanguageCode] ??
          _birthdayMatrixByLanguage[_fallbackLanguageCode],
      'supabase_ledger_missing_birthday_matrix:$languageCode',
    );
  }

  @override
  BirthChartDataSet getNameMatrixContent({required String languageCode}) {
    _refreshDynamicVariantsIfNeeded();
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    final BirthChartDataSet dataSet = _requireContent(
      _nameMatrixByLanguage[normalizedLanguageCode] ??
          _nameMatrixByLanguage[_fallbackLanguageCode],
      'supabase_ledger_missing_name_matrix:$languageCode',
    );
    return _ensureNameMatrixArrows(dataSet);
  }

  @override
  LifeCycleContent getLifePinnacleContent({
    required int number,
    required String languageCode,
  }) {
    _refreshDynamicVariantsIfNeeded();
    final Map<int, LifeCycleContent> map = _resolveLifePinnacleMap(
      languageCode,
    );
    return _requireContent(
      map[number] ?? map[1],
      'supabase_ledger_missing_life_pinnacle:$languageCode:$number',
    );
  }

  @override
  LifeCycleContent getLifeChallengeContent({
    required int number,
    required String languageCode,
  }) {
    _refreshDynamicVariantsIfNeeded();
    final Map<int, LifeCycleContent> map = _resolveLifeChallengeMap(
      languageCode,
    );
    return _requireContent(
      map[number] ?? map[1],
      'supabase_ledger_missing_life_challenge:$languageCode:$number',
    );
  }

  @override
  NumerologyCompatibilityContent getCompatibilityContent({
    required int overallScore,
    required String languageCode,
  }) {
    _refreshDynamicVariantsIfNeeded();
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    final Map<String, NumerologyCompatibilityContent> ledgerMap =
        _compatibilityByLanguage[normalizedLanguageCode] ??
        _compatibilityByLanguage[_fallbackLanguageCode] ??
        const <String, NumerologyCompatibilityContent>{};
    if (ledgerMap.isEmpty) {
      throw StateError('supabase_ledger_missing_compatibility:$languageCode');
    }
    final String band = _resolveCompatibilityBand(overallScore);
    final NumerologyCompatibilityContent resolved = _requireContent(
      ledgerMap[band],
      'supabase_ledger_missing_compatibility_band:$languageCode:$band',
    );
    _logCompatibilityResolution(
      mode: 'overall',
      languageCode: normalizedLanguageCode,
      score: overallScore,
      band: band,
      selectedKey: band,
      source: 'ledger.overall_band',
      hasLedgerCompatibility: true,
    );
    return resolved;
  }

  @override
  NumerologyCompatibilityContent getCompatibilityAspectContent({
    required CompatibilityAspect aspect,
    required int score,
    required String languageCode,
  }) {
    _refreshDynamicVariantsIfNeeded();
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    final Map<String, NumerologyCompatibilityContent> ledgerMap =
        _compatibilityByLanguage[normalizedLanguageCode] ??
        _compatibilityByLanguage[_fallbackLanguageCode] ??
        const <String, NumerologyCompatibilityContent>{};
    if (ledgerMap.isEmpty) {
      throw StateError('supabase_ledger_missing_compatibility:$languageCode');
    }
    final String band = _resolveCompatibilityBand(score);
    final String aspectBandKey = '${aspect.storageKey}.$band';
    final NumerologyCompatibilityContent? aspectContent =
        ledgerMap[aspectBandKey];
    final NumerologyCompatibilityContent? overallBandContent = ledgerMap[band];
    final NumerologyCompatibilityContent resolved = _requireContent(
      aspectContent ?? overallBandContent,
      'supabase_ledger_missing_compatibility_aspect:$languageCode:$aspectBandKey',
    );

    late final String selectedKey;
    late final String source;
    if (aspectContent != null) {
      selectedKey = aspectBandKey;
      source = 'ledger.aspect_band';
    } else if (overallBandContent != null) {
      selectedKey = band;
      source = 'ledger.overall_band_fallback';
    } else {
      selectedKey = aspectBandKey;
      source = 'ledger.missing';
    }

    _logCompatibilityResolution(
      mode: 'aspect.${aspect.storageKey}',
      languageCode: normalizedLanguageCode,
      score: score,
      band: band,
      selectedKey: selectedKey,
      source: source,
      hasLedgerCompatibility: true,
    );
    return resolved;
  }

  Map<int, NumerologyUniversalDayContent> _resolveUniversalDayMap(
    String languageCode,
  ) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    return _universalDayByLanguage[normalizedLanguageCode] ??
        _universalDayByLanguage[_fallbackLanguageCode] ??
        const <int, NumerologyUniversalDayContent>{};
  }

  Map<int, List<NumerologyDailyMessageTemplate>> _resolveDailyMessageMap(
    String languageCode,
  ) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    return _dailyMessageByLanguage[normalizedLanguageCode] ??
        _dailyMessageByLanguage[_fallbackLanguageCode] ??
        const <int, List<NumerologyDailyMessageTemplate>>{};
  }

  Map<int, NumerologyLuckyNumberContent> _resolveLuckyNumberMap(
    String languageCode,
  ) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    return _luckyNumberByLanguage[normalizedLanguageCode] ??
        _luckyNumberByLanguage[_fallbackLanguageCode] ??
        const <int, NumerologyLuckyNumberContent>{};
  }

  Map<String, NumerologyAngelNumberContent> _resolveAngelNumberMap(
    String languageCode,
  ) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    return _angelNumberByLanguage[normalizedLanguageCode] ??
        _angelNumberByLanguage[_fallbackLanguageCode] ??
        const <String, NumerologyAngelNumberContent>{};
  }

  Map<int, NumerologyNumberLibraryContent> _resolveNumberLibraryMap(
    String languageCode,
  ) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    return _numberLibraryByLanguage[normalizedLanguageCode] ??
        _numberLibraryByLanguage[_fallbackLanguageCode] ??
        const <int, NumerologyNumberLibraryContent>{};
  }

  Map<int, NumerologyTodayPersonalNumberContent> _resolveTodayPersonalNumberMap(
    String languageCode,
  ) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    return _todayPersonalNumberByLanguage[normalizedLanguageCode] ??
        _todayPersonalNumberByLanguage[_fallbackLanguageCode] ??
        const <int, NumerologyTodayPersonalNumberContent>{};
  }

  Map<int, NumerologyPersonalMonthContent> _resolvePersonalMonthMap(
    String languageCode,
  ) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    return _personalMonthByLanguage[normalizedLanguageCode] ??
        _personalMonthByLanguage[_fallbackLanguageCode] ??
        const <int, NumerologyPersonalMonthContent>{};
  }

  Map<int, NumerologyPersonalYearContent> _resolvePersonalYearMap(
    String languageCode,
  ) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    return _personalYearByLanguage[normalizedLanguageCode] ??
        _personalYearByLanguage[_fallbackLanguageCode] ??
        const <int, NumerologyPersonalYearContent>{};
  }

  Map<int, CoreNumberContent> _resolveLifePathNumberMap(String languageCode) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    return _lifePathNumberByLanguage[normalizedLanguageCode] ??
        _lifePathNumberByLanguage[_fallbackLanguageCode] ??
        const <int, CoreNumberContent>{};
  }

  Map<int, CoreNumberContent> _resolveExpressionNumberMap(String languageCode) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    return _expressionNumberByLanguage[normalizedLanguageCode] ??
        _expressionNumberByLanguage[_fallbackLanguageCode] ??
        const <int, CoreNumberContent>{};
  }

  Map<int, CoreNumberContent> _resolveSoulUrgeNumberMap(String languageCode) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    return _soulUrgeNumberByLanguage[normalizedLanguageCode] ??
        _soulUrgeNumberByLanguage[_fallbackLanguageCode] ??
        const <int, CoreNumberContent>{};
  }

  Map<int, CoreNumberContent> _resolveMissionNumberMap(String languageCode) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    return _missionNumberByLanguage[normalizedLanguageCode] ??
        _missionNumberByLanguage[_fallbackLanguageCode] ??
        const <int, CoreNumberContent>{};
  }

  Map<int, LifeCycleContent> _resolveLifePinnacleMap(String languageCode) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    return _lifePinnacleByLanguage[normalizedLanguageCode] ??
        _lifePinnacleByLanguage[_fallbackLanguageCode] ??
        const <int, LifeCycleContent>{};
  }

  Map<int, LifeCycleContent> _resolveLifeChallengeMap(String languageCode) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    return _lifeChallengeByLanguage[normalizedLanguageCode] ??
        _lifeChallengeByLanguage[_fallbackLanguageCode] ??
        const <int, LifeCycleContent>{};
  }

  String _resolveCompatibilityBand(int overallScore) {
    if (overallScore >= 80) {
      return 'excellent';
    }
    if (overallScore >= 70) {
      return 'good';
    }
    if (overallScore >= 60) {
      return 'moderate';
    }
    return 'effort';
  }

  String _normalizeLanguageCode(String languageCode) {
    final String normalized = languageCode.toLowerCase();
    if (_supportedLanguages.contains(normalized)) {
      return normalized;
    }
    return _fallbackLanguageCode;
  }

  T _requireContent<T>(T? value, String errorCode) {
    if (value != null) {
      return value;
    }
    throw StateError(errorCode);
  }

  Map<int, NumerologyUniversalDayContent> _parseUniversalDayEntries(
    Map<String, dynamic> numbers,
  ) {
    final Map<int, NumerologyUniversalDayContent> map =
        <int, NumerologyUniversalDayContent>{};
    for (final MapEntry<String, dynamic> entry in numbers.entries) {
      final int? number = int.tryParse(entry.key.trim());
      final Map<String, dynamic>? payload = _asJsonMap(
        _resolveVariantPayload(entry.value),
      );
      if (number == null || payload == null) {
        continue;
      }

      try {
        map[number] = NumerologyUniversalDayContent.fromJson(payload);
      } catch (_) {
        continue;
      }
    }
    return map;
  }

  Map<int, List<NumerologyDailyMessageTemplate>> _parseDailyMessageEntries(
    Map<String, dynamic> numbers,
  ) {
    final Map<int, List<NumerologyDailyMessageTemplate>> map =
        <int, List<NumerologyDailyMessageTemplate>>{};
    for (final MapEntry<String, dynamic> entry in numbers.entries) {
      final int? number = int.tryParse(entry.key.trim());
      final List<dynamic>? templateItems = _resolveDailyMessageTemplateItems(
        entry.value,
      );
      if (number == null || templateItems == null || templateItems.isEmpty) {
        continue;
      }

      final List<NumerologyDailyMessageTemplate> templates =
          <NumerologyDailyMessageTemplate>[];
      for (final dynamic item in templateItems) {
        final Map<String, dynamic>? templatePayload = _asJsonMap(
          _resolveVariantPayload(item),
        );
        if (templatePayload == null) {
          continue;
        }
        try {
          templates.add(
            NumerologyDailyMessageTemplate.fromJson(templatePayload),
          );
        } catch (_) {
          continue;
        }
      }

      if (templates.isNotEmpty) {
        map[number] = templates;
      }
    }

    return map;
  }

  List<dynamic>? _resolveDailyMessageTemplateItems(Object? raw) {
    if (raw is List<dynamic>) {
      return raw;
    }

    final Map<String, dynamic>? payload = _asJsonMap(raw);
    if (payload == null) {
      final Object? resolved = _resolveVariantPayload(raw);
      return resolved is List<dynamic> ? resolved : null;
    }

    final Object? variantsRaw =
        payload['variants'] ?? payload['messages'] ?? payload['templates'];
    if (variantsRaw is List<dynamic>) {
      return variantsRaw;
    }

    if (payload.containsKey('payload')) {
      final Object? nested = payload['payload'];
      if (nested is List<dynamic>) {
        return nested;
      }
      if (nested is Map<String, dynamic>) {
        final Object? nestedVariants =
            nested['variants'] ?? nested['messages'] ?? nested['templates'];
        if (nestedVariants is List<dynamic>) {
          return nestedVariants;
        }
      }
    }

    final Object? resolved = _resolveVariantPayload(payload);
    if (resolved is List<dynamic>) {
      return resolved;
    }
    if (resolved is Map<String, dynamic>) {
      return <dynamic>[resolved];
    }
    return null;
  }

  Map<int, NumerologyLuckyNumberContent> _parseLuckyNumberEntries(
    Map<String, dynamic> numbers,
  ) {
    final Map<int, NumerologyLuckyNumberContent> map =
        <int, NumerologyLuckyNumberContent>{};
    for (final MapEntry<String, dynamic> entry in numbers.entries) {
      final int? number = int.tryParse(entry.key.trim());
      final Map<String, dynamic>? payload = _asJsonMap(
        _resolveVariantPayload(entry.value),
      );
      if (number == null || payload == null) {
        continue;
      }

      try {
        map[number] = NumerologyLuckyNumberContent.fromJson(payload);
      } catch (_) {
        continue;
      }
    }

    return map;
  }

  Map<String, NumerologyAngelNumberContent> _parseAngelNumberEntries(
    Map<String, dynamic> numbers,
  ) {
    final Map<String, NumerologyAngelNumberContent> map =
        <String, NumerologyAngelNumberContent>{};
    for (final MapEntry<String, dynamic> entry in numbers.entries) {
      final String number = entry.key.trim();
      final Map<String, dynamic>? payload = _asJsonMap(
        _resolveVariantPayload(entry.value),
      );
      if (number.isEmpty || payload == null) {
        continue;
      }

      try {
        map[number] = NumerologyAngelNumberContent.fromJson(payload);
      } catch (_) {
        continue;
      }
    }
    return map;
  }

  List<String> _resolveAngelPopularNumbers(
    Map<String, NumerologyAngelNumberContent> map,
  ) {
    final List<String> allNumbers = map.keys.toList(growable: false)
      ..sort((String a, String b) => a.compareTo(b));
    if (allNumbers.isEmpty) {
      return const <String>[];
    }

    final List<String> preferred = <String>[
      '111',
      '222',
      '333',
    ].where(map.containsKey).toList(growable: false);
    if (preferred.length == 3) {
      return preferred;
    }

    return allNumbers.take(3).toList(growable: false);
  }

  List<String> _extractAngelPopularNumbersFromLedger({
    required Map<String, dynamic> rawEntries,
    required Map<String, NumerologyAngelNumberContent> parsedMap,
  }) {
    final Object? rawPopularPayload =
        rawEntries['__popular_numbers__'] ?? rawEntries['popular_numbers'];
    if (rawPopularPayload == null) {
      return _resolveAngelPopularNumbers(parsedMap);
    }

    final Map<String, dynamic>? popularPayload = _asJsonMap(
      _resolveVariantPayload(rawPopularPayload),
    );
    final Object? rawItems = popularPayload?['items'] ?? rawPopularPayload;
    if (rawItems is! List<dynamic>) {
      return _resolveAngelPopularNumbers(parsedMap);
    }

    final List<String> items = rawItems
        .map((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty && parsedMap.containsKey(item))
        .toList(growable: false);
    if (items.isNotEmpty) {
      return items;
    }
    return _resolveAngelPopularNumbers(parsedMap);
  }

  Map<int, NumerologyTodayPersonalNumberContent> _parseTodayPersonalEntries(
    Map<String, dynamic> numbers,
  ) {
    final Map<int, NumerologyTodayPersonalNumberContent> map =
        <int, NumerologyTodayPersonalNumberContent>{};
    for (final MapEntry<String, dynamic> entry in numbers.entries) {
      final int? number = int.tryParse(entry.key.trim());
      final Map<String, dynamic>? payload = _asJsonMap(
        _resolveVariantPayload(entry.value),
      );
      if (number == null || payload == null) {
        continue;
      }
      try {
        map[number] = NumerologyTodayPersonalNumberContent.fromJson(payload);
      } catch (_) {
        continue;
      }
    }
    return map;
  }

  Map<int, NumerologyPersonalMonthContent> _parsePersonalMonthEntries(
    Map<String, dynamic> numbers,
  ) {
    final Map<int, NumerologyPersonalMonthContent> map =
        <int, NumerologyPersonalMonthContent>{};
    for (final MapEntry<String, dynamic> entry in numbers.entries) {
      final int? number = int.tryParse(entry.key.trim());
      final Map<String, dynamic>? payload = _asJsonMap(
        _resolveVariantPayload(entry.value),
      );
      if (number == null || payload == null) {
        continue;
      }
      try {
        map[number] = NumerologyPersonalMonthContent.fromJson(payload);
      } catch (_) {
        continue;
      }
    }
    return map;
  }

  Map<int, NumerologyPersonalYearContent> _parsePersonalYearEntries(
    Map<String, dynamic> numbers,
  ) {
    final Map<int, NumerologyPersonalYearContent> map =
        <int, NumerologyPersonalYearContent>{};
    for (final MapEntry<String, dynamic> entry in numbers.entries) {
      final int? number = int.tryParse(entry.key.trim());
      final Map<String, dynamic>? payload = _asJsonMap(
        _resolveVariantPayload(entry.value),
      );
      if (number == null || payload == null) {
        continue;
      }
      try {
        map[number] = NumerologyPersonalYearContent.fromJson(payload);
      } catch (_) {
        continue;
      }
    }
    return map;
  }

  Map<int, CoreNumberContent> _parseCoreNumberEntries(
    Map<String, dynamic> numbers,
  ) {
    final Map<int, CoreNumberContent> map = <int, CoreNumberContent>{};
    for (final MapEntry<String, dynamic> entry in numbers.entries) {
      final int? number = int.tryParse(entry.key.trim());
      final Map<String, dynamic>? payload = _asJsonMap(
        _resolveVariantPayload(entry.value),
      );
      if (number == null || payload == null) {
        continue;
      }
      try {
        map[number] = CoreNumberContent.fromJson(payload);
      } catch (_) {
        continue;
      }
    }
    return map;
  }

  BirthChartDataSet? _parseMatrixDataSet(Map<String, dynamic> raw) {
    Map<String, dynamic>? payload = _asJsonMap(_resolveVariantPayload(raw));
    if (payload == null || payload.isEmpty) {
      return null;
    }
    if (!payload.containsKey('numbers')) {
      final Map<String, dynamic>? defaultPayload = _asJsonMap(
        _resolveVariantPayload(payload['default'] ?? payload['1']),
      );
      if (defaultPayload != null && defaultPayload.containsKey('numbers')) {
        payload = defaultPayload;
      } else {
        Object? firstValue;
        final Iterator<Object?> iterator = payload.values.iterator;
        if (iterator.moveNext()) {
          firstValue = iterator.current;
        }
        final Map<String, dynamic>? firstPayload = _asJsonMap(
          _resolveVariantPayload(firstValue),
        );
        if (firstPayload != null && firstPayload.containsKey('numbers')) {
          payload = firstPayload;
        }
      }
    }
    try {
      return BirthChartDataSet.fromJson(payload);
    } catch (_) {
      return null;
    }
  }

  BirthChartDataSet _ensureNameMatrixArrows(BirthChartDataSet dataSet) {
    if (dataSet.arrows.isNotEmpty) {
      return dataSet;
    }
    return BirthChartDataSet(
      numbers: dataSet.numbers,
      physicalAxis: dataSet.physicalAxis,
      mentalAxis: dataSet.mentalAxis,
      emotionalAxis: dataSet.emotionalAxis,
      arrows: NumerologyReadingData.nameChartArrows,
    );
  }

  Map<int, LifeCycleContent> _parseLifeCycleEntries(Map<String, dynamic> map) {
    final Map<int, LifeCycleContent> result = <int, LifeCycleContent>{};
    for (final MapEntry<String, dynamic> entry in map.entries) {
      final int? number = int.tryParse(entry.key.trim());
      final Map<String, dynamic>? payload = _asJsonMap(
        _resolveVariantPayload(entry.value),
      );
      if (number == null || payload == null) {
        continue;
      }
      try {
        result[number] = LifeCycleContent.fromJson(payload);
      } catch (_) {
        continue;
      }
    }
    return result;
  }

  Map<String, NumerologyCompatibilityContent> _parseCompatibilityEntries(
    Map<String, dynamic> map,
  ) {
    final Map<String, NumerologyCompatibilityContent> result =
        <String, NumerologyCompatibilityContent>{};
    for (final MapEntry<String, dynamic> entry in map.entries) {
      final String key = entry.key.trim().toLowerCase();
      final Map<String, dynamic>? payload = _asJsonMap(
        _resolveVariantPayload(entry.value),
      );
      if (key.isEmpty || payload == null) {
        continue;
      }
      try {
        result[key] = NumerologyCompatibilityContent.fromJson(payload);
      } catch (_) {
        continue;
      }
    }
    return result;
  }

  Object? _resolveVariantPayload(Object? raw) {
    final Map<String, dynamic>? payload = _asJsonMap(raw);
    if (payload == null) {
      return raw;
    }

    final Object? variantsRaw = payload['variants'];
    if (variantsRaw is List<dynamic> && variantsRaw.isNotEmpty) {
      final int index = _resolveVariantIndex(
        length: variantsRaw.length,
        strategy:
            payload['variant_strategy'] as String? ??
            payload['variantStrategy'] as String?,
      );
      return variantsRaw[index];
    }
    if (variantsRaw is Map<String, dynamic> && variantsRaw.isNotEmpty) {
      final List<String> keys = variantsRaw.keys.toList(growable: false)
        ..sort();
      final int index = _resolveVariantIndex(
        length: keys.length,
        strategy:
            payload['variant_strategy'] as String? ??
            payload['variantStrategy'] as String?,
      );
      return variantsRaw[keys[index]];
    }

    if (payload.containsKey('payload')) {
      return payload['payload'];
    }
    if (payload.containsKey('default')) {
      return payload['default'];
    }
    return payload;
  }

  int _resolveVariantIndex({required int length, String? strategy}) {
    if (length <= 1) {
      return 0;
    }
    final String normalizedStrategy = (strategy ?? 'day_of_year_mod')
        .trim()
        .toLowerCase();
    return switch (normalizedStrategy) {
      'static' => 0,
      _ => (_currentDayOfYear() - 1) % length,
    };
  }

  int _currentDayOfYear([DateTime? date]) {
    final DateTime now = date ?? DateTime.now();
    return now.difference(DateTime(now.year, 1, 1)).inDays + 1;
  }

  void _refreshDynamicVariantsIfNeeded() {
    if (!_isWarmedUp) {
      return;
    }
    final int currentDay = _currentDayOfYear();
    if (currentDay == _lastResolvedVariantDayOfYear) {
      return;
    }
    _lastResolvedVariantDayOfYear = currentDay;
    for (final MapEntry<String, Map<String, dynamic>> entry
        in _ledgerPayloadByLanguage.entries) {
      _applyLedgerPayload(languageCode: entry.key, ledger: entry.value);
    }
  }

  void _logCompatibilityResolution({
    required String mode,
    required String languageCode,
    required int score,
    required String band,
    required String selectedKey,
    required String source,
    required bool hasLedgerCompatibility,
  }) {
    assert(() {
      developer.log(
        'Compatibility content resolve: '
        'mode=$mode locale=$languageCode score=$score band=$band '
        'selected_key=$selectedKey source=$source ledger=$hasLedgerCompatibility',
        name: 'AssetNumerologyContentRepository',
      );
      return true;
    }());
  }
}
