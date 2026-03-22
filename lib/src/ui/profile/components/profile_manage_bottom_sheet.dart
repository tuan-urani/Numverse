import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/core/model/user_profile.dart';
import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/compatibility/components/compatibility_profile_input_dialog.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_state.dart';
import 'package:test/src/ui/widgets/app_primary_button.dart';
import 'package:test/src/ui/widgets/app_profile_list.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class ProfileManageBottomSheet extends StatefulWidget {
  const ProfileManageBottomSheet({required this.sessionBloc, super.key});

  final MainSessionBloc sessionBloc;

  static Future<void> show(
    BuildContext context, {
    required MainSessionBloc sessionBloc,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (BuildContext context) {
        return ProfileManageBottomSheet(sessionBloc: sessionBloc);
      },
    );
  }

  @override
  State<ProfileManageBottomSheet> createState() =>
      _ProfileManageBottomSheetState();
}

class _ProfileManageBottomSheetState extends State<ProfileManageBottomSheet> {
  String? _switchingProfileId;

  bool get _isSwitchingProfile => _switchingProfileId != null;

  @override
  Widget build(BuildContext context) {
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
                bloc: widget.sessionBloc,
                builder: (BuildContext context, MainSessionState state) {
                  return Stack(
                    children: <Widget>[
                      Column(
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
                                      LocaleKey.profileManageProfilesTitle.tr,
                                      style: AppStyles.h4(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    4.height,
                                    Text(
                                      LocaleKey
                                          .profileManageProfilesSubtitle
                                          .tr,
                                      style: AppStyles.bodySmall(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: _isSwitchingProfile
                                    ? null
                                    : () => Navigator.of(context).pop(),
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
                                interactionsEnabled: !_isSwitchingProfile,
                                onSelectProfile: (String profileId) async {
                                  await _switchProfile(
                                    context,
                                    profileId: profileId,
                                  );
                                },
                                onEditProfile: (String profileId) async {
                                  await _handleEditProfile(
                                    context,
                                    state: state,
                                    profileId: profileId,
                                  );
                                },
                                onDeleteProfile: (String profileId) async {
                                  await _handleDeleteProfile(
                                    context,
                                    state: state,
                                    profileId: profileId,
                                  );
                                },
                                padding: const EdgeInsets.only(bottom: 8),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
                              child: Text(
                                LocaleKey.profileManageProfilesAddHint.tr,
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
                            onPressed: _isSwitchingProfile
                                ? null
                                : () async {
                                    bool didSubmit = false;
                                    await CompatibilityProfileInputDialog.show(
                                      context,
                                      title: LocaleKey
                                          .todayProfileSwitcherAddProfile
                                          .tr,
                                      onSubmit:
                                          (
                                            String name,
                                            DateTime birthDate,
                                          ) async {
                                            didSubmit = true;
                                            await widget.sessionBloc.addProfile(
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
                      ),
                      if (_isSwitchingProfile)
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.midnight.withValues(alpha: 0.48),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.richGold.withValues(
                                    alpha: 0.95,
                                  ),
                                ),
                              ),
                            ),
                          ),
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

  Future<void> _switchProfile(
    BuildContext context, {
    required String profileId,
  }) async {
    if (_isSwitchingProfile) {
      return;
    }
    setState(() {
      _switchingProfileId = profileId;
    });
    try {
      await widget.sessionBloc.switchProfile(profileId);
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (_) {
      // Keep sheet open for retry when switch fails.
    } finally {
      if (mounted) {
        setState(() {
          _switchingProfileId = null;
        });
      }
    }
  }

  Future<void> _handleDeleteProfile(
    BuildContext context, {
    required MainSessionState state,
    required String profileId,
  }) async {
    final UserProfile? profile = _findProfileById(state.profiles, profileId);
    if (profile == null) {
      return;
    }
    final bool isLastProfile = state.profiles.length == 1;
    final bool confirmed = await _showDeleteConfirmDialog(
      context,
      isLastProfile: isLastProfile,
    );
    if (!context.mounted || !confirmed) {
      return;
    }
    await widget.sessionBloc.removeProfile(profile.id);
  }

  Future<void> _handleEditProfile(
    BuildContext context, {
    required MainSessionState state,
    required String profileId,
  }) async {
    final UserProfile? profile = _findProfileById(state.profiles, profileId);
    if (profile == null) {
      return;
    }
    await CompatibilityProfileInputDialog.show(
      context,
      title: LocaleKey.profileManageProfilesEditTitle.tr,
      subtitle: LocaleKey.profileManageProfilesEditSubtitle.tr,
      submitLabel: LocaleKey.commonSave.tr,
      initialName: profile.name,
      initialBirthDate: profile.birthDate,
      note: '',
      onBeforeSubmit: _showEditConfirmDialog,
      onSubmit: (String name, DateTime birthDate) async {
        await widget.sessionBloc.updateProfile(
          profileId: profile.id,
          name: name,
          birthDate: birthDate,
        );
      },
    );
  }

  UserProfile? _findProfileById(List<UserProfile> profiles, String profileId) {
    for (final UserProfile profile in profiles) {
      if (profile.id == profileId) {
        return profile;
      }
    }
    return null;
  }

  Future<bool> _showDeleteConfirmDialog(
    BuildContext context, {
    required bool isLastProfile,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(
            isLastProfile
                ? LocaleKey.profileManageProfilesDeleteLastTitle.tr
                : LocaleKey.commonDelete.tr,
            style: AppStyles.h5(fontWeight: FontWeight.w600),
          ),
          content: Text(
            isLastProfile
                ? LocaleKey.profileManageProfilesDeleteLastConfirm.tr
                : LocaleKey.profileManageProfilesDeleteConfirm.tr,
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

  Future<bool> _showEditConfirmDialog(BuildContext context) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(
            LocaleKey.profileManageProfilesEditConfirmTitle.tr,
            style: AppStyles.h5(fontWeight: FontWeight.w600),
          ),
          content: Text(
            LocaleKey.profileManageProfilesEditConfirmBody.tr,
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
                style: AppStyles.bodyMedium(color: AppColors.richGold),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
