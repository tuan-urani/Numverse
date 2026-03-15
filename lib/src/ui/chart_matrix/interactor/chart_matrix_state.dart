import 'package:equatable/equatable.dart';

import 'package:test/src/core/model/numerology_reading_models.dart';
import 'package:test/src/helper/birth_chart_content_resolver.dart';

class ChartMatrixState extends Equatable {
  const ChartMatrixState({
    required this.hasProfile,
    required this.profileName,
    required this.formattedBirthDate,
    required this.birthChart,
    required this.birthAxes,
    required this.birthArrows,
    required this.birthChartData,
    required this.birthResolvedContent,
    required this.nameChart,
    required this.nameAxes,
    required this.nameChartData,
    required this.nameResolvedContent,
    required this.nameDominantNumbers,
    required this.expandedBirthChart,
    required this.expandedNameChart,
  });

  factory ChartMatrixState.initial() {
    return ChartMatrixState(
      hasProfile: false,
      profileName: '',
      formattedBirthDate: '',
      birthChart: _emptyChart(),
      birthAxes: _emptyAxes(),
      birthArrows: _emptyArrows(),
      birthChartData: _emptyDataSet(),
      birthResolvedContent: const BirthChartResolvedContent(),
      nameChart: _emptyChart(),
      nameAxes: _emptyAxes(),
      nameChartData: _emptyDataSet(),
      nameResolvedContent: const BirthChartResolvedContent(),
      nameDominantNumbers: const <DominantNumber>[],
      expandedBirthChart: true,
      expandedNameChart: false,
    );
  }

  final bool hasProfile;
  final String profileName;
  final String formattedBirthDate;
  final BirthChartGrid birthChart;
  final BirthChartAxes birthAxes;
  final BirthChartArrows birthArrows;
  final BirthChartDataSet birthChartData;
  final BirthChartResolvedContent birthResolvedContent;
  final BirthChartGrid nameChart;
  final BirthChartAxes nameAxes;
  final BirthChartDataSet nameChartData;
  final BirthChartResolvedContent nameResolvedContent;
  final List<DominantNumber> nameDominantNumbers;
  final bool expandedBirthChart;
  final bool expandedNameChart;

  ChartMatrixState copyWith({
    bool? hasProfile,
    String? profileName,
    String? formattedBirthDate,
    BirthChartGrid? birthChart,
    BirthChartAxes? birthAxes,
    BirthChartArrows? birthArrows,
    BirthChartDataSet? birthChartData,
    BirthChartResolvedContent? birthResolvedContent,
    BirthChartGrid? nameChart,
    BirthChartAxes? nameAxes,
    BirthChartDataSet? nameChartData,
    BirthChartResolvedContent? nameResolvedContent,
    List<DominantNumber>? nameDominantNumbers,
    bool? expandedBirthChart,
    bool? expandedNameChart,
  }) {
    return ChartMatrixState(
      hasProfile: hasProfile ?? this.hasProfile,
      profileName: profileName ?? this.profileName,
      formattedBirthDate: formattedBirthDate ?? this.formattedBirthDate,
      birthChart: birthChart ?? this.birthChart,
      birthAxes: birthAxes ?? this.birthAxes,
      birthArrows: birthArrows ?? this.birthArrows,
      birthChartData: birthChartData ?? this.birthChartData,
      birthResolvedContent: birthResolvedContent ?? this.birthResolvedContent,
      nameChart: nameChart ?? this.nameChart,
      nameAxes: nameAxes ?? this.nameAxes,
      nameChartData: nameChartData ?? this.nameChartData,
      nameResolvedContent: nameResolvedContent ?? this.nameResolvedContent,
      nameDominantNumbers: nameDominantNumbers ?? this.nameDominantNumbers,
      expandedBirthChart: expandedBirthChart ?? this.expandedBirthChart,
      expandedNameChart: expandedNameChart ?? this.expandedNameChart,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    hasProfile,
    profileName,
    formattedBirthDate,
    birthChart,
    birthAxes,
    birthArrows,
    birthChartData,
    birthResolvedContent,
    nameChart,
    nameAxes,
    nameChartData,
    nameResolvedContent,
    nameDominantNumbers,
    expandedBirthChart,
    expandedNameChart,
  ];

  static BirthChartGrid _emptyChart() {
    return const BirthChartGrid(
      grid: <List<int?>>[
        <int?>[null, null, null],
        <int?>[null, null, null],
        <int?>[null, null, null],
      ],
      numbers: <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0, 8: 0, 9: 0},
      presentNumbers: <int>[],
      missingNumbers: <int>[1, 2, 3, 4, 5, 6, 7, 8, 9],
    );
  }

  static BirthChartAxes _emptyAxes() {
    const ChartAxisScore zero = ChartAxisScore(
      present: false,
      numbers: <int>[],
      count: 0,
    );
    return const BirthChartAxes(physical: zero, mental: zero, emotional: zero);
  }

  static BirthChartArrows _emptyArrows() {
    const ChartArrowPattern pattern = ChartArrowPattern(
      present: false,
      numbers: <int>[],
    );
    return const BirthChartArrows(
      determination: pattern,
      planning: pattern,
      willpower: pattern,
      activity: pattern,
      sensitivity: pattern,
      frustration: pattern,
      success: pattern,
      spirituality: pattern,
    );
  }

  static BirthChartDataSet _emptyDataSet() {
    const ChartAxisMeaning emptyAxis = ChartAxisMeaning(
      name: '',
      description: '',
      presentDescription: '',
      missingDescription: '',
    );
    return const BirthChartDataSet(
      numbers: <int, ChartNumberMeaning>{},
      physicalAxis: emptyAxis,
      mentalAxis: emptyAxis,
      emotionalAxis: emptyAxis,
    );
  }
}
