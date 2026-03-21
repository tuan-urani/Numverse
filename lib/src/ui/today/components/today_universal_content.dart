import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/core/model/profile_time_life_snapshot.dart';
import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/helper/numerology_helper.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/compatibility/components/compatibility_profile_input_dialog.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_state.dart';
import 'package:test/src/ui/widgets/app_glow_text.dart';
import 'package:test/src/ui/widgets/app_mystical_card.dart';
import 'package:test/src/ui/widgets/app_primary_button.dart';
import 'package:test/src/utils/app_assets.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_pages.dart';
import 'package:test/src/utils/app_styles.dart';
import 'package:test/src/utils/tab_navigation_helper.dart';

class TodayUniversalContent extends StatelessWidget {
  const TodayUniversalContent({super.key});

  static const int _streakTarget = 7;
  static const int _streakReward = 50;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainSessionBloc, MainSessionState>(
      bloc: Get.find<MainSessionBloc>(),
      builder: (BuildContext context, MainSessionState state) {
        final String profileId =
            state.currentProfile?.id ?? MainSessionBloc.guestProfileId;
        final snapshot = state.timeLifeByProfileId[profileId];
        final int universalDay =
            snapshot?.valueOf(ProfileTimeLifeSnapshot.universalDayMetric) ??
            NumerologyHelper.calculateUniversalDayNumber();
        final int luckyNumber =
            snapshot?.valueOf(ProfileTimeLifeSnapshot.luckyNumberMetric) ??
            NumerologyHelper.luckyNumber();
        final int checkInReward = _checkInReward(state.currentStreak);
        final int nextDayReward = _checkInReward(state.currentStreak + 1);

        final double streakProgress = (state.currentStreak / _streakTarget)
            .clamp(0.0, 1.0);
        final double earningProgress = (state.dailyEarnings / state.dailyLimit)
            .clamp(0.0, 1.0);

        return Column(
          children: <Widget>[
            _SoulPointsCard(
              soulPoints: state.soulPoints,
              streakLabel:
                  '${state.currentStreak} ${LocaleKey.todayStreakDayUnit.tr}',
              streakProgress: streakProgress,
              streakCurrent: state.currentStreak,
              streakTarget: _streakTarget,
            ),
            14.height,
            _DailyCheckInCard(
              hasCheckedInToday: state.hasCheckedInToday,
              checkInReward: checkInReward,
              nextDayReward: nextDayReward,
              dailyEarnings: state.dailyEarnings,
              dailyLimit: state.dailyLimit,
              earningProgress: earningProgress,
              onCheckIn: () => Get.find<MainSessionBloc>().checkIn(),
            ),
            16.height,
            _SectionTitle(
              title: LocaleKey.todayExploreFreeTitle.tr,
              subtitle: LocaleKey.todayExploreFreeSubtitle.tr,
            ),
            10.height,
            Row(
              children: <Widget>[
                Expanded(
                  child: _NumberFeatureCard(
                    title: LocaleKey.todayUniversalDayTitle.tr,
                    subtitle: LocaleKey.todayUniversalDaySubtitle.tr,
                    value: '$universalDay',
                    icon: Icons.calendar_month,
                    onTap: () => _trackAndNavigate(AppPages.universalDay),
                  ),
                ),
                10.width,
                Expanded(
                  child: _NumberFeatureCard(
                    title: LocaleKey.todayLuckyNumberTitle.tr,
                    subtitle: LocaleKey.todayLuckyNumberSubtitle.tr,
                    value: '$luckyNumber',
                    icon: Icons.star,
                    onTap: () => _trackAndNavigate(AppPages.luckyNumber),
                  ),
                ),
              ],
            ),
            10.height,
            _WideFeatureCard(
              title: LocaleKey.todayDailyMessageTitle.tr,
              subtitle: LocaleKey.todayDailyMessageSubtitle.tr,
              icon: Icons.chat_bubble_outline,
              onTap: () => _trackAndNavigate(AppPages.dailyMessage),
            ),
            10.height,
            Row(
              children: <Widget>[
                Expanded(
                  child: _InfoFeatureCard(
                    title: LocaleKey.todayAngelNumberTitle.tr,
                    subtitle: LocaleKey.todayAngelNumberSubtitle.tr,
                    icon: Icons.search,
                    onTap: () => _trackAndNavigate(AppPages.angelNumbers),
                  ),
                ),
                10.width,
                Expanded(
                  child: _InfoFeatureCard(
                    title: LocaleKey.todayNumberLibraryTitle.tr,
                    subtitle: LocaleKey.todayNumberLibrarySubtitle.tr,
                    icon: Icons.menu_book,
                    onTap: () => _trackAndNavigate(AppPages.numberLibrary),
                  ),
                ),
              ],
            ),
            if (!state.hasAnyProfile) ...<Widget>[
              12.height,
              _UnlockCard(
                onTap: () => CompatibilityProfileInputDialog.show(
                  context,
                  onSubmit: (String name, DateTime birthDate) async {
                    await Get.find<MainSessionBloc>().addProfile(
                      name: name,
                      birthDate: birthDate,
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  static int _checkInReward(int streak) {
    if (streak >= 30) {
      return 30;
    }
    if (streak >= 14) {
      return 20;
    }
    if (streak >= 7) {
      return 15;
    }
    return 10;
  }

  void _trackAndNavigate(String route) {
    final MainSessionBloc cubit = Get.find<MainSessionBloc>();
    cubit.trackInteraction('today');
    TabNavigationHelper.pushCommonRoute(route);
  }
}

class _SoulPointsCard extends StatelessWidget {
  const _SoulPointsCard({
    required this.soulPoints,
    required this.streakLabel,
    required this.streakProgress,
    required this.streakCurrent,
    required this.streakTarget,
  });

  final int soulPoints;
  final String streakLabel;
  final double streakProgress;
  final int streakCurrent;
  final int streakTarget;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.richGold.withValues(alpha: 0.18),
            blurRadius: 26,
            spreadRadius: 0.8,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.energyOrange.withValues(alpha: 0.1),
            blurRadius: 34,
            spreadRadius: 1.2,
          ),
        ],
      ),
      child: AppMysticalCard(
        borderColor: AppColors.richGold.withValues(alpha: 0.34),
        child: Stack(
          children: <Widget>[
            const Positioned(
              top: -18,
              right: -12,
              child: _PulseOrb(
                size: 102,
                color: AppColors.goldSoft,
                alpha: 0.15,
              ),
            ),
            Positioned(
              bottom: -42,
              left: -20,
              child: Container(
                width: 126,
                height: 126,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.violetAccent.withValues(alpha: 0.24),
                ),
              ),
            ),
            Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.richGold.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.richGold.withValues(alpha: 0.42),
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.richGold.withValues(alpha: 0.22),
                            blurRadius: 14,
                            spreadRadius: 0.6,
                          ),
                        ],
                      ),
                      child: SvgPicture.asset(
                        AppAssets.iconCoinPng,
                        width: 22,
                        height: 22,
                        colorFilter: ColorFilter.mode(
                          AppColors.goldBright,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    12.width,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            LocaleKey.todaySoulPoints.tr,
                            style: AppStyles.caption(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ).copyWith(letterSpacing: 0.5),
                          ),
                          2.height,
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: AppGlowText(
                              text: '$soulPoints',
                              style: AppStyles.numberLarge().copyWith(
                                fontSize: 44,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      fit: FlexFit.loose,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: <Color>[
                                  AppColors.energyOrange.withValues(
                                    alpha: 0.24,
                                  ),
                                  AppColors.richGold.withValues(alpha: 0.2),
                                ],
                              ),
                              border: Border.all(
                                color: AppColors.energyOrange.withValues(
                                  alpha: 0.42,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: AppColors.energyOrange.withValues(
                                    alpha: 0.18,
                                  ),
                                  blurRadius: 12,
                                  spreadRadius: 0.4,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Icon(
                                  Icons.local_fire_department,
                                  size: 15,
                                  color: AppColors.energyOrange,
                                ),
                                6.width,
                                Text(
                                  streakLabel,
                                  style: AppStyles.bodySmall(
                                    color: AppColors.energyOrange,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                12.height,
                _ProgressInfo(
                  headLabel:
                      '${LocaleKey.todayDailyStreakLabel.tr}: $streakCurrent/$streakTarget',
                  progress: streakProgress,
                  leftCaption:
                      '${LocaleKey.todayRemainingPrefix.tr} '
                      '${(streakTarget - streakCurrent).clamp(0, streakTarget)} '
                      '${LocaleKey.todayStreakDaysRemaining.tr}',
                  rightCaption:
                      '+${TodayUniversalContent._streakReward} ${LocaleKey.todayRewardPointsSuffix.tr}',
                  rightCaptionColor: AppColors.richGold,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyCheckInCard extends StatelessWidget {
  const _DailyCheckInCard({
    required this.hasCheckedInToday,
    required this.checkInReward,
    required this.nextDayReward,
    required this.dailyEarnings,
    required this.dailyLimit,
    required this.earningProgress,
    required this.onCheckIn,
  });

  final bool hasCheckedInToday;
  final int checkInReward;
  final int nextDayReward;
  final int dailyEarnings;
  final int dailyLimit;
  final double earningProgress;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    return AppMysticalCard(
      borderColor: AppColors.richGold.withValues(alpha: 0.4),
      child: Stack(
        children: <Widget>[
          const Positioned(top: -20, right: -20, child: _PulseOrb(size: 126)),
          Column(
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          LocaleKey.todayCheckInTitle.tr,
                          style: AppStyles.h4(fontWeight: FontWeight.w600),
                        ),
                        6.height,
                        Text(
                          hasCheckedInToday
                              ? '${LocaleKey.todayCheckInClaimed.tr} '
                                    '$checkInReward ${LocaleKey.todaySoulPoints.tr}'
                              : '${LocaleKey.todayCheckInAvailable.tr} '
                                    '$checkInReward ${LocaleKey.todaySoulPoints.tr} '
                                    '${LocaleKey.todayNowSuffix.tr}',
                          style: AppStyles.bodySmall(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _CompactActionButton(
                    active: !hasCheckedInToday,
                    onTap: hasCheckedInToday ? null : onCheckIn,
                    label: hasCheckedInToday
                        ? LocaleKey.todayCheckInDone.tr
                        : LocaleKey.todayCheckInCta.tr,
                    icon: hasCheckedInToday
                        ? Icons.check_circle
                        : Icons.auto_awesome,
                  ),
                ],
              ),
              12.height,
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.richGold.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.richGold.withValues(alpha: 0.24),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.local_fire_department,
                          size: 14,
                          color: AppColors.richGold,
                        ),
                        6.width,
                        Text(
                          hasCheckedInToday
                              ? LocaleKey.todayCheckInMilestoneTitleClaimed.tr
                              : LocaleKey.todayCheckInMilestoneTitlePending.tr,
                          style: AppStyles.bodySmall(
                            color: AppColors.richGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    8.height,
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 4.5,
                      children: <Widget>[
                        _MilestoneRow(
                          label: LocaleKey.todayCheckInMilestoneTomorrow.tr,
                          reward: nextDayReward,
                        ),
                        _MilestoneRow(
                          label: LocaleKey.todayCheckInMilestoneDay7.tr,
                          reward: 15,
                        ),
                        _MilestoneRow(
                          label: LocaleKey.todayCheckInMilestoneDay14.tr,
                          reward: 20,
                        ),
                        _MilestoneRow(
                          label: LocaleKey.todayCheckInMilestoneDay30.tr,
                          reward: 30,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              12.height,
              _ProgressInfo(
                headLabel:
                    '${LocaleKey.todayDailyLimit.tr}: $dailyEarnings/$dailyLimit ${LocaleKey.todayRewardPointsSuffix.tr}',
                progress: earningProgress,
                leftCaption: dailyEarnings >= dailyLimit
                    ? LocaleKey.todayDailyLimitReached.tr
                    : '${LocaleKey.todayRemainingPrefix.tr} '
                          '${dailyLimit - dailyEarnings} '
                          '${LocaleKey.todayRewardPointsSuffix.tr} '
                          '${LocaleKey.todayDailyLimitRemaining.tr}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({required this.label, required this.reward});

  final String label;
  final int reward;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            '$label:',
            style: AppStyles.caption(color: AppColors.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '+$reward ${LocaleKey.todayRewardPointsSuffix.tr}',
          style: AppStyles.caption(
            color: AppColors.richGold,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ProgressInfo extends StatelessWidget {
  const _ProgressInfo({
    required this.headLabel,
    required this.progress,
    required this.leftCaption,
    this.rightCaption,
    this.rightCaptionColor = AppColors.richGold,
  });

  final String headLabel;
  final double progress;
  final String leftCaption;
  final String? rightCaption;
  final Color rightCaptionColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                headLabel,
                style: AppStyles.caption(color: AppColors.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (rightCaption != null)
              Text(
                rightCaption!,
                style: AppStyles.caption(
                  color: rightCaptionColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        6.height,
        SizedBox(
          width: double.infinity,
          child: _ShimmerProgressBar(progress: progress),
        ),
        6.height,
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            leftCaption,
            style: AppStyles.caption(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _ShimmerProgressBar extends StatefulWidget {
  const _ShimmerProgressBar({required this.progress});

  final double progress;

  @override
  State<_ShimmerProgressBar> createState() => _ShimmerProgressBarState();
}

class _ShimmerProgressBarState extends State<_ShimmerProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    final double safeProgress = widget.progress.clamp(0.0, 1.0);

    return SizedBox(
      width: double.infinity,
      height: 10,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.deepViolet.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(999),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: safeProgress),
                      duration: const Duration(milliseconds: 560),
                      curve: Curves.easeOutCubic,
                      builder:
                          (BuildContext context, double value, Widget? child) {
                            final double width = constraints.maxWidth * value;
                            if (width <= 0) {
                              return const SizedBox.shrink();
                            }

                            return SizedBox(
                              width: width,
                              child: Stack(
                                fit: StackFit.expand,
                                children: <Widget>[
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: <Color>[
                                          AppColors.richGold,
                                          AppColors.goldBright,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  AnimatedBuilder(
                                    animation: _controller,
                                    builder:
                                        (BuildContext context, Widget? child) {
                                          return FractionalTranslation(
                                            translation: Offset(
                                              (_controller.value * 2) - 1,
                                              0,
                                            ),
                                            child: child,
                                          );
                                        },
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: FractionallySizedBox(
                                        widthFactor: 0.5,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: <Color>[
                                                AppColors.transparent,
                                                AppColors.white.withValues(
                                                  alpha: 0.28,
                                                ),
                                                AppColors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.active,
    required this.onTap,
    required this.label,
    required this.icon,
  });

  final bool active;
  final VoidCallback? onTap;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: active
              ? const LinearGradient(
                  colors: <Color>[AppColors.richGold, AppColors.goldBright],
                )
              : null,
          color: active ? null : AppColors.deepViolet,
          border: Border.all(
            color: active
                ? AppColors.goldBright.withValues(alpha: 0.85)
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 14,
              color: active ? AppColors.midnight : AppColors.textMuted,
            ),
            5.width,
            Text(
              label,
              style: AppStyles.caption(
                color: active ? AppColors.midnight : AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: AppStyles.h4(fontWeight: FontWeight.w600)),
        4.height,
        Text(subtitle, style: AppStyles.bodySmall(color: AppColors.textMuted)),
      ],
    );
  }
}

class _NumberFeatureCard extends StatelessWidget {
  const _NumberFeatureCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppMysticalCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.richGold.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppColors.richGold),
          ),
          10.height,
          Text(title, style: AppStyles.bodySmall(fontWeight: FontWeight.w600)),
          4.height,
          AppGlowText(text: value, style: AppStyles.numberMedium()),
          2.height,
          Text(subtitle, style: AppStyles.caption(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _WideFeatureCard extends StatelessWidget {
  const _WideFeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppMysticalCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.richGold.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 21, color: AppColors.richGold),
          ),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppStyles.bodyMedium(fontWeight: FontWeight.w600),
                ),
                2.height,
                Text(
                  subtitle,
                  style: AppStyles.bodySmall(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.richGold),
        ],
      ),
    );
  }
}

class _InfoFeatureCard extends StatelessWidget {
  const _InfoFeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppMysticalCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.richGold.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: AppColors.richGold),
          ),
          10.height,
          Text(title, style: AppStyles.bodySmall(fontWeight: FontWeight.w600)),
          4.height,
          Text(
            subtitle,
            style: AppStyles.caption(color: AppColors.textMuted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _UnlockCard extends StatelessWidget {
  const _UnlockCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppMysticalCard(
      borderColor: AppColors.richGold.withValues(alpha: 0.3),
      child: Column(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.richGold.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline,
              color: AppColors.richGold,
              size: 24,
            ),
          ),
          10.height,
          Text(
            LocaleKey.todayUnlockTitle.tr,
            style: AppStyles.h4(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          8.height,
          Text(
            LocaleKey.todayUnlockSubtitle.tr,
            style: AppStyles.bodySmall(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          14.height,
          AppPrimaryButton(
            label: LocaleKey.todayUnlockCta.tr,
            onPressed: onTap,
            leading: const Icon(Icons.auto_awesome, color: AppColors.midnight),
          ),
        ],
      ),
    );
  }
}

class _PulseOrb extends StatefulWidget {
  const _PulseOrb({
    required this.size,
    this.color = AppColors.richGold,
    this.alpha = 0.14,
  });

  final double size;
  final Color color;
  final double alpha;

  @override
  State<_PulseOrb> createState() => _PulseOrbState();
}

class _PulseOrbState extends State<_PulseOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2900),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double scale = 0.9 + (_controller.value * 0.2);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: widget.alpha),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
