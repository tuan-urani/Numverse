import 'package:get/get.dart';

import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/ui/life_path/interactor/life_path_bloc.dart';

class LifePathBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LifePathBloc>()) {
      Get.lazyPut<LifePathBloc>(
        () => LifePathBloc(
          contentRepository: Get.find<INumerologyContentRepository>(),
        ),
      );
    }
  }
}
