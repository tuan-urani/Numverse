import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

typedef ProfileSoulPointsAction = Future<void> Function();

class ProfileSoulPointsActionsDialog extends StatelessWidget {
  const ProfileSoulPointsActionsDialog({
    required this.adEarnedToday,
    required this.adDailyLimit,
    required this.onWatchAdTap,
    required this.onBuyPointsTap,
    super.key,
  });

  final int adEarnedToday;
  final int adDailyLimit;
  final ProfileSoulPointsAction onWatchAdTap;
  final ProfileSoulPointsAction onBuyPointsTap;

  bool get isAdLimitReached => adEarnedToday >= adDailyLimit;

  static Future<void> show(
    BuildContext context, {
    required int adEarnedToday,
    required int adDailyLimit,
    required ProfileSoulPointsAction onWatchAdTap,
    required ProfileSoulPointsAction onBuyPointsTap,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext _) {
        return ProfileSoulPointsActionsDialog(
          adEarnedToday: adEarnedToday,
          adDailyLimit: adDailyLimit,
          onWatchAdTap: onWatchAdTap,
          onBuyPointsTap: onBuyPointsTap,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.mysticalCardGradient(),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.richGold.withValues(alpha: 0.3)),
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
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppColors.textMuted,
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
                      LocaleKey.profileSoulPointsActionAdsProgress.trParams(
                        <String, String>{
                          'earned': '$adEarnedToday',
                          'limit': '$adDailyLimit',
                        },
                      ),
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
              14.height,
              _ActionCard(
                icon: Icons.ondemand_video_rounded,
                title: LocaleKey.profileSoulPointsActionWatchAdTitle.tr,
                subtitle: LocaleKey.profileSoulPointsActionWatchAdBody.tr,
                enabled: !isAdLimitReached,
                onTap: () async {
                  Navigator.of(context).pop();
                },
              ),
              10.height,
              _ActionCard(
                icon: Icons.shopping_bag_rounded,
                title: LocaleKey.profileSoulPointsActionBuyPointTitle.tr,
                subtitle: LocaleKey.profileSoulPointsActionBuyPointBody.tr,
                enabled: true,
                onTap: () async {
                  Navigator.of(context).pop();
                  await onBuyPointsTap();
                },
              ),
            ],
          ),
        ),
      ),
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
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
