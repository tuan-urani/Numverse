import 'package:get/get.dart';

import 'package:test/src/ui/today_detail/interactor/today_detail_bloc.dart';

class TodayDetailBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<TodayDetailBloc>()) {
      Get.lazyPut<TodayDetailBloc>(TodayDetailBloc.new);
    }
  }
}
