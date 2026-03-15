import 'package:equatable/equatable.dart';

import 'package:test/src/core/model/user_profile.dart';

sealed class ChartMatrixEvent extends Equatable {
  const ChartMatrixEvent();
}

final class ChartMatrixProfileSynced extends ChartMatrixEvent {
  const ChartMatrixProfileSynced({
    required this.profile,
    required this.languageCode,
  });

  final UserProfile? profile;
  final String languageCode;

  @override
  List<Object?> get props => <Object?>[profile, languageCode];
}

final class ChartMatrixBirthChartToggled extends ChartMatrixEvent {
  const ChartMatrixBirthChartToggled();

  @override
  List<Object?> get props => <Object?>[];
}

final class ChartMatrixNameChartToggled extends ChartMatrixEvent {
  const ChartMatrixNameChartToggled();

  @override
  List<Object?> get props => <Object?>[];
}
