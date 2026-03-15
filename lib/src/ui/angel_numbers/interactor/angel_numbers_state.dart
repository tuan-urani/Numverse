import 'package:equatable/equatable.dart';

class AngelNumberMeaning extends Equatable {
  const AngelNumberMeaning({
    required this.title,
    required this.coreMeanings,
    required this.universeMessages,
    required this.guidance,
  });

  final String title;
  final List<String> coreMeanings;
  final List<String> universeMessages;
  final List<String> guidance;

  @override
  List<Object?> get props => <Object?>[
    title,
    coreMeanings,
    universeMessages,
    guidance,
  ];
}

class AngelNumbersState extends Equatable {
  const AngelNumbersState({
    required this.searchText,
    required this.displayNumber,
    required this.result,
    required this.hasSearched,
    required this.popularNumbers,
    required this.showInputError,
  });

  factory AngelNumbersState.initial({List<String>? popularNumbers}) {
    return const AngelNumbersState(
      searchText: '',
      displayNumber: '',
      result: null,
      hasSearched: false,
      popularNumbers: <String>[],
      showInputError: false,
    ).copyWith(
      popularNumbers: popularNumbers ?? const <String>['111', '222', '333'],
    );
  }

  final String searchText;
  final String displayNumber;
  final AngelNumberMeaning? result;
  final bool hasSearched;
  final List<String> popularNumbers;
  final bool showInputError;

  bool get hasResult => result != null && displayNumber.isNotEmpty;

  AngelNumbersState copyWith({
    String? searchText,
    String? displayNumber,
    AngelNumberMeaning? result,
    bool clearResult = false,
    bool? hasSearched,
    List<String>? popularNumbers,
    bool? showInputError,
  }) {
    return AngelNumbersState(
      searchText: searchText ?? this.searchText,
      displayNumber: displayNumber ?? this.displayNumber,
      result: clearResult ? null : (result ?? this.result),
      hasSearched: hasSearched ?? this.hasSearched,
      popularNumbers: popularNumbers ?? this.popularNumbers,
      showInputError: showInputError ?? this.showInputError,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    searchText,
    displayNumber,
    result,
    hasSearched,
    popularNumbers,
    showInputError,
  ];
}
