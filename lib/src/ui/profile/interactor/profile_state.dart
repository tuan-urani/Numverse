import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/utils/app_pages.dart';

class ProfileState extends Equatable {
  const ProfileState({required this.menuItems});

  factory ProfileState.initial() {
    return const ProfileState(
      menuItems: <ProfileMenuItem>[
        ProfileMenuItem(
          id: 'settings',
          titleKey: LocaleKey.profileSettings,
          subtitleKey: LocaleKey.profileMenuSettingsSubtitle,
          route: AppPages.settings,
          icon: Icons.settings_outlined,
        ),
        ProfileMenuItem(
          id: 'privacy-policy',
          titleKey: LocaleKey.privacyDocPolicyTitle,
          subtitleKey: LocaleKey.profileMenuPrivacySubtitle,
          route: AppPages.privacyPolicy,
          icon: Icons.description_outlined,
        ),
        ProfileMenuItem(
          id: 'terms-of-use',
          titleKey: LocaleKey.privacyDocTermsTitle,
          subtitleKey: LocaleKey.profileMenuPrivacySubtitle,
          route: AppPages.termsOfUse,
          icon: Icons.description_outlined,
        ),
        ProfileMenuItem(
          id: 'help',
          titleKey: LocaleKey.profileHelp,
          subtitleKey: LocaleKey.profileMenuHelpSubtitle,
          route: AppPages.help,
          icon: Icons.help_outline_rounded,
        ),
      ],
    );
  }

  final List<ProfileMenuItem> menuItems;

  @override
  List<Object?> get props => <Object?>[menuItems];
}

class ProfileMenuItem extends Equatable {
  const ProfileMenuItem({
    required this.id,
    required this.titleKey,
    required this.subtitleKey,
    required this.route,
    required this.icon,
  });

  final String id;
  final String titleKey;
  final String subtitleKey;
  final String route;
  final IconData icon;

  @override
  List<Object?> get props => <Object?>[id, titleKey, subtitleKey, route, icon];
}
