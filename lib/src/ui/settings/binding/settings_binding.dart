import 'package:get/get.dart';

import 'package:test/src/core/repository/interface/i_cloud_account_repository.dart';
import 'package:test/src/core/service/interface/i_daily_alarm_notification_service.dart';
import 'package:test/src/ui/settings/interactor/settings_bloc.dart';
import 'package:test/src/utils/app_shared.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SettingsBloc>()) {
      Get.lazyPut<SettingsBloc>(
        () => SettingsBloc(
          cloudAccountRepository: Get.find<ICloudAccountRepository>(),
          appShared: Get.find<AppShared>(),
          dailyAlarmNotificationService:
              Get.find<IDailyAlarmNotificationService>(),
          localeCodeProvider: () => Get.locale?.languageCode ?? 'vi',
        ),
      );
    }
  }
}
