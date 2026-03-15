import 'package:get/get.dart';

import 'package:test/src/ui/privacy/interactor/privacy_bloc.dart';

class PrivacyBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PrivacyBloc>()) {
      Get.lazyPut<PrivacyBloc>(PrivacyBloc.new);
    }
  }
}
