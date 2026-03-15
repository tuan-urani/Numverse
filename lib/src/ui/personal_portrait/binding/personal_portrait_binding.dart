import 'package:get/get.dart';

import 'package:test/src/ui/personal_portrait/interactor/personal_portrait_bloc.dart';

class PersonalPortraitBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PersonalPortraitBloc>()) {
      Get.lazyPut<PersonalPortraitBloc>(PersonalPortraitBloc.new);
    }
  }
}
