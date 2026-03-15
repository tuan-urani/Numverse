import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/helper/numerology_helper.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/main/interactor/main_session_state.dart';
import 'package:test/src/ui/widgets/app_mystical_card.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class ProfileIdentityCard extends StatelessWidget {
  const ProfileIdentityCard({required this.sessionState, super.key});

  final MainSessionState sessionState;

  @override
  Widget build(BuildContext context) {
    final bool hasProfile = sessionState.currentProfile != null;
    final String profileName = hasProfile
        ? sessionState.currentProfile!.name
        : LocaleKey.profileSetupNamePlaceholder.tr;
    final String birthDate = hasProfile
        ? _formatDate(sessionState.currentProfile!.birthDate)
        : LocaleKey.profileBirthDatePlaceholder.tr;
    final String avatarLabel = hasProfile ? profileName.characters.first : '?';

    final int lifePathNumber = hasProfile
        ? NumerologyHelper.getLifePathNumber(
            sessionState.currentProfile!.birthDate,
          )
        : 0;
    final int soulUrgeNumber = hasProfile
        ? NumerologyHelper.getSoulUrgeNumber(sessionState.currentProfile!.name)
        : 0;
    final int missionNumber = hasProfile
        ? NumerologyHelper.getMissionNumber(
            sessionState.currentProfile!.birthDate,
            sessionState.currentProfile!.name,
          )
        : 0;

    return AppMysticalCard(
      padding: EdgeInsets.zero,
      borderColor: AppColors.richGold.withValues(alpha: 0.2),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 200),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  _AvatarBadge(label: avatarLabel.toUpperCase()),
                  16.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          profileName,
                          style: AppStyles.h4(fontWeight: FontWeight.w600),
                        ),
                        2.height,
                        Text(
                          birthDate,
                          style: AppStyles.bodySmall(
                            color: AppColors.textMuted,
                          ),
                        ),
                        8.height,
                        Row(
                          children: <Widget>[
                            if (sessionState.isAuthenticated &&
                                hasProfile) ...<Widget>[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.textMuted.withValues(
                                    alpha: 0.16,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: AppColors.border.withValues(
                                      alpha: 0.55,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  LocaleKey.profilePlanFreeTag.tr,
                                  style: AppStyles.caption(
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              8.width,
                            ],
                            const Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: AppColors.richGold,
                            ),
                            4.width,
                            Text(
                              LocaleKey.profileSoulPointsLabel.trParams(
                                <String, String>{
                                  'points': '${sessionState.soulPoints}',
                                },
                              ),
                              style: AppStyles.caption(
                                color: AppColors.richGold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              12.height,
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.52),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: <Widget>[
                      _CoreNumberCell(
                        label: LocaleKey.profileCoreLifePathLabel.tr,
                        value: hasProfile ? '$lifePathNumber' : '•',
                        isPlaceholder: !hasProfile,
                      ),
                      _CoreNumberCell(
                        label: LocaleKey.profileCoreMissionLabel.tr,
                        value: hasProfile ? '$missionNumber' : '•',
                        isPlaceholder: !hasProfile,
                      ),
                      _CoreNumberCell(
                        label: LocaleKey.profileCoreSoulLabel.tr,
                        value: hasProfile ? '$soulUrgeNumber' : '•',
                        isPlaceholder: !hasProfile,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final String day = value.day.toString().padLeft(2, '0');
    final String month = value.month.toString().padLeft(2, '0');
    final String year = value.year.toString();
    return '$day/$month/$year';
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.richGold.withValues(alpha: 0.3),
            AppColors.violetAccent.withValues(alpha: 0.3),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.richGold.withValues(alpha: 0.34),
            blurRadius: 18,
          ),
          BoxShadow(
            color: AppColors.richGold.withValues(alpha: 0.18),
            blurRadius: 36,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style:
            AppStyles.numberMedium(
              color: AppColors.richGold,
              fontWeight: FontWeight.w700,
            ).copyWith(
              fontSize: 24,
              shadows: <Shadow>[
                Shadow(
                  color: AppColors.richGold.withValues(alpha: 0.75),
                  blurRadius: 12,
                ),
              ],
            ),
      ),
    );
  }
}

class _CoreNumberCell extends StatelessWidget {
  const _CoreNumberCell({
    required this.label,
    required this.value,
    this.isPlaceholder = false,
  });

  final String label;
  final String value;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(
            value,
            style:
                AppStyles.numberMedium(
                  color: AppColors.richGold,
                  fontWeight: FontWeight.w700,
                ).copyWith(
                  fontSize: isPlaceholder ? 30 : 24,
                  shadows: <Shadow>[
                    Shadow(
                      color: AppColors.richGold.withValues(
                        alpha: isPlaceholder ? 0.85 : 0.6,
                      ),
                      blurRadius: isPlaceholder ? 14 : 10,
                    ),
                  ],
                ),
          ),
          1.height,
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppStyles.caption(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
