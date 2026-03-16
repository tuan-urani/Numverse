import 'package:flutter/material.dart';
import 'package:test/src/locale/locale_key.dart';

enum BottomNavigationPage { today, compatibility, ai, profile }

extension BottomNavigationPageExtension on BottomNavigationPage {
  String get labelKey {
    switch (this) {
      case BottomNavigationPage.today:
        return LocaleKey.mainTabToday;
      case BottomNavigationPage.compatibility:
        return LocaleKey.mainTabCompatibility;
      case BottomNavigationPage.ai:
        return LocaleKey.mainTabNumAi;
      case BottomNavigationPage.profile:
        return LocaleKey.mainTabProfile;
    }
  }

  IconData get activeIcon {
    switch (this) {
      case BottomNavigationPage.today:
        return Icons.home_outlined;
      case BottomNavigationPage.compatibility:
        return Icons.favorite_border_rounded;
      case BottomNavigationPage.ai:
        return Icons.auto_awesome_outlined;
      case BottomNavigationPage.profile:
        return Icons.person_outline_rounded;
    }
  }

  IconData get inactiveIcon {
    switch (this) {
      case BottomNavigationPage.today:
        return Icons.home_outlined;
      case BottomNavigationPage.compatibility:
        return Icons.favorite_border_rounded;
      case BottomNavigationPage.ai:
        return Icons.auto_awesome_outlined;
      case BottomNavigationPage.profile:
        return Icons.person_outline_rounded;
    }
  }

  int get index {
    switch (this) {
      case BottomNavigationPage.today:
        return 0;
      case BottomNavigationPage.compatibility:
        return 1;
      case BottomNavigationPage.ai:
        return 2;
      case BottomNavigationPage.profile:
        return 3;
    }
  }

  IconData getIcon(bool isSelected) {
    return isSelected ? activeIcon : inactiveIcon;
  }
}

BottomNavigationPage resolveBottomNavigationPage(int tabIndex) {
  switch (tabIndex) {
    case 0:
      return BottomNavigationPage.today;
    case 1:
      return BottomNavigationPage.compatibility;
    case 2:
      return BottomNavigationPage.ai;
    case 3:
      return BottomNavigationPage.profile;
    default:
      return BottomNavigationPage.today;
  }
}
