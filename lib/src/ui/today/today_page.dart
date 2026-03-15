import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_state.dart';
import 'package:test/src/ui/today/components/today_header.dart';
import 'package:test/src/ui/today/components/today_personal_content.dart';
import 'package:test/src/ui/widgets/app_state_view.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final MainSessionBloc sessionCubit = Get.find<MainSessionBloc>();
    if (sessionCubit.state.viewState == AppViewStateStatus.loading) {
      sessionCubit.initialize();
    }

    return BlocBuilder<MainSessionBloc, MainSessionState>(
      bloc: sessionCubit,
      builder: (BuildContext context, MainSessionState sessionState) {
        return AppStateView(
          status: sessionState.viewState,
          onRetry: sessionCubit.initialize,
          success: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const TodayHeader(),
                  14.height,
                  const TodayPersonalContent(),
                  84.height,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
