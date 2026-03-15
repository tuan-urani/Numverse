import 'package:get/get.dart';

import 'package:test/src/ui/settings/interactor/settings_bloc.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SettingsBloc>()) {
      Get.lazyPut<SettingsBloc>(SettingsBloc.new);
    }
  }
}
