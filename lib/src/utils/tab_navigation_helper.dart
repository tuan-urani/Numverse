import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:test/src/enums/bottom_navigation_page.dart';
import 'package:test/src/ui/main/bloc/main_bloc.dart';
import 'package:test/src/utils/app_pages.dart';

class TabNavigationHelper {
  const TabNavigationHelper._();

  static Future<T?> pushCommonRoute<T>(
    String route, {
    Object? arguments,
  }) async {
    final NavigatorState? tabNavigator = _currentTabNavigator();
    if (tabNavigator != null) {
      return tabNavigator.pushNamed<T>(route, arguments: arguments);
    }
    return Get.toNamed<T>(route, arguments: arguments);
  }

  static Future<T?> navigateFromMain<T>(
    String route, {
    Object? arguments,
  }) async {
    final BottomNavigationPage? tab = _resolvePrimaryTab(route);
    if (tab != null) {
      if (Get.isRegistered<MainBloc>()) {
        Get.find<MainBloc>().openTab(tab);
        return null;
      }
      return Get.toNamed<T>(route, arguments: arguments);
    }

    return pushCommonRoute<T>(route, arguments: arguments);
  }

  static NavigatorState? _currentTabNavigator() {
    if (!Get.isRegistered<MainBloc>()) {
      return null;
    }
    final MainBloc mainBloc = Get.find<MainBloc>();
    return mainBloc.tabNavKeys[mainBloc.state.currentPage.index].currentState;
  }

  static BottomNavigationPage? _resolvePrimaryTab(String route) {
    switch (route) {
      case AppPages.main:
      case AppPages.home:
      case AppPages.today:
        return BottomNavigationPage.today;
      case AppPages.compatibility:
        return BottomNavigationPage.compatibility;
      case AppPages.numai:
        return BottomNavigationPage.ai;
      case AppPages.profile:
        return BottomNavigationPage.profile;
      default:
        return null;
    }
  }
}
