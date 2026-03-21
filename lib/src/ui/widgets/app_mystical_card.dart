import 'package:flutter/material.dart';

import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_dimensions.dart';

class AppMysticalCard extends StatelessWidget {
  const AppMysticalCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppDimensions.lg),
    this.onTap,
    this.borderColor,
    this.margin,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: AppColors.mysticalCardGradient(),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: borderColor ?? AppColors.richGold.withValues(alpha: 0.24),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.richGold.withValues(alpha: 0.12),
            blurRadius: 22,
            spreadRadius: 0.5,
          ),
          BoxShadow(
            color: AppColors.deepViolet.withValues(alpha: 0.6),
            blurRadius: 28,
            spreadRadius: 1.2,
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        gradient: AppColors.mysticalCardHighlightGradient(),
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: content,
      ),
    );
  }
}
