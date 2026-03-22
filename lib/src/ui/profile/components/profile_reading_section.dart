import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class ProfileReadingSection extends StatelessWidget {
  const ProfileReadingSection({
    required this.sections,
    required this.hasProfile,
    required this.onTapSection,
    required this.onTapLocked,
    required this.onTapNumAi,
    super.key,
  });

  final List<ProfileReadingSectionItem> sections;
  final bool hasProfile;
  final ValueChanged<ProfileReadingSectionItem> onTapSection;
  final VoidCallback onTapLocked;
  final VoidCallback onTapNumAi;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          LocaleKey.profileReadingSectionTitle.tr,
          style: AppStyles.bodyMedium(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        4.height,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(
              Icons.auto_awesome_rounded,
              size: 13,
              color: AppColors.textMuted,
            ),
            4.width,
            Expanded(
              child: Text(
                LocaleKey.profileReadingSectionHint.tr,
                style: AppStyles.caption(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
        4.height,
        GestureDetector(
          onTap: onTapNumAi,
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 13,
                color: AppColors.richGold,
              ),
              4.width,
              Text(
                LocaleKey.profileReadingSectionNumAiCta.tr,
                style: AppStyles.bodySmall(
                  color: AppColors.richGold,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        8.height,
        for (int index = 0; index < sections.length; index++) ...<Widget>[
          _ReadingItemCard(
            item: sections[index],
            hasProfile: hasProfile,
            onTap: () => onTapSection(sections[index]),
            onTapLocked: onTapLocked,
          ),
          if (index != sections.length - 1) 8.height,
        ],
      ],
    );
  }
}

class ProfileReadingSectionItem {
  const ProfileReadingSectionItem({
    required this.id,
    required this.route,
    this.icon,
    this.iconAssetPath,
    required this.title,
    required this.description,
    required this.lockedDescription,
    required this.gradient,
  }) : assert(icon != null || iconAssetPath != null);

  final String id;
  final String route;
  final IconData? icon;
  final String? iconAssetPath;
  final String title;
  final String description;
  final String lockedDescription;
  final List<Color> gradient;
}

class _ReadingItemCard extends StatelessWidget {
  const _ReadingItemCard({
    required this.item,
    required this.hasProfile,
    required this.onTap,
    required this.onTapLocked,
  });

  final ProfileReadingSectionItem item;
  final bool hasProfile;
  final VoidCallback onTap;
  final VoidCallback onTapLocked;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 84),
      child: Stack(
        children: <Widget>[
          Opacity(
            opacity: hasProfile ? 1 : 0.5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.7),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.richGold.withValues(
                      alpha: hasProfile ? 0.16 : 0.1,
                    ),
                    blurRadius: 14,
                    spreadRadius: 0.3,
                  ),
                  BoxShadow(
                    color: AppColors.deepViolet.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 0.6,
                  ),
                ],
              ),
              child: Material(
                color: AppColors.transparent,
                child: InkWell(
                  onTap: hasProfile ? onTap : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: item.gradient,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.richGold.withValues(alpha: 0.2),
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: AppColors.richGold.withValues(
                                  alpha: 0.22,
                                ),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: item.iconAssetPath != null
                              ? Image.asset(
                                  item.iconAssetPath!,
                                  width: 22,
                                  height: 22,
                                  color: AppColors.richGold,
                                  colorBlendMode: BlendMode.srcIn,
                                )
                              : Icon(
                                  item.icon ?? Icons.auto_awesome_rounded,
                                  size: 22,
                                  color: AppColors.richGold,
                                ),
                        ),
                        12.width,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                item.title,
                                style: AppStyles.h5(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              2.height,
                              Text(
                                item.description,
                                style: AppStyles.caption(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (!hasProfile)
            Positioned.fill(
              child: Material(
                color: AppColors.transparent,
                child: InkWell(
                  onTap: onTapLocked,
                  borderRadius: BorderRadius.circular(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.richGold.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppColors.richGold.withValues(alpha: 0.18),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.richGold.withValues(
                                    alpha: 0.2,
                                  ),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: AppColors.richGold.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.lock_rounded,
                                  size: 18,
                                  color: AppColors.richGold,
                                ),
                              ),
                              10.width,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppStyles.bodyMedium(
                                        color: AppColors.richGold,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    1.height,
                                    Text(
                                      item.lockedDescription,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppStyles.caption(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    1.height,
                                    Text(
                                      LocaleKey.profileGuestTeaserCta.tr,
                                      style: AppStyles.caption(
                                        color: AppColors.richGold.withValues(
                                          alpha: 0.95,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
