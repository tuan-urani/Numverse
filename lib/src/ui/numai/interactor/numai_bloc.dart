import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:test/src/ui/numai/interactor/numai_event.dart';
import 'package:test/src/ui/numai/interactor/numai_state.dart';

class NumAiBloc extends Bloc<NumAiEvent, NumAiState> {
  NumAiBloc() : super(NumAiState.initial());

  static const int chatCost = 3;
}
