import 'package:equatable/equatable.dart';

class DailyMessageState extends Equatable {
  const DailyMessageState({
    required this.formattedDate,
    required this.dayNumber,
    required this.mainMessage,
    required this.subMessage,
    required this.hintAction,
    required this.thinking,
    required this.tips,
  });

  final String formattedDate;
  final int dayNumber;
  final String mainMessage;
  final String subMessage;
  final String hintAction;
  final String thinking;
  final List<String> tips;

  @override
  List<Object?> get props => <Object?>[
    formattedDate,
    dayNumber,
    mainMessage,
    subMessage,
    hintAction,
    thinking,
    tips,
  ];
}
