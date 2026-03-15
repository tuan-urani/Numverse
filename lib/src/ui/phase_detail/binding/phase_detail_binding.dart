import 'package:get/get.dart';

import 'package:test/src/ui/phase_detail/interactor/phase_detail_bloc.dart';

class PhaseDetailBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PhaseDetailBloc>()) {
      Get.lazyPut<PhaseDetailBloc>(PhaseDetailBloc.new);
    }
  }
}
