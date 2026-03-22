import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_state.dart';
import 'package:test/src/ui/widgets/app_reward_celebration_overlay.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

typedef ProfileSoulPointsAction = Future<void> Function();

class ProfileSoulPointsActionsDialog extends StatefulWidget {
  const ProfileSoulPointsActionsDialog({
    required this.sessionBloc,
    required this.onWatchAdTap,
    super.key,
  });

  final MainSessionBloc sessionBloc;
  final ProfileSoulPointsAction onWatchAdTap;

  static Future<void> show(
    BuildContext context, {
    required MainSessionBloc sessionBloc,
    required ProfileSoulPointsAction onWatchAdTap,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext _) {
        return ProfileSoulPointsActionsDialog(
          sessionBloc: sessionBloc,
          onWatchAdTap: onWatchAdTap,
        );
      },
    );
  }

  @override
  State<ProfileSoulPointsActionsDialog> createState() =>
      _ProfileSoulPointsActionsDialogState();
}

class _ProfileSoulPointsActionsDialogState
    extends State<ProfileSoulPointsActionsDialog> {
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
        'Watch ad action failed in soul points dialog.',
        name: 'ProfileSoulPointsActionsDialog',
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
      subtitle: LocaleKey.profileSoulPointsActionWatchAdTitle.tr,
    );
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
                color: AppColors.richGold.withValues(alpha: 0.3),
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
                          LocaleKey.profileSoulPointsActionTitle.tr,
                          style: AppStyles.h4(fontWeight: FontWeight.w600),
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
                  6.height,
                  Text(
                    LocaleKey.profileSoulPointsActionSubtitle.tr,
                    style: AppStyles.bodySmall(color: AppColors.textSecondary),
                  ),
                  12.height,
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.violetAccent.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.8),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          LocaleKey.profileSoulPointsActionAdsProgress
                              .trParams(<String, String>{
                                'earned': '${state.dailyAdEarnings}',
                                'limit': '${state.dailyAdLimit}',
                              }),
                          style: AppStyles.bodySmall(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isAdLimitReached) ...<Widget>[
                          6.height,
                          Text(
                            LocaleKey.profileSoulPointsActionAdsLimitReached.tr,
                            style: AppStyles.caption(
                              color: AppColors.energyAmber,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // if (_isWatchingAd) ...<Widget>[
                  //   10.height,
                  //   Row(
                  //     children: <Widget>[
                  //       const SizedBox(
                  //         width: 16,
                  //         height: 16,
                  //         child: CircularProgressIndicator(
                  //           strokeWidth: 2,
                  //           color: AppColors.richGold,
                  //         ),
                  //       ),
                  //       8.width,
                  //       Expanded(
                  //         child: Text(
                  //           LocaleKey.commonLoading.tr,
                  //           style: AppStyles.caption(
                  //             color: AppColors.textSecondary,
                  //             fontWeight: FontWeight.w600,
                  //           ),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ],
                  14.height,
                  _ActionCard(
                    icon: Icons.ondemand_video_rounded,
                    title: LocaleKey.profileSoulPointsActionWatchAdTitle.tr,
                    subtitle: LocaleKey.profileSoulPointsActionWatchAdBody.tr,
                    enabled: !isAdLimitReached && !_isWatchingAd,
                    isLoading: _isWatchingAd,
                    onTap: () => _handleWatchAdTap(state),
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

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
    this.isLoading = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final bool isLoading;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.85),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.richGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 18, color: AppColors.richGold),
                ),
                10.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: AppStyles.bodyMedium(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      2.height,
                      Text(
                        subtitle,
                        style: AppStyles.caption(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.richGold,
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
