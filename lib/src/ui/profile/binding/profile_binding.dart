import 'package:get/get.dart';

import 'package:test/src/ui/profile/interactor/profile_bloc.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ProfileBloc>()) {
      Get.lazyPut<ProfileBloc>(ProfileBloc.new);
    }
  }
}
