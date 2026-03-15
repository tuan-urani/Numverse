import 'package:equatable/equatable.dart';

class LuckyNumberState extends Equatable {
  const LuckyNumberState({
    required this.formattedDate,
    required this.luckyNumber,
    required this.title,
    required this.message,
    required this.meaning,
    required this.howToUse,
    required this.situations,
  });

  final String formattedDate;
  final int luckyNumber;
  final String title;
  final String message;
  final String meaning;
  final List<String> howToUse;
  final List<String> situations;

  @override
  List<Object?> get props => <Object?>[
    formattedDate,
    luckyNumber,
    title,
    message,
    meaning,
    howToUse,
    situations,
  ];
}
