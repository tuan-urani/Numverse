import 'package:equatable/equatable.dart';

class CoreNumberContent extends Equatable {
  const CoreNumberContent({
    required this.title,
    required this.description,
    required this.interpretation,
    required this.keywords,
  });

  factory CoreNumberContent.fromJson(Map<String, dynamic> json) {
    return CoreNumberContent(
      title: (json['title'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      interpretation: (json['interpretation'] as String? ?? '').trim(),
      keywords: _parseStringList(json['keywords']),
    );
  }

  final String title;
  final String description;
  final String interpretation;
  final List<String> keywords;

  @override
  List<Object?> get props => <Object?>[
    title,
    description,
    interpretation,
    keywords,
  ];

  static List<String> _parseStringList(Object? value) {
    return switch (value) {
      List<dynamic>() =>
        value
            .whereType<String>()
            .map((String item) => item.trim())
            .where((String item) => item.isNotEmpty)
            .toList(growable: false),
      String() when value.trim().isNotEmpty => <String>[value.trim()],
      _ => const <String>[],
    };
  }
}

class ChartNumberMeaning extends Equatable {
  const ChartNumberMeaning({
    required this.strength,
    required this.lesson,
    this.strengthByCount = const <String, String>{},
    this.lessonByCount = const <String, String>{},
  });

  factory ChartNumberMeaning.fromJson(Map<String, dynamic> json) {
    return ChartNumberMeaning(
      strength: (json['strength'] as String? ?? '').trim(),
      lesson: (json['lesson'] as String? ?? '').trim(),
      strengthByCount: _parseStringMap(
        json['strength_by_count'] ?? json['strengthByCount'],
      ),
      lessonByCount: _parseStringMap(
        json['lesson_by_count'] ?? json['lessonByCount'],
      ),
    );
  }

  final String strength;
  final String lesson;
  final Map<String, String> strengthByCount;
  final Map<String, String> lessonByCount;

  @override
  List<Object?> get props => <Object?>[
    strength,
    lesson,
    strengthByCount,
    lessonByCount,
  ];

  static Map<String, String> _parseStringMap(Object? value) {
    final Map<String, dynamic>? raw = switch (value) {
      Map<String, dynamic>() => value,
      _ => null,
    };
    if (raw == null || raw.isEmpty) {
      return const <String, String>{};
    }

    final Map<String, String> result = <String, String>{};
    for (final MapEntry<String, dynamic> entry in raw.entries) {
      final String key = entry.key.trim().toLowerCase();
      final String text = (entry.value as String? ?? '').trim();
      if (key.isEmpty || text.isEmpty) {
        continue;
      }
      result[key] = text;
    }
    return result;
  }
}

class ChartAxisMeaning extends Equatable {
  const ChartAxisMeaning({
    required this.name,
    required this.description,
    required this.presentDescription,
    required this.missingDescription,
    this.descriptionByCount = const <String, String>{},
  });

  factory ChartAxisMeaning.fromJson(Map<String, dynamic> json) {
    return ChartAxisMeaning(
      name: (json['name'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      presentDescription: (json['present_description'] as String? ?? '').trim(),
      missingDescription: (json['missing_description'] as String? ?? '').trim(),
      descriptionByCount: ChartNumberMeaning._parseStringMap(
        json['description_by_count'] ?? json['descriptionByCount'],
      ),
    );
  }

  final String name;
  final String description;
  final String presentDescription;
  final String missingDescription;
  final Map<String, String> descriptionByCount;

  @override
  List<Object?> get props => <Object?>[
    name,
    description,
    presentDescription,
    missingDescription,
    descriptionByCount,
  ];
}

class ChartArrowMeaning extends Equatable {
  const ChartArrowMeaning({
    required this.key,
    required this.title,
    required this.presentDescription,
    required this.missingDescription,
    this.numbers = const <int>[],
  });

  factory ChartArrowMeaning.fromJson(
    Map<String, dynamic> json, {
    required String key,
  }) {
    final List<int> numbers = switch (json['numbers']) {
      List<dynamic>() =>
        json['numbers']
            .map((dynamic value) {
              return switch (value) {
                int() => value,
                String() => int.tryParse(value.trim()),
                _ => null,
              };
            })
            .whereType<int>()
            .toList(growable: false),
      _ => const <int>[],
    };

    return ChartArrowMeaning(
      key: key,
      title: (json['title'] as String? ?? '').trim(),
      presentDescription: (json['present_description'] as String? ?? '').trim(),
      missingDescription: (json['missing_description'] as String? ?? '').trim(),
      numbers: numbers,
    );
  }

  final String key;
  final String title;
  final String presentDescription;
  final String missingDescription;
  final List<int> numbers;

  @override
  List<Object?> get props => <Object?>[
    key,
    title,
    presentDescription,
    missingDescription,
    numbers,
  ];
}

class BirthChartDataSet extends Equatable {
  const BirthChartDataSet({
    required this.numbers,
    required this.physicalAxis,
    required this.mentalAxis,
    required this.emotionalAxis,
    this.arrows = const <String, ChartArrowMeaning>{},
  });

  factory BirthChartDataSet.fromJson(Map<String, dynamic> json) {
    final Map<int, ChartNumberMeaning> numbers = <int, ChartNumberMeaning>{};
    final Object? rawNumbers = json['numbers'];
    if (rawNumbers is Map<String, dynamic>) {
      for (final MapEntry<String, dynamic> entry in rawNumbers.entries) {
        final int? key = int.tryParse(entry.key.trim());
        final Map<String, dynamic>? value = switch (entry.value) {
          Map<String, dynamic>() => entry.value,
          _ => null,
        };
        if (key == null || value == null) {
          continue;
        }
        numbers[key] = ChartNumberMeaning.fromJson(value);
      }
    }

    Map<String, dynamic>? asMap(Object? value) {
      return switch (value) {
        Map<String, dynamic>() => value,
        _ => null,
      };
    }

    final ChartAxisMeaning emptyAxis = const ChartAxisMeaning(
      name: '',
      description: '',
      presentDescription: '',
      missingDescription: '',
    );

    final ChartAxisMeaning physicalAxis = switch (asMap(
      json['physical_axis'] ?? json['physicalAxis'],
    )) {
      final Map<String, dynamic> map => ChartAxisMeaning.fromJson(map),
      _ => emptyAxis,
    };
    final ChartAxisMeaning mentalAxis = switch (asMap(
      json['mental_axis'] ?? json['mentalAxis'],
    )) {
      final Map<String, dynamic> map => ChartAxisMeaning.fromJson(map),
      _ => emptyAxis,
    };
    final ChartAxisMeaning emotionalAxis = switch (asMap(
      json['emotional_axis'] ?? json['emotionalAxis'],
    )) {
      final Map<String, dynamic> map => ChartAxisMeaning.fromJson(map),
      _ => emptyAxis,
    };

    final Map<String, ChartArrowMeaning> arrows = <String, ChartArrowMeaning>{};
    final Object? rawArrows = json['arrows'];
    if (rawArrows is Map<String, dynamic>) {
      for (final MapEntry<String, dynamic> entry in rawArrows.entries) {
        final String key = entry.key.trim().toLowerCase();
        final Map<String, dynamic>? value = asMap(entry.value);
        if (key.isEmpty || value == null) {
          continue;
        }
        arrows[key] = ChartArrowMeaning.fromJson(value, key: key);
      }
    }

    return BirthChartDataSet(
      numbers: numbers,
      physicalAxis: physicalAxis,
      mentalAxis: mentalAxis,
      emotionalAxis: emotionalAxis,
      arrows: arrows,
    );
  }

  final Map<int, ChartNumberMeaning> numbers;
  final ChartAxisMeaning physicalAxis;
  final ChartAxisMeaning mentalAxis;
  final ChartAxisMeaning emotionalAxis;
  final Map<String, ChartArrowMeaning> arrows;

  @override
  List<Object?> get props => <Object?>[
    numbers,
    physicalAxis,
    mentalAxis,
    emotionalAxis,
    arrows,
  ];
}

class BirthChartGrid extends Equatable {
  const BirthChartGrid({
    required this.grid,
    required this.numbers,
    required this.presentNumbers,
    required this.missingNumbers,
  });

  final List<List<int?>> grid;
  final Map<int, int> numbers;
  final List<int> presentNumbers;
  final List<int> missingNumbers;

  @override
  List<Object?> get props => <Object?>[
    grid,
    numbers,
    presentNumbers,
    missingNumbers,
  ];
}

class ChartAxisScore extends Equatable {
  const ChartAxisScore({
    required this.present,
    required this.numbers,
    required this.count,
  });

  final bool present;
  final List<int> numbers;
  final int count;

  @override
  List<Object?> get props => <Object?>[present, numbers, count];
}

class BirthChartAxes extends Equatable {
  const BirthChartAxes({
    required this.physical,
    required this.mental,
    required this.emotional,
  });

  final ChartAxisScore physical;
  final ChartAxisScore mental;
  final ChartAxisScore emotional;

  @override
  List<Object?> get props => <Object?>[physical, mental, emotional];
}

class ChartArrowPattern extends Equatable {
  const ChartArrowPattern({required this.present, required this.numbers});

  final bool present;
  final List<int> numbers;

  @override
  List<Object?> get props => <Object?>[present, numbers];
}

class BirthChartArrows extends Equatable {
  const BirthChartArrows({
    required this.determination,
    required this.planning,
    required this.willpower,
    required this.activity,
    required this.sensitivity,
    required this.frustration,
    required this.success,
    required this.spirituality,
  });

  final ChartArrowPattern determination;
  final ChartArrowPattern planning;
  final ChartArrowPattern willpower;
  final ChartArrowPattern activity;
  final ChartArrowPattern sensitivity;
  final ChartArrowPattern frustration;
  final ChartArrowPattern success;
  final ChartArrowPattern spirituality;

  @override
  List<Object?> get props => <Object?>[
    determination,
    planning,
    willpower,
    activity,
    sensitivity,
    frustration,
    success,
    spirituality,
  ];
}

class DominantNumber extends Equatable {
  const DominantNumber({required this.number, required this.count});

  final int number;
  final int count;

  @override
  List<Object?> get props => <Object?>[number, count];
}

enum LifeCycleStatus { passed, active, future }

class LifeCycleContent extends Equatable {
  const LifeCycleContent({
    required this.theme,
    required this.description,
    required this.opportunities,
    required this.advice,
  });

  factory LifeCycleContent.fromJson(Map<String, dynamic> json) {
    return LifeCycleContent(
      theme: (json['theme'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      opportunities: (json['opportunities'] as String? ?? '').trim(),
      advice: (json['advice'] as String? ?? '').trim(),
    );
  }

  final String theme;
  final String description;
  final String opportunities;
  final String advice;

  @override
  List<Object?> get props => <Object?>[
    theme,
    description,
    opportunities,
    advice,
  ];
}

class PinnacleCycle extends Equatable {
  const PinnacleCycle({
    required this.number,
    required this.startAge,
    required this.endAge,
    required this.period,
    required this.status,
  });

  final int number;
  final int startAge;
  final int endAge;
  final String period;
  final LifeCycleStatus status;

  @override
  List<Object?> get props => <Object?>[
    number,
    startAge,
    endAge,
    period,
    status,
  ];
}

class ChallengeCycle extends Equatable {
  const ChallengeCycle({
    required this.number,
    required this.startAge,
    required this.endAge,
    required this.period,
    required this.status,
  });

  final int number;
  final int startAge;
  final int endAge;
  final String period;
  final LifeCycleStatus status;

  @override
  List<Object?> get props => <Object?>[
    number,
    startAge,
    endAge,
    period,
    status,
  ];
}
