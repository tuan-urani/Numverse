import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/core/service/admob_rewarded_ad_service.dart';
import 'package:test/src/ui/compatibility/components/compatibility_profile_input_dialog.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_error_resolver.dart';
import 'package:test/src/ui/main/interactor/main_session_state.dart';
import 'package:test/src/ui/profile/components/profile_auth_dialog.dart';
import 'package:test/src/ui/profile/components/profile_header.dart';
import 'package:test/src/ui/profile/components/profile_identity_card.dart';
import 'package:test/src/ui/profile/components/profile_manage_bottom_sheet.dart';
import 'package:test/src/ui/profile/components/profile_reading_section.dart';
import 'package:test/src/ui/profile/components/profile_soul_points_actions_dialog.dart';
import 'package:test/src/ui/profile/components/profile_settings_bottom_sheet.dart';
import 'package:test/src/ui/profile/interactor/profile_state.dart';
import 'package:test/src/ui/widgets/ad_reward_claim_flow.dart';
import 'package:test/src/ui/widgets/app_state_view.dart';
import 'package:test/src/utils/app_assets.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_pages.dart';
import 'package:test/src/utils/app_styles.dart';
import 'package:test/src/utils/tab_navigation_helper.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const int _adRewardPointsPerWatch = 5;

  late final MainSessionBloc _sessionBloc;
  late final AdMobRewardedAdService _adMobRewardedAdService;
  bool _isDeletingUserData = false;

  @override
  void initState() {
    super.initState();
    _sessionBloc = Get.find<MainSessionBloc>();
    _adMobRewardedAdService = Get.find<AdMobRewardedAdService>();

    if (_sessionBloc.state.viewState == AppViewStateStatus.loading) {
      _sessionBloc.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainSessionBloc, MainSessionState>(
      bloc: _sessionBloc,
      builder: (BuildContext context, MainSessionState state) {
        final bool showUnbackedSubtitle =
            state.hasAnyProfile && !state.isRegisteredUser;
        final String headerSubtitle = showUnbackedSubtitle
            ? LocaleKey.profileSubtitleUnbacked.tr
            : LocaleKey.profileSubtitle.tr;
        final String? headerSubtitleAction = showUnbackedSubtitle
            ? LocaleKey.profileGuestAuthAction.tr
            : null;
        return AppStateView(
          status: state.viewState,
          onRetry: _sessionBloc.initialize,
          success: Stack(
            children: <Widget>[
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ProfileHeader(
                        subtitle: headerSubtitle,
                        subtitleActionLabel: headerSubtitleAction,
                        onTapSubtitleAction: showUnbackedSubtitle
                            ? () => _showAuthDialog(context)
                            : null,
                        onOpenSettings: () =>
                            _showSettingsSheet(context, state),
                      ),
                      20.height,
                      ProfileIdentityCard(
                        sessionState: state,
                        onTapManageProfiles: () =>
                            _showProfileManageSheet(context),
                        onTapEarnMorePoints: () =>
                            _showSoulPointsActionDialog(context),
                      ),
                      20.height,
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              ProfileReadingSection(
                                sections: _buildReadingSections(),
                                hasProfile: state.hasAnyProfile,
                                onTapSection: (ProfileReadingSectionItem item) {
                                  TabNavigationHelper.pushCommonRoute(
                                    item.route,
                                  );
                                },
                                onTapLocked: () =>
                                    _showCreateProfileDialog(context),
                                onTapNumAi: () =>
                                    TabNavigationHelper.navigateFromMain(
                                      AppPages.numai,
                                    ),
                              ),
                              84.height,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isDeletingUserData) const _ProfileDeleteUserDataOverlay(),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCreateProfileDialog(BuildContext context) async {
    await CompatibilityProfileInputDialog.show(
      context,
      onSubmit: (String name, DateTime birthDate) async {
        await _sessionBloc.addProfile(name: name, birthDate: birthDate);
      },
    );
  }

  Future<void> _showSoulPointsActionDialog(BuildContext context) async {
    await ProfileSoulPointsActionsDialog.show(
      context,
      sessionBloc: _sessionBloc,
      onWatchAdTap: () async {
        await AdRewardClaimFlow.watchAdThenClaim(
          sessionBloc: _sessionBloc,
          adMobRewardedAdService: _adMobRewardedAdService,
          amount: _adRewardPointsPerWatch,
          placementCode: 'profile_soul_points_dialog',
        );
      },
    );
  }

  Future<void> _showProfileManageSheet(BuildContext context) async {
    await ProfileManageBottomSheet.show(context, sessionBloc: _sessionBloc);
  }

  Future<void> _showAuthDialog(BuildContext context) async {
    await ProfileAuthDialog.show(
      context,
      defaultTab: ProfileAuthDialogTab.register,
    );
  }

  Future<void> _showSettingsSheet(
    BuildContext context,
    MainSessionState state,
  ) async {
    final List<ProfileMenuItem> items = ProfileState.initial().menuItems;

    await ProfileSettingsBottomSheet.show(
      items: items,
      showLogout: state.isRegisteredUser && state.hasCloudSession,
      onTapItem: (ProfileMenuItem item) {
        if (_isDeletingUserData) {
          return;
        }
        Get.back<void>();
        if (item.id == kProfileDeleteUserDataMenuItemId) {
          unawaited(_handleDeleteUserData(context));
          return;
        }
        TabNavigationHelper.pushCommonRoute(item.route);
      },
      onTapLogout: () async {
        if (_isDeletingUserData) {
          return;
        }
        Get.back<void>();
        final bool confirmed = await _confirmLogout(context);
        if (!confirmed || !mounted) {
          return;
        }
        await _sessionBloc.logout();
        if (!mounted) {
          return;
        }
        Get.offAllNamed(
          AppPages.splash,
          arguments: <String, dynamic>{'skipOnboarding': true},
        );
      },
    );
  }

  Future<void> _handleDeleteUserData(BuildContext context) async {
    if (_isDeletingUserData) {
      return;
    }
    final bool confirmed = await _confirmDeleteUserData(context);
    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isDeletingUserData = true;
    });

    try {
      await _sessionBloc.deleteUserData();
      if (!mounted) {
        return;
      }
      Get.offAllNamed(
        AppPages.splash,
        arguments: <String, dynamic>{'skipOnboarding': true},
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      Get.snackbar(
        LocaleKey.commonError.tr,
        resolveMainSessionErrorMessage(error),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.card.withValues(alpha: 0.95),
        colorText: AppColors.textPrimary,
        borderColor: AppColors.error.withValues(alpha: 0.45),
        borderWidth: 1,
        margin: const EdgeInsets.all(12),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingUserData = false;
        });
      }
    }
  }

  Future<bool> _confirmLogout(BuildContext context) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(
            LocaleKey.profileLogoutConfirmTitle.tr,
            style: AppStyles.h5(fontWeight: FontWeight.w600),
          ),
          content: Text(
            LocaleKey.profileLogoutConfirmBody.tr,
            style: AppStyles.bodyMedium(color: AppColors.textSecondary),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                LocaleKey.commonCancel.tr,
                style: AppStyles.bodyMedium(color: AppColors.textMuted),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                LocaleKey.commonConfirm.tr,
                style: AppStyles.bodyMedium(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<bool> _confirmDeleteUserData(BuildContext context) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(
            LocaleKey.profileDeleteUserDataConfirmTitle.tr,
            style: AppStyles.h5(fontWeight: FontWeight.w600),
          ),
          content: Text(
            LocaleKey.profileDeleteUserDataConfirmBody.tr,
            style: AppStyles.bodyMedium(color: AppColors.textSecondary),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                LocaleKey.commonCancel.tr,
                style: AppStyles.bodyMedium(color: AppColors.textMuted),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                LocaleKey.commonDelete.tr,
                style: AppStyles.bodyMedium(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  List<ProfileReadingSectionItem> _buildReadingSections() =>
      <ProfileReadingSectionItem>[
        ProfileReadingSectionItem(
          id: 'core',
          route: AppPages.coreNumbers,
          iconAssetPath: AppAssets.iconNumerologySecondPng,
          title: LocaleKey.readingCoreNumbersTitle.tr,
          description: LocaleKey.readingCoreNumbersBody.tr,
          lockedDescription: LocaleKey.readingCoreNumbersBody.tr,
          gradient: <Color>[
            AppColors.richGold.withValues(alpha: 0.2),
            AppColors.richGold.withValues(alpha: 0.05),
          ],
        ),
        ProfileReadingSectionItem(
          id: 'matrix',
          route: AppPages.chartMatrix,
          icon: Icons.grid_view_rounded,
          title: LocaleKey.readingChartMatrixTitle.tr,
          description: LocaleKey.readingChartMatrixBody.tr,
          lockedDescription: LocaleKey.readingChartMatrixBody.tr,
          gradient: <Color>[
            AppColors.violetAccent.withValues(alpha: 0.25),
            AppColors.violetAccent.withValues(alpha: 0.08),
          ],
        ),
        ProfileReadingSectionItem(
          id: 'lifepath',
          route: AppPages.lifePath,
          iconAssetPath: AppAssets.iconRoundMapPng,
          title: LocaleKey.readingLifePathTitle.tr,
          description: LocaleKey.readingLifePathBody.tr,
          lockedDescription: LocaleKey.readingLifePathBody.tr,
          gradient: <Color>[
            AppColors.energyTeal.withValues(alpha: 0.2),
            AppColors.energyTeal.withValues(alpha: 0.06),
          ],
        ),
        // ProfileReadingSectionItem(
        //   id: 'portrait',
        //   route: AppPages.personalPortrait,
        //   icon: Icons.account_circle_rounded,
        //   title: LocaleKey.readingPortraitTitle.tr,
        //   description: LocaleKey.readingPortraitBody.tr,
        //   lockedDescription: LocaleKey.readingPortraitBody.tr,
        //   gradient: <Color>[
        //     AppColors.richGold.withValues(alpha: 0.2),
        //     AppColors.energyPurple.withValues(alpha: 0.08),
        //   ],
        // ),
      ];
}

class _ProfileDeleteUserDataOverlay extends StatelessWidget {
  const _ProfileDeleteUserDataOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.midnight.withValues(alpha: 0.45),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.richGold,
                  ),
                ),
                12.height,
                Text(
                  LocaleKey.profileDeleteUserDataProcessing.tr,
                  style: AppStyles.bodyMedium(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
