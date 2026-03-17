import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/core/model/comparison_profile.dart';
import 'package:test/src/core/model/compatibility_history_item.dart';
import 'package:test/src/core/model/user_profile.dart';
import 'package:test/src/helper/compatibility_scoring.dart';
import 'package:test/src/helper/numerology_helper.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/compatibility/components/compatibility_add_profile_dialog.dart';
import 'package:test/src/ui/compatibility/components/compatibility_content.dart';
import 'package:test/src/ui/compatibility/components/compatibility_profile_input_dialog.dart';
import 'package:test/src/ui/compatibility/interactor/compatibility_constants.dart';
import 'package:test/src/ui/compatibility/interactor/compatibility_state.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_state.dart';
import 'package:test/src/ui/profile/components/profile_soul_points_actions_dialog.dart';
import 'package:test/src/ui/widgets/app_mystical_scaffold.dart';
import 'package:test/src/ui/widgets/app_state_view.dart';
import 'package:test/src/ui/widgets/soul_points_insufficient_dialog.dart';
import 'package:test/src/utils/app_pages.dart';
import 'package:test/src/utils/tab_navigation_helper.dart';

class CompatibilityPage extends StatelessWidget {
  const CompatibilityPage({super.key});

  static const int _adRewardPointsPerWatch = 5;

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
                  onNeedMorePointsTap: () => _showSoulPointsActionDialog(
                    context,
                    sessionCubit: sessionCubit,
                    sessionState: sessionState,
                  ),
                  historyItems: sessionState.compatibilityHistory,
                  onHistoryTap: (CompatibilityHistoryItem item) async {
                    await TabNavigationHelper.pushCommonRoute(
                      AppPages.comparisonResult,
                      arguments: item.toJson(),
                    );
                  },
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
      await SoulPointsInsufficientDialog.show(
        context,
        requiredPoints: kCompatibilityComparisonCost,
        onWatchAdTap: _onWatchAdTap,
        onBuyPointsTap: _onBuyPointsTap,
      );
      return;
    }

    final DateTime comparedAt = DateTime.now();
    final String requestId =
        'compat:${comparedAt.microsecondsSinceEpoch}:${selected.id}';

    final bool canDeduct = await sessionCubit.deductSoulPoints(
      kCompatibilityComparisonCost,
      sourceType: 'compatibility_compare',
      metadata: const <String, dynamic>{'screen': 'compatibility'},
      requestId: requestId,
    );
    if (!context.mounted) {
      return;
    }
    if (!canDeduct) {
      await SoulPointsInsufficientDialog.show(
        context,
        requiredPoints: kCompatibilityComparisonCost,
        onWatchAdTap: _onWatchAdTap,
        onBuyPointsTap: _onBuyPointsTap,
      );
      return;
    }

    final UserProfile selfProfile = latestSessionState.currentProfile!;
    final CompatibilityHistoryItem historyItem = _buildHistoryItem(
      selfProfile: selfProfile,
      targetProfile: selected,
      comparedAt: comparedAt,
      requestId: requestId,
    );
    try {
      await sessionCubit.saveCompatibilityHistory(historyItem);
    } catch (_) {
      // Keep navigation flow smooth even if history persistence fails.
    }
    if (!context.mounted) {
      return;
    }

    await TabNavigationHelper.pushCommonRoute(
      AppPages.comparisonResult,
      arguments: historyItem.toJson(),
    );
  }

  Future<void> _onWatchAdTap() async {
    Get.snackbar(
      LocaleKey.commonComingSoon.tr,
      LocaleKey.commonComingSoon.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _showSoulPointsActionDialog(
    BuildContext context, {
    required MainSessionBloc sessionCubit,
    required MainSessionState sessionState,
  }) async {
    await ProfileSoulPointsActionsDialog.show(
      context,
      adEarnedToday: sessionState.dailyAdEarnings,
      adDailyLimit: sessionState.dailyAdLimit,
      onWatchAdTap: () async {
        await sessionCubit.claimAdReward(amount: _adRewardPointsPerWatch);
      },
      onBuyPointsTap: _onBuyPointsTap,
    );
  }

  Future<void> _onBuyPointsTap() async {
    await TabNavigationHelper.pushCommonRoute(AppPages.subscription);
  }

  CompatibilityHistoryItem _buildHistoryItem({
    required UserProfile selfProfile,
    required ComparisonProfile targetProfile,
    required DateTime comparedAt,
    required String requestId,
  }) {
    final int selfLifePath = NumerologyHelper.getLifePathNumber(
      selfProfile.birthDate,
    );
    final int selfSoul = NumerologyHelper.getSoulUrgeNumber(selfProfile.name);
    final int selfPersonality = NumerologyHelper.getPersonalityNumber(
      selfProfile.name,
    );
    final int selfExpression = NumerologyHelper.getExpressionNumber(
      selfProfile.name,
    );
    final int targetSoul = NumerologyHelper.getSoulUrgeNumber(
      targetProfile.name,
    );
    final int targetPersonality = NumerologyHelper.getPersonalityNumber(
      targetProfile.name,
    );
    final int targetExpression = NumerologyHelper.getExpressionNumber(
      targetProfile.name,
    );

    final CompatibilityScoreBreakdown scores = CompatibilityScoring.calculate(
      selfLifePath: selfLifePath,
      selfExpression: selfExpression,
      selfPersonality: selfPersonality,
      selfSoul: selfSoul,
      targetLifePath: targetProfile.lifePathNumber,
      targetExpression: targetExpression,
      targetPersonality: targetPersonality,
      targetSoul: targetSoul,
    );

    return CompatibilityHistoryItem(
      id: requestId,
      requestId: requestId,
      primaryProfileId: selfProfile.id,
      primaryName: selfProfile.name,
      primaryBirthDate: selfProfile.birthDate,
      primaryLifePath: selfLifePath,
      primarySoul: selfSoul,
      primaryPersonality: selfPersonality,
      primaryExpression: selfExpression,
      targetProfileId: targetProfile.id,
      targetName: targetProfile.name,
      targetRelation: targetProfile.relation,
      targetBirthDate: targetProfile.birthDate,
      targetLifePath: targetProfile.lifePathNumber,
      targetSoul: targetSoul,
      targetPersonality: targetPersonality,
      targetExpression: targetExpression,
      overallScore: scores.overall,
      coreScore: scores.core,
      communicationScore: scores.communication,
      soulScore: scores.soul,
      personalityScore: scores.personality,
      createdAt: comparedAt,
    );
  }
}
