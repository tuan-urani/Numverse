import 'package:get/get.dart';

import 'package:test/src/ui/month_detail/interactor/month_detail_bloc.dart';

class MonthDetailBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<MonthDetailBloc>()) {
      Get.lazyPut<MonthDetailBloc>(MonthDetailBloc.new);
    }
  }
}
