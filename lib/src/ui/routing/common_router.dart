import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/ui/angel_numbers/angel_numbers_page.dart';
import 'package:test/src/ui/angel_numbers/binding/angel_numbers_binding.dart';
import 'package:test/src/ui/chart_matrix/binding/chart_matrix_binding.dart';
import 'package:test/src/ui/chart_matrix/chart_matrix_page.dart';
import 'package:test/src/ui/comparison_result/binding/comparison_result_binding.dart';
import 'package:test/src/ui/comparison_result/comparison_result_page.dart';
import 'package:test/src/ui/core_numbers/binding/core_numbers_binding.dart';
import 'package:test/src/ui/core_numbers/core_numbers_page.dart';
import 'package:test/src/ui/daily_message/binding/daily_message_binding.dart';
import 'package:test/src/ui/daily_message/daily_message_page.dart';
import 'package:test/src/ui/help/binding/help_binding.dart';
import 'package:test/src/ui/help/help_page.dart';
import 'package:test/src/ui/legal_webview/legal_webview_page.dart';
import 'package:test/src/ui/life_path/binding/life_path_binding.dart';
import 'package:test/src/ui/life_path/life_path_page.dart';
import 'package:test/src/ui/login/binding/login_binding.dart';
import 'package:test/src/ui/login/login_page.dart';
import 'package:test/src/ui/lucky_number/binding/lucky_number_binding.dart';
import 'package:test/src/ui/lucky_number/lucky_number_page.dart';
import 'package:test/src/ui/month_detail/binding/month_detail_binding.dart';
import 'package:test/src/ui/month_detail/month_detail_page.dart';
import 'package:test/src/ui/my_profile/binding/my_profile_binding.dart';
import 'package:test/src/ui/my_profile/my_profile_page.dart';
import 'package:test/src/ui/notifications/binding/notifications_binding.dart';
import 'package:test/src/ui/notifications/notifications_page.dart';
import 'package:test/src/ui/numai_chat/binding/numai_chat_binding.dart';
import 'package:test/src/ui/numai_chat/numai_chat_page.dart';
import 'package:test/src/ui/number_library/binding/number_library_binding.dart';
import 'package:test/src/ui/number_library/number_library_page.dart';
import 'package:test/src/ui/onboarding/onboarding_page.dart';
import 'package:test/src/ui/personal_portrait/binding/personal_portrait_binding.dart';
import 'package:test/src/ui/personal_portrait/personal_portrait_page.dart';
import 'package:test/src/ui/phase_detail/binding/phase_detail_binding.dart';
import 'package:test/src/ui/phase_detail/phase_detail_page.dart';
import 'package:test/src/ui/privacy/binding/privacy_binding.dart';
import 'package:test/src/ui/privacy/privacy_page.dart';
import 'package:test/src/ui/reading/binding/reading_binding.dart';
import 'package:test/src/ui/reading/reading_page.dart';
import 'package:test/src/ui/saved_profiles/binding/saved_profiles_binding.dart';
import 'package:test/src/ui/saved_profiles/saved_profiles_page.dart';
import 'package:test/src/ui/settings/binding/settings_binding.dart';
import 'package:test/src/ui/settings/settings_page.dart';
import 'package:test/src/ui/splash/splash_page.dart';
import 'package:test/src/ui/subscription/binding/subscription_binding.dart';
import 'package:test/src/ui/subscription/subscription_page.dart';
import 'package:test/src/ui/today/binding/today_binding.dart';
import 'package:test/src/ui/today/today_page.dart';
import 'package:test/src/ui/today_detail/binding/today_detail_binding.dart';
import 'package:test/src/ui/today_detail/today_detail_page.dart';
import 'package:test/src/ui/universal_day/binding/universal_day_binding.dart';
import 'package:test/src/ui/universal_day/universal_day_page.dart';
import 'package:test/src/ui/year_detail/binding/year_detail_binding.dart';
import 'package:test/src/ui/year_detail/year_detail_page.dart';
import 'package:test/src/utils/app_pages.dart';

/// Router chung chứa các page phụ có thể được gọi từ các tab bottom bar.
/// Không bao gồm 4 route đại diện tab: today / compatibility / numai / profile.
class CommonRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppPages.splash:
        return _buildRoute(
          settings: settings,
          pageBuilder: (_) => const SplashPage(),
        );
      case AppPages.login:
      case AppPages.register:
        return _buildRoute(
          settings: settings,
          binding: LoginBinding(),
          pageBuilder: (_) => const LoginPage(),
        );
      case AppPages.onboarding:
        return _buildRoute(
          settings: settings,
          pageBuilder: (_) => const OnboardingPage(),
        );
      case AppPages.home:
        return _buildRoute(
          settings: settings,
          binding: TodayBinding(),
          pageBuilder: (_) => const TodayPage(),
        );
      case AppPages.reading:
        return _buildRoute(
          settings: settings,
          binding: ReadingBinding(),
          pageBuilder: (_) => const ReadingPage(),
        );
      case AppPages.todayDetail:
        return _buildRoute(
          settings: settings,
          binding: TodayDetailBinding(),
          pageBuilder: (_) => const TodayDetailPage(),
        );
      case AppPages.monthDetail:
        return _buildRoute(
          settings: settings,
          binding: MonthDetailBinding(),
          pageBuilder: (_) => const MonthDetailPage(),
        );
      case AppPages.yearDetail:
        return _buildRoute(
          settings: settings,
          binding: YearDetailBinding(),
          pageBuilder: (_) => const YearDetailPage(),
        );
      case AppPages.phaseDetail:
        return _buildRoute(
          settings: settings,
          binding: PhaseDetailBinding(),
          pageBuilder: (_) => const PhaseDetailPage(),
        );
      case AppPages.coreNumbers:
        return _buildRoute(
          settings: settings,
          binding: CoreNumbersBinding(),
          pageBuilder: (_) => const CoreNumbersPage(),
        );
      case AppPages.chartMatrix:
        return _buildRoute(
          settings: settings,
          binding: ChartMatrixBinding(),
          pageBuilder: (_) => const ChartMatrixPage(),
        );
      case AppPages.lifePath:
        return _buildRoute(
          settings: settings,
          binding: LifePathBinding(),
          pageBuilder: (_) => const LifePathPage(),
        );
      case AppPages.personalPortrait:
        return _buildRoute(
          settings: settings,
          binding: PersonalPortraitBinding(),
          pageBuilder: (_) => const PersonalPortraitPage(),
        );
      case AppPages.comparisonResult:
        return _buildRoute(
          settings: settings,
          binding: ComparisonResultBinding(),
          pageBuilder: (_) => const ComparisonResultPage(),
        );
      case AppPages.numaiChat:
        return _buildRoute(
          settings: settings,
          binding: NumAiChatBinding(),
          pageBuilder: (_) => const NumAiChatPage(),
        );
      case AppPages.myProfile:
        return _buildRoute(
          settings: settings,
          binding: MyProfileBinding(),
          pageBuilder: (_) => const MyProfilePage(),
        );
      case AppPages.savedProfiles:
        return _buildRoute(
          settings: settings,
          binding: SavedProfilesBinding(),
          pageBuilder: (_) => const SavedProfilesPage(),
        );
      case AppPages.subscription:
        return _buildRoute(
          settings: settings,
          binding: SubscriptionBinding(),
          pageBuilder: (_) => const SubscriptionPage(),
        );
      case AppPages.settings:
        return _buildRoute(
          settings: settings,
          binding: SettingsBinding(),
          pageBuilder: (_) => const SettingsPage(),
        );
      case AppPages.notifications:
        return _buildRoute(
          settings: settings,
          binding: NotificationsBinding(),
          pageBuilder: (_) => const NotificationsPage(),
        );
      case AppPages.privacy:
        return _buildRoute(
          settings: settings,
          binding: PrivacyBinding(),
          pageBuilder: (_) => const PrivacyPage(),
        );
      case AppPages.privacyPolicy:
        return _buildRoute(
          settings: settings,
          pageBuilder: (_) => LegalWebviewPage.privacyPolicy(),
        );
      case AppPages.termsOfUse:
        return _buildRoute(
          settings: settings,
          pageBuilder: (_) => LegalWebviewPage.termsOfUse(),
        );
      case AppPages.help:
        return _buildRoute(
          settings: settings,
          binding: HelpBinding(),
          pageBuilder: (_) => const HelpPage(),
        );
      case AppPages.universalDay:
        return _buildRoute(
          settings: settings,
          binding: UniversalDayBinding(),
          pageBuilder: (_) => const UniversalDayPage(),
        );
      case AppPages.luckyNumber:
        return _buildRoute(
          settings: settings,
          binding: LuckyNumberBinding(),
          pageBuilder: (_) => const LuckyNumberPage(),
        );
      case AppPages.dailyMessage:
        return _buildRoute(
          settings: settings,
          binding: DailyMessageBinding(),
          pageBuilder: (_) => const DailyMessagePage(),
        );
      case AppPages.angelNumbers:
        return _buildRoute(
          settings: settings,
          binding: AngelNumbersBinding(),
          pageBuilder: (_) => const AngelNumbersPage(),
        );
      case AppPages.numberLibrary:
        return _buildRoute(
          settings: settings,
          binding: NumberLibraryBinding(),
          pageBuilder: (_) => const NumberLibraryPage(),
        );
      default:
        return _buildRoute(
          settings: settings,
          pageBuilder: (_) => const SizedBox.shrink(),
        );
    }
  }

  static Route<dynamic> _buildRoute({
    required RouteSettings settings,
    required WidgetBuilder pageBuilder,
    Bindings? binding,
  }) {
    binding?.dependencies();
    return PageRouteBuilder<void>(
      settings: settings,
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return pageBuilder(context);
          },
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      transitionsBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final Animation<double> fadeAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            final Animation<Offset> slideAnimation =
                Tween<Offset>(
                  begin: const Offset(0.06, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                  ),
                );
            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(position: slideAnimation, child: child),
            );
          },
    );
  }
}
