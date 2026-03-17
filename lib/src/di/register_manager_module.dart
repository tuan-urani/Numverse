import 'package:get/get.dart';

import 'package:test/src/core/service/admob_rewarded_ad_service.dart';

Future<void> registerManagerModule() async {
  if (!Get.isRegistered<AdMobRewardedAdService>()) {
    Get.put<AdMobRewardedAdService>(AdMobRewardedAdService(), permanent: true);
  }
}
