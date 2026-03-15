import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/settings/interactor/settings_state.dart';
import 'package:test/src/ui/widgets/app_mystical_card.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class SettingsAppearanceCard extends StatelessWidget {
  const SettingsAppearanceCard({
    required this.state,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    super.key,
  });

  final SettingsState state;
  final ValueChanged<SettingsThemeMode> onThemeChanged;
  final ValueChanged<SettingsLanguage> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    return AppMysticalCard(
      borderColor: AppColors.border.withValues(alpha: 0.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            LocaleKey.settingsSectionAppearance.tr,
            style: AppStyles.h5(fontWeight: FontWeight.w700),
          ),
          14.height,
          Row(
            children: <Widget>[
              Icon(
                state.theme == SettingsThemeMode.dark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                size: 18,
                color: AppColors.richGold,
              ),
              10.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      LocaleKey.settingsThemeTitle.tr,
                      style: AppStyles.bodyMedium(fontWeight: FontWeight.w600),
                    ),
                    2.height,
                    Text(
                      state.theme == SettingsThemeMode.dark
                          ? LocaleKey.settingsThemeDark.tr
                          : LocaleKey.settingsThemeLight.tr,
                      style: AppStyles.caption(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              _ThemeButton(
                icon: Icons.light_mode_rounded,
                active: state.theme == SettingsThemeMode.light,
                onTap: () => onThemeChanged(SettingsThemeMode.light),
              ),
              8.width,
              _ThemeButton(
                icon: Icons.dark_mode_rounded,
                active: state.theme == SettingsThemeMode.dark,
                onTap: () => onThemeChanged(SettingsThemeMode.dark),
              ),
            ],
          ),
          14.height,
          Container(height: 1, color: AppColors.border.withValues(alpha: 0.48)),
          14.height,
          Row(
            children: <Widget>[
              const Icon(
                Icons.language_rounded,
                size: 18,
                color: AppColors.richGold,
              ),
              10.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      LocaleKey.settingsLanguageTitle.tr,
                      style: AppStyles.bodyMedium(fontWeight: FontWeight.w600),
                    ),
                    2.height,
                    Text(
                      state.language == SettingsLanguage.vi
                          ? LocaleKey.settingsLanguageVietnamese.tr
                          : LocaleKey.settingsLanguageEnglish.tr,
                      style: AppStyles.caption(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.7),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<SettingsLanguage>(
                    dropdownColor: AppColors.card,
                    value: state.language,
                    style: AppStyles.bodySmall(),
                    iconEnabledColor: AppColors.richGold,
                    onChanged: (SettingsLanguage? value) {
                      if (value == null) {
                        return;
                      }
                      onLanguageChanged(value);
                    },
                    items: <DropdownMenuItem<SettingsLanguage>>[
                      DropdownMenuItem<SettingsLanguage>(
                        value: SettingsLanguage.vi,
                        child: Text(LocaleKey.settingsLanguageVietnamese.tr),
                      ),
                      DropdownMenuItem<SettingsLanguage>(
                        value: SettingsLanguage.en,
                        child: Text(LocaleKey.settingsLanguageEnglish.tr),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active
              ? AppColors.richGold.withValues(alpha: 0.2)
              : AppColors.background.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? AppColors.richGold.withValues(alpha: 0.4)
                : AppColors.border.withValues(alpha: 0.8),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? AppColors.richGold : AppColors.textMuted,
        ),
      ),
    );
  }
}
