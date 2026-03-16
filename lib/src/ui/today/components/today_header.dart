import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/core/model/user_profile.dart';
import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/compatibility/components/compatibility_profile_input_dialog.dart';
import 'package:test/src/ui/main/interactor/main_navigation_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_state.dart';
import 'package:test/src/ui/widgets/app_primary_button.dart';
import 'package:test/src/ui/widgets/app_profile_list.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_dimensions.dart';
import 'package:test/src/utils/app_pages.dart';
import 'package:test/src/utils/app_styles.dart';

class TodayHeader extends StatelessWidget {
  const TodayHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainSessionBloc, MainSessionState>(
      bloc: Get.find<MainSessionBloc>(),
      builder: (BuildContext context, MainSessionState state) {
        final String greeting = _greeting();
        final String firstName = _firstName(state.currentProfile?.name);
        final String profileDisplayName = _profileDisplayName(firstName);
        final String viewingName =
            state.currentProfile?.name.trim().isNotEmpty == true
            ? state.currentProfile!.name
            : LocaleKey.todayViewingGuest.tr;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    profileDisplayName.isEmpty
                        ? '$greeting ✨'
                        : '$greeting, $profileDisplayName ✨',
                    style: AppStyles.h2(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                10.width,
                _ProfileEntryAvatar(
                  currentProfile: state.currentProfile,
                  onTap: _openProfileHub,
                ),
              ],
            ),
            6.height,
            Text(
              LocaleKey.todaySubtitle.tr,
              style: AppStyles.bodyMedium(color: AppColors.textSecondary),
            ),
            10.height,
            _QuickSwitchChip(
              profileName: viewingName,
              onTap: () => _QuickSwitchSheet.show(context),
            ),
          ],
        );
      },
    );
  }

  void _openProfileHub() {
    if (Get.isRegistered<MainNavigationBloc>()) {
      Get.find<MainNavigationBloc>().selectTab(3);
      return;
    }
    Get.toNamed(AppPages.profile);
  }

  String _greeting() {
    final int hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return LocaleKey.todayGreetingMorning.tr;
    }
    if (hour >= 11 && hour < 13) {
      return LocaleKey.todayGreetingNoon.tr;
    }
    if (hour >= 13 && hour < 18) {
      return LocaleKey.todayGreetingAfternoon.tr;
    }
    if (hour >= 18 && hour < 22) {
      return LocaleKey.todayGreetingEvening.tr;
    }
    return LocaleKey.todayGreetingNight.tr;
  }

  String _firstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) {
      return '';
    }
    final List<String> parts = fullName
        .trim()
        .split(' ')
        .where((String part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '';
    }
    return parts.first;
  }

  String _profileDisplayName(String firstName) {
    if (firstName.isEmpty) {
      return '';
    }
    final String prefix = LocaleKey.todayUserPrefix.tr.trim();
    if (prefix.isEmpty) {
      return firstName;
    }
    return firstName;
  }
}

class _ProfileEntryAvatar extends StatelessWidget {
  const _ProfileEntryAvatar({
    required this.currentProfile,
    required this.onTap,
  });

  final UserProfile? currentProfile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final UserProfile? profile = currentProfile;

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: AppDimensions.touchTarget,
        height: AppDimensions.touchTarget,
        child: Align(
          alignment: Alignment.center,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: profile == null
                  ? null
                  : appProfileAvatarGradient(profile.id),
              color: profile == null
                  ? AppColors.card.withValues(alpha: 0.7)
                  : null,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.richGold.withValues(alpha: 0.45),
                width: 2,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.richGold.withValues(alpha: 0.2),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: profile == null
                ? const Icon(
                    Icons.person_rounded,
                    size: 20,
                    color: AppColors.richGold,
                  )
                : Text(
                    appProfileInitials(profile.name),
                    style: AppStyles.bodySmall(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _QuickSwitchChip extends StatelessWidget {
  const _QuickSwitchChip({required this.profileName, required this.onTap});

  final String profileName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: double.infinity,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                AppColors.card.withValues(alpha: 0.82),
                AppColors.card.withValues(alpha: 0.62),
              ],
            ),
          ),
          child: Row(
            children: <Widget>[
              Text(
                '${LocaleKey.todayViewingLabel.tr}: ',
                style: AppStyles.bodySmall(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Expanded(
                child: Text(
                  profileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.bodySmall(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              6.width,
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.richGold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickSwitchSheet extends StatelessWidget {
  const _QuickSwitchSheet();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (BuildContext context) => const _QuickSwitchSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MainSessionBloc sessionBloc = Get.find<MainSessionBloc>();

    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 12,
      ),
      child: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.72,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: BlocBuilder<MainSessionBloc, MainSessionState>(
                bloc: sessionBloc,
                builder: (BuildContext context, MainSessionState state) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  LocaleKey.todayQuickSwitchTitle.tr,
                                  style: AppStyles.h4(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                4.height,
                                Text(
                                  LocaleKey.todayQuickSwitchHint.tr,
                                  style: AppStyles.bodySmall(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            splashRadius: 20,
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      10.height,
                      if (state.profiles.isNotEmpty)
                        Flexible(
                          child: AppProfileList(
                            profiles: state.profiles,
                            currentProfileId: state.currentProfile?.id,
                            onSelectProfile: (String profileId) async {
                              await sessionBloc.switchProfile(profileId);
                              if (!context.mounted) {
                                return;
                              }
                              Navigator.of(context).pop();
                            },
                            padding: const EdgeInsets.only(bottom: 8),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
                          child: Text(
                            LocaleKey.todayProfileSwitcherAddHint.tr,
                            style: AppStyles.bodySmall(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      8.height,
                      AppPrimaryButton(
                        label: LocaleKey.todayProfileSwitcherAddProfile.tr,
                        leading: const Icon(
                          Icons.add_rounded,
                          color: AppColors.midnight,
                          size: 16,
                        ),
                        onPressed: () async {
                          bool didSubmit = false;
                          await CompatibilityProfileInputDialog.show(
                            context,
                            onSubmit: (String name, DateTime birthDate) async {
                              didSubmit = true;
                              await sessionBloc.addProfile(
                                name: name,
                                birthDate: birthDate,
                              );
                            },
                          );
                          if (!context.mounted || !didSubmit) {
                            return;
                          }
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
