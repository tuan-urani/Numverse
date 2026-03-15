import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:test/src/ui/notifications/interactor/notifications_event.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, int> {
  NotificationsBloc() : super(0);
}
