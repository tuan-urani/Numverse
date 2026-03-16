import 'package:get/get.dart';

import 'package:test/src/core/repository/interface/i_admin_ledger_repository.dart';
import 'package:test/src/ui/admin/interactor/admin_bloc.dart';

class AdminBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AdminBloc>()) {
      Get.lazyPut<AdminBloc>(
        () => AdminBloc(Get.find<IAdminLedgerRepository>()),
      );
    }
  }
}
