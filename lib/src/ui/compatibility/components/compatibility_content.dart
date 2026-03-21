import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:test/src/core/model/compatibility_history_item.dart';
import 'package:test/src/core/model/user_profile.dart';
import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/helper/numerology_helper.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/compatibility/interactor/compatibility_state.dart';
import 'package:test/src/utils/app_assets.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class CompatibilityContent extends StatelessWidget {
  const CompatibilityContent({
    required this.state,
    required this.currentProfile,
    required this.soulPoints,
    required this.comparisonCost,
    required this.onAddProfileTap,
    required this.onSelectProfile,
    required this.onCompareTap,
    required this.onNeedMorePointsTap,
    required this.historyItems,
    required this.onHistoryTap,
    super.key,
  });

  final CompatibilityState state;
  final UserProfile? currentProfile;
  final int soulPoints;
  final int comparisonCost;
  final VoidCallback onAddProfileTap;
  final ValueChanged<String> onSelectProfile;
  final VoidCallback onCompareTap;
  final VoidCallback onNeedMorePointsTap;
  final List<CompatibilityHistoryItem> historyItems;
  final ValueChanged<CompatibilityHistoryItem> onHistoryTap;

  @override
  Widget build(BuildContext context) {
    final bool hasCurrentProfile = currentProfile != null;
    final int? lifePath = hasCurrentProfile
        ? NumerologyHelper.getLifePathNumber(currentProfile!.birthDate)
        : null;
    final String birthDate = hasCurrentProfile
        ? DateFormat('dd/MM/yyyy').format(currentProfile!.birthDate)
        : LocaleKey.compatibilityOwnProfilePlaceholderDate.tr;
    final bool hasSelectedProfile = state.selectedProfile != null;
    final bool hasEnoughPoints = soulPoints >= comparisonCost;
    final bool canCompare = hasSelectedProfile && hasEnoughPoints;
    final List<CompatibilityHistoryItem> visibleHistory = historyItems
        .take(10)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                LocaleKey.compatibilityTitle.tr,
                style: AppStyles.titleLarge(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              2.height,
              Text(
                LocaleKey.compatibilitySubtitle.tr,
                style: AppStyles.bodySmall(color: AppColors.textMuted),
              ),
              16.height,
              _CurrentProfileCard(
                profile: currentProfile,
                lifePath: lifePath,
                birthDate: birthDate,
              ),
              18.height,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        LocaleKey.compatibilitySelectProfileTitle.tr,
                        style: AppStyles.caption(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ).copyWith(letterSpacing: 0.8),
                      ),
                    ),
                  ),
                  _AddCompareProfileButton(
                    highlight: !state.hasProfiles,
                    onTap: onAddProfileTap,
                  ),
                ],
              ),
              10.height,
              if (!state.hasProfiles) ...<Widget>[
                const _EmptyCompareProfileCard(),
                12.height,
              ] else
                for (final compareProfile in state.compareProfiles) ...<Widget>[
                  _CompareProfileCard(
                    profileId: compareProfile.id,
                    name: compareProfile.name,
                    relation: _relationLabel(compareProfile.relation),
                    formattedDate: DateFormat(
                      'dd/MM/yyyy',
                    ).format(compareProfile.birthDate),
                    lifePathNumber: compareProfile.lifePathNumber,
                    selected: compareProfile.id == state.selectedProfileId,
                    onTap: onSelectProfile,
                  ),
                  10.height,
                ],
              16.height,
              _SoulPointsCard(
                soulPoints: soulPoints,
                comparisonCost: comparisonCost,
              ),
              12.height,
              _CompareButton(
                enabled: canCompare,
                comparisonCost: comparisonCost,
                needsMorePointsCta: !hasEnoughPoints,
                missingPoints: hasEnoughPoints
                    ? 0
                    : comparisonCost - soulPoints,
                onCompareTap: onCompareTap,
                onNeedMorePointsTap: onNeedMorePointsTap,
              ),
              if (visibleHistory.isNotEmpty) ...<Widget>[
                18.height,
                Text(
                  LocaleKey.compatibilityHistoryTitle.tr,
                  style: AppStyles.h5(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                4.height,
                Text(
                  LocaleKey.compatibilityHistorySubtitle.tr,
                  style: AppStyles.bodySmall(color: AppColors.textMuted),
                ),
                10.height,
                for (final CompatibilityHistoryItem item
                    in visibleHistory) ...<Widget>[
                  _HistoryItemCard(
                    item: item,
                    relationLabel: _relationLabel(item.targetRelation),
                    onTap: onHistoryTap,
                  ),
                  10.height,
                ],
              ],
              12.height,
            ],
          ),
        ),
      ),
    );
  }

  String _relationLabel(String relationKey) {
    return switch (relationKey) {
      'lover' => LocaleKey.compatibilityRelationLover.tr,
      'spouse' => LocaleKey.compatibilityRelationSpouse.tr,
      'friend' => LocaleKey.compatibilityRelationFriend.tr,
      'coworker' => LocaleKey.compatibilityRelationCoworker.tr,
      'mother' => LocaleKey.compatibilityRelationMother.tr,
      'father' => LocaleKey.compatibilityRelationFather.tr,
      'sibling' => LocaleKey.compatibilityRelationSibling.tr,
      _ => LocaleKey.compatibilityRelationOther.tr,
    };
  }
}

class _CurrentProfileCard extends StatelessWidget {
  const _CurrentProfileCard({
    required this.profile,
    required this.lifePath,
    required this.birthDate,
  });

  final UserProfile? profile;
  final int? lifePath;
  final String birthDate;

  @override
  Widget build(BuildContext context) {
    final bool hasProfile = profile != null;
    final String profileName =
        profile?.name ?? LocaleKey.compatibilityOwnProfilePlaceholderName.tr;
    final String profileInitial = profileName.trim().isEmpty
        ? '?'
        : profileName.characters.first.toUpperCase();

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.card.withValues(alpha: 0.84),
            AppColors.violetAccent.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.32)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.richGold.withValues(alpha: 0.18),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            LocaleKey.compatibilityOwnProfileLabel.tr,
            style: AppStyles.caption(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ).copyWith(letterSpacing: 0.8),
          ),
          8.height,
          Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: <Color>[
                      AppColors.richGold.withValues(alpha: 0.36),
                      AppColors.violetAccent.withValues(alpha: 0.36),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.richGold.withValues(alpha: 0.45),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  hasProfile ? profileInitial : '?',
                  style: AppStyles.numberSmall(fontWeight: FontWeight.w700),
                ),
              ),
              12.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      profileName,
                      style: AppStyles.h5(fontWeight: FontWeight.w600),
                    ),
                    3.height,
                    RichText(
                      text: TextSpan(
                        style: AppStyles.bodySmall(color: AppColors.textMuted),
                        children: <InlineSpan>[
                          TextSpan(text: '$birthDate • '),
                          TextSpan(
                            text:
                                '${LocaleKey.compatibilityLifePathLabel.tr}: ',
                          ),
                          TextSpan(
                            text: lifePath == null ? '•' : '$lifePath',
                            style: AppStyles.bodySmall(
                              color: AppColors.richGold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddCompareProfileButton extends StatefulWidget {
  const _AddCompareProfileButton({
    required this.highlight,
    required this.onTap,
  });

  final bool highlight;
  final VoidCallback onTap;

  @override
  State<_AddCompareProfileButton> createState() =>
      _AddCompareProfileButtonState();
}

class _AddCompareProfileButtonState extends State<_AddCompareProfileButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    final Widget button = InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.richGold.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.richGold.withValues(alpha: 0.34)),
          boxShadow: widget.highlight
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppColors.richGold.withValues(alpha: 0.35),
                    blurRadius: 14,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.add_rounded, size: 16, color: AppColors.richGold),
            4.width,
            Text(
              LocaleKey.compatibilityAddNew.tr,
              style: AppStyles.caption(
                color: AppColors.richGold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );

    if (!widget.highlight) {
      return button;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            final double scale = 1 + (_controller.value * 0.04);
            return Transform.scale(scale: scale, child: child);
          },
          child: button,
        ),
        8.height,
        Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Container(
              width: 220,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.richGold.withValues(alpha: 0.28),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.18),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.richGold,
                    ),
                  ),
                  8.width,
                  Expanded(
                    child: Text(
                      LocaleKey.compatibilityAddTooltip.tr,
                      style: AppStyles.caption(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -4,
              right: 20,
              child: Transform.rotate(
                angle: 0.78,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.card.withValues(alpha: 0.94),
                    border: Border(
                      left: BorderSide(
                        color: AppColors.richGold.withValues(alpha: 0.28),
                      ),
                      top: BorderSide(
                        color: AppColors.richGold.withValues(alpha: 0.28),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _EmptyCompareProfileCard extends StatelessWidget {
  const _EmptyCompareProfileCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.richGold.withValues(alpha: 0.12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.add_circle_outline_rounded,
              size: 30,
              color: AppColors.richGold,
            ),
          ),
          10.height,
          Text(
            LocaleKey.compatibilityEmptyTitle.tr,
            style: AppStyles.h5(fontWeight: FontWeight.w600),
          ),
          4.height,
          Text(
            LocaleKey.compatibilityEmptySubtitle.tr,
            textAlign: TextAlign.center,
            style: AppStyles.bodySmall(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _CompareProfileCard extends StatelessWidget {
  const _CompareProfileCard({
    required this.profileId,
    required this.name,
    required this.relation,
    required this.formattedDate,
    required this.lifePathNumber,
    required this.selected,
    required this.onTap,
  });

  final String profileId;
  final String name;
  final String relation;
  final String formattedDate;
  final int lifePathNumber;
  final bool selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(profileId),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.richGold.withValues(alpha: 0.08)
              : AppColors.card.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.richGold.withValues(alpha: 0.5)
                : AppColors.border.withValues(alpha: 0.55),
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: <Color>[
                    AppColors.richGold.withValues(alpha: 0.32),
                    AppColors.violetAccent.withValues(alpha: 0.32),
                  ],
                ),
                border: Border.all(
                  color: AppColors.richGold.withValues(alpha: 0.5),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '$lifePathNumber',
                style: AppStyles.h5(
                  color: AppColors.richGold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            12.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(name, style: AppStyles.h5(fontWeight: FontWeight.w600)),
                  2.height,
                  Text(
                    '$relation • $formattedDate',
                    style: AppStyles.caption(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.richGold.withValues(alpha: 0.22),
                ),
                padding: const EdgeInsets.all(4),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.richGold,
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

class _SoulPointsCard extends StatelessWidget {
  const _SoulPointsCard({
    required this.soulPoints,
    required this.comparisonCost,
  });

  final int soulPoints;
  final int comparisonCost;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            AppColors.richGold.withValues(alpha: 0.14),
            AppColors.card.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.34)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.richGold.withValues(alpha: 0.2),
                  ),
                  child: SvgPicture.asset(
                    AppAssets.iconCoinPng,
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      AppColors.richGold,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                10.width,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      LocaleKey.compatibilitySoulPointsLabel.tr,
                      style: AppStyles.caption(color: AppColors.textMuted),
                    ),
                    Text(
                      '$soulPoints',
                      style: AppStyles.titleLarge(
                        color: AppColors.richGold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                LocaleKey.compatibilityCostLabel.tr,
                style: AppStyles.caption(color: AppColors.textMuted),
              ),
              Row(
                children: <Widget>[
                  SvgPicture.asset(
                    AppAssets.iconCoinPng,
                    width: 15,
                    height: 15,
                    colorFilter: const ColorFilter.mode(
                      AppColors.richGold,
                      BlendMode.srcIn,
                    ),
                  ),
                  2.width,
                  Text(
                    '$comparisonCost',
                    style: AppStyles.titleLarge(
                      color: AppColors.richGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompareButton extends StatefulWidget {
  const _CompareButton({
    required this.enabled,
    required this.comparisonCost,
    required this.needsMorePointsCta,
    required this.missingPoints,
    required this.onCompareTap,
    required this.onNeedMorePointsTap,
  });

  final bool enabled;
  final int comparisonCost;
  final bool needsMorePointsCta;
  final int missingPoints;
  final VoidCallback onCompareTap;
  final VoidCallback onNeedMorePointsTap;

  @override
  State<_CompareButton> createState() => _CompareButtonState();
}

class _CompareButtonState extends State<_CompareButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.needsMorePointsCta) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _CompareButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.needsMorePointsCta && widget.needsMorePointsCta) {
      _glowController.repeat(reverse: true);
    } else if (oldWidget.needsMorePointsCta && !widget.needsMorePointsCta) {
      _glowController
        ..stop()
        ..value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canTap = widget.enabled || widget.needsMorePointsCta;
    final bool useActiveStyle = widget.enabled || widget.needsMorePointsCta;
    final bool emphasizeNeedMore = widget.needsMorePointsCta;
    final double glowValue = _glowController.value;

    final LinearGradient activeGradient = emphasizeNeedMore
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              AppColors.energyOrange.withValues(alpha: 0.96),
              AppColors.energyRose.withValues(alpha: 0.92),
            ],
          )
        : AppColors.primaryGradient();

    final Color foregroundColor = useActiveStyle
        ? (emphasizeNeedMore ? AppColors.white : AppColors.midnight)
        : AppColors.textMuted;

    final String label = emphasizeNeedMore
        ? LocaleKey.compatibilityStartNeedMorePointsCta.trParams(
            <String, String>{'points': '${widget.missingPoints}'},
          )
        : LocaleKey.compatibilityStart.tr;

    return InkWell(
      onTap: canTap
          ? (emphasizeNeedMore
                ? widget.onNeedMorePointsTap
                : widget.onCompareTap)
          : null,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          gradient: useActiveStyle
              ? activeGradient
              : LinearGradient(
                  colors: <Color>[
                    AppColors.border.withValues(alpha: 0.8),
                    AppColors.deepViolet.withValues(alpha: 0.8),
                  ],
                ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: emphasizeNeedMore
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppColors.energyOrange.withValues(
                      alpha: 0.28 + (glowValue * 0.32),
                    ),
                    blurRadius: 18 + (glowValue * 18),
                    spreadRadius: 1 + (glowValue * 2),
                  ),
                  BoxShadow(
                    color: AppColors.energyRose.withValues(
                      alpha: 0.2 + (glowValue * 0.2),
                    ),
                    blurRadius: 24 + (glowValue * 12),
                  ),
                ]
              : useActiveStyle
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppColors.richGold.withValues(alpha: 0.28),
                    blurRadius: 14,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (!emphasizeNeedMore) ...<Widget>[
              Icon(
                Icons.compare_arrows_rounded,
                size: 17,
                color: foregroundColor,
              ),
              8.width,
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: AppStyles.buttonMedium(
                  color: foregroundColor,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (!emphasizeNeedMore) ...<Widget>[
              8.width,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: foregroundColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '${widget.comparisonCost}',
                      style: AppStyles.caption(
                        color: foregroundColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }
}

class _HistoryItemCard extends StatelessWidget {
  const _HistoryItemCard({
    required this.item,
    required this.relationLabel,
    required this.onTap,
  });

  final CompatibilityHistoryItem item;
  final String relationLabel;
  final ValueChanged<CompatibilityHistoryItem> onTap;

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return InkWell(
      onTap: () => onTap(item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.56),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.72),
            width: 1.2,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _scoreColor(item.overallScore).withValues(alpha: 0.2),
              ),
              alignment: Alignment.center,
              child: Text(
                '${item.overallScore}',
                style: AppStyles.bodySmall(
                  color: _scoreColor(item.overallScore),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            12.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${item.primaryName} • ${item.targetName}',
                    style: AppStyles.h5(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  2.height,
                  Text(
                    '$relationLabel • ${dateFormat.format(item.createdAt)}',
                    style: AppStyles.caption(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            8.width,
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) {
      return AppColors.richGold;
    }
    if (score >= 70) {
      return AppColors.success;
    }
    if (score >= 60) {
      return AppColors.warning;
    }
    return AppColors.error;
  }
}
