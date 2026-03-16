import 'package:flutter/material.dart';
import 'package:test/src/ui/profile/profile_page.dart';
import 'package:test/src/ui/routing/common_router.dart';

class ProfileRouter {
  static String currentRoute = '/';
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    currentRoute = settings.name ?? '/';
    switch (settings.name) {
      case '/':
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const ProfilePage(),
        );
      default:
        return CommonRouter.onGenerateRoute(settings);
    }
  }
}
