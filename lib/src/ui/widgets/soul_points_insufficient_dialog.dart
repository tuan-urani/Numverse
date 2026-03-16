import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

typedef SoulPointsDialogAction = Future<void> Function();

class SoulPointsInsufficientDialog extends StatelessWidget {
  const SoulPointsInsufficientDialog({
    required this.requiredPoints,
    required this.onWatchAdTap,
    required this.onBuyPointsTap,
    super.key,
  });

  final int requiredPoints;
  final SoulPointsDialogAction onWatchAdTap;
  final SoulPointsDialogAction onBuyPointsTap;

  static Future<void> show(
    BuildContext context, {
    required int requiredPoints,
    required SoulPointsDialogAction onWatchAdTap,
    required SoulPointsDialogAction onBuyPointsTap,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return SoulPointsInsufficientDialog(
          requiredPoints: requiredPoints,
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
          border: Border.all(color: AppColors.richGold.withValues(alpha: 0.32)),
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
                        <String, String>{'points': '$requiredPoints'},
                      ),
                      style: AppStyles.bodyMedium(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await onWatchAdTap();
                      },
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
                      child: Text(
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
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await onBuyPointsTap();
                        },
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
  }
}
