import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:test/src/core/model/numerology_content_models.dart';
import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/ui/number_library/interactor/number_library_event.dart';
import 'package:test/src/ui/number_library/interactor/number_library_state.dart';

class NumberLibraryBloc extends Bloc<NumberLibraryEvent, NumberLibraryState> {
  NumberLibraryBloc({
    required INumerologyContentRepository contentRepository,
    required String languageCode,
  }) : _contentRepository = contentRepository,
       _languageCode = languageCode,
       super(
         NumberLibraryState.initial(
           basicNumbers: contentRepository.getNumberLibraryBasicNumbers(
             languageCode: languageCode,
           ),
           masterNumbers: contentRepository.getNumberLibraryMasterNumbers(
             languageCode: languageCode,
           ),
         ),
       ) {
    on<NumberLibraryBasicNumbersExpandedToggled>(
      _onBasicNumbersExpandedToggled,
    );
    on<NumberLibraryMasterNumbersExpandedToggled>(
      _onMasterNumbersExpandedToggled,
    );
    on<NumberLibraryNumberSelected>(_onNumberSelected);
  }

  final INumerologyContentRepository _contentRepository;
  final String _languageCode;

  void toggleBasicNumbersExpanded() {
    add(const NumberLibraryBasicNumbersExpandedToggled());
  }

  void _onBasicNumbersExpandedToggled(
    NumberLibraryBasicNumbersExpandedToggled event,
    Emitter<NumberLibraryState> emit,
  ) {
    emit(state.copyWith(isBasicNumbersExpanded: !state.isBasicNumbersExpanded));
  }

  void toggleMasterNumbersExpanded() {
    add(const NumberLibraryMasterNumbersExpandedToggled());
  }

  void _onMasterNumbersExpandedToggled(
    NumberLibraryMasterNumbersExpandedToggled event,
    Emitter<NumberLibraryState> emit,
  ) {
    emit(
      state.copyWith(isMasterNumbersExpanded: !state.isMasterNumbersExpanded),
    );
  }

  void selectNumber(int number) {
    add(NumberLibraryNumberSelected(number));
  }

  void _onNumberSelected(
    NumberLibraryNumberSelected event,
    Emitter<NumberLibraryState> emit,
  ) {
    final int number = event.number;
    final NumerologyNumberLibraryContent meaning = _contentRepository
        .getNumberLibraryContent(number: number, languageCode: _languageCode);
    emit(state.copyWith(selectedNumber: number, selectedMeaning: meaning));
  }
}
