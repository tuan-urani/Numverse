import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:test/src/ui/privacy/interactor/privacy_event.dart';
import 'package:test/src/ui/privacy/interactor/privacy_state.dart';

class PrivacyBloc extends Bloc<PrivacyEvent, PrivacyState> {
  PrivacyBloc() : super(PrivacyState.initial());
}
