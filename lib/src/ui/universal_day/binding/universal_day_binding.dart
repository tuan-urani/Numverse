import 'package:get/get.dart';

import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/ui/universal_day/interactor/universal_day_bloc.dart';

class UniversalDayBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<UniversalDayBloc>()) {
      Get.lazyPut<UniversalDayBloc>(() {
        return UniversalDayBloc(
          contentRepository: Get.find<INumerologyContentRepository>(),
          languageCode: Get.locale?.languageCode ?? 'vi',
        );
      });
    }
  }
}
