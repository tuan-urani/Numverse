import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_state.dart';
import 'package:test/src/ui/widgets/app_reward_celebration_overlay.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

typedef SoulPointsDialogAction = Future<void> Function();

class SoulPointsInsufficientDialog extends StatefulWidget {
  const SoulPointsInsufficientDialog({
    required this.sessionBloc,
    required this.requiredPoints,
    required this.onWatchAdTap,
    required this.onBuyPointsTap,
    super.key,
  });

  final MainSessionBloc sessionBloc;
  final int requiredPoints;
  final SoulPointsDialogAction onWatchAdTap;
  final SoulPointsDialogAction onBuyPointsTap;

  static Future<void> show(
    BuildContext context, {
    required MainSessionBloc sessionBloc,
    required int requiredPoints,
    required SoulPointsDialogAction onWatchAdTap,
    required SoulPointsDialogAction onBuyPointsTap,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return SoulPointsInsufficientDialog(
          sessionBloc: sessionBloc,
          requiredPoints: requiredPoints,
          onWatchAdTap: onWatchAdTap,
          onBuyPointsTap: onBuyPointsTap,
        );
      },
    );
  }

  @override
  State<SoulPointsInsufficientDialog> createState() =>
      _SoulPointsInsufficientDialogState();
}

class _SoulPointsInsufficientDialogState
    extends State<SoulPointsInsufficientDialog> {
  bool _isWatchingAd = false;

  Future<void> _handleWatchAdTap(MainSessionState state) async {
    if (_isWatchingAd) {
      return;
    }

    final int remaining = state.dailyAdLimit - state.dailyAdEarnings;
    if (remaining <= 0) {
      return;
    }

    final int soulPointsBefore = state.soulPoints;
    setState(() {
      _isWatchingAd = true;
    });
    try {
      await widget.onWatchAdTap();
    } catch (error, stackTrace) {
      developer.log(
        'Watch ad action failed in insufficient points dialog.',
        name: 'SoulPointsInsufficientDialog',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isWatchingAd = false;
        });
      }
    }

    if (!mounted) {
      return;
    }

    final int rewarded =
        (widget.sessionBloc.state.soulPoints - soulPointsBefore).clamp(0, 9999);
    if (rewarded <= 0) {
      return;
    }
    AppRewardCelebrationOverlay.show(
      context,
      reward: rewarded,
      title: LocaleKey.commonSuccess.tr,
      subtitle: LocaleKey.soulPointsWatchAdAction.tr,
    );
  }

  Future<void> _handleBuyTap() async {
    if (_isWatchingAd) {
      return;
    }
    Navigator.of(context).pop();
    await widget.onBuyPointsTap();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainSessionBloc, MainSessionState>(
      bloc: widget.sessionBloc,
      builder: (BuildContext context, MainSessionState state) {
        final bool isAdLimitReached =
            state.dailyAdEarnings >= state.dailyAdLimit;
        return Dialog(
          backgroundColor: AppColors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.mysticalCardGradient(),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.richGold.withValues(alpha: 0.32),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          LocaleKey.soulPointsInsufficientTitle.tr,
                          style: AppStyles.numberSmall(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ).copyWith(fontSize: 24, height: 1.2),
                        ),
                      ),
                      InkWell(
                        onTap: _isWatchingAd
                            ? null
                            : () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(10),
                        child: Opacity(
                          opacity: _isWatchingAd ? 0.5 : 1,
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 20,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          LocaleKey.soulPointsInsufficientBody.trParams(
                            <String, String>{
                              'points': '${widget.requiredPoints}',
                            },
                          ),
                          style: AppStyles.bodyMedium(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    LocaleKey.profileSoulPointsActionAdsProgress
                        .trParams(<String, String>{
                          'earned': '${state.dailyAdEarnings}',
                          'limit': '${state.dailyAdLimit}',
                        }),
                    style: AppStyles.caption(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isAdLimitReached) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      LocaleKey.profileSoulPointsActionAdsLimitReached.tr,
                      style: AppStyles.caption(
                        color: AppColors.energyAmber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (_isWatchingAd) ...<Widget>[
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.richGold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            LocaleKey.commonLoading.tr,
                            style: AppStyles.caption(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: (!_isWatchingAd && !isAdLimitReached)
                              ? () => _handleWatchAdTap(state)
                              : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: BorderSide(
                              color: AppColors.border.withValues(alpha: 0.9),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isWatchingAd
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.richGold,
                                  ),
                                )
                              : Text(
                                  LocaleKey.soulPointsWatchAdAction.tr,
                                  style: AppStyles.buttonMedium(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient(),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: _isWatchingAd ? null : _handleBuyTap,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: AppColors.transparent,
                              shadowColor: AppColors.transparent,
                              foregroundColor: AppColors.midnight,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              LocaleKey.soulPointsBuyAction.tr,
                              style: AppStyles.buttonMedium(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
