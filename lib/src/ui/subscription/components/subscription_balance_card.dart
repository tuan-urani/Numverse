import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/widgets/app_mystical_card.dart';
import 'package:test/src/utils/app_assets.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class SubscriptionBalanceCard extends StatelessWidget {
  const SubscriptionBalanceCard({required this.currentPoints, super.key});

  final int currentPoints;

  @override
  Widget build(BuildContext context) {
    return AppMysticalCard(
      borderColor: AppColors.richGold.withValues(alpha: 0.3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.richGold.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(10),
              child: SvgPicture.asset(
                AppAssets.iconCoinPng,
                width: 21,
                height: 21,
                colorFilter: const ColorFilter.mode(
                  AppColors.richGold,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  LocaleKey.subscriptionBalanceLabel.tr,
                  style: AppStyles.caption(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                2.height,
                Text(
                  LocaleKey.profileSoulPointsLabel.trParams(<String, String>{
                    'points': '$currentPoints',
                  }),
                  style: AppStyles.h4(
                    color: AppColors.richGold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                2.height,
                Text(
                  LocaleKey.subscriptionBalanceHint.tr,
                  style: AppStyles.caption(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          // 8.width,
          // Container(
          //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          //   decoration: BoxDecoration(
          //     color: AppColors.violetAccent.withValues(alpha: 0.26),
          //     borderRadius: BorderRadius.circular(12),
          //     border: Border.all(
          //       color: AppColors.border.withValues(alpha: 0.8),
          //     ),
          //   ),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.center,
          //     children: <Widget>[
          //       Text(
          //         '$currentPoints',
          //         style: AppStyles.numberSmall(fontWeight: FontWeight.w700),
          //       ),
          //       Text(
          //         LocaleKey.subscriptionBalanceUnit.tr,
          //         style: AppStyles.caption(
          //           color: AppColors.textMuted,
          //           fontWeight: FontWeight.w600,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}
