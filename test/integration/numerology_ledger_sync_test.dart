import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test/src/core/model/compatibility_aspect.dart';
import 'package:test/src/core/model/numerology_reading_models.dart';
import 'package:test/src/core/repository/numerology_content_repository.dart';
import 'package:test/src/helper/birth_chart_content_resolver.dart';
import 'package:test/src/utils/app_supabase_config.dart';

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

Map<String, dynamic> _compatibilityPayload(String quotePrefix) {
  return <String, dynamic>{
    'strengths': <String>['$quotePrefix strength'],
    'challenges': <String>['$quotePrefix challenge'],
    'advice': <String>['$quotePrefix advice'],
    'quote': '$quotePrefix quote',
  };
}

Map<String, dynamic> _buildCompleteLedger({required String tag}) {
  return <String, dynamic>{
    'universal_day': <String, dynamic>{
      '1': <String, dynamic>{
        'title': 'Universal $tag',
        'energy_theme': 'Theme $tag',
        'meaning': 'Meaning $tag',
        'energy_manifestation': 'Manifest $tag',
        'keywords': <String>['K1', 'K2'],
      },
    },
    'daily_message': <String, dynamic>{
      '1': <Map<String, dynamic>>[
        <String, dynamic>{
          'main_message': 'Main $tag',
          'sub_message': 'Sub $tag',
          'hint_action': 'Hint $tag',
          'thinking': 'Thinking $tag',
          'tips': <String>['Tip $tag'],
        },
      ],
    },
    'lucky_number': <String, dynamic>{
      '1': <String, dynamic>{
        'title': 'Lucky $tag',
        'message': 'Message $tag',
        'meaning': 'Meaning $tag',
        'how_to_use': <String>['Use $tag'],
        'situations': <String>['Situation $tag'],
      },
    },
    'angel_number': <String, dynamic>{
      '111': <String, dynamic>{
        'title': 'Angel $tag',
        'core_meanings': <String>['Core $tag'],
        'universe_messages': <String>['Universe $tag'],
        'guidance': <String>['Guidance $tag'],
      },
      'popular_numbers': <String, dynamic>{
        'items': <String>['111'],
      },
    },
    'number_library': <String, dynamic>{
      '1': <String, dynamic>{
        'title': 'Number 1 $tag',
        'description': 'Description $tag',
        'keywords': <String>['Key $tag'],
        'symbolism': 'Symbol $tag',
      },
      '11': <String, dynamic>{
        'title': 'Number 11 $tag',
        'description': 'Description 11 $tag',
        'keywords': <String>['Key 11 $tag'],
        'symbolism': 'Symbol 11 $tag',
      },
    },
    'todaypersonalnumber': <String, dynamic>{
      '1': <String, dynamic>{
        'day_card_title': 'Day $tag',
        'day_card_subtitle': 'Subtitle $tag',
        'quote': 'Quote $tag',
        'daily_rhythm': 'Rhythm $tag',
        'detail': <String>['Detail $tag'],
        'hint_actions': <String>['Hint action $tag'],
        'should_do': <String>['Do $tag'],
        'should_avoid': <String>['Avoid $tag'],
      },
    },
    'month_personal_number': <String, dynamic>{
      '1': <String, dynamic>{
        'keyword': 'Keyword $tag',
        'hero_title': 'Hero $tag',
        'focus': <String>['Focus $tag'],
        'steps': <Map<String, dynamic>>[
          <String, dynamic>{'title': 'Step $tag', 'body': 'Body $tag'},
        ],
        'priorities': <String>['Priority $tag'],
        'cautions': <String>['Caution $tag'],
      },
    },
    'year_personal_number': <String, dynamic>{
      '1': <String, dynamic>{
        'keyword': 'Year keyword $tag',
        'hero_title': 'Year hero $tag',
        'theme': <String>['Theme $tag'],
        'lessons': <Map<String, dynamic>>[
          <String, dynamic>{'title': 'Lesson $tag', 'body': 'Body $tag'},
        ],
        'focus_areas': <Map<String, dynamic>>[
          <String, dynamic>{'title': 'Focus $tag', 'body': 'Body $tag'},
        ],
      },
    },
    'life_path_number': <String, dynamic>{
      '1': <String, dynamic>{
        'title': 'Life Path $tag',
        'description': 'Description $tag',
        'interpretation': 'Interpretation $tag',
        'keywords': <String>['Keyword $tag'],
      },
    },
    'expression_number': <String, dynamic>{
      '1': <String, dynamic>{
        'title': 'Expression $tag',
        'description': 'Description $tag',
        'interpretation': 'Interpretation $tag',
        'keywords': <String>['Keyword $tag'],
      },
    },
    'soul_urge_number': <String, dynamic>{
      '1': <String, dynamic>{
        'title': 'Soul $tag',
        'description': 'Description $tag',
        'interpretation': 'Interpretation $tag',
        'keywords': <String>['Keyword $tag'],
      },
    },
    'mission_number': <String, dynamic>{
      '1': <String, dynamic>{
        'title': 'Mission $tag',
        'description': 'Description $tag',
        'interpretation': 'Interpretation $tag',
        'keywords': <String>['Keyword $tag'],
      },
    },
    'birthday_matrix': <String, dynamic>{
      'numbers': <String, dynamic>{
        '1': <String, dynamic>{
          'strength': 'Strength $tag',
          'lesson': 'Lesson $tag',
        },
      },
      'physical_axis': <String, dynamic>{
        'name': 'physical',
        'description': '',
        'present_description': 'present',
        'missing_description': 'missing',
      },
      'mental_axis': <String, dynamic>{
        'name': 'mental',
        'description': '',
        'present_description': 'present',
        'missing_description': 'missing',
      },
      'emotional_axis': <String, dynamic>{
        'name': 'emotional',
        'description': '',
        'present_description': 'present',
        'missing_description': 'missing',
      },
    },
    'name_matrix': <String, dynamic>{
      'numbers': <String, dynamic>{
        '1': <String, dynamic>{
          'strength': 'Strength $tag',
          'lesson': 'Lesson $tag',
        },
      },
      'physical_axis': <String, dynamic>{
        'name': 'physical',
        'description': '',
        'present_description': 'present',
        'missing_description': 'missing',
      },
      'mental_axis': <String, dynamic>{
        'name': 'mental',
        'description': '',
        'present_description': 'present',
        'missing_description': 'missing',
      },
      'emotional_axis': <String, dynamic>{
        'name': 'emotional',
        'description': '',
        'present_description': 'present',
        'missing_description': 'missing',
      },
    },
    'life_pinnacle': <String, dynamic>{
      '1': <String, dynamic>{
        'theme': 'Pinnacle $tag',
        'description': 'Description $tag',
        'opportunities': 'Opportunities $tag',
        'advice': 'Advice $tag',
      },
    },
    'life_challenge': <String, dynamic>{
      '0': <String, dynamic>{
        'theme': 'Challenge $tag',
        'description': 'Description $tag',
        'opportunities': 'Opportunities $tag',
        'advice': 'Advice $tag',
      },
    },
    'compatibility_content': <String, dynamic>{
      'excellent': _compatibilityPayload('$tag excellent'),
      'good': _compatibilityPayload('$tag good'),
      'moderate': _compatibilityPayload('$tag moderate'),
      'effort': _compatibilityPayload('$tag effort'),
    },
  };
}

Map<String, dynamic> _buildEnvelope({
  required String locale,
  required String version,
  required String checksum,
  required Map<String, dynamic> ledger,
}) {
  return <String, dynamic>{
    'not_modified': false,
    'version': version,
    'checksum': checksum,
    'locale': locale,
    'ledger': ledger,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('warmUp resolves ledger variant and compatibility content', () async {
    final Map<String, dynamic> viLedger = _buildCompleteLedger(tag: 'vi')
      ..addAll(<String, dynamic>{
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
          'excellent': _compatibilityPayload('excellent'),
          'good': _compatibilityPayload('good'),
          'moderate': _compatibilityPayload('moderate'),
          'effort': _compatibilityPayload('effort'),
          'life_path.good': _compatibilityPayload('life path good'),
        },
      });

    final Dio dio = Dio();
    dio.httpClientAdapter = _QueueHttpClientAdapter(<Map<String, dynamic>>[
      _buildEnvelope(
        locale: 'vi',
        version: '1.0.2',
        checksum: 'checksum_vi',
        ledger: viLedger,
      ),
      _buildEnvelope(
        locale: 'en',
        version: '1.0.2',
        checksum: 'checksum_en',
        ledger: _buildCompleteLedger(tag: 'en'),
      ),
    ]);

    final AssetNumerologyContentRepository repository =
        AssetNumerologyContentRepository(
          dio: dio,
          supabaseConfig: const AppSupabaseConfig(
            baseUrl: 'https://oeghmguqrmynbbhnjxfx.supabase.co',
            anonKey: 'test_anon_key',
          ),
        );

    await repository.warmUp();

    final int dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays +
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
    final lifePathAspect = repository.getCompatibilityAspectContent(
      aspect: CompatibilityAspect.lifePath,
      score: 75,
      languageCode: 'vi',
    );
    final expressionAspect = repository.getCompatibilityAspectContent(
      aspect: CompatibilityAspect.expression,
      score: 75,
      languageCode: 'vi',
    );

    expect(universal.title, expectedTitle);
    expect(lifePath.title, 'Life Path 7 remote');
    expect(pinnacle.theme, 'Pinnacle 1 remote');
    expect(challenge.theme, 'Challenge 0 remote');
    expect(compatibility.quote, 'good quote');
    expect(lifePathAspect.quote, 'life path good quote');
    expect(expressionAspect.quote, 'good quote');
  });

  test(
    'warmUp fails when server responds not_modified in strict mode',
    () async {
      final Dio dio = Dio();
      dio.httpClientAdapter = _QueueHttpClientAdapter(<Map<String, dynamic>>[
        <String, dynamic>{
          'not_modified': true,
          'version': '1.0.9',
          'checksum': 'checksum_vi',
        },
      ]);

      final AssetNumerologyContentRepository repository =
          AssetNumerologyContentRepository(
            dio: dio,
            supabaseConfig: const AppSupabaseConfig(
              baseUrl: 'https://oeghmguqrmynbbhnjxfx.supabase.co',
              anonKey: 'test_anon_key',
            ),
          );

      await expectLater(repository.warmUp, throwsA(isA<StateError>()));
    },
  );

  test('warmUp fails when ledger misses required content types', () async {
    final Map<String, dynamic> invalidLedger = _buildCompleteLedger(tag: 'vi')
      ..remove('compatibility_content');

    final Dio dio = Dio();
    dio.httpClientAdapter = _QueueHttpClientAdapter(<Map<String, dynamic>>[
      _buildEnvelope(
        locale: 'vi',
        version: '1.0.3',
        checksum: 'checksum_vi',
        ledger: invalidLedger,
      ),
      _buildEnvelope(
        locale: 'en',
        version: '1.0.3',
        checksum: 'checksum_en',
        ledger: _buildCompleteLedger(tag: 'en'),
      ),
    ]);

    final AssetNumerologyContentRepository repository =
        AssetNumerologyContentRepository(
          dio: dio,
          supabaseConfig: const AppSupabaseConfig(
            baseUrl: 'https://oeghmguqrmynbbhnjxfx.supabase.co',
            anonKey: 'test_anon_key',
          ),
        );

    await expectLater(repository.warmUp, throwsA(isA<StateError>()));
  });

  test(
    'matrix payload from ledger resolves count-axis-arrow mapping',
    () async {
      final Map<String, dynamic> viLedger = _buildCompleteLedger(tag: 'vi')
        ..addAll(<String, dynamic>{
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
        });

      final Dio dio = Dio();
      dio.httpClientAdapter = _QueueHttpClientAdapter(<Map<String, dynamic>>[
        _buildEnvelope(
          locale: 'vi',
          version: '1.0.3',
          checksum: 'checksum_vi',
          ledger: viLedger,
        ),
        _buildEnvelope(
          locale: 'en',
          version: '1.0.3',
          checksum: 'checksum_en',
          ledger: _buildCompleteLedger(tag: 'en'),
        ),
      ]);

      final AssetNumerologyContentRepository repository =
          AssetNumerologyContentRepository(
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
        mental: ChartAxisScore(
          present: false,
          numbers: <int>[3, 6, 9],
          count: 1,
        ),
        emotional: ChartAxisScore(
          present: false,
          numbers: <int>[2, 5, 8],
          count: 2,
        ),
      );
      const arrows = BirthChartArrows(
        determination: ChartArrowPattern(
          present: true,
          numbers: <int>[3, 5, 7],
        ),
        planning: ChartArrowPattern(present: false, numbers: <int>[1, 2, 3]),
        willpower: ChartArrowPattern(present: false, numbers: <int>[4, 5, 6]),
        activity: ChartArrowPattern(present: false, numbers: <int>[1, 5, 9]),
        sensitivity: ChartArrowPattern(present: false, numbers: <int>[3, 6, 9]),
        frustration: ChartArrowPattern(present: false, numbers: <int>[4, 5, 6]),
        success: ChartArrowPattern(present: false, numbers: <int>[7, 8, 9]),
        spirituality: ChartArrowPattern(
          present: false,
          numbers: <int>[1, 5, 9],
        ),
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
    },
  );
}
