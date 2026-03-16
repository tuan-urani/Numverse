import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/core/model/comparison_profile.dart';
import 'package:test/src/ui/compatibility/components/compatibility_add_profile_dialog.dart';
import 'package:test/src/ui/compatibility/components/compatibility_content.dart';
import 'package:test/src/ui/compatibility/components/compatibility_insufficient_points_dialog.dart';
import 'package:test/src/ui/compatibility/components/compatibility_profile_input_dialog.dart';
import 'package:test/src/ui/compatibility/interactor/compatibility_constants.dart';
import 'package:test/src/ui/compatibility/interactor/compatibility_state.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_state.dart';
import 'package:test/src/ui/widgets/app_mystical_scaffold.dart';
import 'package:test/src/ui/widgets/app_state_view.dart';
import 'package:test/src/utils/app_pages.dart';
import 'package:test/src/utils/tab_navigation_helper.dart';

class CompatibilityPage extends StatelessWidget {
  const CompatibilityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final MainSessionBloc sessionCubit = Get.find<MainSessionBloc>();

    if (sessionCubit.state.viewState == AppViewStateStatus.loading) {
      sessionCubit.initialize();
    }

    return AppMysticalScaffold(
      child: SafeArea(
        bottom: false,
        child: BlocBuilder<MainSessionBloc, MainSessionState>(
          bloc: sessionCubit,
          builder: (BuildContext context, MainSessionState sessionState) {
            final CompatibilityState compatibilityState = CompatibilityState(
              compareProfiles: sessionState.compareProfiles,
              selectedProfileId: sessionState.selectedCompareProfileId,
            );
            return AppStateView(
              status: sessionState.viewState,
              onRetry: sessionCubit.initialize,
              success: SingleChildScrollView(
                child: CompatibilityContent(
                  state: compatibilityState,
                  currentProfile: sessionState.currentProfile,
                  soulPoints: sessionState.soulPoints,
                  comparisonCost: kCompatibilityComparisonCost,
                  onAddProfileTap: () =>
                      _onAddProfileTap(context, sessionCubit),
                  onSelectProfile: (String profileId) {
                    sessionCubit.selectCompareProfile(profileId);
                  },
                  onCompareTap: () => _onCompareTap(
                    context,
                    sessionCubit: sessionCubit,
                    sessionState: sessionState,
                    compatibilityState: compatibilityState,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onAddProfileTap(
    BuildContext context,
    MainSessionBloc sessionBloc,
  ) async {
    final CompatibilityAddProfileResult? result =
        await CompatibilityAddProfileDialog.show(context);

    if (!context.mounted || result == null) {
      return;
    }

    await sessionBloc.addCompareProfile(
      name: result.name,
      relation: result.relation,
      birthDate: result.birthDate,
    );
  }

  Future<void> _onCompareTap(
    BuildContext context, {
    required MainSessionBloc sessionCubit,
    required MainSessionState sessionState,
    required CompatibilityState compatibilityState,
  }) async {
    final ComparisonProfile? selected = compatibilityState.selectedProfile;
    if (selected == null) {
      return;
    }

    MainSessionState latestSessionState = sessionState;

    if (latestSessionState.currentProfile == null) {
      await CompatibilityProfileInputDialog.show(
        context,
        onSubmit: (String name, DateTime birthDate) async {
          await sessionCubit.addProfile(name: name, birthDate: birthDate);
        },
      );
      if (!context.mounted) {
        return;
      }
      latestSessionState = sessionCubit.state;
      if (latestSessionState.currentProfile == null) {
        return;
      }
    }

    if (latestSessionState.soulPoints < kCompatibilityComparisonCost) {
      await CompatibilityInsufficientPointsDialog.show(
        context,
        comparisonCost: kCompatibilityComparisonCost,
        onTopup: () {},
      );
      return;
    }

    final bool canDeduct = await sessionCubit.deductSoulPoints(
      kCompatibilityComparisonCost,
    );
    if (!context.mounted) {
      return;
    }
    if (!canDeduct) {
      await CompatibilityInsufficientPointsDialog.show(
        context,
        comparisonCost: kCompatibilityComparisonCost,
        onTopup: () {},
      );
      return;
    }

    await TabNavigationHelper.pushCommonRoute(
      AppPages.comparisonResult,
      arguments: selected.toJson(),
    );
  }
}
