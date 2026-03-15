import 'package:get/get.dart';

import 'package:test/src/ui/compatibility/interactor/compatibility_bloc.dart';

class CompatibilityBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CompatibilityBloc>()) {
      Get.lazyPut<CompatibilityBloc>(CompatibilityBloc.new);
    }
  }
}
