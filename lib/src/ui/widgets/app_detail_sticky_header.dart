import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class AppDetailStickyHeader extends StatelessWidget {
  const AppDetailStickyHeader({
    required this.title,
    this.onBackTap,
    this.titleStyle,
    super.key,
  });

  final String title;
  final VoidCallback? onBackTap;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.82),
            border: Border(
              bottom: BorderSide(
                color: AppColors.border.withValues(alpha: 0.45),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: <Widget>[
                InkWell(
                  onTap: onBackTap ?? () => Navigator.of(context).maybePop(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.richGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      size: 20,
                      color: AppColors.richGold,
                    ),
                  ),
                ),
                12.width,
                Expanded(
                  child: Text(
                    title,
                    style:
                        titleStyle ?? AppStyles.h3(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
