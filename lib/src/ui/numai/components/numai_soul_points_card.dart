import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/widgets/app_mystical_card.dart';
import 'package:test/src/utils/app_assets.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class NumAiSoulPointsCard extends StatelessWidget {
  const NumAiSoulPointsCard({
    required this.soulPoints,
    required this.chatCost,
    super.key,
  });

  final int soulPoints;
  final int chatCost;

  @override
  Widget build(BuildContext context) {
    return AppMysticalCard(
      borderColor: AppColors.richGold.withValues(alpha: 0.32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              SvgPicture.asset(
                AppAssets.iconCoinPng,
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(
                  AppColors.richGold,
                  BlendMode.srcIn,
                ),
              ),
              8.width,
              Expanded(
                child: Text(
                  LocaleKey.numaiSoulPointsLabel.tr,
                  style: AppStyles.bodyMedium(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '$soulPoints',
                style: AppStyles.numberSmall(
                  color: AppColors.richGold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          10.height,
          Text(
            LocaleKey.numaiCostLine.trParams(<String, String>{
              'cost': '$chatCost',
            }),
            style: AppStyles.caption(color: AppColors.textSecondary),
          ),
          4.height,
          Text(
            LocaleKey.numaiEarnLine.tr,
            style: AppStyles.caption(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
