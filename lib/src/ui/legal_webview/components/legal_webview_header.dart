import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class LegalWebviewHeader extends StatelessWidget {
  const LegalWebviewHeader({
    required this.titleKey,
    required this.onBackTap,
    super.key,
  });

  final String titleKey;
  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.transparent,
        border: Border(bottom: BorderSide(color: AppColors.transparent)),
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
                color: AppColors.richGold,
                size: 24,
              ),
            ),
          ),
          10.width,
          Expanded(
            child: Text(
              titleKey.tr,
              style: AppStyles.h4(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
