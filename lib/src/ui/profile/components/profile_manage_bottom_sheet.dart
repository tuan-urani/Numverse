import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/compatibility/components/compatibility_profile_input_dialog.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_state.dart';
import 'package:test/src/ui/widgets/app_primary_button.dart';
import 'package:test/src/ui/widgets/app_profile_list.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class ProfileManageBottomSheet extends StatelessWidget {
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
                                  LocaleKey.profileManageProfilesTitle.tr,
                                  style: AppStyles.h4(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                4.height,
                                Text(
                                  LocaleKey.profileManageProfilesSubtitle.tr,
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
