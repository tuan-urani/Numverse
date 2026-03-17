import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppAdMobConfig {
  const AppAdMobConfig();

  static const String _androidRewardedTestAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _iosRewardedTestAdUnitId =
      'ca-app-pub-3940256099942544/1712485313';

  String get rewardedAdUnitId {
    if (kIsWeb) {
      return '';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _resolveRewardedAdUnitId(
          envKey: 'ADMOB_ANDROID_REWARDED_UNIT_ID',
          debugFallback: _androidRewardedTestAdUnitId,
        );
      case TargetPlatform.iOS:
        return _resolveRewardedAdUnitId(
          envKey: 'ADMOB_IOS_REWARDED_UNIT_ID',
          debugFallback: _iosRewardedTestAdUnitId,
        );
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return '';
    }
  }

  bool get isRewardedAdConfigured => rewardedAdUnitId.isNotEmpty;

  String _resolveRewardedAdUnitId({
    required String envKey,
    required String debugFallback,
  }) {
    final String fromEnv = (dotenv.env[envKey] ?? '').trim();
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    if (kDebugMode) {
      return debugFallback;
    }
    return '';
  }
}
