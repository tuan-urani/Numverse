import 'package:get/get.dart';

import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/ui/angel_numbers/interactor/angel_numbers_bloc.dart';

class AngelNumbersBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AngelNumbersBloc>()) {
      Get.lazyPut<AngelNumbersBloc>(() {
        return AngelNumbersBloc(
          contentRepository: Get.find<INumerologyContentRepository>(),
          languageCode: Get.locale?.languageCode ?? 'vi',
        );
      });
    }
  }
}
