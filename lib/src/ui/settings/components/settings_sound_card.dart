import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/settings/interactor/settings_state.dart';
import 'package:test/src/ui/widgets/app_mystical_card.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class SettingsSoundCard extends StatelessWidget {
  const SettingsSoundCard({
    required this.state,
    required this.onToggleDailyAlarm,
    super.key,
  });

  final SettingsState state;
  final VoidCallback onToggleDailyAlarm;

  @override
  Widget build(BuildContext context) {
    return AppMysticalCard(
      borderColor: AppColors.border.withValues(alpha: 0.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            LocaleKey.notificationsTitle.tr,
            style: AppStyles.h5(fontWeight: FontWeight.w700),
          ),
          14.height,
          _SettingSwitchRow(
            icon: Icons.alarm_on_outlined,
            title: LocaleKey.settingsDailyAlarmTitle.tr,
            subtitle: null,
            enabled: state.dailyAlarmEnabled,
            isLoading: state.dailyAlarmSyncing,
            onTap: onToggleDailyAlarm,
          ),
        ],
      ),
    );
  }
}

class _SettingSwitchRow extends StatelessWidget {
  const _SettingSwitchRow({
    required this.icon,
    required this.title,
    required this.enabled,
    required this.onTap,
    required this.subtitle,
    this.isLoading = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool enabled;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.richGold : AppColors.textMuted,
        ),
        10.width,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: AppStyles.bodyMedium(fontWeight: FontWeight.w600),
              ),
              if (subtitle != null) ...<Widget>[
                2.height,
                Text(
                  subtitle!,
                  style: AppStyles.caption(color: AppColors.textMuted),
                ),
              ],
            ],
          ),
        ),
        InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 44,
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: enabled
                  ? AppColors.richGold.withValues(alpha: 0.75)
                  : AppColors.border.withValues(alpha: 0.65),
            ),
            child: Align(
              alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
