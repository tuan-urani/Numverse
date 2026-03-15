import 'package:flutter_test/flutter_test.dart';

import 'package:test/src/core/model/numerology_reading_models.dart';
import 'package:test/src/helper/birth_chart_content_resolver.dart';

void main() {
  test('resolver maps number/axis/arrow content by computed facts', () {
    final BirthChartGrid chart = BirthChartGrid(
      grid: const <List<int?>>[
        <int?>[null, null, null],
        <int?>[null, null, null],
        <int?>[null, null, null],
      ],
      numbers: const <int, int>{
        1: 2,
        2: 1,
        3: 0,
        4: 1,
        5: 0,
        6: 0,
        7: 1,
        8: 0,
        9: 1,
      },
      presentNumbers: const <int>[1, 2, 4, 7, 9],
      missingNumbers: const <int>[3, 5, 6, 8],
    );

    final BirthChartAxes axes = BirthChartAxes(
      physical: const ChartAxisScore(
        present: false,
        numbers: <int>[1, 4, 7],
        count: 2,
      ),
      mental: const ChartAxisScore(
        present: false,
        numbers: <int>[3, 6, 9],
        count: 1,
      ),
      emotional: const ChartAxisScore(
        present: false,
        numbers: <int>[2, 5, 8],
        count: 1,
      ),
    );

    const BirthChartArrows arrows = BirthChartArrows(
      determination: ChartArrowPattern(present: true, numbers: <int>[3, 5, 7]),
      planning: ChartArrowPattern(present: false, numbers: <int>[1, 2, 3]),
      willpower: ChartArrowPattern(present: false, numbers: <int>[4, 5, 6]),
      activity: ChartArrowPattern(present: true, numbers: <int>[1, 5, 9]),
      sensitivity: ChartArrowPattern(present: false, numbers: <int>[3, 6, 9]),
      frustration: ChartArrowPattern(present: true, numbers: <int>[4, 5, 6]),
      success: ChartArrowPattern(present: false, numbers: <int>[7, 8, 9]),
      spirituality: ChartArrowPattern(present: true, numbers: <int>[1, 5, 9]),
    );

    const BirthChartDataSet dataSet = BirthChartDataSet(
      numbers: <int, ChartNumberMeaning>{
        1: ChartNumberMeaning(
          strength: 'strength-1',
          lesson: 'lesson-1',
          strengthByCount: <String, String>{'2_plus': 'strength-1-2plus'},
        ),
        3: ChartNumberMeaning(
          strength: 'strength-3',
          lesson: 'lesson-3',
          lessonByCount: <String, String>{'0': 'lesson-3-missing'},
        ),
      },
      physicalAxis: ChartAxisMeaning(
        name: 'physical',
        description: '',
        presentDescription: 'physical-present',
        missingDescription: 'physical-missing',
        descriptionByCount: <String, String>{'2': 'physical-two'},
      ),
      mentalAxis: ChartAxisMeaning(
        name: 'mental',
        description: '',
        presentDescription: 'mental-present',
        missingDescription: 'mental-missing',
        descriptionByCount: <String, String>{'1': 'mental-one'},
      ),
      emotionalAxis: ChartAxisMeaning(
        name: 'emotional',
        description: '',
        presentDescription: 'emotional-present',
        missingDescription: 'emotional-missing',
        descriptionByCount: <String, String>{'1': 'emotional-one'},
      ),
      arrows: <String, ChartArrowMeaning>{
        'determination': ChartArrowMeaning(
          key: 'determination',
          title: 'Determination',
          presentDescription: 'determination-present',
          missingDescription: 'determination-missing',
          numbers: <int>[3, 5, 7],
        ),
        'frustration': ChartArrowMeaning(
          key: 'frustration',
          title: 'Frustration',
          presentDescription: 'frustration-present',
          missingDescription: 'frustration-missing',
          numbers: <int>[4, 5, 6],
        ),
      },
    );

    final BirthChartResolvedContent resolved =
        BirthChartContentResolver.resolve(
          chart: chart,
          axes: axes,
          arrows: arrows,
          data: dataSet,
        );

    expect(resolved.strengthByNumber[1], 'strength-1-2plus');
    expect(resolved.lessonByNumber[3], 'lesson-3-missing');
    expect(resolved.axisDescriptionByKey['physical'], 'physical-two');
    expect(resolved.axisDescriptionByKey['mental'], 'mental-one');
    expect(resolved.axisDescriptionByKey['emotional'], 'emotional-one');

    expect(resolved.activeArrows.length, 2);
    expect(resolved.activeArrows.first.key, 'determination');
    expect(resolved.activeArrows.first.text, 'determination-present');
    expect(resolved.activeArrows.last.key, 'frustration');
    expect(resolved.activeArrows.last.text, 'frustration-present');
    expect(resolved.inactiveArrows, isEmpty);
  });
}
