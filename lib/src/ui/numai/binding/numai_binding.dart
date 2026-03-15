import 'package:get/get.dart';

import 'package:test/src/ui/numai/interactor/numai_bloc.dart';

class NumAiBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<NumAiBloc>()) {
      Get.lazyPut<NumAiBloc>(NumAiBloc.new);
    }
  }
}
