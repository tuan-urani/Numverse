import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:test/src/ui/subscription/interactor/subscription_event.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, int> {
  SubscriptionBloc() : super(0);
}
