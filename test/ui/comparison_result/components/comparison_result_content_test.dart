import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:test/src/ui/comparison_result/components/comparison_result_content.dart';
import 'package:test/src/ui/comparison_result/interactor/comparison_result_state.dart';

void main() {
  testWidgets(
    'renders collapsible aspect insight cards and keeps overall quote',
    (WidgetTester tester) async {
      const ComparisonResultState state = ComparisonResultState(
        languageCode: 'vi',
        selfProfileId: 'self-1',
        targetProfileId: 'target-1',
        selfName: 'An',
        selfDate: '01/01/1994',
        selfLifePath: 7,
        selfSoul: 5,
        selfPersonality: 3,
        selfExpression: 4,
        targetName: 'Binh',
        targetRelation: 'friend',
        targetDate: '03/06/1993',
        targetLifePath: 9,
        targetSoul: 6,
        targetPersonality: 8,
        targetExpression: 9,
        overallScore: 75,
        coreScore: 84,
        communicationScore: 77,
        expressionScore: 78,
        soulScore: 90,
        personalityScore: 66,
        strengths: <String>['overall strength'],
        challenges: <String>['overall challenge'],
        advice: <String>['overall advice'],
        quote: 'overall quote',
        lifePathInsight: ComparisonAspectInsight(
          strengths: <String>['lp strength'],
          challenges: <String>['lp challenge'],
          advice: <String>['lp advice'],
          quote: 'lp quote',
        ),
        expressionInsight: ComparisonAspectInsight(
          strengths: <String>['expression strength'],
          challenges: <String>['expression challenge'],
          advice: <String>['expression advice'],
          quote: 'expression quote',
        ),
        soulInsight: ComparisonAspectInsight(
          strengths: <String>['soul strength'],
          challenges: <String>['soul challenge'],
          advice: <String>['soul advice'],
          quote: 'soul quote',
        ),
        personalityInsight: ComparisonAspectInsight(
          strengths: <String>['personality strength'],
          challenges: <String>['personality challenge'],
          advice: <String>['personality advice'],
          quote: 'personality quote',
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ComparisonResultContent(state: state),
            ),
          ),
        ),
      );

      expect(find.text('overall quote'), findsOneWidget);
      expect(find.text('lp quote'), findsNothing);
      expect(find.text('expression quote'), findsNothing);
      expect(find.text('soul quote'), findsNothing);
      expect(find.text('personality quote'), findsNothing);

      final Finder collapseToggles = find.byIcon(Icons.expand_more_rounded);
      expect(collapseToggles, findsNWidgets(4));

      await tester.tap(collapseToggles.at(0));
      await tester.pump(const Duration(milliseconds: 260));
      expect(find.text('lp quote'), findsOneWidget);

      await tester.tap(collapseToggles.at(1));
      await tester.pump(const Duration(milliseconds: 260));
      expect(find.text('expression quote'), findsOneWidget);

      await tester.ensureVisible(collapseToggles.at(2));
      await tester.tap(collapseToggles.at(2));
      await tester.pump(const Duration(milliseconds: 260));
      expect(find.text('soul quote'), findsOneWidget);

      await tester.ensureVisible(collapseToggles.at(3));
      await tester.tap(collapseToggles.at(3));
      await tester.pump(const Duration(milliseconds: 260));
      expect(find.text('personality quote'), findsOneWidget);
    },
  );
}
