import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/today/interactor/today_state.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_dimensions.dart';
import 'package:test/src/utils/app_styles.dart';

class TodayTabSwitch extends StatelessWidget {
  const TodayTabSwitch({
    required this.currentTab,
    required this.onTabSelected,
    super.key,
  });

  final TodayTab currentTab;
  final ValueChanged<TodayTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.deepViolet.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _TabButton(
              active: currentTab == TodayTab.universal,
              label: LocaleKey.todayTabUniversal.tr,
              icon: Icons.public,
              onTap: () => onTabSelected(TodayTab.universal),
            ),
          ),
          4.width,
          Expanded(
            child: _TabButton(
              active: currentTab == TodayTab.personal,
              label: LocaleKey.todayTabPersonal.tr,
              icon: Icons.person,
              onTap: () => onTabSelected(TodayTab.personal),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.active,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final bool active;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          color: active ? AppColors.card : AppColors.transparent,
          border: Border.all(
            color: active
                ? AppColors.richGold.withValues(alpha: 0.26)
                : AppColors.transparent,
          ),
          boxShadow: active
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 16,
              color: active ? AppColors.richGold : AppColors.textMuted,
            ),
            6.width,
            Text(
              label,
              style: AppStyles.bodyMedium(
                color: active ? AppColors.richGold : AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
