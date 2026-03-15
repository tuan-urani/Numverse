import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:test/src/ui/personal_portrait/interactor/personal_portrait_event.dart';
import 'package:test/src/ui/personal_portrait/interactor/personal_portrait_state.dart';

class PersonalPortraitBloc
    extends Bloc<PersonalPortraitEvent, PersonalPortraitState> {
  PersonalPortraitBloc() : super(PersonalPortraitState.initial());
}
