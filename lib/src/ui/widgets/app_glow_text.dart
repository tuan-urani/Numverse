import 'package:flutter/material.dart';

import 'package:test/src/ui/widgets/app_text_gradient.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class AppGlowText extends StatelessWidget {
  const AppGlowText({
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
    super.key,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return AppTextGradient(
      text: text,
      textAlign: textAlign,
      style: (style ?? AppStyles.numberSmall()).copyWith(
        shadows: <Shadow>[
          Shadow(
            color: AppColors.richGold.withValues(alpha: 0.75),
            blurRadius: 14,
          ),
          Shadow(
            color: AppColors.richGold.withValues(alpha: 0.42),
            blurRadius: 26,
          ),
        ],
      ),
      gradient: AppColors.goldTextGradient(),
    );
  }
}
