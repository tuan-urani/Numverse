import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/profile/interactor/profile_state.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class ProfileSettingsBottomSheet extends StatelessWidget {
  const ProfileSettingsBottomSheet({
    required this.items,
    required this.showLogout,
    required this.onTapItem,
    required this.onTapLogout,
    super.key,
  });

  final List<ProfileMenuItem> items;
  final bool showLogout;
  final ValueChanged<ProfileMenuItem> onTapItem;
  final VoidCallback onTapLogout;

  static Future<void> show(
    BuildContext context, {
    required List<ProfileMenuItem> items,
    required bool showLogout,
    required ValueChanged<ProfileMenuItem> onTapItem,
    required VoidCallback onTapLogout,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      backgroundColor: AppColors.transparent,
      builder: (BuildContext context) {
        return ProfileSettingsBottomSheet(
          items: items,
          showLogout: showLogout,
          onTapItem: onTapItem,
          onTapLogout: onTapLogout,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.9)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              12.height,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  LocaleKey.profileSettings.tr,
                  style: AppStyles.h5(fontWeight: FontWeight.w600),
                ),
              ),
              12.height,
              for (int index = 0; index < items.length; index++) ...<Widget>[
                _SettingsMenuItem(
                  item: items[index],
                  onTap: () => onTapItem(items[index]),
                ),
                if (index != items.length - 1) 4.height,
              ],
              if (showLogout) ...<Widget>[
                12.height,
                Divider(
                  color: AppColors.border.withValues(alpha: 0.7),
                  height: 1,
                ),
                12.height,
                _LogoutButton(onTap: onTapLogout),
              ],
              10.height,
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: AppColors.card.withValues(alpha: 0.38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  child: Text(
                    LocaleKey.profileSettingsSheetClose.tr,
                    style: AppStyles.bodyMedium(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsMenuItem extends StatelessWidget {
  const _SettingsMenuItem({required this.item, required this.onTap});

  final ProfileMenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
          child: Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.card.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.8),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  item.icon,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
              10.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.titleKey.tr,
                      style: AppStyles.bodyMedium(fontWeight: FontWeight.w600),
                    ),
                    1.height,
                    Text(
                      item.subtitleKey.tr,
                      style: AppStyles.caption(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
          child: Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.35),
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.logout_rounded,
                  size: 18,
                  color: AppColors.error,
                ),
              ),
              10.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      LocaleKey.profileLogoutTitle.tr,
                      style: AppStyles.bodyMedium(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    1.height,
                    Text(
                      LocaleKey.profileLogoutSubtitle.tr,
                      style: AppStyles.caption(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
