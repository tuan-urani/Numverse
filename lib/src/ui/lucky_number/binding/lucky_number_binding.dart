import 'package:get/get.dart';

import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/ui/lucky_number/interactor/lucky_number_bloc.dart';

class LuckyNumberBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LuckyNumberBloc>()) {
      Get.lazyPut<LuckyNumberBloc>(() {
        return LuckyNumberBloc(
          contentRepository: Get.find<INumerologyContentRepository>(),
          languageCode: Get.locale?.languageCode ?? 'vi',
        );
      });
    }
  }
}
