import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/compatibility/components/compatibility_profile_input_dialog.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_state.dart';
import 'package:test/src/ui/profile/components/profile_header.dart';
import 'package:test/src/ui/profile/components/profile_identity_card.dart';
import 'package:test/src/ui/profile/components/profile_reading_section.dart';
import 'package:test/src/ui/profile/components/profile_settings_bottom_sheet.dart';
import 'package:test/src/ui/profile/interactor/profile_state.dart';
import 'package:test/src/ui/widgets/app_state_view.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_pages.dart';
import 'package:test/src/utils/app_styles.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final MainSessionBloc _sessionBloc;

  @override
  void initState() {
    super.initState();
    _sessionBloc = Get.find<MainSessionBloc>();

    if (_sessionBloc.state.viewState == AppViewStateStatus.loading) {
      _sessionBloc.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainSessionBloc, MainSessionState>(
      bloc: _sessionBloc,
      builder: (BuildContext context, MainSessionState state) {
        return AppStateView(
          status: state.viewState,
          onRetry: _sessionBloc.initialize,
          success: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ProfileHeader(
                    onOpenSettings: () => _showSettingsSheet(context, state),
                  ),
                  20.height,
                  ProfileIdentityCard(sessionState: state),
                  20.height,
                  ProfileReadingSection(
                    sections: _buildReadingSections(),
                    hasProfile: state.hasAnyProfile,
                    onTapSection: (ProfileReadingSectionItem item) {
                      Get.toNamed(item.route);
                    },
                    onTapLocked: () => _showCreateProfileDialog(context),
                    onTapNumAi: () => Get.toNamed(AppPages.numai),
                  ),
                  84.height,
                ],
              ),
            ),
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

  Future<void> _showSettingsSheet(
    BuildContext context,
    MainSessionState state,
  ) async {
    final List<ProfileMenuItem> items = ProfileState.initial().menuItems;

    await ProfileSettingsBottomSheet.show(
      context,
      items: items,
      showLogout: state.isAuthenticated,
      onTapItem: (ProfileMenuItem item) {
        Navigator.of(context).pop();
        Get.toNamed(item.route);
      },
      onTapLogout: () async {
        Navigator.of(context).pop();
        final bool confirmed = await _confirmLogout(context);
        if (!confirmed || !mounted) {
          return;
        }
        await _sessionBloc.logout();
        if (!mounted) {
          return;
        }
        Get.offAllNamed(AppPages.main);
      },
    );
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

  List<ProfileReadingSectionItem> _buildReadingSections() =>
      <ProfileReadingSectionItem>[
        ProfileReadingSectionItem(
          id: 'core',
          route: AppPages.coreNumbers,
          icon: Icons.star_rounded,
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
          icon: Icons.trending_up_rounded,
          title: LocaleKey.readingLifePathTitle.tr,
          description: LocaleKey.readingLifePathBody.tr,
          lockedDescription: LocaleKey.readingLifePathBody.tr,
          gradient: <Color>[
            AppColors.energyTeal.withValues(alpha: 0.2),
            AppColors.energyTeal.withValues(alpha: 0.06),
          ],
        ),
        ProfileReadingSectionItem(
          id: 'portrait',
          route: AppPages.personalPortrait,
          icon: Icons.account_circle_rounded,
          title: LocaleKey.readingPortraitTitle.tr,
          description: LocaleKey.readingPortraitBody.tr,
          lockedDescription: LocaleKey.readingPortraitBody.tr,
          gradient: <Color>[
            AppColors.richGold.withValues(alpha: 0.2),
            AppColors.energyPurple.withValues(alpha: 0.08),
          ],
        ),
      ];
}
