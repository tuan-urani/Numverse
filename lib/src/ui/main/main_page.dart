import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/ui/compatibility/compatibility_page.dart';
import 'package:test/src/ui/main/interactor/main_navigation_bloc.dart';
import 'package:test/src/ui/numai/numai_page.dart';
import 'package:test/src/ui/profile/profile_page.dart';
import 'package:test/src/ui/today/today_page.dart';
import 'package:test/src/ui/widgets/app_bottom_nav_bar.dart';
import 'package:test/src/ui/widgets/app_mystical_scaffold.dart';

import 'package:test/src/ui/main/interactor/main_session_bloc.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  late final MainSessionBloc _sessionBloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionBloc = Get.find<MainSessionBloc>();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _sessionBloc.refreshTimeLifeForCurrentProfile();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MainNavigationBloc navigationBloc = Get.find<MainNavigationBloc>();

    return BlocBuilder<MainNavigationBloc, int>(
      bloc: navigationBloc,
      builder: (BuildContext context, int currentIndex) {
        return AppMysticalScaffold(
          bottomNavigationBar: AppBottomNavBar(
            items: buildMainBottomNavItems(),
            currentIndex: currentIndex,
            onTap: navigationBloc.selectTab,
          ),
          child: IndexedStack(
            index: currentIndex,
            children: const <Widget>[
              TodayPage(),
              CompatibilityPage(),
              NumAiPage(),
              ProfilePage(),
            ],
          ),
        );
      },
    );
  }
}
