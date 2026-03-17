import 'dart:developer' as developer;

import 'package:get/get.dart';

import 'package:test/src/core/service/admob_rewarded_ad_service.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_state.dart';

class AdRewardClaimFlow {
  const AdRewardClaimFlow._();

  static Future<bool> watchAdThenClaim({
    required MainSessionBloc sessionBloc,
    required AdMobRewardedAdService adMobRewardedAdService,
    required int amount,
    required String placementCode,
  }) async {
    final String cleanPlacementCode = placementCode.trim().isNotEmpty
        ? placementCode.trim()
        : 'default_rewarded';

    try {
      await sessionBloc.refreshAdRewardStatus(
        placementCode: cleanPlacementCode,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to refresh ad reward status before showing ad.',
        name: 'AdRewardClaimFlow',
        error: error,
        stackTrace: stackTrace,
      );
    }

    final MainSessionState latestState = sessionBloc.state;
    final int remaining =
        latestState.dailyAdLimit - latestState.dailyAdEarnings;
    if (remaining <= 0) {
      _showLimitReachedFeedback();
      return false;
    }

    final AdMobRewardedAdResult adResult = await adMobRewardedAdService
        .showRewardedAd(placementCode: cleanPlacementCode);
    if (!adResult.didEarnReward) {
      if (adResult.shouldShowErrorMessage) {
        Get.snackbar(LocaleKey.commonError.tr, LocaleKey.stateErrorSubtitle.tr);
      }
      return false;
    }

    final String requestId =
        'admob:${DateTime.now().microsecondsSinceEpoch}:$cleanPlacementCode';
    final bool granted = await sessionBloc.claimAdReward(
      amount: amount,
      placementCode: cleanPlacementCode,
      requestId: requestId,
    );
    if (!granted) {
      _showLimitReachedFeedback();
    }
    return granted;
  }

  static void _showLimitReachedFeedback() {
    Get.snackbar(
      LocaleKey.commonError.tr,
      LocaleKey.profileSoulPointsActionAdsLimitReached.tr,
    );
  }
}
