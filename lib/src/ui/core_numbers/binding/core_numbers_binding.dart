import 'package:get/get.dart';

import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/ui/core_numbers/interactor/core_numbers_bloc.dart';

class CoreNumbersBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CoreNumbersBloc>()) {
      Get.lazyPut<CoreNumbersBloc>(
        () => CoreNumbersBloc(
          contentRepository: Get.find<INumerologyContentRepository>(),
        ),
      );
    }
  }
}
