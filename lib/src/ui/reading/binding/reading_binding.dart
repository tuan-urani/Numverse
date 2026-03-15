import 'package:get/get.dart';

import 'package:test/src/ui/reading/interactor/reading_bloc.dart';

class ReadingBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ReadingBloc>()) {
      Get.lazyPut<ReadingBloc>(ReadingBloc.new);
    }
  }
}
