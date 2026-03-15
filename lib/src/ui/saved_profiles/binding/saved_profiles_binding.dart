import 'package:get/get.dart';

import 'package:test/src/ui/saved_profiles/interactor/saved_profiles_bloc.dart';

class SavedProfilesBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SavedProfilesBloc>()) {
      Get.lazyPut<SavedProfilesBloc>(SavedProfilesBloc.new);
    }
  }
}
