import 'package:flutter/material.dart';
import 'package:test/src/ui/routing/common_router.dart';
import 'package:test/src/ui/today/today_page.dart';

class TodayRouter {
  static String currentRoute = '/';
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    currentRoute = settings.name ?? '/';
    switch (settings.name) {
      case '/':
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const TodayPage(),
        );
      default:
        return CommonRouter.onGenerateRoute(settings);
    }
  }
}
