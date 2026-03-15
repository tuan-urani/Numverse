import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class CompatibilityInsufficientPointsDialog extends StatelessWidget {
  const CompatibilityInsufficientPointsDialog({
    required this.comparisonCost,
    required this.onTopup,
    super.key,
  });

  final int comparisonCost;
  final VoidCallback onTopup;

  static Future<void> show(
    BuildContext context, {
    required int comparisonCost,
    required VoidCallback onTopup,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return CompatibilityInsufficientPointsDialog(
          comparisonCost: comparisonCost,
          onTopup: onTopup,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> params = <String, String>{
      'points': '$comparisonCost',
    };

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
                      LocaleKey.compatibilityInsufficientTitle.tr,
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
              14.height,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 20,
                    color: AppColors.error,
                  ),
                  10.width,
                  Expanded(
                    child: Text(
                      LocaleKey.compatibilityInsufficientBody.trParams(params),
                      style: AppStyles.bodyMedium(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              18.height,
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
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
                        LocaleKey.compatibilityInsufficientClose.tr,
                        style: AppStyles.buttonMedium(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  10.width,
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient(),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onTopup();
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
                          LocaleKey.compatibilityInsufficientTopup.tr,
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
