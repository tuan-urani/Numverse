import 'package:flutter/material.dart';
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
import 'package:test/src/utils/app_colors.dart';
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
        final String currentTime = _formatTime(DateTime.now());

        return Column(
          children: <Widget>[
            _DailyCheckInCard(
              soulPoints: state.soulPoints,
              currentStreak: state.currentStreak,
              hasCheckedInToday: state.hasCheckedInToday,
              onCheckIn: () => sessionBloc.checkIn(),
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
              icon: Icons.auto_awesome,
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

  String _formatTime(DateTime now) {
    final String hour = now.hour.toString().padLeft(2, '0');
    final String minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
    required this.hasCheckedInToday,
    required this.onCheckIn,
  });

  final int soulPoints;
  final int currentStreak;
  final bool hasCheckedInToday;
  final Future<void> Function() onCheckIn;

  @override
  State<_DailyCheckInCard> createState() => _DailyCheckInCardState();
}

class _DailyCheckInCardState extends State<_DailyCheckInCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _autoClaimAttempted = false;
  OverlayEntry? _celebrationOverlayEntry;
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);
    _scheduleAutoClaimIfNeeded();
  }

  @override
  void dispose() {
    _celebrationOverlayEntry?.remove();
    _celebrationOverlayEntry = null;
    _ambientController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _DailyCheckInCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool didCheckInTodayTransition =
        !oldWidget.hasCheckedInToday && widget.hasCheckedInToday;
    final bool didStreakAdvance =
        widget.currentStreak > oldWidget.currentStreak;
    final bool didSoulPointsIncrease = widget.soulPoints > oldWidget.soulPoints;
    if (didCheckInTodayTransition ||
        didStreakAdvance ||
        didSoulPointsIncrease) {
      _triggerCelebration(oldWidget);
    }
    if (oldWidget.hasCheckedInToday && !widget.hasCheckedInToday) {
      _autoClaimAttempted = false;
      _scheduleAutoClaimIfNeeded();
      return;
    }
    _scheduleAutoClaimIfNeeded();
  }

  void _scheduleAutoClaimIfNeeded() {
    if (widget.hasCheckedInToday || _autoClaimAttempted) {
      return;
    }
    _autoClaimAttempted = true;
    Future<void>.delayed(const Duration(milliseconds: 800), () async {
      if (!mounted || widget.hasCheckedInToday) {
        return;
      }
      await widget.onCheckIn();
    });
  }

  void _triggerCelebration(_DailyCheckInCard oldWidget) {
    int reward = widget.soulPoints - oldWidget.soulPoints;
    if (reward <= 0 && widget.currentStreak > oldWidget.currentStreak) {
      reward = _rewardByStreak(oldWidget.currentStreak);
    }
    reward = reward.clamp(0, 9999);
    if (reward <= 0) {
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _celebrationOverlayEntry?.remove();

      final OverlayState overlayState = Overlay.of(context, rootOverlay: true);

      final OverlayEntry entry = OverlayEntry(
        builder: (BuildContext context) {
          final String title = milestone != null
              ? '${LocaleKey.todayCheckInMilestoneCelebration.tr} ${milestone.labelKey.tr}!'
              : LocaleKey.todayCheckInCelebrationSuccess.tr;
          return Positioned.fill(
            child: IgnorePointer(
              child: Material(
                color: AppColors.midnight.withValues(alpha: 0.74),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 230),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    decoration: BoxDecoration(
                      color: AppColors.midnightSoft.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.richGold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.emoji_events_rounded,
                          size: 36,
                          color: AppColors.richGold,
                        ),
                        8.height,
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: AppStyles.h5(
                            color: AppColors.richGold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        8.height,
                        Text(
                          '+$reward ${LocaleKey.todayRewardPointsSuffix.tr}',
                          style: AppStyles.h3(
                            color: AppColors.richGold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${LocaleKey.todayDailyStreak.tr}: $streak ${LocaleKey.todayCheckInDays.tr}',
                          style: AppStyles.caption(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );

      overlayState.insert(entry);
      _celebrationOverlayEntry = entry;

      Future<void>.delayed(const Duration(milliseconds: 2800), () {
        if (_celebrationOverlayEntry == entry) {
          entry.remove();
          _celebrationOverlayEntry = null;
        }
      });
    });
  }

  int _rewardByStreak(int streak) {
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
        final double orbScale = 0.92 + (0.16 * pulse);
        final double orbAlpha = 0.14 + (0.1 * pulse);
        final double glowFactor = 0.82 + (0.38 * pulse);
        final double shimmerDx = (_ambientController.value * 2) - 1;

        return Stack(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.richGold.withValues(alpha: 0.3),
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
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.richGold.withValues(
                      alpha: (0.1 + (0.08 * pulse)).clamp(0, 1),
                    ),
                    blurRadius: 18 + (4 * pulse),
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: AppColors.deepViolet.withValues(alpha: 0.5),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      top: -26,
                      right: -18,
                      child: Transform.scale(
                        scale: orbScale,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.richGold.withValues(
                              alpha: orbAlpha,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -22,
                      left: -16,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.richGold.withValues(
                            alpha: (0.08 + (0.04 * pulse)).clamp(0, 1),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: 0.15,
                          child: FractionalTranslation(
                            translation: Offset(shimmerDx, 0),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: FractionallySizedBox(
                                widthFactor: 0.45,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: <Color>[
                                        AppColors.transparent,
                                        AppColors.white.withValues(alpha: 0.08),
                                        AppColors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                          child: Column(
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Row(
                                      children: <Widget>[
                                        _HeaderOrb(
                                          size: 48,
                                          glowColor: AppColors.richGold,
                                          icon: Icons.bolt_rounded,
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
                                                    fontWeight: FontWeight.w700,
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
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: <Widget>[
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: <Widget>[
                                            Text(
                                              LocaleKey.todayDailyStreak.tr,
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
                                                          ? AppColors.richGold
                                                          : AppColors.textMuted,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ).copyWith(
                                                      height: 1,
                                                      shadows:
                                                          widget.currentStreak >
                                                              0
                                                          ? <Shadow>[
                                                              Shadow(
                                                                color: AppColors
                                                                    .richGold
                                                                    .withValues(
                                                                      alpha:
                                                                          (0.3 +
                                                                                  (0.2 * pulse))
                                                                              .clamp(0, 1),
                                                                    ),
                                                                blurRadius: 12,
                                                              ),
                                                            ]
                                                          : null,
                                                    ),
                                                children: <TextSpan>[
                                                  TextSpan(
                                                    text:
                                                        '${widget.currentStreak}',
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        ' ${LocaleKey.todayCheckInDays.tr}',
                                                    style: AppStyles.bodySmall(
                                                      color:
                                                          AppColors.textMuted,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        10.width,
                                        _HeaderOrb(
                                          size: 48,
                                          glowColor: AppColors.energyOrange,
                                          icon: Icons.local_fire_department,
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
                            child: Column(
                              children: <Widget>[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    10,
                                    12,
                                    10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.richGold.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.richGold.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
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
                                    ],
                                  ),
                                ),
                                10.height,
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    LocaleKey.todayCheckInMilestoneGridTitle.tr,
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
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _checkInMilestones.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 4,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                        childAspectRatio: 0.95,
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
                                10.height,
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(
                                    10,
                                    10,
                                    10,
                                    10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.deepViolet.withValues(
                                      alpha: 0.45,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    children: <Widget>[
                                      _TipRow(
                                        text: LocaleKey
                                            .todayCheckInTipKeepStreak
                                            .tr,
                                      ),
                                      6.height,
                                      _TipRow(
                                        text: LocaleKey.todayCheckInTipReset.tr,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
    required this.icon,
    required this.iconColor,
    this.active = true,
    this.glowFactor = 1,
  });

  final double size;
  final Color glowColor;
  final IconData icon;
  final Color iconColor;
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
          child: Icon(icon, size: 24, color: iconColor),
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
    final Color borderColor = isCompleted
        ? AppColors.richGold.withValues(alpha: 0.4)
        : isCurrent
        ? AppColors.richGold.withValues(alpha: 0.35)
        : AppColors.border.withValues(alpha: 0.35);
    final Color bgColor = isCompleted
        ? AppColors.richGold.withValues(alpha: 0.1)
        : isCurrent
        ? AppColors.richGold.withValues(alpha: 0.05)
        : AppColors.deepViolet.withValues(alpha: 0.26);

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: isCurrent ? 1.6 : 1),
      ),
      child: Stack(
        children: <Widget>[
          if (milestone.special)
            const Positioned(
              top: -2,
              right: -2,
              child: Icon(
                Icons.auto_awesome,
                size: 11,
                color: AppColors.richGold,
              ),
            ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                milestone.labelKey.tr,
                textAlign: TextAlign.center,
                style: AppStyles.caption(
                  color: isCompleted ? AppColors.richGold : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              4.height,
              Text(
                '+${milestone.reward}',
                style: AppStyles.bodySmall(
                  color: isCompleted || isCurrent
                      ? AppColors.richGold
                      : AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isCompleted)
                const Icon(Icons.check, size: 12, color: AppColors.richGold),
            ],
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.richGold,
              shape: BoxShape.circle,
            ),
          ),
        ),
        8.width,
        Expanded(
          child: Text(
            text,
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
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -56,
            right: -36,
            child: _FloatingOrb(
              size: 160,
              alpha: 0.2,
              durationMs: 4200,
              startValue: 0,
              color: AppColors.richGold,
            ),
          ),
          Positioned(
            bottom: -58,
            left: -24,
            child: _FloatingOrb(
              size: 128,
              alpha: 0.16,
              durationMs: 4700,
              startValue: 0.55,
              color: AppColors.energyViolet,
            ),
          ),
          Column(
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
                    style: AppStyles.h3(
                      fontWeight: FontWeight.w600,
                    ).copyWith(fontSize: 18, height: 1.3),
                  ),
                ],
              ),
              12.height,
              Center(
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      width: 118,
                      height: 118,
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          const _HeroPulseAura(),
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: <Color>[
                                  AppColors.richGold.withValues(alpha: 0.3),
                                  AppColors.energyViolet.withValues(alpha: 0.2),
                                ],
                              ),
                              border: Border.all(
                                color: AppColors.richGold.withValues(
                                  alpha: 0.5,
                                ),
                                width: 2,
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: AppColors.richGold.withValues(
                                    alpha: 0.28,
                                  ),
                                  blurRadius: 22,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: AppGlowText(
                                text: displayNumber,
                                style: AppStyles.numberLarge().copyWith(
                                  fontSize: 60,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    8.height,
                    Text(
                      rhythmText,
                      textAlign: TextAlign.center,
                      style: AppStyles.bodyMedium(
                        color: AppColors.richGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              12.height,
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
                    padding: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
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
                icon: isGuest ? Icons.lock_rounded : Icons.auto_awesome,
                onTap: onTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPulseAura extends StatefulWidget {
  const _HeroPulseAura();

  @override
  State<_HeroPulseAura> createState() => _HeroPulseAuraState();
}

class _HeroPulseAuraState extends State<_HeroPulseAura>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double pulse = Curves.easeInOut.transform(_controller.value);
        final double scale = 0.9 + (0.24 * pulse);
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: 0.25 + (0.2 * (1 - pulse)),
            child: Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.richGold.withValues(alpha: 0.32),
              ),
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
                child: Icon(icon, size: 14, color: iconColor),
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
  final IconData icon;
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
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: _animatedGradient(_controller.value),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.richGold.withValues(alpha: 0.2),
                      blurRadius: 18,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          );
        },
        child: Padding(
          padding: 14.paddingAll,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(widget.icon, size: 16, color: AppColors.midnight),
              8.width,
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

class _FloatingOrb extends StatefulWidget {
  const _FloatingOrb({
    required this.size,
    required this.alpha,
    this.durationMs = 4200,
    this.startValue = 0,
    this.color = AppColors.richGold,
  });

  final double size;
  final double alpha;
  final int durationMs;
  final double startValue;
  final Color color;

  @override
  State<_FloatingOrb> createState() => _FloatingOrbState();
}

class _FloatingOrbState extends State<_FloatingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
      value: widget.startValue.clamp(0.0, 1.0),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double dy = -9 + (_controller.value * 18);
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: widget.alpha),
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
