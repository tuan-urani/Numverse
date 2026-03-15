import 'package:get/get.dart';

import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/ui/comparison_result/interactor/comparison_result_bloc.dart';

class ComparisonResultBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ComparisonResultBloc>()) {
      Get.lazyPut<ComparisonResultBloc>(
        () => ComparisonResultBloc(
          contentRepository: Get.find<INumerologyContentRepository>(),
        ),
      );
    }
  }
}
