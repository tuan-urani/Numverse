import 'package:flutter_test/flutter_test.dart';
import 'package:test/src/helper/compatibility_scoring.dart';

void main() {
  test('compatibility scoring keeps legacy weighting behavior', () {
    final CompatibilityScoreBreakdown score = CompatibilityScoring.calculate(
      selfLifePath: 7,
      selfExpression: 3,
      selfPersonality: 5,
      selfSoul: 2,
      targetLifePath: 9,
      targetExpression: 6,
      targetPersonality: 3,
      targetSoul: 6,
    );

    expect(score.core, 84);
    expect(score.communication, 80);
    expect(score.soul, 72);
    expect(score.personality, 84);
    expect(score.overall, 79);
    expect(score.band, 'good');
  });

  test('pairScore clamps difference and maps to score map', () {
    expect(CompatibilityScoring.pairScore(1, 1), 96);
    expect(CompatibilityScoring.pairScore(1, 9), 48);
    expect(CompatibilityScoring.pairScore(1, 99), 48);
  });
}
