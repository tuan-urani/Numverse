import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_state.dart';
import 'package:test/src/ui/reading/components/reading_content.dart';
import 'package:test/src/ui/reading/components/reading_profile_dialog.dart';
import 'package:test/src/ui/reading/interactor/reading_bloc.dart';
import 'package:test/src/ui/reading/interactor/reading_state.dart';
import 'package:test/src/ui/widgets/app_state_view.dart';

class ReadingPage extends StatelessWidget {
  const ReadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final MainSessionBloc sessionCubit = Get.find<MainSessionBloc>();
    final ReadingBloc bloc = Get.isRegistered<ReadingBloc>()
        ? Get.find<ReadingBloc>()
        : Get.put<ReadingBloc>(ReadingBloc());

    if (sessionCubit.state.viewState == AppViewStateStatus.loading) {
      sessionCubit.initialize();
    }

    return MultiBlocListener(
      listeners: <BlocListener<dynamic, dynamic>>[
        BlocListener<ReadingBloc, ReadingState>(
          bloc: bloc,
          listenWhen: (ReadingState previous, ReadingState current) {
            return previous.isProfileDialogOpen != current.isProfileDialogOpen;
          },
          listener: (BuildContext context, ReadingState state) {
            if (!state.isProfileDialogOpen) {
              return;
            }

            ReadingProfileDialog.show(
              context,
              onSubmit: (String name, DateTime birthDate) async {
                await sessionCubit.addProfile(name: name, birthDate: birthDate);
              },
            ).whenComplete(bloc.closeProfileDialog);
          },
        ),
      ],
      child: BlocBuilder<MainSessionBloc, MainSessionState>(
        bloc: sessionCubit,
        builder: (BuildContext context, MainSessionState sessionState) {
          return AppStateView(
            status: sessionState.viewState,
            onRetry: sessionCubit.initialize,
            success: ReadingContent(
              profile: sessionState.currentProfile,
              onLockedTap: bloc.openProfileDialog,
            ),
          );
        },
      ),
    );
  }
}
