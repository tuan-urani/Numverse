import 'package:get/get.dart';

import 'package:test/src/ui/help/interactor/help_bloc.dart';

class HelpBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HelpBloc>()) {
      Get.lazyPut<HelpBloc>(HelpBloc.new);
    }
  }
}
