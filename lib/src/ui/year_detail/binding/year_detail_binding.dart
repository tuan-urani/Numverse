import 'package:get/get.dart';

import 'package:test/src/ui/year_detail/interactor/year_detail_bloc.dart';

class YearDetailBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<YearDetailBloc>()) {
      Get.lazyPut<YearDetailBloc>(YearDetailBloc.new);
    }
  }
}
