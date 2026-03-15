import 'package:get/get.dart';

import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/ui/chart_matrix/interactor/chart_matrix_bloc.dart';

class ChartMatrixBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ChartMatrixBloc>()) {
      Get.lazyPut<ChartMatrixBloc>(
        () => ChartMatrixBloc(
          contentRepository: Get.find<INumerologyContentRepository>(),
        ),
      );
    }
  }
}
