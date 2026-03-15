import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:test/src/ui/profile/interactor/profile_event.dart';
import 'package:test/src/ui/profile/interactor/profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(ProfileState.initial());
}
