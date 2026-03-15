import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/widgets/app_mystical_card.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class HelpSupportCard extends StatelessWidget {
  const HelpSupportCard({super.key});

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
                Icons.help_outline_rounded,
                size: 18,
                color: AppColors.richGold,
              ),
              8.width,
              Text(
                LocaleKey.helpNeedSupportTitle.tr,
                style: AppStyles.h5(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          8.height,
          Text(
            LocaleKey.helpNeedSupportBody.tr,
            style: AppStyles.bodySmall(color: AppColors.textMuted),
          ),
          12.height,
          _ContactRow(
            icon: Icons.mail_outline_rounded,
            title: LocaleKey.helpContactEmailTitle.tr,
            subtitle: LocaleKey.helpContactEmailValue.tr,
          ),
          8.height,
          _ContactRow(
            icon: Icons.phone_in_talk_rounded,
            title: LocaleKey.helpContactHotlineTitle.tr,
            subtitle: LocaleKey.helpContactHotlineValue.tr,
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: AppColors.richGold),
          10.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppStyles.bodySmall(fontWeight: FontWeight.w600),
                ),
                2.height,
                Text(
                  subtitle,
                  style: AppStyles.caption(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
