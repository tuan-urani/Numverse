import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/widgets/app_mystical_card.dart';
import 'package:test/src/ui/widgets/app_primary_button.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class ProfileGuestTeaser extends StatelessWidget {
  const ProfileGuestTeaser({required this.onTapUnlock, super.key});

  final VoidCallback onTapUnlock;

  @override
  Widget build(BuildContext context) {
    return AppMysticalCard(
      borderColor: AppColors.richGold.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            LocaleKey.profileGuestTeaserTitle.tr,
            style: AppStyles.h4(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          6.height,
          Text(
            LocaleKey.profileGuestTeaserBody.tr,
            style: AppStyles.bodyMedium(color: AppColors.textSecondary),
          ),
          14.height,
          _BulletLine(
            icon: Icons.stars_rounded,
            text: LocaleKey.profileGuestTeaserPointOne.tr,
          ),
          8.height,
          _BulletLine(
            icon: Icons.calendar_month_rounded,
            text: LocaleKey.profileGuestTeaserPointTwo.tr,
          ),
          8.height,
          _BulletLine(
            icon: Icons.auto_graph_rounded,
            text: LocaleKey.profileGuestTeaserPointThree.tr,
          ),
          16.height,
          AppPrimaryButton(
            label: LocaleKey.profileGuestTeaserCta.tr,
            onPressed: onTapUnlock,
            leading: const Icon(
              Icons.lock_open_rounded,
              size: 16,
              color: AppColors.midnight,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 14, color: AppColors.richGold),
        8.width,
        Expanded(
          child: Text(
            text,
            style: AppStyles.bodySmall(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
