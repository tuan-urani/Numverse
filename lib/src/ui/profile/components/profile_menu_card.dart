import 'package:flutter/material.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/ui/widgets/app_mystical_card.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class ProfileMenuCard extends StatelessWidget {
  const ProfileMenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppMysticalCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  AppColors.violetAccent.withValues(alpha: 0.22),
                  AppColors.deepViolet.withValues(alpha: 0.42),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.richGold.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(icon, color: AppColors.richGold, size: 20),
          ),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppStyles.bodyMedium(fontWeight: FontWeight.w600),
                ),
                2.height,
                Text(
                  subtitle,
                  style: AppStyles.caption(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
