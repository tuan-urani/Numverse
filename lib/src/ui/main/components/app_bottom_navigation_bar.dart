import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/enums/bottom_navigation_page.dart';
import 'package:test/src/ui/main/bloc/main_bloc.dart';
import 'package:test/src/ui/main/bloc/main_event.dart';
import 'package:test/src/ui/main/bloc/main_state.dart';
import 'package:test/src/ui/widgets/app_bottom_nav_bar.dart';

class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final MainBloc bloc = Get.find<MainBloc>();

    return BlocBuilder<MainBloc, MainState>(
      bloc: bloc,
      buildWhen: (MainState previous, MainState current) =>
          previous.currentPage != current.currentPage,
      builder: (BuildContext context, MainState state) {
        return AppBottomNavBar(
          items: buildMainBottomNavItems(),
          currentIndex: state.currentPage.index,
          onTap: (int index) {
            final BottomNavigationPage selectedPage =
                resolveBottomNavigationPage(index);

            if (selectedPage == state.currentPage) {
              bloc.popTabToRoot(selectedPage);
              return;
            }

            bloc.add(OnChangeTabEvent(selectedPage));
          },
        );
      },
    );
  }
}
