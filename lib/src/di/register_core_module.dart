import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:test/src/core/repository/admin_ledger_repository.dart';
import 'package:test/src/core/repository/interface/i_admin_ledger_repository.dart';
import 'package:test/src/core/repository/app_session_repository.dart';
import 'package:test/src/core/repository/cloud_account_repository.dart';
import 'package:test/src/core/repository/interface/i_app_session_repository.dart';
import 'package:test/src/core/repository/interface/i_cloud_account_repository.dart';
import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/core/repository/numerology_content_repository.dart';
import 'package:test/src/utils/app_shared.dart';

Future<void> registerCoreModule() async {
  if (!Get.isRegistered<AppShared>()) {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    Get.put<AppShared>(AppShared(preferences), permanent: true);
  }

  if (!Get.isRegistered<IAppSessionRepository>()) {
    Get.lazyPut<IAppSessionRepository>(
      () => LocalAppSessionRepository(Get.find<AppShared>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<ICloudAccountRepository>()) {
    Get.lazyPut<ICloudAccountRepository>(
      () => CloudAccountRepository(appShared: Get.find<AppShared>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<IAdminLedgerRepository>()) {
    Get.lazyPut<IAdminLedgerRepository>(
      () => AdminLedgerRepository(appShared: Get.find<AppShared>()),
      fenix: true,
    );
  }

  if (!Get.isRegistered<INumerologyContentRepository>()) {
    final AssetNumerologyContentRepository repository =
        AssetNumerologyContentRepository(appShared: Get.find<AppShared>());
    await repository.warmUp();
    Get.put<INumerologyContentRepository>(repository, permanent: true);
  }
}
