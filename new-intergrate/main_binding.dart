import 'package:get/get.dart';
import 'package:test/src/ui/main/bloc/main_bloc.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainBloc>(() => MainBloc());
  }
}
