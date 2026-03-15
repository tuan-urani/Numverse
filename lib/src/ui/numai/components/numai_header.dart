import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class NumAiHeader extends StatelessWidget {
  const NumAiHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              LocaleKey.numaiTitle.tr,
              style: AppStyles.h2(fontWeight: FontWeight.w700),
            ),
            8.width,
            const Icon(
              Icons.auto_awesome_rounded,
              size: 24,
              color: AppColors.richGold,
            ),
          ],
        ),
        4.height,
        Text(
          LocaleKey.numaiSubtitle.tr,
          style: AppStyles.bodySmall(color: AppColors.textMuted),
        ),
      ],
    );
  }
}
