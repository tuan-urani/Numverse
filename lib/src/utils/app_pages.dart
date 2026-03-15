import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/ui/angel_numbers/angel_numbers_page.dart';
import 'package:test/src/ui/angel_numbers/binding/angel_numbers_binding.dart';
import 'package:test/src/ui/chart_matrix/binding/chart_matrix_binding.dart';
import 'package:test/src/ui/chart_matrix/chart_matrix_page.dart';
import 'package:test/src/ui/comparison_result/binding/comparison_result_binding.dart';
import 'package:test/src/ui/comparison_result/comparison_result_page.dart';
import 'package:test/src/ui/compatibility/binding/compatibility_binding.dart';
import 'package:test/src/ui/core_numbers/binding/core_numbers_binding.dart';
import 'package:test/src/ui/core_numbers/core_numbers_page.dart';
import 'package:test/src/ui/daily_message/binding/daily_message_binding.dart';
import 'package:test/src/ui/daily_message/daily_message_page.dart';
import 'package:test/src/ui/help/binding/help_binding.dart';
import 'package:test/src/ui/help/help_page.dart';
import 'package:test/src/ui/life_path/binding/life_path_binding.dart';
import 'package:test/src/ui/life_path/life_path_page.dart';
import 'package:test/src/ui/login/binding/login_binding.dart';
import 'package:test/src/ui/login/login_page.dart';
import 'package:test/src/ui/lucky_number/binding/lucky_number_binding.dart';
import 'package:test/src/ui/lucky_number/lucky_number_page.dart';
import 'package:test/src/ui/main/binding/main_binding.dart';
import 'package:test/src/ui/main/interactor/main_navigation_bloc.dart';
import 'package:test/src/ui/main/main_page.dart';
import 'package:test/src/ui/month_detail/binding/month_detail_binding.dart';
import 'package:test/src/ui/month_detail/month_detail_page.dart';
import 'package:test/src/ui/my_profile/binding/my_profile_binding.dart';
import 'package:test/src/ui/my_profile/my_profile_page.dart';
import 'package:test/src/ui/notifications/binding/notifications_binding.dart';
import 'package:test/src/ui/notifications/notifications_page.dart';
import 'package:test/src/ui/numai/binding/numai_binding.dart';
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
import 'package:test/src/ui/profile/binding/profile_binding.dart';
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
import 'package:test/src/ui/today_detail/binding/today_detail_binding.dart';
import 'package:test/src/ui/today_detail/today_detail_page.dart';
import 'package:test/src/ui/universal_day/binding/universal_day_binding.dart';
import 'package:test/src/ui/universal_day/universal_day_page.dart';
import 'package:test/src/ui/year_detail/binding/year_detail_binding.dart';
import 'package:test/src/ui/year_detail/year_detail_page.dart';

class AppPages {
  AppPages._();

  static const String splash = '/splash';
  static const String main = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';
  static const String home = '/home';

  static const String today = '/today';
  static const String reading = '/reading';
  static const String compatibility = '/compatibility';
  static const String numai = '/numai';
  static const String profile = '/profile';

  static const String todayDetail = '/today-detail';
  static const String monthDetail = '/month-detail';
  static const String yearDetail = '/year-detail';
  static const String phaseDetail = '/phase-detail';

  static const String coreNumbers = '/core-numbers';
  static const String chartMatrix = '/chart-matrix';
  static const String lifePath = '/life-path';
  static const String personalPortrait = '/personal-portrait';

  static const String comparisonResult = '/comparison-result';
  static const String numaiChat = '/numai-chat';
  static const String myProfile = '/my-profile';
  static const String savedProfiles = '/saved-profiles';
  static const String subscription = '/subscription';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String privacy = '/privacy';
  static const String help = '/help';

  static const String universalDay = '/universal-day';
  static const String luckyNumber = '/lucky-number';
  static const String dailyMessage = '/daily-message';
  static const String angelNumbers = '/angel-numbers';
  static const String numberLibrary = '/number-library';

  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    GetPage(name: splash, page: () => const SplashPage()),
    GetPage(
      name: main,
      page: () => const MainPage(),
      bindings: <Bindings>[
        MainBinding(),
        TodayBinding(),
        CompatibilityBinding(),
        NumAiBinding(),
        ProfileBinding(),
      ],
    ),
    GetPage(
      name: login,
      page: () => const LoginPage(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: register,
      page: () => const LoginPage(),
      binding: LoginBinding(),
    ),
    GetPage(name: onboarding, page: () => const OnboardingPage()),
    GetPage(
      name: home,
      page: () => const _MainTabEntry(tabIndex: 0),
      bindings: <Bindings>[MainBinding(), TodayBinding()],
    ),
    GetPage(
      name: today,
      page: () => const _MainTabEntry(tabIndex: 0),
      bindings: <Bindings>[MainBinding(), TodayBinding()],
    ),
    GetPage(
      name: reading,
      page: () => const ReadingPage(),
      binding: ReadingBinding(),
    ),
    GetPage(
      name: compatibility,
      page: () => const _MainTabEntry(tabIndex: 1),
      bindings: <Bindings>[MainBinding(), CompatibilityBinding()],
    ),
    GetPage(
      name: numai,
      page: () => const _MainTabEntry(tabIndex: 2),
      bindings: <Bindings>[MainBinding(), NumAiBinding()],
    ),
    GetPage(
      name: profile,
      page: () => const _MainTabEntry(tabIndex: 3),
      bindings: <Bindings>[MainBinding(), ProfileBinding()],
    ),
    GetPage(
      name: todayDetail,
      page: () => const TodayDetailPage(),
      binding: TodayDetailBinding(),
    ),
    GetPage(
      name: monthDetail,
      page: () => const MonthDetailPage(),
      binding: MonthDetailBinding(),
    ),
    GetPage(
      name: yearDetail,
      page: () => const YearDetailPage(),
      binding: YearDetailBinding(),
    ),
    GetPage(
      name: phaseDetail,
      page: () => const PhaseDetailPage(),
      binding: PhaseDetailBinding(),
    ),
    GetPage(
      name: coreNumbers,
      page: () => const CoreNumbersPage(),
      binding: CoreNumbersBinding(),
    ),
    GetPage(
      name: chartMatrix,
      page: () => const ChartMatrixPage(),
      binding: ChartMatrixBinding(),
    ),
    GetPage(
      name: lifePath,
      page: () => const LifePathPage(),
      binding: LifePathBinding(),
    ),
    GetPage(
      name: personalPortrait,
      page: () => const PersonalPortraitPage(),
      binding: PersonalPortraitBinding(),
    ),
    GetPage(
      name: comparisonResult,
      page: () => const ComparisonResultPage(),
      bindings: <Bindings>[MainBinding(), ComparisonResultBinding()],
    ),
    GetPage(
      name: numaiChat,
      page: () => const NumAiChatPage(),
      binding: NumAiChatBinding(),
    ),
    GetPage(
      name: myProfile,
      page: () => const MyProfilePage(),
      binding: MyProfileBinding(),
    ),
    GetPage(
      name: savedProfiles,
      page: () => const SavedProfilesPage(),
      binding: SavedProfilesBinding(),
    ),
    GetPage(
      name: subscription,
      page: () => const SubscriptionPage(),
      binding: SubscriptionBinding(),
    ),
    GetPage(
      name: settings,
      page: () => const SettingsPage(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: notifications,
      page: () => const NotificationsPage(),
      binding: NotificationsBinding(),
    ),
    GetPage(
      name: privacy,
      page: () => const PrivacyPage(),
      binding: PrivacyBinding(),
    ),
    GetPage(name: help, page: () => const HelpPage(), binding: HelpBinding()),
    GetPage(
      name: universalDay,
      page: () => const UniversalDayPage(),
      binding: UniversalDayBinding(),
    ),
    GetPage(
      name: luckyNumber,
      page: () => const LuckyNumberPage(),
      binding: LuckyNumberBinding(),
    ),
    GetPage(
      name: dailyMessage,
      page: () => const DailyMessagePage(),
      binding: DailyMessageBinding(),
    ),
    GetPage(
      name: angelNumbers,
      page: () => const AngelNumbersPage(),
      binding: AngelNumbersBinding(),
    ),
    GetPage(
      name: numberLibrary,
      page: () => const NumberLibraryPage(),
      binding: NumberLibraryBinding(),
    ),
  ];
}

class _MainTabEntry extends StatefulWidget {
  const _MainTabEntry({required this.tabIndex});

  final int tabIndex;

  @override
  State<_MainTabEntry> createState() => _MainTabEntryState();
}

class _MainTabEntryState extends State<_MainTabEntry> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Get.isRegistered<MainNavigationBloc>()) {
        return;
      }
      Get.find<MainNavigationBloc>().selectTab(widget.tabIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const MainPage();
  }
}
