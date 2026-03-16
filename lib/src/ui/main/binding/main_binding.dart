import 'package:get/get.dart';

import 'package:test/src/core/repository/interface/i_app_session_repository.dart';
import 'package:test/src/core/repository/interface/i_cloud_account_repository.dart';
import 'package:test/src/ui/main/bloc/main_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<MainBloc>()) {
      Get.lazyPut<MainBloc>(MainBloc.new, fenix: true);
    }

    if (!Get.isRegistered<MainSessionBloc>()) {
      Get.lazyPut<MainSessionBloc>(
        () => MainSessionBloc(
          Get.find<IAppSessionRepository>(),
          Get.find<ICloudAccountRepository>(),
        ),
        fenix: true,
      );
    }
  }
}
