import 'package:flutter/material.dart';
import 'package:test/src/ui/numai/numai_page.dart';
import 'package:test/src/ui/routing/common_router.dart';

class AiRouter {
  static String currentRoute = '/';
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    currentRoute = settings.name ?? '/';
    switch (settings.name) {
      case '/':
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const NumAiPage(),
        );
      default:
        return CommonRouter.onGenerateRoute(settings);
    }
  }
}
