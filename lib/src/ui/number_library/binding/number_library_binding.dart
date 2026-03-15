import 'package:get/get.dart';

import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/ui/number_library/interactor/number_library_bloc.dart';

class NumberLibraryBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<NumberLibraryBloc>()) {
      Get.lazyPut<NumberLibraryBloc>(() {
        return NumberLibraryBloc(
          contentRepository: Get.find<INumerologyContentRepository>(),
          languageCode: Get.locale?.languageCode ?? 'vi',
        );
      });
    }
  }
}
