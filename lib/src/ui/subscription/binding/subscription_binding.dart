import 'package:get/get.dart';

import 'package:test/src/ui/subscription/interactor/subscription_bloc.dart';

class SubscriptionBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SubscriptionBloc>()) {
      Get.lazyPut<SubscriptionBloc>(SubscriptionBloc.new);
    }
  }
}
