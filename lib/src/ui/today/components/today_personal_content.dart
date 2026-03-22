import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/core/model/numerology_content_models.dart';
import 'package:test/src/core/model/profile_time_life_snapshot.dart';
import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/helper/numerology_helper.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/compatibility/components/compatibility_profile_input_dialog.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_state.dart';
import 'package:test/src/ui/widgets/app_glow_text.dart';
import 'package:test/src/ui/widgets/app_mystical_card.dart';
import 'package:test/src/ui/widgets/app_reward_celebration_overlay.dart';
import 'package:test/src/utils/app_assets.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_dimensions.dart';
import 'package:test/src/utils/app_pages.dart';
import 'package:test/src/utils/app_styles.dart';
import 'package:test/src/utils/tab_navigation_helper.dart';

class TodayPersonalContent extends StatelessWidget {
  const TodayPersonalContent({super.key});

  @override
  Widget build(BuildContext context) {
    final MainSessionBloc sessionBloc = Get.find<MainSessionBloc>();
    return BlocBuilder<MainSessionBloc, MainSessionState>(
      bloc: sessionBloc,
      builder: (BuildContext context, MainSessionState state) {
        final int personalDayNumber = _resolvePersonalDayNumber(state);
        final int personalMonthNumber = _resolvePersonalMonthNumber(state);
        final int personalYearNumber = _resolvePersonalYearNumber(state);
        final NumerologyPersonalMonthContent personalMonthContent =
            _resolvePersonalMonthContent(personalMonthNumber);
        final NumerologyPersonalYearContent personalYearContent =
            _resolvePersonalYearContent(personalYearNumber);
        final NumerologyTodayPersonalNumberContent content =
            _resolvePersonalContent(personalDayNumber);
        final bool isGuest = state.currentProfile == null;

        final String profileId =
            state.currentProfile?.id ?? MainSessionBloc.guestProfileId;
        final ProfileTimeLifeSnapshot? snapshot =
            state.timeLifeByProfileId[profileId];
        final int luckyNumber =
            snapshot?.valueOf(ProfileTimeLifeSnapshot.luckyNumberMetric) ??
            NumerologyHelper.luckyNumber();
        final int angelNumber =
            state.dailyAngelNumber ?? _angelNumberFromTime(DateTime.now());
        final String currentTime = _formatAngelNumber(angelNumber);

        return Column(
          children: <Widget>[
            _DailyCheckInCard(
              soulPoints: state.soulPoints,
              currentStreak: state.currentStreak,
              lastCheckInRewardAwarded: state.lastCheckInRewardAwarded,
              lastCheckInEventId: state.lastCheckInEventId,
            ),
            12.height,
            _PersonalHeroCard(
              onTap: () async {
                if (isGuest) {
                  await _handleGuestUnlockAndNavigate(
                    context,
                    sessionBloc,
                    AppPages.todayDetail,
                  );
                  return;
                }
                _trackAndNavigate(sessionBloc, AppPages.todayDetail);
              },
              isGuest: isGuest,
              personalDayNumber: personalDayNumber,
              quote: content.quote,
              dailyRhythm: content.dailyRhythm,
            ),
            10.height,
            _InlineCtaRow(
              icon: Icons.lightbulb_outline_rounded,
              iconColor: AppColors.richGold.withValues(alpha: 0.65),
              lead: LocaleKey.todayPersonalInlineProfileLead.tr,
              action: LocaleKey.todayPersonalInlineProfileCta.tr,
              actionColor: AppColors.richGold,
              onTap: () => _trackAndNavigate(sessionBloc, AppPages.profile),
            ),
            12.height,
            _LuckyAngelGrid(
              luckyNumber: luckyNumber,
              currentTime: currentTime,
              onLuckyTap: () =>
                  _trackAndNavigate(sessionBloc, AppPages.luckyNumber),
              onAngelTap: () =>
                  _trackAndNavigate(sessionBloc, AppPages.angelNumbers),
            ),
            14.height,
            _ContextSection(
              isGuest: isGuest,
              personalMonthNumber: personalMonthNumber,
              personalYearNumber: personalYearNumber,
              monthKeyword: personalMonthContent.keyword,
              yearKeyword: personalYearContent.keyword,
              onMonthTap: () async {
                if (isGuest) {
                  await _handleGuestUnlockAndNavigate(
                    context,
                    sessionBloc,
                    AppPages.monthDetail,
                  );
                  return;
                }
                _trackAndNavigate(sessionBloc, AppPages.monthDetail);
              },
              onYearTap: () async {
                if (isGuest) {
                  await _handleGuestUnlockAndNavigate(
                    context,
                    sessionBloc,
                    AppPages.yearDetail,
                  );
                  return;
                }
                _trackAndNavigate(sessionBloc, AppPages.yearDetail);
              },
            ),
            10.height,
            _InlineCtaRow(
              icon: Icons.favorite,
              iconColor: AppColors.energyPink,
              lead: LocaleKey.todayPersonalCompatibilityLead.tr,
              action: LocaleKey.todayPersonalCompatibilityCta.tr,
              actionColor: AppColors.energyPink,
              onTap: () =>
                  _trackAndNavigate(sessionBloc, AppPages.compatibility),
            ),
          ],
        );
      },
    );
  }

  void _trackAndNavigate(MainSessionBloc sessionBloc, String route) {
    sessionBloc.trackInteraction('today');
    TabNavigationHelper.navigateFromMain(route);
  }

  Future<void> _handleGuestUnlockAndNavigate(
    BuildContext context,
    MainSessionBloc sessionBloc,
    String route,
  ) async {
    bool didSubmit = false;
    await CompatibilityProfileInputDialog.show(
      context,
      onSubmit: (String name, DateTime birthDate) async {
        didSubmit = true;
        await sessionBloc.addProfile(name: name, birthDate: birthDate);
      },
    );

    if (!context.mounted || !didSubmit) {
      return;
    }

    if (sessionBloc.state.currentProfile == null) {
      return;
    }

    sessionBloc.trackInteraction('today');
    await TabNavigationHelper.navigateFromMain(route);
  }

  int _angelNumberFromTime(DateTime now) {
    return (now.hour * 100) + now.minute;
  }

  String _formatAngelNumber(int value) {
    final int hour = value ~/ 100;
    final int minute = value % 100;
    final String hourText = hour.toString().padLeft(2, '0');
    final String minuteText = minute.toString().padLeft(2, '0');
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return '00:00';
    }
    return '$hourText:$minuteText';
  }

  int _resolvePersonalDayNumber(MainSessionState state) {
    final String profileId =
        state.currentProfile?.id ?? MainSessionBloc.guestProfileId;
    final int? number = state.timeLifeByProfileId[profileId]?.valueOf(
      ProfileTimeLifeSnapshot.personalDayMetric,
    );
    if (number != null) {
      return number;
    }

    final profile = state.currentProfile;
    if (profile == null) {
      return 0;
    }
    return NumerologyHelper.calculatePersonalDayNumber(
      birthDate: profile.birthDate,
      date: DateTime.now(),
    );
  }

  int _resolvePersonalMonthNumber(MainSessionState state) {
    final String profileId =
        state.currentProfile?.id ?? MainSessionBloc.guestProfileId;
    final ProfileTimeLifeSnapshot? snapshot =
        state.timeLifeByProfileId[profileId];
    final profile = state.currentProfile;
    if (profile == null) {
      final int? universalNumber = snapshot?.valueOf(
        ProfileTimeLifeSnapshot.universalMonthMetric,
      );
      if (universalNumber != null) {
        return universalNumber;
      }
      return NumerologyHelper.calculateUniversalMonthNumber(DateTime.now());
    }
    final int? personalNumber = snapshot?.valueOf(
      ProfileTimeLifeSnapshot.personalMonthMetric,
    );
    if (personalNumber != null) {
      return personalNumber;
    }
    return NumerologyHelper.calculatePersonalMonthNumber(
      birthDate: profile.birthDate,
      date: DateTime.now(),
    );
  }

  int _resolvePersonalYearNumber(MainSessionState state) {
    final String profileId =
        state.currentProfile?.id ?? MainSessionBloc.guestProfileId;
    final ProfileTimeLifeSnapshot? snapshot =
        state.timeLifeByProfileId[profileId];
    final profile = state.currentProfile;
    if (profile == null) {
      final int? universalNumber = snapshot?.valueOf(
        ProfileTimeLifeSnapshot.universalYearMetric,
      );
      if (universalNumber != null) {
        return universalNumber;
      }
      return NumerologyHelper.calculateUniversalYearNumber(DateTime.now());
    }
    final int? personalNumber = snapshot?.valueOf(
      ProfileTimeLifeSnapshot.personalYearMetric,
    );
    if (personalNumber != null) {
      return personalNumber;
    }
    return NumerologyHelper.calculatePersonalYearNumber(
      birthDate: profile.birthDate,
      date: DateTime.now(),
    );
  }

  NumerologyTodayPersonalNumberContent _resolvePersonalContent(
    int personalDayNumber,
  ) {
    final INumerologyContentRepository contentRepository =
        Get.find<INumerologyContentRepository>();
    final String languageCode = Get.locale?.languageCode ?? 'vi';
    return contentRepository.getTodayPersonalNumberContent(
      number: personalDayNumber,
      languageCode: languageCode,
    );
  }

  NumerologyPersonalMonthContent _resolvePersonalMonthContent(
    int personalMonthNumber,
  ) {
    final INumerologyContentRepository contentRepository =
        Get.find<INumerologyContentRepository>();
    final String languageCode = Get.locale?.languageCode ?? 'vi';
    return contentRepository.getPersonalMonthContent(
      number: personalMonthNumber,
      languageCode: languageCode,
    );
  }

  NumerologyPersonalYearContent _resolvePersonalYearContent(
    int personalYearNumber,
  ) {
    final INumerologyContentRepository contentRepository =
        Get.find<INumerologyContentRepository>();
    final String languageCode = Get.locale?.languageCode ?? 'vi';
    return contentRepository.getPersonalYearContent(
      number: personalYearNumber,
      languageCode: languageCode,
    );
  }
}

class _CheckInMilestone {
  const _CheckInMilestone({
    required this.day,
    required this.reward,
    required this.labelKey,
    this.special = false,
  });

  final int day;
  final int reward;
  final String labelKey;
  final bool special;
}

const List<_CheckInMilestone> _checkInMilestones = <_CheckInMilestone>[
  _CheckInMilestone(
    day: 1,
    reward: 10,
    labelKey: LocaleKey.todayCheckInMilestoneLabelDay1,
  ),
  _CheckInMilestone(
    day: 7,
    reward: 20,
    labelKey: LocaleKey.todayCheckInMilestoneLabelWeek1,
  ),
  _CheckInMilestone(
    day: 14,
    reward: 30,
    labelKey: LocaleKey.todayCheckInMilestoneLabelWeek2,
  ),
  _CheckInMilestone(
    day: 30,
    reward: 50,
    labelKey: LocaleKey.todayCheckInMilestoneLabelMonth1,
    special: true,
  ),
];

class _DailyCheckInCard extends StatefulWidget {
  const _DailyCheckInCard({
    required this.soulPoints,
    required this.currentStreak,
    required this.lastCheckInRewardAwarded,
    required this.lastCheckInEventId,
  });

  final int soulPoints;
  final int currentStreak;
  final int lastCheckInRewardAwarded;
  final int lastCheckInEventId;

  @override
  State<_DailyCheckInCard> createState() => _DailyCheckInCardState();
}

class _DailyCheckInCardState extends State<_DailyCheckInCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _ambientController;
  int _lastCelebratedEventId = 0;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);
    _tryTriggerCelebrationIfNeeded();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _DailyCheckInCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tryTriggerCelebrationIfNeeded();
  }

  void _tryTriggerCelebrationIfNeeded() {
    final int eventId = widget.lastCheckInEventId;
    final int rewardAwarded = widget.lastCheckInRewardAwarded;
    final bool hasFreshEvent = eventId > _lastCelebratedEventId;
    if (!hasFreshEvent || rewardAwarded <= 0) {
      return;
    }
    _lastCelebratedEventId = eventId;
    _triggerCelebration(rewardAwarded);
    Get.find<MainSessionBloc>().consumeCheckInCelebration(eventId: eventId);
  }

  void _triggerCelebration(int rewardAwarded) {
    final int reward = rewardAwarded.clamp(0, 9999);
    if (reward == 0) {
      return;
    }
    final _CheckInMilestone? celebrationMilestone = _milestoneOfDay(
      widget.currentStreak,
    );
    _showCelebrationOverlay(
      reward: reward,
      streak: widget.currentStreak,
      milestone: celebrationMilestone,
    );
  }

  void _showCelebrationOverlay({
    required int reward,
    required int streak,
    required _CheckInMilestone? milestone,
  }) {
    if (!mounted) {
      return;
    }
    final String title = milestone != null
        ? '${LocaleKey.todayCheckInMilestoneCelebration.tr} ${milestone.labelKey.tr}!'
        : LocaleKey.todayCheckInCelebrationSuccess.tr;
    AppRewardCelebrationOverlay.show(
      context,
      reward: reward,
      title: title,
      subtitle:
          '${LocaleKey.todayDailyStreak.tr}: $streak ${LocaleKey.todayCheckInDays.tr}',
    );
  }

  _CheckInMilestone _nextMilestone(int streak) {
    for (final _CheckInMilestone milestone in _checkInMilestones) {
      if (milestone.day > streak) {
        return milestone;
      }
    }
    return _checkInMilestones.last;
  }

  _CheckInMilestone? _milestoneOfDay(int day) {
    for (final _CheckInMilestone milestone in _checkInMilestones) {
      if (milestone.day == day) {
        return milestone;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final _CheckInMilestone nextMilestone = _nextMilestone(
      widget.currentStreak,
    );
    final int daysUntilMilestone = (nextMilestone.day - widget.currentStreak)
        .clamp(0, nextMilestone.day);
    final double milestoneProgress = (widget.currentStreak / nextMilestone.day)
        .clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _ambientController,
      builder: (BuildContext context, Widget? child) {
        final double pulse = Curves.easeInOut.transform(
          _ambientController.value,
        );
        final double glowFactor = 0.82 + (0.38 * pulse);

        return Stack(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.richGold.withValues(alpha: 0.6),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    AppColors.richGold.withValues(alpha: 0.1),
                    AppColors.card.withValues(alpha: 0.5),
                    AppColors.card.withValues(alpha: 0.3),
                  ],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                          child: Column(
                            children: <Widget>[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                  10,
                                  10,
                                  10,
                                  10,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: <Color>[
                                      AppColors.richGold.withValues(
                                        alpha: 0.06 + (0.05 * pulse),
                                      ),
                                      AppColors.transparent,
                                    ],
                                  ),
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Row(
                                        children: <Widget>[
                                          _HeaderOrb(
                                            size: 48,
                                            glowColor: AppColors.richGold,
                                            iconAsset: AppAssets.iconCoinPng,
                                            iconSize: 22,
                                            iconColor: AppColors.richGold,
                                            glowFactor: glowFactor,
                                          ),
                                          10.width,
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                LocaleKey.todaySoulPoints.tr,
                                                style: AppStyles.caption(
                                                  color: AppColors.textMuted,
                                                  fontWeight: FontWeight.w600,
                                                ).copyWith(letterSpacing: 0.6),
                                              ),
                                              Text(
                                                '${widget.soulPoints}',
                                                style:
                                                    AppStyles.h1(
                                                      color: AppColors.richGold,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ).copyWith(
                                                      height: 1,
                                                      shadows: <Shadow>[
                                                        Shadow(
                                                          color: AppColors
                                                              .richGold
                                                              .withValues(
                                                                alpha:
                                                                    (0.32 +
                                                                            (0.22 *
                                                                                pulse))
                                                                        .clamp(
                                                                          0,
                                                                          1,
                                                                        ),
                                                              ),
                                                          blurRadius: 14,
                                                        ),
                                                      ],
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: <Widget>[
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: <Widget>[
                                              Text(
                                                "Chuỗi Ngày",
                                                style: AppStyles.caption(
                                                  color: AppColors.textMuted,
                                                  fontWeight: FontWeight.w600,
                                                ).copyWith(letterSpacing: 0.6),
                                              ),
                                              RichText(
                                                text: TextSpan(
                                                  style:
                                                      AppStyles.h1(
                                                        color:
                                                            widget.currentStreak >
                                                                0
                                                            ? AppColors
                                                                  .energyOrange
                                                            : AppColors
                                                                  .textMuted,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ).copyWith(
                                                        height: 1,
                                                        shadows:
                                                            widget.currentStreak >
                                                                0
                                                            ? <Shadow>[
                                                                Shadow(
                                                                  color: AppColors.richGold.withValues(
                                                                    alpha:
                                                                        (0.3 +
                                                                                (0.2 *
                                                                                    pulse))
                                                                            .clamp(
                                                                              0,
                                                                              1,
                                                                            ),
                                                                  ),
                                                                  blurRadius:
                                                                      12,
                                                                ),
                                                              ]
                                                            : null,
                                                      ),
                                                  children: <TextSpan>[
                                                    TextSpan(
                                                      text:
                                                          '${widget.currentStreak}',
                                                    ),
                                                    // TextSpan(
                                                    //   text:
                                                    //       ' ${LocaleKey.todayCheckInDays.tr}',
                                                    //   style:
                                                    //       AppStyles.bodySmall(
                                                    //         color: AppColors
                                                    //             .textMuted,
                                                    //         fontWeight:
                                                    //             FontWeight.w600,
                                                    //       ),
                                                    // ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          10.width,
                                          _HeaderOrb(
                                            size: 48,
                                            glowColor: AppColors.energyOrange,
                                            iconAsset: AppAssets.iconFireSvg,
                                            iconColor: widget.currentStreak > 0
                                                ? AppColors.energyOrange
                                                : AppColors.textMuted,
                                            active: widget.currentStreak > 0,
                                            glowFactor: glowFactor,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              10.height,
                              Material(
                                color: AppColors.transparent,
                                child: InkWell(
                                  onTap: () => setState(() {
                                    _isExpanded = !_isExpanded;
                                  }),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Text(
                                          _isExpanded
                                              ? LocaleKey
                                                    .todayCheckInCollapse
                                                    .tr
                                              : LocaleKey.todayCheckInExpand.tr,
                                          style: AppStyles.bodySmall(
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                        6.width,
                                        Icon(
                                          _isExpanded
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                          size: 16,
                                          color: AppColors.textMuted,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                10,
                                12,
                                12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.richGold.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      const Icon(
                                        Icons.emoji_events_rounded,
                                        size: 14,
                                        color: AppColors.richGold,
                                      ),
                                      6.width,
                                      Expanded(
                                        child: Text(
                                          '${LocaleKey.todayCheckInNextMilestone.tr}: ${nextMilestone.labelKey.tr}',
                                          style: AppStyles.bodySmall(
                                            color: AppColors.textPrimary
                                                .withValues(alpha: 0.85),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${widget.currentStreak}/${nextMilestone.day}',
                                        style: AppStyles.bodySmall(
                                          color: AppColors.richGold,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  8.height,
                                  _ShimmerProgressBar(
                                    progress: milestoneProgress,
                                  ),
                                  8.height,
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          '${LocaleKey.todayCheckInDaysRemaining.tr} $daysUntilMilestone ${LocaleKey.todayCheckInDays.tr}',
                                          style: AppStyles.caption(
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: <Widget>[
                                          const Icon(
                                            Icons.auto_awesome,
                                            size: 12,
                                            color: AppColors.richGold,
                                          ),
                                          4.width,
                                          Text(
                                            '+${nextMilestone.reward} ${LocaleKey.todayRewardPointsSuffix.tr}',
                                            style: AppStyles.caption(
                                              color: AppColors.richGold,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  10.height,
                                  Container(
                                    height: 1,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      gradient: LinearGradient(
                                        colors: <Color>[
                                          AppColors.transparent,
                                          AppColors.richGold.withValues(
                                            alpha: 0.28,
                                          ),
                                          AppColors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  10.height,
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      LocaleKey
                                          .todayCheckInMilestoneGridTitle
                                          .tr,
                                      style: AppStyles.bodySmall(
                                        color: AppColors.textPrimary.withValues(
                                          alpha: 0.75,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  8.height,
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _checkInMilestones.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 8,
                                          mainAxisSpacing: 8,
                                          childAspectRatio: 2.1,
                                        ),
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                          final _CheckInMilestone milestone =
                                              _checkInMilestones[index];
                                          final bool isCompleted =
                                              widget.currentStreak >=
                                              milestone.day;
                                          final bool isCurrent =
                                              !isCompleted &&
                                              milestone == nextMilestone;
                                          return _MilestoneRewardTile(
                                            milestone: milestone,
                                            isCompleted: isCompleted,
                                            isCurrent: isCurrent,
                                          );
                                        },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          crossFadeState: _isExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 260),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeaderOrb extends StatelessWidget {
  const _HeaderOrb({
    required this.size,
    required this.glowColor,
    this.icon,
    this.iconAsset,
    this.iconColor = AppColors.richGold,
    this.iconSize = 24,
    this.active = true,
    this.glowFactor = 1,
  }) : assert(
         icon != null || iconAsset != null,
         '_HeaderOrb requires either icon or iconAsset.',
       );

  final double size;
  final Color glowColor;
  final IconData? icon;
  final String? iconAsset;
  final Color iconColor;
  final double iconSize;
  final bool active;
  final double glowFactor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        if (active)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: glowColor.withValues(
                    alpha: (0.26 * glowFactor).clamp(0, 1),
                  ),
                  blurRadius: 12 + (8 * glowFactor),
                ),
              ],
            ),
          ),
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                glowColor.withValues(alpha: (0.22 * glowFactor).clamp(0, 1)),
                glowColor.withValues(alpha: (0.08 * glowFactor).clamp(0, 1)),
              ],
            ),
            border: Border.all(
              color: active
                  ? glowColor.withValues(alpha: (0.45 * glowFactor).clamp(0, 1))
                  : AppColors.border.withValues(alpha: 0.45),
              width: 1.6,
            ),
          ),
          child: iconAsset != null
              ? SvgPicture.asset(
                  iconAsset!,
                  width: iconSize,
                  height: iconSize,
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                )
              : Icon(icon, size: iconSize, color: iconColor),
        ),
      ],
    );
  }
}

class _MilestoneRewardTile extends StatelessWidget {
  const _MilestoneRewardTile({
    required this.milestone,
    required this.isCompleted,
    required this.isCurrent,
  });

  final _CheckInMilestone milestone;
  final bool isCompleted;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.circular(12);
    final Color borderColor = isCompleted
        ? AppColors.richGold.withValues(alpha: 0.46)
        : isCurrent
        ? AppColors.goldBright.withValues(alpha: 0.58)
        : AppColors.border.withValues(alpha: 0.35);
    final Color startColor = isCompleted
        ? AppColors.richGold.withValues(alpha: 0.16)
        : isCurrent
        ? AppColors.richGold.withValues(alpha: 0.11)
        : AppColors.deepViolet.withValues(alpha: 0.3);
    final Color endColor = isCompleted
        ? AppColors.deepViolet.withValues(alpha: 0.42)
        : isCurrent
        ? AppColors.deepViolet.withValues(alpha: 0.36)
        : AppColors.deepViolet.withValues(alpha: 0.26);
    final Color primaryTextColor = isCompleted || isCurrent
        ? AppColors.textSecondary
        : AppColors.textMuted;
    final Color rewardColor = isCompleted || isCurrent
        ? AppColors.richGold
        : AppColors.textMuted;
    final Color statusColor = isCompleted
        ? AppColors.goldBright
        : isCurrent
        ? AppColors.richGold
        : AppColors.textMuted;
    final IconData statusIcon = isCompleted
        ? Icons.check_rounded
        : isCurrent
        ? Icons.radio_button_checked_rounded
        : Icons.lock_outline_rounded;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: borderColor, width: isCurrent ? 1.7 : 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[startColor, endColor],
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor.withValues(alpha: 0.14),
              border: Border.all(color: statusColor.withValues(alpha: 0.72)),
            ),
            child: Icon(statusIcon, size: 14, color: statusColor),
          ),
          8.width,
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  milestone.labelKey.tr,
                  style: AppStyles.bodySmall(
                    color: primaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                2.height,
                Text(
                  '+${milestone.reward} ${LocaleKey.todayRewardPointsSuffix.tr}',
                  style: AppStyles.caption(
                    color: rewardColor,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (milestone.special)
            const Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: AppColors.richGold,
            ),
        ],
      ),
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
      height: 8,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.deepViolet.withValues(alpha: 0.8),
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

class _PersonalHeroCard extends StatelessWidget {
  const _PersonalHeroCard({
    required this.onTap,
    required this.isGuest,
    required this.personalDayNumber,
    required this.quote,
    required this.dailyRhythm,
  });

  final VoidCallback onTap;
  final bool isGuest;
  final int personalDayNumber;
  final String quote;
  final String dailyRhythm;

  @override
  Widget build(BuildContext context) {
    final String displayNumber = isGuest
        ? LocaleKey.todayPersonalGuestNumber.tr
        : (personalDayNumber > 0 ? '$personalDayNumber' : '•');
    final String quoteText = isGuest
        ? LocaleKey.todayPersonalGuestQuote.tr
        : (quote.isEmpty ? LocaleKey.todayPersonalHeroBody.tr : quote);
    final String rhythmText = isGuest
        ? LocaleKey.todayPersonalGuestRhythm.tr
        : (dailyRhythm.isEmpty
              ? LocaleKey.todayPersonalRhythmValue.tr
              : dailyRhythm);
    final String cardTitle = isGuest
        ? LocaleKey.todayPersonalGuestHeroTitle.tr
        : LocaleKey.todayPersonalHeroTitle.tr;
    final String ctaLabel = isGuest
        ? LocaleKey.todayPersonalGuestCta.tr
        : LocaleKey.todayPersonalDetailCta.tr;

    return AppMysticalCard(
      borderColor: AppColors.richGold.withValues(alpha: 0.32),
      padding: EdgeInsets.zero,
      child: Stack(
        children: <Widget>[
          const Positioned.fill(child: _PersonalHeroCosmicBackground()),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.auto_awesome,
                      color: AppColors.richGold,
                      size: 20,
                    ),
                    8.width,
                    Text(
                      cardTitle,
                      style: AppStyles.h5(
                        fontWeight: FontWeight.w600,
                      ).copyWith(fontSize: 18, height: 1.3),
                    ),
                  ],
                ),
                12.height,
                Center(
                  child: Column(
                    children: <Widget>[
                      _HeroNumberGalaxy(numberText: displayNumber),
                      10.height,
                      Text(
                        rhythmText,
                        textAlign: TextAlign.center,
                        style: AppStyles.h4(
                          color: AppColors.richGold,
                          fontWeight: FontWeight.w700,
                        ).copyWith(height: 1.24),
                      ),
                    ],
                  ),
                ),
                14.height,
                Stack(
                  children: <Widget>[
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 1,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              AppColors.richGold,
                              AppColors.richGold.withValues(alpha: 0.5),
                              AppColors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 12,
                        top: 2,
                        bottom: 2,
                      ),
                      child: Text(
                        '"$quoteText"',
                        style: AppStyles.bodyMedium(
                          color: AppColors.textPrimary.withValues(alpha: 0.9),
                        ).copyWith(fontStyle: FontStyle.italic, height: 1.52),
                      ),
                    ),
                  ],
                ),
                if (isGuest) ...<Widget>[
                  12.height,
                  Text(
                    LocaleKey.todayPersonalGuestHint.tr,
                    style: AppStyles.bodySmall(
                      color: AppColors.textSecondary.withValues(alpha: 0.96),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                12.height,
                _PrimaryGlowButton(
                  label: ctaLabel,
                  icon: isGuest ? null : Icons.auto_awesome,
                  onTap: onTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroNumberGalaxy extends StatelessWidget {
  const _HeroNumberGalaxy({required this.numberText});

  final String numberText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 132,
      child: CustomPaint(
        painter: const _HeroNumberSkyPainter(),
        child: Center(
          child: AppGlowText(
            text: numberText,
            style: AppStyles.numberLarge().copyWith(
              fontSize: 98,
              height: 0.9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroNumberSkyPainter extends CustomPainter {
  const _HeroNumberSkyPainter();

  static const List<Offset> _stars = <Offset>[
    Offset(0.08, 0.28),
    Offset(0.16, 0.2),
    Offset(0.22, 0.34),
    Offset(0.32, 0.16),
    Offset(0.42, 0.26),
    Offset(0.56, 0.18),
    Offset(0.68, 0.22),
    Offset(0.8, 0.14),
    Offset(0.9, 0.26),
    Offset(0.12, 0.58),
    Offset(0.2, 0.66),
    Offset(0.32, 0.56),
    Offset(0.4, 0.72),
    Offset(0.58, 0.64),
    Offset(0.72, 0.58),
    Offset(0.84, 0.7),
    Offset(0.18, 0.86),
    Offset(0.36, 0.9),
    Offset(0.64, 0.88),
    Offset(0.82, 0.84),
  ];

  static const List<Offset> _goldStars = <Offset>[
    Offset(0.18, 0.22),
    Offset(0.38, 0.2),
    Offset(0.64, 0.3),
    Offset(0.78, 0.24),
    Offset(0.28, 0.62),
    Offset(0.72, 0.7),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width * 0.5, size.height * 0.48);

    final Paint glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: <Color>[
              AppColors.goldBright.withValues(alpha: 0.34),
              AppColors.richGold.withValues(alpha: 0.18),
              AppColors.transparent,
            ],
            stops: const <double>[0, 0.34, 1],
          ).createShader(
            Rect.fromCircle(center: center, radius: size.shortestSide * 0.58),
          );
    canvas.drawCircle(center, size.shortestSide * 0.58, glowPaint);

    final Paint hazePaint = Paint()
      ..shader =
          RadialGradient(
            colors: <Color>[
              AppColors.goldSoft.withValues(alpha: 0.14),
              AppColors.energyViolet.withValues(alpha: 0.06),
              AppColors.transparent,
            ],
            stops: const <double>[0, 0.58, 1],
          ).createShader(
            Rect.fromCenter(
              center: center,
              width: size.width * 0.86,
              height: size.height * 0.66,
            ),
          );
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.86,
        height: size.height * 0.66,
      ),
      hazePaint,
    );

    final Paint starPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < _stars.length; i++) {
      final Offset star = _stars[i];
      final bool anchor = i % 6 == 0;
      starPaint.color = (anchor ? AppColors.goldSoft : AppColors.white)
          .withValues(alpha: anchor ? 0.52 : 0.28);
      canvas.drawCircle(
        Offset(size.width * star.dx, size.height * star.dy),
        anchor ? 1.8 : 1.05,
        starPaint,
      );
    }

    final Paint goldPaint = Paint()..style = PaintingStyle.fill;
    for (final Offset star in _goldStars) {
      final Offset position = Offset(
        size.width * star.dx,
        size.height * star.dy,
      );
      canvas.drawCircle(
        position,
        3.8,
        Paint()..color = AppColors.goldBright.withValues(alpha: 0.16),
      );
      goldPaint.color = AppColors.goldBright.withValues(alpha: 0.84);
      canvas.drawCircle(position, 1.3, goldPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeroNumberSkyPainter oldDelegate) => false;
}

class _PersonalHeroCosmicBackground extends StatelessWidget {
  const _PersonalHeroCosmicBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      AppColors.energyViolet.withValues(alpha: 0.3),
                      AppColors.deepViolet.withValues(alpha: 0.22),
                      AppColors.midnight.withValues(alpha: 0.12),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -86,
              top: -52,
              child: _CosmicGlowOrb(
                size: 210,
                color: AppColors.richGold.withValues(alpha: 0.16),
              ),
            ),
            Positioned(
              right: -74,
              top: 26,
              child: _CosmicGlowOrb(
                size: 150,
                color: AppColors.energyViolet.withValues(alpha: 0.2),
              ),
            ),
            Positioned(
              right: -52,
              bottom: -66,
              child: _CosmicGlowOrb(
                size: 190,
                color: AppColors.energyPink.withValues(alpha: 0.14),
              ),
            ),
            const Positioned.fill(child: _AnimatedPersonalHeroConstellation()),
          ],
        ),
      ),
    );
  }
}

class _CosmicGlowOrb extends StatelessWidget {
  const _CosmicGlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, AppColors.transparent],
          ),
        ),
      ),
    );
  }
}

class _ConstellationLine {
  const _ConstellationLine(this.from, this.to);

  final Offset from;
  final Offset to;
}

class _AnimatedPersonalHeroConstellation extends StatefulWidget {
  const _AnimatedPersonalHeroConstellation();

  @override
  State<_AnimatedPersonalHeroConstellation> createState() =>
      _AnimatedPersonalHeroConstellationState();
}

class _AnimatedPersonalHeroConstellationState
    extends State<_AnimatedPersonalHeroConstellation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return CustomPaint(
          painter: _PersonalHeroConstellationPainter(
            progress: _controller.value,
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

class _PersonalHeroConstellationPainter extends CustomPainter {
  const _PersonalHeroConstellationPainter({required this.progress});

  final double progress;

  static const List<Offset> _stars = <Offset>[
    Offset(0.08, 0.12),
    Offset(0.17, 0.2),
    Offset(0.27, 0.14),
    Offset(0.36, 0.22),
    Offset(0.6, 0.1),
    Offset(0.72, 0.18),
    Offset(0.84, 0.12),
    Offset(0.92, 0.24),
    Offset(0.16, 0.46),
    Offset(0.24, 0.38),
    Offset(0.78, 0.42),
    Offset(0.88, 0.36),
    Offset(0.14, 0.7),
    Offset(0.32, 0.76),
    Offset(0.68, 0.72),
    Offset(0.82, 0.84),
  ];

  static const List<_ConstellationLine> _lines = <_ConstellationLine>[
    _ConstellationLine(Offset(0.08, 0.12), Offset(0.17, 0.2)),
    _ConstellationLine(Offset(0.17, 0.2), Offset(0.27, 0.14)),
    _ConstellationLine(Offset(0.27, 0.14), Offset(0.36, 0.22)),
    _ConstellationLine(Offset(0.6, 0.1), Offset(0.72, 0.18)),
    _ConstellationLine(Offset(0.72, 0.18), Offset(0.84, 0.12)),
    _ConstellationLine(Offset(0.84, 0.12), Offset(0.92, 0.24)),
    _ConstellationLine(Offset(0.14, 0.7), Offset(0.32, 0.76)),
    _ConstellationLine(Offset(0.68, 0.72), Offset(0.82, 0.84)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final double phase = progress * (2 * math.pi);

    for (int i = 0; i < _lines.length; i++) {
      final _ConstellationLine line = _lines[i];
      final double linePulse =
          0.45 + (0.55 * (0.5 + (0.5 * math.sin(phase + (i * 0.8)))));
      final Paint linePaint = Paint()
        ..color = AppColors.richGold.withValues(
          alpha: 0.12 + (0.12 * linePulse),
        )
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(size.width * line.from.dx, size.height * line.from.dy),
        Offset(size.width * line.to.dx, size.height * line.to.dy),
        linePaint,
      );
    }

    final Paint starPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < _stars.length; i++) {
      final Offset star = _stars[i];
      final bool isAnchor = i % 4 == 0;
      final double twinkle =
          0.4 + (0.6 * (0.5 + (0.5 * math.sin(phase + (i * 0.65)))));
      final double alpha = isAnchor
          ? (0.34 + (0.4 * twinkle)).clamp(0, 1)
          : (0.16 + (0.3 * twinkle)).clamp(0, 1);
      starPaint.color = (isAnchor ? AppColors.richGold : AppColors.white)
          .withValues(alpha: alpha);
      final double radius = isAnchor
          ? 1.6 + (0.5 * twinkle)
          : 1.1 + (0.25 * twinkle);
      canvas.drawCircle(
        Offset(size.width * star.dx, size.height * star.dy),
        radius,
        starPaint,
      );
    }

    final Offset center = Offset(size.width * 0.5, size.height * 0.32);
    final Paint arcPaint = Paint()
      ..color = AppColors.richGold.withValues(
        alpha: (0.16 + (0.1 * (0.5 + (0.5 * math.sin(phase))))).clamp(0, 1),
      )
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final double arcShift = 0.16 * math.sin(phase * 0.75);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width * 0.35),
      3.4 + arcShift,
      2.7,
      false,
      arcPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width * 0.42),
      3.7 - (arcShift * 0.8),
      2.2,
      false,
      arcPaint
        ..color = AppColors.energyViolet.withValues(
          alpha: (0.14 + (0.1 * (0.5 + (0.5 * math.sin(phase + 1.2))))).clamp(
            0,
            1,
          ),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _PersonalHeroConstellationPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _InlineCtaRow extends StatelessWidget {
  const _InlineCtaRow({
    required this.icon,
    required this.iconColor,
    required this.lead,
    required this.action,
    required this.actionColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String lead;
  final String action;
  final Color actionColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(icon, size: 15, color: iconColor),
              ),
              8.width,
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: AppStyles.bodyMedium(
                      color: AppColors.textPrimary.withValues(alpha: 0.75),
                    ),
                    children: <TextSpan>[
                      TextSpan(text: lead),
                      const TextSpan(text: ' '),
                      TextSpan(
                        text: action,
                        style: AppStyles.bodyMedium(
                          color: actionColor,
                          fontWeight: FontWeight.w600,
                        ),
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
}

class _LuckyAngelGrid extends StatelessWidget {
  const _LuckyAngelGrid({
    required this.luckyNumber,
    required this.currentTime,
    required this.onLuckyTap,
    required this.onAngelTap,
  });

  final int luckyNumber;
  final String currentTime;
  final VoidCallback onLuckyTap;
  final VoidCallback onAngelTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _TeaserNumberCard(
            intro: LocaleKey.todayPersonalLuckyIntro.tr,
            value: '$luckyNumber',
            hint: LocaleKey.todayPersonalLuckyHint.tr,
            cta: LocaleKey.todayPersonalLuckyCta.tr,
            onTap: onLuckyTap,
          ),
        ),
        10.width,
        Expanded(
          child: _TeaserNumberCard(
            intro: LocaleKey.todayPersonalAngelIntro.tr,
            value: currentTime,
            hint:
                '${LocaleKey.todayPersonalAngelHintLineOne.tr}\n${LocaleKey.todayPersonalAngelHintLineTwo.tr}',
            cta: LocaleKey.todayPersonalAngelCta.tr,
            onTap: onAngelTap,
          ),
        ),
      ],
    );
  }
}

class _TeaserNumberCard extends StatelessWidget {
  const _TeaserNumberCard({
    required this.intro,
    required this.value,
    required this.hint,
    required this.cta,
    required this.onTap,
  });

  final String intro;
  final String value;
  final String hint;
  final String cta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppMysticalCard(
      onTap: onTap,
      borderColor: AppColors.border.withValues(alpha: 0.78),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            intro,
            textAlign: TextAlign.center,
            style: AppStyles.bodySmall(
              color: AppColors.textPrimary.withValues(alpha: 0.92),
            ),
          ),
          8.height,
          AppGlowText(
            text: value,
            style: AppStyles.numberMedium().copyWith(
              fontSize: 40,
              height: 1.06,
            ),
          ),
          6.height,
          Text(
            hint,
            textAlign: TextAlign.center,
            style: AppStyles.caption(
              color: AppColors.textMuted,
            ).copyWith(fontStyle: FontStyle.italic, height: 1.38),
          ),
          8.height,
          Text(
            cta,
            textAlign: TextAlign.center,
            style: AppStyles.bodySmall(
              color: AppColors.richGold,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextSection extends StatelessWidget {
  const _ContextSection({
    required this.isGuest,
    required this.personalMonthNumber,
    required this.personalYearNumber,
    required this.monthKeyword,
    required this.yearKeyword,
    required this.onMonthTap,
    required this.onYearTap,
  });

  final bool isGuest;
  final int personalMonthNumber;
  final int personalYearNumber;
  final String monthKeyword;
  final String yearKeyword;
  final Future<void> Function() onMonthTap;
  final Future<void> Function() onYearTap;

  @override
  Widget build(BuildContext context) {
    final String monthValue = personalMonthNumber > 0
        ? '$personalMonthNumber'
        : LocaleKey.todayMonthValue.tr;
    final String yearValue = personalYearNumber > 0
        ? '$personalYearNumber'
        : LocaleKey.todayYearValue.tr;

    final String monthTitle = isGuest
        ? LocaleKey.todayUniversalMonthTitle.tr
        : LocaleKey.todayMonthTitle.tr;
    final String yearTitle = isGuest
        ? LocaleKey.todayUniversalYearTitle.tr
        : LocaleKey.todayYearTitle.tr;

    final String monthSummaryPrefix = isGuest
        ? LocaleKey.todayUniversalMonthSummaryPrefix.tr
        : LocaleKey.todayPersonalMonthSummaryPrefix.tr;
    final String yearSummaryPrefix = isGuest
        ? LocaleKey.todayUniversalYearSummaryPrefix.tr
        : LocaleKey.todayPersonalYearSummaryPrefix.tr;

    final String monthSummary = monthKeyword.isNotEmpty
        ? '$monthSummaryPrefix ${monthKeyword.toLowerCase()}'
        : LocaleKey.todayMonthKeyword.tr;
    final String yearSummary = yearKeyword.isNotEmpty
        ? '$yearSummaryPrefix ${yearKeyword.toLowerCase()}'
        : LocaleKey.todayYearKeyword.tr;
    final String ctaLabel = isGuest
        ? LocaleKey.todayPersonalGuestContextCta.tr
        : '${LocaleKey.commonViewDetail.tr} →';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(Icons.trending_up, size: 18, color: AppColors.richGold),
            8.width,
            Expanded(
              child: Text(
                LocaleKey.todayContextTitle.tr,
                style: AppStyles.h5(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        10.height,
        AppMysticalCard(
          padding: EdgeInsets.zero,
          borderColor: AppColors.border.withValues(alpha: 0.78),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _ContextColumn(
                    title: monthTitle,
                    value: monthValue,
                    summary: monthSummary,
                    ctaLabel: ctaLabel,
                    onTap: onMonthTap,
                  ),
                ),
                Container(
                  width: 1,
                  height: 172,
                  color: AppColors.richGold.withValues(alpha: 0.16),
                ),
                Expanded(
                  child: _ContextColumn(
                    title: yearTitle,
                    value: yearValue,
                    summary: yearSummary,
                    ctaLabel: ctaLabel,
                    onTap: onYearTap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ContextColumn extends StatelessWidget {
  const _ContextColumn({
    required this.title,
    required this.value,
    required this.summary,
    required this.ctaLabel,
    required this.onTap,
  });

  final String title;
  final String value;
  final String summary;
  final String ctaLabel;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              style: AppStyles.caption(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ).copyWith(letterSpacing: 0.8),
            ),
            10.height,
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    AppColors.richGold.withValues(alpha: 0.2),
                    AppColors.energyBlue.withValues(alpha: 0.14),
                  ],
                ),
                border: Border.all(
                  color: AppColors.richGold.withValues(alpha: 0.34),
                ),
              ),
              child: Center(
                child: AppGlowText(
                  text: value,
                  style: AppStyles.numberMedium(),
                ),
              ),
            ),
            8.height,
            Text(
              summary,
              textAlign: TextAlign.center,
              style: AppStyles.bodySmall(
                color: AppColors.textPrimary,
              ).copyWith(height: 1.42),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            10.height,
            Text(
              ctaLabel,
              style: AppStyles.bodySmall(
                color: AppColors.richGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryGlowButton extends StatefulWidget {
  const _PrimaryGlowButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  State<_PrimaryGlowButton> createState() => _PrimaryGlowButtonState();
}

class _PrimaryGlowButtonState extends State<_PrimaryGlowButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  double _gradientTravel(double t) {
    if (t < 0.5) {
      return Curves.ease.transform(t * 2);
    }
    return 1 - Curves.ease.transform((t - 0.5) * 2);
  }

  LinearGradient _animatedGradient(double t) {
    final double travel = _gradientTravel(t);
    final double shift = -0.9 + (travel * 1.8);
    return LinearGradient(
      begin: Alignment(-1 + shift, 1),
      end: Alignment(1 + shift, -1),
      colors: const <Color>[
        AppColors.richGold,
        AppColors.goldBright,
        AppColors.goldSoft,
        AppColors.goldBright,
        AppColors.richGold,
      ],
      stops: const <double>[0, 0.25, 0.5, 0.75, 1],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(999),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: _animatedGradient(_controller.value),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.richGold.withValues(alpha: 0.28),
                      blurRadius: 22,
                      spreadRadius: 0,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (widget.icon != null) ...<Widget>[
                Icon(widget.icon, size: 16, color: AppColors.midnight),
                8.width,
              ],
              Text(
                widget.label,
                style: AppStyles.buttonLarge(
                  color: AppColors.midnight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
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

class _PulseOrb extends StatefulWidget {
  const _PulseOrb({required this.size});

  final double size;

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
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double scale = 0.92 + (_controller.value * 0.18);
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.richGold.withValues(alpha: 0.12),
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
