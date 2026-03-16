import 'package:flutter/material.dart';
import 'package:test/src/ui/compatibility/compatibility_page.dart';
import 'package:test/src/ui/routing/common_router.dart';

class CompatibilityRouter {
  static String currentRoute = '/';
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    currentRoute = settings.name ?? '/';
    switch (settings.name) {
      case '/':
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const CompatibilityPage(),
        );
      default:
        return CommonRouter.onGenerateRoute(settings);
    }
  }
}
