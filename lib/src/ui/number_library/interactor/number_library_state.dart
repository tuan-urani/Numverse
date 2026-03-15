import 'package:equatable/equatable.dart';

import 'package:test/src/core/model/numerology_content_models.dart';

class NumberLibraryState extends Equatable {
  const NumberLibraryState({
    required this.basicNumbers,
    required this.masterNumbers,
    required this.isBasicNumbersExpanded,
    required this.isMasterNumbersExpanded,
    required this.selectedNumber,
    required this.selectedMeaning,
  });

  factory NumberLibraryState.initial({
    List<int>? basicNumbers,
    List<int>? masterNumbers,
  }) {
    return NumberLibraryState(
      basicNumbers: basicNumbers ?? const <int>[1, 2, 3, 4, 5, 6, 7, 8, 9],
      masterNumbers: masterNumbers ?? const <int>[11, 22, 33],
      isBasicNumbersExpanded: false,
      isMasterNumbersExpanded: false,
      selectedNumber: null,
      selectedMeaning: null,
    );
  }

  final List<int> basicNumbers;
  final List<int> masterNumbers;
  final bool isBasicNumbersExpanded;
  final bool isMasterNumbersExpanded;
  final int? selectedNumber;
  final NumerologyNumberLibraryContent? selectedMeaning;

  bool get hasSelection => selectedNumber != null && selectedMeaning != null;

  NumberLibraryState copyWith({
    List<int>? basicNumbers,
    List<int>? masterNumbers,
    bool? isBasicNumbersExpanded,
    bool? isMasterNumbersExpanded,
    int? selectedNumber,
    NumerologyNumberLibraryContent? selectedMeaning,
    bool clearSelection = false,
  }) {
    return NumberLibraryState(
      basicNumbers: basicNumbers ?? this.basicNumbers,
      masterNumbers: masterNumbers ?? this.masterNumbers,
      isBasicNumbersExpanded:
          isBasicNumbersExpanded ?? this.isBasicNumbersExpanded,
      isMasterNumbersExpanded:
          isMasterNumbersExpanded ?? this.isMasterNumbersExpanded,
      selectedNumber: clearSelection
          ? null
          : (selectedNumber ?? this.selectedNumber),
      selectedMeaning: clearSelection
          ? null
          : (selectedMeaning ?? this.selectedMeaning),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    basicNumbers,
    masterNumbers,
    isBasicNumbersExpanded,
    isMasterNumbersExpanded,
    selectedNumber,
    selectedMeaning,
  ];
}
