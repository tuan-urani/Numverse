import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:test/src/enums/bottom_navigation_page.dart';
import 'package:test/src/ui/main/bloc/main_bloc.dart';
import 'package:test/src/ui/main/bloc/main_event.dart';
import 'package:test/src/ui/main/bloc/main_state.dart';
import 'package:test/src/ui/main/components/app_bottom_navigation_bar.dart';
import 'package:test/src/utils/app_colors.dart';

Map<BottomNavigationPage, Widget> pages = {};

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => Get.find<MainBloc>()..add(const MainInitialized()),
      child: BlocBuilder<MainBloc, MainState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.transparent,
            extendBody: true,
            extendBodyBehindAppBar: true,
            body: BlocBuilder<MainBloc, MainState>(
              buildWhen:
                  (previous, current) =>
                      previous.currentPage != current.currentPage,
              builder: (context, state) {
                _createPage(state.currentPage, context);
                return IndexedStack(
                  sizing: StackFit.expand,
                  index: pages.keys.toList().indexOf(state.currentPage),
                  children: pages.values.toList(),
                );
              },
            ),
            bottomNavigationBar: const AppBottomNavigationBar(),
          );
        },
      ),
    );
  }

  void _createPage(BottomNavigationPage currentPage, BuildContext context) {
    final bloc = context.read<MainBloc>();
    switch (currentPage) {
       case BottomNavigationPage.today:
      //   // if (!Get.isRegistered<TodayBloc>()) {
      //   //   TodayBinding().dependencies();
      //   // }
         pages.putIfAbsent(
           currentPage,
           () => CupertinoTabView(
             navigatorKey: bloc.tabNavKeys[0],
             // will replace by onGenerateRoute later
             builder: (_) => const SizedBox.shrink(),
      //       onGenerateRoute: TodayRouter.onGenerateRoute,
           ),
         );
         break;
       case BottomNavigationPage.compatibility:
      //   // if (!Get.isRegistered<CompatibilityBloc>()) {
      //   //   CompatibilityBinding().dependencies();
      //   // }
         pages.putIfAbsent(
           currentPage,
           () => CupertinoTabView(
             navigatorKey: bloc.tabNavKeys[1],
             // will replace by onGenerateRoute later
             builder: (_) => const SizedBox.shrink(),
      //       onGenerateRoute: CompatibilityRouter.onGenerateRoute,
           ),
         );
         break;
       case BottomNavigationPage.ai:
      //   // if (!Get.isRegistered<AiBloc>()) {
      //   //   AiBinding().dependencies();
      //   // }
         pages.putIfAbsent(
           currentPage,
           () => CupertinoTabView(
             navigatorKey: bloc.tabNavKeys[2],
             // will replace by onGenerateRoute later
             builder: (_) => const SizedBox.shrink(),
      //       onGenerateRoute: AiRouter.onGenerateRoute,
           ),
         );
         break;
       case BottomNavigationPage.profile:
      //   // if (!Get.isRegistered<ProfileBloc>()) {
      //   //   ProfileBinding().dependencies();
      //   // }
         pages.putIfAbsent(
           currentPage,
           () => CupertinoTabView(
             navigatorKey: bloc.tabNavKeys[3],
             // will replace by onGenerateRoute later
             builder: (_) => const SizedBox.shrink(),
      //       onGenerateRoute: ProfileRouter.onGenerateRoute,
           ),
         );
         break;
    }
  }
}
