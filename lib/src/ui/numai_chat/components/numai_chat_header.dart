import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class NumAiChatHeader extends StatelessWidget {
  const NumAiChatHeader({
    required this.soulPoints,
    required this.onBackTap,
    super.key,
  });

  final int soulPoints;
  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.84),
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: <Widget>[
          InkWell(
            onTap: onBackTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.richGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                size: 24,
                color: AppColors.richGold,
              ),
            ),
          ),
          10.width,
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  AppColors.richGold.withValues(alpha: 0.3),
                  AppColors.deepViolet.withValues(alpha: 0.5),
                ],
              ),
              border: Border.all(
                color: AppColors.richGold.withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: AppColors.richGold,
            ),
          ),
          8.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  LocaleKey.numaiTitle.tr,
                  style: AppStyles.h5(fontWeight: FontWeight.w700),
                ),
                Text(
                  LocaleKey.numaiChatSubtitle.tr,
                  style: AppStyles.caption(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.richGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.richGold.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.stars_rounded,
                  size: 15,
                  color: AppColors.richGold,
                ),
                4.width,
                Text(
                  '$soulPoints',
                  style: AppStyles.bodySmall(
                    color: AppColors.richGold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
