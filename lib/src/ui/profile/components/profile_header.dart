import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({required this.onOpenSettings, super.key});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                LocaleKey.profileTitle.tr,
                style: AppStyles.h2(fontWeight: FontWeight.w700),
              ),
            ),
            Material(
              color: AppColors.transparent,
              child: InkWell(
                onTap: onOpenSettings,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.richGold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.richGold.withValues(alpha: 0.22),
                    ),
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    size: 20,
                    color: AppColors.richGold,
                  ),
                ),
              ),
            ),
          ],
        ),
        4.height,
        Text(
          LocaleKey.profileSubtitle.tr,
          style: AppStyles.bodyMedium(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
