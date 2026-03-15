class CompatibilityScoreBreakdown {
  const CompatibilityScoreBreakdown({
    required this.overall,
    required this.core,
    required this.communication,
    required this.soul,
    required this.personality,
  });

  final int overall;
  final int core;
  final int communication;
  final int soul;
  final int personality;

  String get band {
    if (overall >= 80) {
      return 'excellent';
    }
    if (overall >= 70) {
      return 'good';
    }
    if (overall >= 60) {
      return 'moderate';
    }
    return 'effort';
  }
}

class CompatibilityScoring {
  CompatibilityScoring._();

  static CompatibilityScoreBreakdown calculate({
    required int selfLifePath,
    required int selfExpression,
    required int selfPersonality,
    required int selfSoul,
    required int targetLifePath,
    required int targetExpression,
    required int targetPersonality,
    required int targetSoul,
  }) {
    final int coreScore = pairScore(selfLifePath, targetLifePath);
    final int communicationScore = _blendTwoScores(
      pairScore(selfExpression, targetExpression),
      pairScore(selfPersonality, targetPersonality),
      firstWeight: 0.6,
      secondWeight: 0.4,
    );
    final int soulScore = pairScore(selfSoul, targetSoul);
    final int personalityScore = pairScore(selfPersonality, targetPersonality);

    final int overallScore = _blendFourScores(
      coreScore,
      communicationScore,
      soulScore,
      personalityScore,
      weights: const <double>[0.3, 0.25, 0.3, 0.15],
    );

    return CompatibilityScoreBreakdown(
      overall: overallScore,
      core: coreScore,
      communication: communicationScore,
      soul: soulScore,
      personality: personalityScore,
    );
  }

  static int pairScore(int first, int second) {
    const List<int> scoreMap = <int>[96, 90, 84, 78, 72, 66, 60, 54, 48];
    final int diff = (first - second).abs().clamp(0, 8);
    return scoreMap[diff];
  }

  static int _blendTwoScores(
    int first,
    int second, {
    double firstWeight = 0.5,
    double secondWeight = 0.5,
  }) {
    return ((first * firstWeight) + (second * secondWeight)).round();
  }

  static int _blendFourScores(
    int first,
    int second,
    int third,
    int fourth, {
    required List<double> weights,
  }) {
    return ((first * weights[0]) +
            (second * weights[1]) +
            (third * weights[2]) +
            (fourth * weights[3]))
        .round();
  }
}
