import 'package:equatable/equatable.dart';

import 'package:test/src/core/model/numerology_reading_models.dart';

class ResolvedArrowInsight extends Equatable {
  const ResolvedArrowInsight({
    required this.key,
    required this.title,
    required this.text,
    required this.numbers,
    required this.active,
  });

  final String key;
  final String title;
  final String text;
  final List<int> numbers;
  final bool active;

  @override
  List<Object?> get props => <Object?>[key, title, text, numbers, active];
}

class BirthChartResolvedContent extends Equatable {
  const BirthChartResolvedContent({
    this.strengthByNumber = const <int, String>{},
    this.lessonByNumber = const <int, String>{},
    this.axisDescriptionByKey = const <String, String>{},
    this.activeArrows = const <ResolvedArrowInsight>[],
    this.inactiveArrows = const <ResolvedArrowInsight>[],
  });

  final Map<int, String> strengthByNumber;
  final Map<int, String> lessonByNumber;
  final Map<String, String> axisDescriptionByKey;
  final List<ResolvedArrowInsight> activeArrows;
  final List<ResolvedArrowInsight> inactiveArrows;

  bool get hasArrowInsights =>
      activeArrows.isNotEmpty || inactiveArrows.isNotEmpty;

  @override
  List<Object?> get props => <Object?>[
    strengthByNumber,
    lessonByNumber,
    axisDescriptionByKey,
    activeArrows,
    inactiveArrows,
  ];
}

class BirthChartContentResolver {
  static const List<String> _arrowOrder = <String>[
    'determination',
    'planning',
    'willpower',
    'activity',
    'sensitivity',
    'frustration',
    'success',
    'spirituality',
  ];

  static BirthChartResolvedContent resolve({
    required BirthChartGrid chart,
    required BirthChartAxes axes,
    required BirthChartArrows arrows,
    required BirthChartDataSet data,
  }) {
    final Map<int, String> strengths = <int, String>{};
    final Map<int, String> lessons = <int, String>{};

    for (final int number in chart.presentNumbers) {
      final int count = chart.numbers[number] ?? 0;
      strengths[number] = _resolveNumberText(
        meaning: data.numbers[number],
        count: count,
        useLesson: false,
      );
    }

    for (final int number in chart.missingNumbers) {
      lessons[number] = _resolveNumberText(
        meaning: data.numbers[number],
        count: 0,
        useLesson: true,
      );
    }

    final Map<String, String> axisDescriptionByKey = <String, String>{
      'physical': _resolveAxisText(
        axis: data.physicalAxis,
        count: axes.physical.count,
        present: axes.physical.present,
      ),
      'mental': _resolveAxisText(
        axis: data.mentalAxis,
        count: axes.mental.count,
        present: axes.mental.present,
      ),
      'emotional': _resolveAxisText(
        axis: data.emotionalAxis,
        count: axes.emotional.count,
        present: axes.emotional.present,
      ),
    };

    final Map<String, ChartArrowPattern> arrowPatterns = _toArrowPatternMap(
      arrows,
    );

    final List<ResolvedArrowInsight> activeArrows = <ResolvedArrowInsight>[];
    final List<ResolvedArrowInsight> inactiveArrows = <ResolvedArrowInsight>[];

    for (final String key in _arrowOrder) {
      final ChartArrowPattern? pattern = arrowPatterns[key];
      final ChartArrowMeaning? meaning = data.arrows[key];
      if (pattern == null || meaning == null) {
        continue;
      }

      final String text =
          (pattern.present
                  ? meaning.presentDescription
                  : meaning.missingDescription)
              .trim();
      if (text.isEmpty) {
        continue;
      }

      final ResolvedArrowInsight insight = ResolvedArrowInsight(
        key: key,
        title: meaning.title.isEmpty ? _formatArrowTitle(key) : meaning.title,
        text: text,
        numbers: meaning.numbers.isEmpty ? pattern.numbers : meaning.numbers,
        active: pattern.present,
      );
      if (pattern.present) {
        activeArrows.add(insight);
      } else {
        inactiveArrows.add(insight);
      }
    }

    final Iterable<String> extraArrowKeys = data.arrows.keys.where(
      (String key) => !_arrowOrder.contains(key),
    );
    for (final String key in extraArrowKeys) {
      final ChartArrowPattern? pattern = arrowPatterns[key];
      final ChartArrowMeaning? meaning = data.arrows[key];
      if (pattern == null || meaning == null) {
        continue;
      }
      final String text =
          (pattern.present
                  ? meaning.presentDescription
                  : meaning.missingDescription)
              .trim();
      if (text.isEmpty) {
        continue;
      }
      final ResolvedArrowInsight insight = ResolvedArrowInsight(
        key: key,
        title: meaning.title.isEmpty ? _formatArrowTitle(key) : meaning.title,
        text: text,
        numbers: meaning.numbers.isEmpty ? pattern.numbers : meaning.numbers,
        active: pattern.present,
      );
      if (pattern.present) {
        activeArrows.add(insight);
      } else {
        inactiveArrows.add(insight);
      }
    }

    return BirthChartResolvedContent(
      strengthByNumber: strengths,
      lessonByNumber: lessons,
      axisDescriptionByKey: axisDescriptionByKey,
      activeArrows: activeArrows,
      inactiveArrows: inactiveArrows,
    );
  }

  static String _resolveNumberText({
    required ChartNumberMeaning? meaning,
    required int count,
    required bool useLesson,
  }) {
    if (meaning == null) {
      return '';
    }
    final String fallback = useLesson ? meaning.lesson : meaning.strength;
    final Map<String, String> mapping = useLesson
        ? meaning.lessonByCount
        : meaning.strengthByCount;
    return _resolveByCount(
      mapping: mapping,
      count: count,
      fallback: fallback,
      present: count > 0,
    );
  }

  static String _resolveAxisText({
    required ChartAxisMeaning axis,
    required int count,
    required bool present,
  }) {
    final String fallback = present
        ? axis.presentDescription
        : axis.missingDescription;
    return _resolveByCount(
      mapping: axis.descriptionByCount,
      count: count,
      fallback: fallback,
      present: present,
    );
  }

  static String _resolveByCount({
    required Map<String, String> mapping,
    required int count,
    required String fallback,
    required bool present,
  }) {
    if (mapping.isEmpty) {
      return fallback;
    }

    final String exact = '$count';
    final String? exactValue = mapping[exact];
    if (exactValue != null && exactValue.isNotEmpty) {
      return exactValue;
    }

    if (count == 0) {
      final String? missing = mapping['missing'] ?? mapping['none'];
      if (missing != null && missing.isNotEmpty) {
        return missing;
      }
    } else if (present) {
      final String? presentValue = mapping['present'];
      if (presentValue != null && presentValue.isNotEmpty) {
        return presentValue;
      }
    }

    String? thresholdValue;
    int maxThreshold = -1;
    for (final MapEntry<String, String> entry in mapping.entries) {
      final Match? plus = RegExp(r'^(\d+)(?:_plus|\+)$').firstMatch(entry.key);
      if (plus == null) {
        continue;
      }
      final int? threshold = int.tryParse(plus.group(1) ?? '');
      if (threshold == null || count < threshold) {
        continue;
      }
      if (threshold > maxThreshold && entry.value.trim().isNotEmpty) {
        maxThreshold = threshold;
        thresholdValue = entry.value;
      }
    }
    if (thresholdValue != null) {
      return thresholdValue;
    }

    final String? defaultValue = mapping['default'];
    if (defaultValue != null && defaultValue.isNotEmpty) {
      return defaultValue;
    }

    return fallback;
  }

  static Map<String, ChartArrowPattern> _toArrowPatternMap(
    BirthChartArrows arrows,
  ) {
    return <String, ChartArrowPattern>{
      'determination': arrows.determination,
      'planning': arrows.planning,
      'willpower': arrows.willpower,
      'activity': arrows.activity,
      'sensitivity': arrows.sensitivity,
      'frustration': arrows.frustration,
      'success': arrows.success,
      'spirituality': arrows.spirituality,
    };
  }

  static String _formatArrowTitle(String key) {
    return key
        .split('_')
        .where((String part) => part.isNotEmpty)
        .map(
          (String part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}
