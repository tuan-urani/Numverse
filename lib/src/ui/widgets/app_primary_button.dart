import 'package:flutter/material.dart';

import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_dimensions.dart';
import 'package:test/src/utils/app_styles.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    required this.label,
    this.onPressed,
    this.leading,
    this.expanded = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final Widget child = AnimatedOpacity(
      opacity: onPressed == null ? 0.55 : 1,
      duration: const Duration(milliseconds: 220),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient(),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: AppColors.goldBright.withValues(alpha: 0.45),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.richGold.withValues(alpha: 0.25),
              blurRadius: 18,
              spreadRadius: 0.5,
            ),
            BoxShadow(
              color: AppColors.deepViolet.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 0.3,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      AppColors.white.withValues(alpha: 0.24),
                      AppColors.transparent,
                      AppColors.transparent,
                    ],
                    stops: const <double>[0, 0.32, 1],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (leading != null) ...<Widget>[
                    leading!,
                    const SizedBox(width: 8),
                  ],
                  Text(label, style: AppStyles.buttonMedium()),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (!expanded) {
      return InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: child,
      );
    }

    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: child,
      ),
    );
  }
}
