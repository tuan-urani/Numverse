import 'dart:collection';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/src/core/model/numerology_reading_models.dart';
import 'package:test/src/core/repository/numerology_content_repository.dart';
import 'package:test/src/helper/birth_chart_content_resolver.dart';
import 'package:test/src/utils/app_shared.dart';
import 'package:test/src/utils/app_supabase_config.dart';

class _MemoryAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    return ByteData.sublistView(Uint8List(0));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    return '{}';
  }
}

class _QueueHttpClientAdapter implements HttpClientAdapter {
  _QueueHttpClientAdapter(List<Map<String, dynamic>> payloads)
    : _payloads = Queue<Map<String, dynamic>>.from(payloads);

  final Queue<Map<String, dynamic>> _payloads;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (_payloads.isEmpty) {
      throw StateError('No mocked payload left for URI: ${options.uri}');
    }
    final Map<String, dynamic> payload = _payloads.removeFirst();
    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'mobile ledger sync flow resolves variant payload and caches version',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final AppShared appShared = AppShared(preferences);

      final Dio dio = Dio();
      dio.httpClientAdapter = _QueueHttpClientAdapter(<Map<String, dynamic>>[
        <String, dynamic>{
          'not_modified': false,
          'version': '1.0.2',
          'checksum':
              '64f6c35bb3c5e831bcea40ad7b70bbe2bc8bfa71233091dac2e5e2fea3e5a951',
          'locale': 'vi',
          'ledger': <String, dynamic>{
            'universal_day': <String, dynamic>{
              '7': <String, dynamic>{
                'variant_strategy': 'day_of_year_mod',
                'variants': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'title': 'Số 7 - Variant A',
                    'energy_theme': 'Theme A',
                    'meaning': 'Meaning A',
                    'energy_manifestation': 'Manifest A',
                    'keywords': <String>['A1', 'A2'],
                  },
                  <String, dynamic>{
                    'title': 'Số 7 - Variant B',
                    'energy_theme': 'Theme B',
                    'meaning': 'Meaning B',
                    'energy_manifestation': 'Manifest B',
                    'keywords': <String>['B1', 'B2'],
                  },
                ],
              },
            },
            'life_path_number': <String, dynamic>{
              '7': <String, dynamic>{
                'title': 'Life Path 7 remote',
                'description': 'remote',
                'interpretation': 'remote',
                'keywords': <String>['remote'],
              },
            },
            'life_pinnacle': <String, dynamic>{
              '1': <String, dynamic>{
                'theme': 'Pinnacle 1 remote',
                'description': 'pinnacle description remote',
                'opportunities': 'pinnacle opportunities remote',
                'advice': 'pinnacle advice remote',
              },
            },
            'life_challenge': <String, dynamic>{
              '0': <String, dynamic>{
                'theme': 'Challenge 0 remote',
                'description': 'challenge description remote',
                'opportunities': 'challenge opportunities remote',
                'advice': 'challenge advice remote',
              },
            },
            'compatibility_content': <String, dynamic>{
              'excellent': <String, dynamic>{
                'strengths': <String>['excellent strength'],
                'challenges': <String>['excellent challenge'],
                'advice': <String>['excellent advice'],
                'quote': 'excellent quote',
              },
              'good': <String, dynamic>{
                'strengths': <String>['good strength'],
                'challenges': <String>['good challenge'],
                'advice': <String>['good advice'],
                'quote': 'good quote',
              },
              'moderate': <String, dynamic>{
                'strengths': <String>['moderate strength'],
                'challenges': <String>['moderate challenge'],
                'advice': <String>['moderate advice'],
                'quote': 'moderate quote',
              },
              'effort': <String, dynamic>{
                'strengths': <String>['effort strength'],
                'challenges': <String>['effort challenge'],
                'advice': <String>['effort advice'],
                'quote': 'effort quote',
              },
            },
          },
        },
        <String, dynamic>{
          'not_modified': false,
          'version': '1.0.2',
          'checksum':
              '64f6c35bb3c5e831bcea40ad7b70bbe2bc8bfa71233091dac2e5e2fea3e5a951',
          'locale': 'en',
          'ledger': <String, dynamic>{},
        },
      ]);

      final AssetNumerologyContentRepository repository =
          AssetNumerologyContentRepository(
            appShared: appShared,
            assetBundle: _MemoryAssetBundle(),
            dio: dio,
            supabaseConfig: const AppSupabaseConfig(
              baseUrl: 'https://oeghmguqrmynbbhnjxfx.supabase.co',
              anonKey: 'test_anon_key',
            ),
          );

      await repository.warmUp();

      final int dayOfYear =
          DateTime.now()
              .difference(DateTime(DateTime.now().year, 1, 1))
              .inDays +
          1;
      final String expectedTitle = dayOfYear.isOdd
          ? 'Số 7 - Variant A'
          : 'Số 7 - Variant B';
      final universal = repository.getUniversalDayContent(
        number: 7,
        languageCode: 'vi',
      );
      final lifePath = repository.getLifePathNumberContent(
        number: 7,
        languageCode: 'vi',
      );
      final pinnacle = repository.getLifePinnacleContent(
        number: 1,
        languageCode: 'vi',
      );
      final challenge = repository.getLifeChallengeContent(
        number: 0,
        languageCode: 'vi',
      );
      final compatibility = repository.getCompatibilityContent(
        overallScore: 75,
        languageCode: 'vi',
      );

      expect(universal.title, expectedTitle);
      expect(lifePath.title, 'Life Path 7 remote');
      expect(pinnacle.theme, 'Pinnacle 1 remote');
      expect(challenge.theme, 'Challenge 0 remote');
      expect(compatibility.quote, 'good quote');

      final String? rawLedger = appShared.getNumerologyLedgerActive('vi');
      expect(rawLedger, isNotNull);
      final Object? decoded = rawLedger == null ? null : jsonDecode(rawLedger);
      expect(decoded is Map<String, dynamic>, true);
      final Map<String, dynamic> envelope = decoded as Map<String, dynamic>;
      expect(envelope['version'], '1.0.2');
      expect((envelope['checksum'] as String?)?.isNotEmpty ?? false, true);
    },
  );

  test('matrix payload from ledger resolves count-axis-arrow mapping', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final AppShared appShared = AppShared(preferences);

    final Dio dio = Dio();
    dio.httpClientAdapter = _QueueHttpClientAdapter(<Map<String, dynamic>>[
      <String, dynamic>{
        'not_modified': false,
        'version': '1.0.3',
        'checksum':
            'a8ee090f8f6a0b13f0e7fa1ad74be8f21591cc16fd62d96f4fe2cfd7ef311f2a',
        'locale': 'vi',
        'ledger': <String, dynamic>{
          'birthday_matrix': <String, dynamic>{
            'default': <String, dynamic>{
              'numbers': <String, dynamic>{
                '1': <String, dynamic>{
                  'strength': 'strength-1',
                  'lesson': 'lesson-1',
                  'strength_by_count': <String, dynamic>{
                    '2_plus': 'strength-1-2plus',
                  },
                },
              },
              'physical_axis': <String, dynamic>{
                'name': 'physical',
                'description': '',
                'present_description': 'physical-present',
                'missing_description': 'physical-missing',
                'description_by_count': <String, dynamic>{'2': 'physical-two'},
              },
              'mental_axis': <String, dynamic>{
                'name': 'mental',
                'description': '',
                'present_description': 'mental-present',
                'missing_description': 'mental-missing',
                'description_by_count': <String, dynamic>{'1': 'mental-one'},
              },
              'emotional_axis': <String, dynamic>{
                'name': 'emotional',
                'description': '',
                'present_description': 'emotional-present',
                'missing_description': 'emotional-missing',
                'description_by_count': <String, dynamic>{'1': 'emotional-one'},
              },
              'arrows': <String, dynamic>{
                'determination': <String, dynamic>{
                  'title': 'Determination',
                  'numbers': <int>[3, 5, 7],
                  'present_description': 'determination-present',
                  'missing_description': 'determination-missing',
                },
              },
            },
          },
        },
      },
      <String, dynamic>{
        'not_modified': false,
        'version': '1.0.3',
        'checksum':
            'a8ee090f8f6a0b13f0e7fa1ad74be8f21591cc16fd62d96f4fe2cfd7ef311f2a',
        'locale': 'en',
        'ledger': <String, dynamic>{},
      },
    ]);

    final AssetNumerologyContentRepository repository =
        AssetNumerologyContentRepository(
          appShared: appShared,
          assetBundle: _MemoryAssetBundle(),
          dio: dio,
          supabaseConfig: const AppSupabaseConfig(
            baseUrl: 'https://oeghmguqrmynbbhnjxfx.supabase.co',
            anonKey: 'test_anon_key',
          ),
        );

    await repository.warmUp();

    final data = repository.getBirthdayMatrixContent(languageCode: 'vi');
    expect(data.numbers[1]?.strengthByCount['2_plus'], 'strength-1-2plus');
    expect(data.physicalAxis.descriptionByCount['2'], 'physical-two');
    expect(data.arrows['determination']?.title, 'Determination');

    final chart = BirthChartGrid(
      grid: const <List<int?>>[
        <int?>[null, null, null],
        <int?>[null, null, null],
        <int?>[null, null, null],
      ],
      numbers: const <int, int>{
        1: 2,
        2: 1,
        3: 1,
        4: 0,
        5: 1,
        6: 0,
        7: 1,
        8: 0,
        9: 0,
      },
      presentNumbers: const <int>[1, 2, 3, 5, 7],
      missingNumbers: const <int>[4, 6, 8, 9],
    );
    const axes = BirthChartAxes(
      physical: ChartAxisScore(
        present: false,
        numbers: <int>[1, 4, 7],
        count: 2,
      ),
      mental: ChartAxisScore(present: false, numbers: <int>[3, 6, 9], count: 1),
      emotional: ChartAxisScore(
        present: false,
        numbers: <int>[2, 5, 8],
        count: 2,
      ),
    );
    const arrows = BirthChartArrows(
      determination: ChartArrowPattern(present: true, numbers: <int>[3, 5, 7]),
      planning: ChartArrowPattern(present: false, numbers: <int>[1, 2, 3]),
      willpower: ChartArrowPattern(present: false, numbers: <int>[4, 5, 6]),
      activity: ChartArrowPattern(present: false, numbers: <int>[1, 5, 9]),
      sensitivity: ChartArrowPattern(present: false, numbers: <int>[3, 6, 9]),
      frustration: ChartArrowPattern(present: false, numbers: <int>[4, 5, 6]),
      success: ChartArrowPattern(present: false, numbers: <int>[7, 8, 9]),
      spirituality: ChartArrowPattern(present: false, numbers: <int>[1, 5, 9]),
    );
    final resolved = BirthChartContentResolver.resolve(
      chart: chart,
      axes: axes,
      arrows: arrows,
      data: data,
    );
    expect(
      resolved.activeArrows.any((item) => item.key == 'determination'),
      true,
    );
  });
}
