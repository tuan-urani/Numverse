import 'package:equatable/equatable.dart';

class UniversalDayState extends Equatable {
  const UniversalDayState({
    required this.formattedDate,
    required this.dayNumber,
    required this.numberTitle,
    required this.energyTheme,
    required this.keywords,
    required this.meaning,
    required this.energyManifestation,
  });

  final String formattedDate;
  final int dayNumber;
  final String numberTitle;
  final String energyTheme;
  final List<String> keywords;
  final String meaning;
  final String energyManifestation;

  @override
  List<Object?> get props => <Object?>[
    formattedDate,
    dayNumber,
    numberTitle,
    energyTheme,
    keywords,
    meaning,
    energyManifestation,
  ];
}
