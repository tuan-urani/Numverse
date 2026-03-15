import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/core/model/user_profile.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/compatibility/components/compatibility_profile_input_dialog.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_state.dart';
import 'package:test/src/ui/widgets/app_primary_button.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_dimensions.dart';
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
                if (state.hasAnyProfile) ...<Widget>[
                  10.width,
                  _ProfileSwitcher(
                    profiles: state.profiles,
                    currentProfile: state.currentProfile,
                  ),
                ],
              ],
            ),
            6.height,
            Text(
              LocaleKey.todaySubtitle.tr,
              style: AppStyles.bodyMedium(color: AppColors.textSecondary),
            ),
          ],
        );
      },
    );
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

class _ProfileSwitcher extends StatelessWidget {
  const _ProfileSwitcher({
    required this.profiles,
    required this.currentProfile,
  });

  final List<UserProfile> profiles;
  final UserProfile? currentProfile;

  @override
  Widget build(BuildContext context) {
    final UserProfile selectedProfile = currentProfile ?? profiles.first;

    return InkWell(
      onTap: () => _ProfileSwitcherDrawer.show(context),
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: AppDimensions.touchTarget,
        height: AppDimensions.touchTarget,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: _profileAvatarGradient(selectedProfile.id),
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
                child: Text(
                  _profileInitials(selectedProfile.name),
                  style: AppStyles.bodySmall(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (profiles.length > 1)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.richGold,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${profiles.length}',
                    style: AppStyles.caption(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSwitcherDrawer extends StatelessWidget {
  const _ProfileSwitcherDrawer();

  static Future<void> show(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'profile_switcher_drawer',
      barrierColor: AppColors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return const _ProfileSwitcherDrawer();
          },
      transitionBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final Animation<Offset> slideAnimation =
                Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                );

            return BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 6 * animation.value,
                sigmaY: 6 * animation.value,
              ),
              child: FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slideAnimation, child: child),
              ),
            );
          },
    );
  }

  @override
  Widget build(BuildContext context) {
    final MainSessionBloc sessionCubit = Get.find<MainSessionBloc>();
    final double drawerWidth = math.min(MediaQuery.sizeOf(context).width, 360);

    return Material(
      color: AppColors.transparent,
      child: Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: drawerWidth,
          height: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(left: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              child: BlocBuilder<MainSessionBloc, MainSessionState>(
                bloc: sessionCubit,
                builder: (BuildContext context, MainSessionState state) {
                  if (!state.hasAnyProfile || state.currentProfile == null) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    children: <Widget>[
                      _DrawerHeader(onClose: () => Navigator.of(context).pop()),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.profiles.length,
                          separatorBuilder: (_, _) => 12.height,
                          itemBuilder: (BuildContext context, int index) {
                            final UserProfile profile = state.profiles[index];
                            final bool isActive =
                                profile.id == state.currentProfile?.id;
                            return _ProfileRowCard(
                              profile: profile,
                              isActive: isActive,
                              canDelete: !isActive && state.profiles.length > 1,
                              onSelect: () {
                                sessionCubit.switchProfile(profile.id);
                                Navigator.of(context).pop();
                              },
                              onDelete: () => _confirmDelete(
                                context: context,
                                sessionCubit: sessionCubit,
                                profileId: profile.id,
                              ),
                            );
                          },
                        ),
                      ),
                      _DrawerFooter(sessionCubit: sessionCubit),
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

  Future<void> _confirmDelete({
    required BuildContext context,
    required MainSessionBloc sessionCubit,
    required String profileId,
  }) async {
    final bool shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppColors.midnightSoft,
              title: Text(
                LocaleKey.commonConfirm.tr,
                style: AppStyles.h4(fontWeight: FontWeight.w600),
              ),
              content: Text(
                LocaleKey.todayProfileSwitcherDeleteConfirm.tr,
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
        ) ??
        false;

    if (!shouldDelete) {
      return;
    }

    await sessionCubit.removeProfile(profileId);
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -48,
            right: -24,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: AppColors.richGold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        LocaleKey.todayProfileSwitcherTitle.tr,
                        style: AppStyles.h3(fontWeight: FontWeight.w700),
                      ),
                      4.height,
                      Text(
                        LocaleKey.todayProfileSwitcherSubtitle.tr,
                        style: AppStyles.bodySmall(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  splashRadius: 20,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRowCard extends StatelessWidget {
  const _ProfileRowCard({
    required this.profile,
    required this.isActive,
    required this.canDelete,
    required this.onSelect,
    required this.onDelete,
  });

  final UserProfile profile;
  final bool isActive;
  final bool canDelete;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isActive ? null : AppColors.card.withValues(alpha: 0.6),
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    AppColors.richGold.withValues(alpha: 0.15),
                    AppColors.richGold.withValues(alpha: 0.08),
                    AppColors.richGold.withValues(alpha: 0.05),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppColors.richGold.withValues(alpha: 0.4)
                : AppColors.border.withValues(alpha: 0.6),
          ),
          boxShadow: isActive
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppColors.richGold.withValues(alpha: 0.16),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: _profileAvatarGradient(profile.id),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive
                        ? AppColors.richGold.withValues(alpha: 0.6)
                        : AppColors.border.withValues(alpha: 0.7),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _profileInitials(profile.name),
                  style: AppStyles.bodyMedium(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              12.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            profile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyles.bodyMedium(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isActive)
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.richGold.withValues(alpha: 0.2),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: AppColors.richGold,
                            ),
                          ),
                      ],
                    ),
                    2.height,
                    Text(
                      _formatDate(profile.birthDate),
                      style: AppStyles.bodySmall(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (canDelete) ...<Widget>[
                8.width,
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppColors.textMuted.withValues(alpha: 0.95),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter({required this.sessionCubit});

  final MainSessionBloc sessionCubit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.5),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          children: <Widget>[
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
                    await sessionCubit.addProfile(
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
            12.height,
            Text(
              LocaleKey.todayProfileSwitcherAddHint.tr,
              textAlign: TextAlign.center,
              style: AppStyles.caption(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

String _profileInitials(String name) {
  final List<String> parts = name
      .trim()
      .split(' ')
      .where((String part) => part.isNotEmpty)
      .toList();

  if (parts.length >= 2) {
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
  if (name.isEmpty) {
    return '?';
  }
  if (name.length == 1) {
    return name.toUpperCase();
  }
  return name.substring(0, 2).toUpperCase();
}

LinearGradient _profileAvatarGradient(String profileId) {
  final List<LinearGradient> gradients = <LinearGradient>[
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        AppColors.goldSoft.withValues(alpha: 0.86),
        AppColors.richGold.withValues(alpha: 0.82),
      ],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        AppColors.richGold.withValues(alpha: 0.88),
        AppColors.goldBright.withValues(alpha: 0.78),
      ],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        AppColors.goldBright.withValues(alpha: 0.84),
        AppColors.goldSoft.withValues(alpha: 0.8),
      ],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        AppColors.richGold.withValues(alpha: 0.82),
        AppColors.violetAccent.withValues(alpha: 0.72),
      ],
    ),
  ];
  int hash = 0;
  for (final int code in profileId.codeUnits) {
    hash += code;
  }
  return gradients[hash % gradients.length];
}

String _formatDate(DateTime value) {
  final String day = value.day.toString().padLeft(2, '0');
  final String month = value.month.toString().padLeft(2, '0');
  final String year = value.year.toString();
  return '$day/$month/$year';
}
