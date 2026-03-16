import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/core/model/comparison_profile.dart';
import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/ui/comparison_result/components/comparison_result_content.dart';
import 'package:test/src/ui/comparison_result/components/comparison_result_header.dart';
import 'package:test/src/ui/comparison_result/interactor/comparison_result_bloc.dart';
import 'package:test/src/ui/comparison_result/interactor/comparison_result_state.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_state.dart';
import 'package:test/src/ui/widgets/app_mystical_scaffold.dart';
import 'package:test/src/ui/widgets/app_state_view.dart';
import 'package:test/src/utils/app_pages.dart';

class ComparisonResultPage extends StatelessWidget {
  const ComparisonResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final MainSessionBloc sessionCubit = Get.find<MainSessionBloc>();
    final ComparisonResultBloc bloc = Get.isRegistered<ComparisonResultBloc>()
        ? Get.find<ComparisonResultBloc>()
        : Get.put<ComparisonResultBloc>(
            ComparisonResultBloc(
              contentRepository: Get.find<INumerologyContentRepository>(),
            ),
          );
    final ComparisonProfile? targetProfile = _targetProfileFromArgs(
      Get.arguments,
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
            final selfProfile = sessionState.currentProfile;
            if (selfProfile == null || targetProfile == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  _onBack(context);
                }
              });
              return const SizedBox.shrink();
            }

            bloc.load(
              selfProfile: selfProfile,
              targetProfile: targetProfile,
              languageCode: Get.locale?.languageCode ?? 'vi',
            );

            return AppStateView(
              status: sessionState.viewState,
              onRetry: sessionCubit.initialize,
              success: BlocBuilder<ComparisonResultBloc, ComparisonResultState>(
                bloc: bloc,
                builder: (BuildContext context, ComparisonResultState state) {
                  return Column(
                    children: <Widget>[
                      ComparisonResultHeader(onBackTap: () => _onBack(context)),
                      Expanded(
                        child: SingleChildScrollView(
                          child: ComparisonResultContent(state: state),
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

  ComparisonProfile? _targetProfileFromArgs(Object? args) {
    if (args is Map<String, dynamic>) {
      return ComparisonProfile.fromJson(args);
    }
    if (args is Map) {
      return ComparisonProfile.fromJson(Map<String, dynamic>.from(args));
    }
    return null;
  }

  void _onBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Get.offAllNamed(AppPages.main);
  }
}
