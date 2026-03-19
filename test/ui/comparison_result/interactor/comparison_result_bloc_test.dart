import 'package:flutter_test/flutter_test.dart';
import 'package:test/src/core/model/comparison_profile.dart';
import 'package:test/src/core/model/compatibility_aspect.dart';
import 'package:test/src/core/model/compatibility_history_item.dart';
import 'package:test/src/core/model/numerology_content_models.dart';
import 'package:test/src/core/model/user_profile.dart';
import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/helper/compatibility_scoring.dart';
import 'package:test/src/helper/numerology_helper.dart';
import 'package:test/src/ui/comparison_result/interactor/comparison_result_bloc.dart';

class _FakeNumerologyContentRepository implements INumerologyContentRepository {
  @override
  NumerologyCompatibilityContent getCompatibilityContent({
    required int overallScore,
    required String languageCode,
  }) {
    final String band = _band(overallScore);
    return NumerologyCompatibilityContent(
      strengths: <String>['overall-$band-strength'],
      challenges: <String>['overall-$band-challenge'],
      advice: <String>['overall-$band-advice'],
      quote: 'overall-$band-quote',
    );
  }

  @override
  NumerologyCompatibilityContent getCompatibilityAspectContent({
    required CompatibilityAspect aspect,
    required int score,
    required String languageCode,
  }) {
    final String band = _band(score);
    return NumerologyCompatibilityContent(
      strengths: <String>['${aspect.storageKey}-$band-strength'],
      challenges: <String>['${aspect.storageKey}-$band-challenge'],
      advice: <String>['${aspect.storageKey}-$band-advice'],
      quote: '${aspect.storageKey}-$band-quote',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }

  String _band(int score) {
    if (score >= 80) {
      return 'excellent';
    }
    if (score >= 70) {
      return 'good';
    }
    if (score >= 60) {
      return 'moderate';
    }
    return 'effort';
  }
}

void main() {
  group('ComparisonResultBloc', () {
    test('load resolves aspect insights from per-aspect score bands', () async {
      final ComparisonResultBloc bloc = ComparisonResultBloc(
        contentRepository: _FakeNumerologyContentRepository(),
      );
      final UserProfile selfProfile = UserProfile(
        id: 'self-1',
        name: 'An Nguyen',
        birthDate: DateTime(1994, 2, 1),
        createdAt: DateTime(2026, 3, 19),
      );
      final ComparisonProfile targetProfile = ComparisonProfile(
        id: 'target-1',
        name: 'Binh Tran',
        relation: 'friend',
        birthDate: DateTime(1993, 6, 3),
        lifePathNumber: NumerologyHelper.getLifePathNumber(
          DateTime(1993, 6, 3),
        ),
      );

      bloc.load(
        selfProfile: selfProfile,
        targetProfile: targetProfile,
        languageCode: 'vi',
      );
      await Future<void>.delayed(Duration.zero);

      final int expectedExpressionScore = CompatibilityScoring.pairScore(
        NumerologyHelper.getExpressionNumber(selfProfile.name),
        NumerologyHelper.getExpressionNumber(targetProfile.name),
      );
      final String expectedExpressionBand = _band(expectedExpressionScore);
      final String expectedLifePathBand = _band(bloc.state.coreScore);

      expect(bloc.state.expressionScore, expectedExpressionScore);
      expect(
        bloc.state.expressionInsight.quote,
        'expression-$expectedExpressionBand-quote',
      );
      expect(
        bloc.state.lifePathInsight.quote,
        'life_path-$expectedLifePathBand-quote',
      );
    });

    test(
      'loadFromHistory resolves per-aspect insight from history numbers',
      () async {
        final ComparisonResultBloc bloc = ComparisonResultBloc(
          contentRepository: _FakeNumerologyContentRepository(),
        );
        final CompatibilityHistoryItem item = CompatibilityHistoryItem(
          id: 'history-1',
          requestId: 'req-1',
          primaryProfileId: 'self-1',
          primaryName: 'A',
          primaryBirthDate: DateTime(1994, 1, 2),
          primaryLifePath: 7,
          primarySoul: 5,
          primaryPersonality: 3,
          primaryExpression: 4,
          targetProfileId: 'target-1',
          targetName: 'B',
          targetRelation: 'friend',
          targetBirthDate: DateTime(1990, 2, 3),
          targetLifePath: 9,
          targetSoul: 6,
          targetPersonality: 8,
          targetExpression: 9,
          overallScore: 75,
          coreScore: 84,
          communicationScore: 77,
          soulScore: 90,
          personalityScore: 66,
          createdAt: DateTime(2026, 3, 19),
        );

        bloc.loadFromHistory(item: item, languageCode: 'vi');
        await Future<void>.delayed(Duration.zero);

        final int expectedExpressionScore = CompatibilityScoring.pairScore(
          item.primaryExpression,
          item.targetExpression,
        );

        expect(bloc.state.expressionScore, expectedExpressionScore);
        expect(
          bloc.state.expressionInsight.quote,
          'expression-${_band(expectedExpressionScore)}-quote',
        );
        expect(bloc.state.soulInsight.quote, 'soul-excellent-quote');
        expect(
          bloc.state.personalityInsight.quote,
          'personality-moderate-quote',
        );
      },
    );
  });
}

String _band(int score) {
  if (score >= 80) {
    return 'excellent';
  }
  if (score >= 70) {
    return 'good';
  }
  if (score >= 60) {
    return 'moderate';
  }
  return 'effort';
}
