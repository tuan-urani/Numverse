import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/widgets/app_mystical_card.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class PrivacyOverviewCard extends StatelessWidget {
  const PrivacyOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppMysticalCard(
      borderColor: AppColors.richGold.withValues(alpha: 0.32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.shield_outlined,
                size: 18,
                color: AppColors.richGold,
              ),
              8.width,
              Text(
                LocaleKey.privacyOverviewTitle.tr,
                style: AppStyles.h5(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          10.height,
          Text(
            LocaleKey.privacyOverviewBody.tr,
            style: AppStyles.bodySmall(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
