import 'package:flutter/material.dart';

import 'package:test/src/core/model/user_profile.dart';
import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class AppProfileList extends StatelessWidget {
  const AppProfileList({
    required this.profiles,
    required this.currentProfileId,
    required this.onSelectProfile,
    super.key,
    this.onEditProfile,
    this.onDeleteProfile,
    this.padding = EdgeInsets.zero,
    this.shrinkWrap = false,
    this.physics,
    this.interactionsEnabled = true,
  });

  final List<UserProfile> profiles;
  final String? currentProfileId;
  final ValueChanged<String> onSelectProfile;
  final ValueChanged<String>? onEditProfile;
  final ValueChanged<String>? onDeleteProfile;
  final EdgeInsetsGeometry padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final bool interactionsEnabled;

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: profiles.length,
      separatorBuilder: (_, _) => 12.height,
      itemBuilder: (BuildContext context, int index) {
        final UserProfile profile = profiles[index];
        final bool isActive = profile.id == currentProfileId;
        final bool canInteract = interactionsEnabled;
        final bool canEdit = onEditProfile != null;
        final bool canDelete = onDeleteProfile != null;
        return _AppProfileRowCard(
          profile: profile,
          isActive: isActive,
          canEdit: canEdit,
          canDelete: canDelete,
          onSelect: canInteract ? () => onSelectProfile(profile.id) : null,
          onEdit: canInteract && canEdit
              ? () => onEditProfile?.call(profile.id)
              : null,
          onDelete: canInteract && canDelete
              ? () => onDeleteProfile?.call(profile.id)
              : null,
        );
      },
    );
  }
}

class _AppProfileRowCard extends StatelessWidget {
  const _AppProfileRowCard({
    required this.profile,
    required this.isActive,
    required this.canEdit,
    required this.canDelete,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final UserProfile profile;
  final bool isActive;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback? onSelect;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

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
                  gradient: appProfileAvatarGradient(profile.id),
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
                  appProfileInitials(profile.name),
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
                      ],
                    ),
                    2.height,
                    Text(
                      appProfileDisplayDate(profile.birthDate),
                      style: AppStyles.bodySmall(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (canEdit || canDelete) ...<Widget>[
                8.width,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (canEdit)
                      InkWell(
                        onTap: onEdit,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppColors.textMuted.withValues(alpha: 0.95),
                          ),
                        ),
                      ),
                    if (canDelete)
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
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String appProfileInitials(String name) {
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
  return name.substring(0, 1).toUpperCase();
}

LinearGradient appProfileAvatarGradient(String profileId) {
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

String appProfileDisplayDate(DateTime value) {
  final String day = value.day.toString().padLeft(2, '0');
  final String month = value.month.toString().padLeft(2, '0');
  final String year = value.year.toString();
  return '$day/$month/$year';
}
