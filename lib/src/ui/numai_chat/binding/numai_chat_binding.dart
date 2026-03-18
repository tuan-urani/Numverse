import 'package:get/get.dart';

import 'package:test/src/core/repository/interface/i_app_session_repository.dart';
import 'package:test/src/core/repository/interface/i_cloud_account_repository.dart';
import 'package:test/src/ui/numai_chat/interactor/numai_chat_bloc.dart';

class NumAiChatBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<NumAiChatBloc>()) {
      Get.lazyPut<NumAiChatBloc>(
        () => NumAiChatBloc(
          cloudAccountRepository: Get.find<ICloudAccountRepository>(),
          appSessionRepository: Get.find<IAppSessionRepository>(),
        ),
      );
    }
  }
}
