import 'package:get/get.dart';

import 'package:test/src/ui/today/interactor/today_bloc.dart';

class TodayBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<TodayBloc>()) {
      Get.lazyPut<TodayBloc>(TodayBloc.new);
    }
  }
}
