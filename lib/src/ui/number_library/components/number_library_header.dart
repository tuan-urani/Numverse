import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_dimensions.dart';
import 'package:test/src/utils/app_styles.dart';

class NumberLibraryHeader extends StatelessWidget {
  const NumberLibraryHeader({required this.onBackTap, super.key});

  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.transparent,
            border: Border(bottom: BorderSide(color: AppColors.transparent)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.pageHorizontal,
              vertical: 12,
            ),
            child: Row(
              children: <Widget>[
                InkWell(
                  onTap: onBackTap,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.richGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      size: 20,
                      color: AppColors.richGold,
                    ),
                  ),
                ),
                12.width,
                Expanded(
                  child: Text(
                    LocaleKey.numberLibraryTitle.tr,
                    style: AppStyles.h3(fontWeight: FontWeight.w700),
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
