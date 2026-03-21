import 'package:get/get.dart';

import 'package:test/src/core/repository/interface/i_cloud_account_repository.dart';
import 'package:test/src/core/service/admob_rewarded_ad_service.dart';
import 'package:test/src/core/service/daily_alarm_notification_service.dart';
import 'package:test/src/core/service/interface/i_daily_alarm_notification_service.dart';
import 'package:test/src/utils/app_shared.dart';

Future<void> registerManagerModule() async {
  if (!Get.isRegistered<AdMobRewardedAdService>()) {
    Get.put<AdMobRewardedAdService>(AdMobRewardedAdService(), permanent: true);
  }

  if (!Get.isRegistered<IDailyAlarmNotificationService>()) {
    Get.put<IDailyAlarmNotificationService>(
      DailyAlarmNotificationService(
        cloudAccountRepository: Get.find<ICloudAccountRepository>(),
        appShared: Get.find<AppShared>(),
      ),
      permanent: true,
    );
  }
}
