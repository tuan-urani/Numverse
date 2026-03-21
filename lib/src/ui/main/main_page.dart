import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/enums/bottom_navigation_page.dart';
import 'package:test/src/core/service/interface/i_daily_alarm_notification_service.dart';
import 'package:test/src/ui/main/bloc/main_bloc.dart';
import 'package:test/src/ui/main/bloc/main_event.dart';
import 'package:test/src/ui/main/bloc/main_state.dart';
import 'package:test/src/ui/main/components/app_bottom_navigation_bar.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/routing/ai_router.dart';
import 'package:test/src/ui/routing/compatibility_router.dart';
import 'package:test/src/ui/routing/profile_router.dart';
import 'package:test/src/ui/routing/today_router.dart';
import 'package:test/src/ui/widgets/app_mystical_scaffold.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  late final MainSessionBloc _sessionBloc;
  late final MainBloc _mainBloc;
  final Map<BottomNavigationPage, Widget> _tabPages =
      <BottomNavigationPage, Widget>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionBloc = Get.find<MainSessionBloc>();
    _mainBloc = Get.find<MainBloc>()..add(const MainInitialized());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _sessionBloc.refreshTimeLifeForCurrentProfile();
      unawaited(
        Get.find<IDailyAlarmNotificationService>().bootstrap(
          localeCode: Get.locale?.languageCode,
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainBloc, MainState>(
      bloc: _mainBloc,
      buildWhen: (MainState previous, MainState current) =>
          previous.currentPage != current.currentPage,
      builder: (BuildContext context, MainState state) {
        final List<BottomNavigationPage> pages = BottomNavigationPage.values;
        final int currentIndex = pages.indexOf(state.currentPage);
        final List<Widget> children = pages
            .map<Widget>(_buildTabView)
            .toList(growable: false);

        return AppMysticalScaffold(
          bottomNavigationBar: const AppBottomNavigationBar(),
          child: IndexedStack(
            index: currentIndex < 0 ? 0 : currentIndex,
            children: children,
          ),
        );
      },
    );
  }

  Widget _buildTabView(BottomNavigationPage page) {
    return _tabPages.putIfAbsent(page, () {
      switch (page) {
        case BottomNavigationPage.today:
          return CupertinoTabView(
            navigatorKey: _mainBloc.tabNavKeys[page.index],
            onGenerateRoute: TodayRouter.onGenerateRoute,
          );
        case BottomNavigationPage.compatibility:
          return CupertinoTabView(
            navigatorKey: _mainBloc.tabNavKeys[page.index],
            onGenerateRoute: CompatibilityRouter.onGenerateRoute,
          );
        case BottomNavigationPage.ai:
          return CupertinoTabView(
            navigatorKey: _mainBloc.tabNavKeys[page.index],
            onGenerateRoute: AiRouter.onGenerateRoute,
          );
        case BottomNavigationPage.profile:
          return CupertinoTabView(
            navigatorKey: _mainBloc.tabNavKeys[page.index],
            onGenerateRoute: ProfileRouter.onGenerateRoute,
          );
      }
    });
  }
}
