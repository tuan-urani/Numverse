import 'dart:async';
import 'dart:developer' as developer;

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:test/src/utils/app_admob_config.dart';

enum AdMobRewardedAdStatus {
  rewarded,
  dismissed,
  failedToLoad,
  failedToShow,
  notConfigured,
  adInProgress,
}

class AdMobRewardedAdResult {
  const AdMobRewardedAdResult({required this.status, this.debugMessage});

  final AdMobRewardedAdStatus status;
  final String? debugMessage;

  bool get didEarnReward => status == AdMobRewardedAdStatus.rewarded;

  bool get shouldShowErrorMessage {
    switch (status) {
      case AdMobRewardedAdStatus.rewarded:
      case AdMobRewardedAdStatus.dismissed:
      case AdMobRewardedAdStatus.adInProgress:
        return false;
      case AdMobRewardedAdStatus.failedToLoad:
      case AdMobRewardedAdStatus.failedToShow:
      case AdMobRewardedAdStatus.notConfigured:
        return true;
    }
  }
}

class AdMobRewardedAdService {
  AdMobRewardedAdService({AppAdMobConfig? config})
    : _config = config ?? const AppAdMobConfig();

  final AppAdMobConfig _config;

  bool _didInitialize = false;
  bool _isShowing = false;

  Future<AdMobRewardedAdResult> showRewardedAd({
    required String placementCode,
  }) async {
    if (!_config.isRewardedAdConfigured) {
      return const AdMobRewardedAdResult(
        status: AdMobRewardedAdStatus.notConfigured,
      );
    }
    if (_isShowing) {
      return const AdMobRewardedAdResult(
        status: AdMobRewardedAdStatus.adInProgress,
      );
    }

    await _initializeIfNeeded();

    final RewardedAd? rewardedAd = await _loadRewardedAd();
    if (rewardedAd == null) {
      return const AdMobRewardedAdResult(
        status: AdMobRewardedAdStatus.failedToLoad,
      );
    }

    _isShowing = true;
    final Completer<AdMobRewardedAdResult> completer =
        Completer<AdMobRewardedAdResult>();
    bool didEarnReward = false;
    bool didDisposeAd = false;

    void safeDispose(Ad ad) {
      if (didDisposeAd) {
        return;
      }
      didDisposeAd = true;
      ad.dispose();
    }

    rewardedAd.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (Ad ad) {
        safeDispose(ad);
        _isShowing = false;
        if (completer.isCompleted) {
          return;
        }
        completer.complete(
          AdMobRewardedAdResult(
            status: didEarnReward
                ? AdMobRewardedAdStatus.rewarded
                : AdMobRewardedAdStatus.dismissed,
          ),
        );
      },
      onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
        safeDispose(ad);
        _isShowing = false;
        developer.log(
          'Rewarded ad failed to show for placement $placementCode.',
          name: 'AdMobRewardedAdService',
          error: error,
        );
        if (completer.isCompleted) {
          return;
        }
        completer.complete(
          AdMobRewardedAdResult(
            status: AdMobRewardedAdStatus.failedToShow,
            debugMessage: error.message,
          ),
        );
      },
    );

    try {
      rewardedAd.show(
        onUserEarnedReward: (_, RewardItem _) {
          didEarnReward = true;
        },
      );
    } catch (error, stackTrace) {
      _isShowing = false;
      safeDispose(rewardedAd);
      developer.log(
        'Rewarded ad show call threw an error for placement $placementCode.',
        name: 'AdMobRewardedAdService',
        error: error,
        stackTrace: stackTrace,
      );
      if (!completer.isCompleted) {
        completer.complete(
          AdMobRewardedAdResult(
            status: AdMobRewardedAdStatus.failedToShow,
            debugMessage: '$error',
          ),
        );
      }
    }

    return completer.future.timeout(
      const Duration(seconds: 90),
      onTimeout: () {
        _isShowing = false;
        safeDispose(rewardedAd);
        return const AdMobRewardedAdResult(
          status: AdMobRewardedAdStatus.failedToShow,
          debugMessage: 'Rewarded ad timeout.',
        );
      },
    );
  }

  Future<void> _initializeIfNeeded() async {
    if (_didInitialize) {
      return;
    }
    await MobileAds.instance.initialize();
    _didInitialize = true;
  }

  Future<RewardedAd?> _loadRewardedAd() async {
    final Completer<RewardedAd?> completer = Completer<RewardedAd?>();
    try {
      await RewardedAd.load(
        adUnitId: _config.rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            if (completer.isCompleted) {
              ad.dispose();
              return;
            }
            completer.complete(ad);
          },
          onAdFailedToLoad: (LoadAdError error) {
            developer.log(
              'Rewarded ad failed to load.',
              name: 'AdMobRewardedAdService',
              error: error,
            );
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          },
        ),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Unexpected error while loading rewarded ad.',
        name: 'AdMobRewardedAdService',
        error: error,
        stackTrace: stackTrace,
      );
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }
    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => null,
    );
  }
}
