import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:test/src/core/model/user_profile.dart';
import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/helper/birth_chart_content_resolver.dart';
import 'package:test/src/helper/numerology_helper.dart';
import 'package:test/src/ui/chart_matrix/interactor/chart_matrix_event.dart';
import 'package:test/src/ui/chart_matrix/interactor/chart_matrix_state.dart';

class ChartMatrixBloc extends Bloc<ChartMatrixEvent, ChartMatrixState> {
  ChartMatrixBloc({required INumerologyContentRepository contentRepository})
    : _contentRepository = contentRepository,
      super(ChartMatrixState.initial()) {
    on<ChartMatrixProfileSynced>(_onProfileSynced);
    on<ChartMatrixBirthChartToggled>(_onBirthChartToggled);
    on<ChartMatrixNameChartToggled>(_onNameChartToggled);
  }

  final INumerologyContentRepository _contentRepository;

  void syncProfile(UserProfile? profile, {required String languageCode}) {
    add(ChartMatrixProfileSynced(profile: profile, languageCode: languageCode));
  }

  void _onProfileSynced(
    ChartMatrixProfileSynced event,
    Emitter<ChartMatrixState> emit,
  ) {
    final UserProfile? profile = event.profile;
    final String languageCode = event.languageCode;
    if (profile == null) {
      emit(ChartMatrixState.initial());
      return;
    }

    final DateTime birthDate = profile.birthDate;
    final String formattedBirthDate = DateFormat(
      'dd/MM/yyyy',
    ).format(birthDate);

    final birthChart = NumerologyHelper.calculateBirthChart(birthDate);
    final birthAxes = NumerologyHelper.analyzeBirthChartAxes(birthChart);
    final birthArrows = NumerologyHelper.analyzeBirthChartArrows(birthChart);

    final nameChart = NumerologyHelper.calculateNameChart(profile.name);
    final nameAxes = NumerologyHelper.analyzeBirthChartAxes(nameChart);
    final nameArrows = NumerologyHelper.analyzeBirthChartArrows(nameChart);
    final nameDominantNumbers = NumerologyHelper.getDominantNumbers(nameChart);
    final birthChartData = _contentRepository.getBirthdayMatrixContent(
      languageCode: languageCode,
    );
    final nameChartData = _contentRepository.getNameMatrixContent(
      languageCode: languageCode,
    );
    final BirthChartResolvedContent birthResolvedContent =
        BirthChartContentResolver.resolve(
          chart: birthChart,
          axes: birthAxes,
          arrows: birthArrows,
          data: birthChartData,
        );
    final BirthChartResolvedContent nameResolvedContent =
        BirthChartContentResolver.resolve(
          chart: nameChart,
          axes: nameAxes,
          arrows: nameArrows,
          data: nameChartData,
        );

    emit(
      state.copyWith(
        hasProfile: true,
        profileName: profile.name,
        formattedBirthDate: formattedBirthDate,
        birthChart: birthChart,
        birthAxes: birthAxes,
        birthArrows: birthArrows,
        birthChartData: birthChartData,
        birthResolvedContent: birthResolvedContent,
        nameChart: nameChart,
        nameAxes: nameAxes,
        nameChartData: nameChartData,
        nameResolvedContent: nameResolvedContent,
        nameDominantNumbers: nameDominantNumbers,
      ),
    );
  }

  void toggleBirthChart() {
    add(const ChartMatrixBirthChartToggled());
  }

  void _onBirthChartToggled(
    ChartMatrixBirthChartToggled event,
    Emitter<ChartMatrixState> emit,
  ) {
    final bool willExpand = !state.expandedBirthChart;
    emit(
      state.copyWith(expandedBirthChart: willExpand, expandedNameChart: false),
    );
  }

  void toggleNameChart() {
    add(const ChartMatrixNameChartToggled());
  }

  void _onNameChartToggled(
    ChartMatrixNameChartToggled event,
    Emitter<ChartMatrixState> emit,
  ) {
    final bool willExpand = !state.expandedNameChart;
    emit(
      state.copyWith(expandedNameChart: willExpand, expandedBirthChart: false),
    );
  }
}
