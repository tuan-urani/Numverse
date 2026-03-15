import 'package:get/get.dart';

import 'package:test/src/ui/my_profile/interactor/my_profile_bloc.dart';

class MyProfileBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<MyProfileBloc>()) {
      Get.lazyPut<MyProfileBloc>(MyProfileBloc.new);
    }
  }
}
