import 'package:get/get.dart';

import 'package:test/src/ui/login/interactor/login_bloc.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LoginBloc>()) {
      Get.lazyPut<LoginBloc>(LoginBloc.new);
    }
  }
}
