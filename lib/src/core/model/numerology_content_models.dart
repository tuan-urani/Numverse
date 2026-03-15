class NumerologyUniversalDayContent {
  const NumerologyUniversalDayContent({
    required this.title,
    required this.energyTheme,
    required this.keywords,
    required this.meaning,
    required this.energyManifestation,
  });

  factory NumerologyUniversalDayContent.fromJson(Map<String, dynamic> json) {
    String firstStringInList(Object? raw) {
      final List<String> list = switch (raw) {
        List<dynamic>() =>
          raw
              .whereType<String>()
              .map((String value) => value.trim())
              .where((String value) => value.isNotEmpty)
              .toList(growable: false),
        String() when raw.trim().isNotEmpty => <String>[raw.trim()],
        _ => const <String>[],
      };
      return list.isEmpty ? '' : list.first;
    }

    return NumerologyUniversalDayContent(
      title: (json['title'] as String? ?? '').trim(),
      energyTheme:
          (json['energy_theme'] as String? ?? firstStringInList(json['advice']))
              .trim(),
      keywords: (json['keywords'] as List<dynamic>)
          .map((dynamic keyword) {
            return keyword as String;
          })
          .toList(growable: false),
      meaning: (json['meaning'] as String? ?? '').trim(),
      energyManifestation:
          (json['energy_manifestation'] as String? ??
                  firstStringInList(json['tips']))
              .trim(),
    );
  }

  final String title;
  final String energyTheme;
  final List<String> keywords;
  final String meaning;
  final String energyManifestation;

  @override
  String toString() {
    return 'NumerologyUniversalDayContent('
        'title: $title, '
        'energyTheme: $energyTheme, '
        'keywords: $keywords, '
        'meaning: $meaning, '
        'energyManifestation: $energyManifestation'
        ')';
  }
}

class NumerologyDailyMessageTemplate {
  const NumerologyDailyMessageTemplate({
    required this.mainMessage,
    required this.subMessage,
    required this.hintAction,
    required this.thinking,
    required this.tips,
  });

  factory NumerologyDailyMessageTemplate.fromJson(Map<String, dynamic> json) {
    final Object? rawTips = json['tips'];
    final List<String> tipsList = switch (rawTips) {
      List<dynamic>() =>
        rawTips
            .whereType<String>()
            .map((String value) => value.trim())
            .where((String value) => value.isNotEmpty)
            .toList(growable: false),
      String() when rawTips.trim().isNotEmpty => <String>[rawTips.trim()],
      _ => const <String>[],
    };

    return NumerologyDailyMessageTemplate(
      mainMessage: json['main_message'] as String,
      subMessage: json['sub_message'] as String,
      hintAction: json['hint_action'] as String,
      thinking: (json['thinking'] as String? ?? '').trim(),
      tips: tipsList,
    );
  }

  final String mainMessage;
  final String subMessage;
  final String hintAction;
  final String thinking;
  final List<String> tips;

  @override
  String toString() {
    return 'NumerologyDailyMessageTemplate('
        'mainMessage: $mainMessage, '
        'subMessage: $subMessage, '
        'hintAction: $hintAction, '
        'thinking: $thinking, '
        'tips: $tips'
        ')';
  }
}

class NumerologyLuckyNumberContent {
  const NumerologyLuckyNumberContent({
    required this.title,
    required this.message,
    required this.meaning,
    required this.howToUse,
    required this.situations,
  });

  factory NumerologyLuckyNumberContent.fromJson(Map<String, dynamic> json) {
    final List<String> howToUse = _parseStringList(json['how_to_use']);
    return NumerologyLuckyNumberContent(
      title: (json['title'] as String? ?? '').trim(),
      message: (json['message'] as String? ?? '').trim(),
      meaning:
          (json['meaning'] as String? ?? json['description'] as String? ?? '')
              .trim(),
      howToUse: howToUse.isNotEmpty
          ? howToUse
          : _parseStringList(json['actions']),
      situations: _parseStringList(json['situations']),
    );
  }

  final String title;
  final String message;
  final String meaning;
  final List<String> howToUse;
  final List<String> situations;

  @override
  String toString() {
    return 'NumerologyLuckyNumberContent('
        'title: $title, '
        'message: $message, '
        'meaning: $meaning, '
        'howToUse: $howToUse, '
        'situations: $situations'
        ')';
  }

  static List<String> _parseStringList(Object? value) {
    final List<String> list = switch (value) {
      List<dynamic>() =>
        value
            .whereType<String>()
            .map((String item) => item.trim())
            .where((String item) => item.isNotEmpty)
            .toList(growable: false),
      String() when value.trim().isNotEmpty => <String>[value.trim()],
      _ => const <String>[],
    };
    return list;
  }
}

class NumerologyAngelNumberContent {
  const NumerologyAngelNumberContent({
    required this.title,
    required this.coreMeanings,
    required this.universeMessages,
    required this.guidance,
  });

  factory NumerologyAngelNumberContent.fromJson(Map<String, dynamic> json) {
    return NumerologyAngelNumberContent(
      title: (json['title'] as String? ?? '').trim(),
      coreMeanings: _parseStringList(json['core_meanings']),
      universeMessages: _parseStringList(json['universe_messages']),
      guidance: _parseStringList(json['guidance']),
    );
  }

  final String title;
  final List<String> coreMeanings;
  final List<String> universeMessages;
  final List<String> guidance;

  @override
  String toString() {
    return 'NumerologyAngelNumberContent('
        'title: $title, '
        'coreMeanings: $coreMeanings, '
        'universeMessages: $universeMessages, '
        'guidance: $guidance'
        ')';
  }

  static List<String> _parseStringList(Object? value) {
    final List<String> list = switch (value) {
      List<dynamic>() =>
        value
            .whereType<String>()
            .map((String item) => item.trim())
            .where((String item) => item.isNotEmpty)
            .toList(growable: false),
      String() when value.trim().isNotEmpty => <String>[value.trim()],
      _ => const <String>[],
    };
    return list;
  }
}

class NumerologyNumberLibraryContent {
  const NumerologyNumberLibraryContent({
    required this.title,
    required this.description,
    required this.keywords,
    required this.symbolism,
  });

  factory NumerologyNumberLibraryContent.fromJson(Map<String, dynamic> json) {
    return NumerologyNumberLibraryContent(
      title: (json['title'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      keywords: _parseStringList(json['keywords']),
      symbolism: (json['symbolism'] as String? ?? '').trim(),
    );
  }

  final String title;
  final String description;
  final List<String> keywords;
  final String symbolism;

  @override
  String toString() {
    return 'NumerologyNumberLibraryContent('
        'title: $title, '
        'description: $description, '
        'keywords: $keywords, '
        'symbolism: $symbolism'
        ')';
  }

  static List<String> _parseStringList(Object? value) {
    final List<String> list = switch (value) {
      List<dynamic>() =>
        value
            .whereType<String>()
            .map((String item) => item.trim())
            .where((String item) => item.isNotEmpty)
            .toList(growable: false),
      String() when value.trim().isNotEmpty => <String>[value.trim()],
      _ => const <String>[],
    };
    return list;
  }
}

class NumerologyTodayPersonalNumberContent {
  const NumerologyTodayPersonalNumberContent({
    required this.quote,
    required this.dailyRhythm,
    required this.detail,
    required this.hintActions,
    required this.shouldDoActions,
    required this.shouldAvoidActions,
  });

  factory NumerologyTodayPersonalNumberContent.fromJson(
    Map<String, dynamic> json,
  ) {
    return NumerologyTodayPersonalNumberContent(
      quote: (json['quote'] as String? ?? '').trim(),
      dailyRhythm:
          (json['daily_rhythm'] as String? ??
                  json['daily rhythm'] as String? ??
                  '')
              .trim(),
      detail: _parseStringList(json['detail']),
      hintActions: _parseStringList(
        json['hint_actions'] ?? json['hint actions'],
      ),
      shouldDoActions: _parseStringList(json['should_do'] ?? json['should do']),
      shouldAvoidActions: _parseStringList(
        json['should_avoid'] ?? json['should avoid'],
      ),
    );
  }

  final String quote;
  final String dailyRhythm;
  final List<String> detail;
  final List<String> hintActions;
  final List<String> shouldDoActions;
  final List<String> shouldAvoidActions;

  @override
  String toString() {
    return 'NumerologyTodayPersonalNumberContent('
        'quote: $quote, '
        'dailyRhythm: $dailyRhythm, '
        'detail: $detail, '
        'hintActions: $hintActions, '
        'shouldDoActions: $shouldDoActions, '
        'shouldAvoidActions: $shouldAvoidActions'
        ')';
  }

  static List<String> _parseStringList(Object? value) {
    final List<String> list = switch (value) {
      List<dynamic>() =>
        value
            .whereType<String>()
            .map((String item) => item.trim())
            .where((String item) => item.isNotEmpty)
            .toList(growable: false),
      String() when value.trim().isNotEmpty => <String>[value.trim()],
      _ => const <String>[],
    };
    return list;
  }
}

class NumerologyPersonalMonthStep {
  const NumerologyPersonalMonthStep({required this.title, required this.body});

  factory NumerologyPersonalMonthStep.fromJson(Map<String, dynamic> json) {
    return NumerologyPersonalMonthStep(
      title: (json['title'] as String? ?? '').trim(),
      body: (json['body'] as String? ?? '').trim(),
    );
  }

  final String title;
  final String body;

  @override
  String toString() {
    return 'NumerologyPersonalMonthStep(title: $title, body: $body)';
  }
}

class NumerologyPersonalMonthContent {
  const NumerologyPersonalMonthContent({
    required this.keyword,
    required this.heroTitle,
    required this.focus,
    required this.steps,
    required this.priorities,
    required this.cautions,
  });

  factory NumerologyPersonalMonthContent.fromJson(Map<String, dynamic> json) {
    final List<NumerologyPersonalMonthStep> steps = switch (json['steps']) {
      List<dynamic>() =>
        (json['steps'] as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(NumerologyPersonalMonthStep.fromJson)
            .toList(growable: false),
      _ => const <NumerologyPersonalMonthStep>[],
    };
    return NumerologyPersonalMonthContent(
      keyword: (json['keyword'] as String? ?? '').trim(),
      heroTitle:
          (json['hero_title'] as String? ?? json['hero title'] as String? ?? '')
              .trim(),
      focus: _parseStringList(json['focus']),
      steps: steps,
      priorities: _parseStringList(json['priorities']),
      cautions: _parseStringList(json['cautions']),
    );
  }

  final String keyword;
  final String heroTitle;
  final List<String> focus;
  final List<NumerologyPersonalMonthStep> steps;
  final List<String> priorities;
  final List<String> cautions;

  @override
  String toString() {
    return 'NumerologyPersonalMonthContent('
        'keyword: $keyword, '
        'heroTitle: $heroTitle, '
        'focus: $focus, '
        'steps: $steps, '
        'priorities: $priorities, '
        'cautions: $cautions'
        ')';
  }

  static List<String> _parseStringList(Object? value) {
    final List<String> list = switch (value) {
      List<dynamic>() =>
        value
            .whereType<String>()
            .map((String item) => item.trim())
            .where((String item) => item.isNotEmpty)
            .toList(growable: false),
      String() when value.trim().isNotEmpty => <String>[value.trim()],
      _ => const <String>[],
    };
    return list;
  }
}

class NumerologyPersonalYearContent {
  const NumerologyPersonalYearContent({
    required this.keyword,
    required this.heroTitle,
    required this.theme,
    required this.lessons,
    required this.focusAreas,
  });

  factory NumerologyPersonalYearContent.fromJson(Map<String, dynamic> json) {
    List<NumerologyPersonalMonthStep> parseSteps(Object? value) {
      return switch (value) {
        List<dynamic>() =>
          value
              .whereType<Map<String, dynamic>>()
              .map(NumerologyPersonalMonthStep.fromJson)
              .toList(growable: false),
        _ => const <NumerologyPersonalMonthStep>[],
      };
    }

    return NumerologyPersonalYearContent(
      keyword: (json['keyword'] as String? ?? '').trim(),
      heroTitle:
          (json['hero_title'] as String? ?? json['hero title'] as String? ?? '')
              .trim(),
      theme: _parseStringList(json['theme']),
      lessons: parseSteps(json['lessons']),
      focusAreas: parseSteps(json['focus_areas'] ?? json['focus areas']),
    );
  }

  final String keyword;
  final String heroTitle;
  final List<String> theme;
  final List<NumerologyPersonalMonthStep> lessons;
  final List<NumerologyPersonalMonthStep> focusAreas;

  @override
  String toString() {
    return 'NumerologyPersonalYearContent('
        'keyword: $keyword, '
        'heroTitle: $heroTitle, '
        'theme: $theme, '
        'lessons: $lessons, '
        'focusAreas: $focusAreas'
        ')';
  }

  static List<String> _parseStringList(Object? value) {
    final List<String> list = switch (value) {
      List<dynamic>() =>
        value
            .whereType<String>()
            .map((String item) => item.trim())
            .where((String item) => item.isNotEmpty)
            .toList(growable: false),
      String() when value.trim().isNotEmpty => <String>[value.trim()],
      _ => const <String>[],
    };
    return list;
  }
}

class NumerologyCompatibilityContent {
  const NumerologyCompatibilityContent({
    required this.strengths,
    required this.challenges,
    required this.advice,
    required this.quote,
  });

  factory NumerologyCompatibilityContent.fromJson(Map<String, dynamic> json) {
    return NumerologyCompatibilityContent(
      strengths: _parseStringList(json['strengths']),
      challenges: _parseStringList(json['challenges']),
      advice: _parseStringList(json['advice']),
      quote: (json['quote'] as String? ?? '').trim(),
    );
  }

  final List<String> strengths;
  final List<String> challenges;
  final List<String> advice;
  final String quote;

  static List<String> _parseStringList(Object? value) {
    final List<String> list = switch (value) {
      List<dynamic>() =>
        value
            .whereType<String>()
            .map((String item) => item.trim())
            .where((String item) => item.isNotEmpty)
            .toList(growable: false),
      String() when value.trim().isNotEmpty => <String>[value.trim()],
      _ => const <String>[],
    };
    return list;
  }
}
