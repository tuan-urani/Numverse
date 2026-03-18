import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/ui/life_path/components/life_path_content.dart';
import 'package:test/src/ui/life_path/components/life_path_header.dart';
import 'package:test/src/ui/life_path/interactor/life_path_bloc.dart';
import 'package:test/src/ui/life_path/interactor/life_path_state.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_state.dart';
import 'package:test/src/ui/widgets/app_mystical_scaffold.dart';
import 'package:test/src/ui/widgets/app_state_view.dart';
import 'package:test/src/utils/app_pages.dart';

class LifePathPage extends StatelessWidget {
  const LifePathPage({super.key});

  @override
  Widget build(BuildContext context) {
    final MainSessionBloc sessionCubit = Get.find<MainSessionBloc>();
    final LifePathBloc bloc = Get.isRegistered<LifePathBloc>()
        ? Get.find<LifePathBloc>()
        : Get.put<LifePathBloc>(
            LifePathBloc(
              contentRepository: Get.find<INumerologyContentRepository>(),
            ),
          );

    if (sessionCubit.state.viewState == AppViewStateStatus.loading) {
      sessionCubit.initialize();
    }

    return AppMysticalScaffold(
      child: SafeArea(
        bottom: false,
        child: BlocBuilder<MainSessionBloc, MainSessionState>(
          bloc: sessionCubit,
          builder: (BuildContext context, MainSessionState sessionState) {
            final String languageCode = Get.locale?.languageCode ?? 'vi';
            bloc.syncProfile(
              sessionState.currentProfile,
              languageCode: languageCode,
            );
            return AppStateView(
              status: sessionState.viewState,
              onRetry: sessionCubit.initialize,
              success: BlocBuilder<LifePathBloc, LifePathState>(
                bloc: bloc,
                builder: (BuildContext context, LifePathState state) {
                  return Column(
                    children: <Widget>[
                      LifePathHeader(onBackTap: () => _onBack(context)),
                      Expanded(
                        child: SingleChildScrollView(
                          child: LifePathContent(state: state),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _onBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Get.offAllNamed(AppPages.main);
  }
}
