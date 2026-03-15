import 'package:get/get.dart';

import 'package:test/src/ui/notifications/interactor/notifications_bloc.dart';

class NotificationsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<NotificationsBloc>()) {
      Get.lazyPut<NotificationsBloc>(NotificationsBloc.new);
    }
  }
}
