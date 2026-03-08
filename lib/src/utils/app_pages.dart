import 'package:get/get.dart';

import 'package:test/src/ui/home/binding/home_binding.dart';
import 'package:test/src/ui/home/home_page.dart';
import 'package:test/src/ui/main/main_page.dart';
import 'package:test/src/ui/splash/splash_page.dart';

class AppPages {
  AppPages._();

  static const String splash = '/splash';
  static const String main = '/';
  static const String home = '/home';

  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    GetPage(name: splash, page: () => const SplashPage()),
    GetPage(name: main, page: () => const MainPage(), binding: HomeBinding()),
    GetPage(name: home, page: () => const HomePage(), binding: HomeBinding()),
  ];
}
