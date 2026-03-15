import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/core/model/numerology_content_models.dart';
import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class YearDetailContent extends StatelessWidget {
  const YearDetailContent({
    required this.personalYearNumber,
    required this.periodLabel,
    required this.content,
    super.key,
  });

  final int personalYearNumber;
  final String periodLabel;
  final NumerologyPersonalYearContent content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _AnimatedReveal(
          delay: 0,
          child: _YearHeroCard(
            periodLabel: periodLabel,
            personalYearNumber: personalYearNumber,
            keyword: content.keyword,
            heroTitle: content.heroTitle,
          ),
        ),
        const SizedBox(height: 24),
        _AnimatedReveal(delay: 80, child: _YearThemeCard(theme: content.theme)),
        const SizedBox(height: 24),
        _AnimatedReveal(
          delay: 160,
          child: _YearPriorityCard(lessons: content.lessons),
        ),
        const SizedBox(height: 24),
        _AnimatedReveal(
          delay: 240,
          child: _YearFocusAreasCard(focusAreas: content.focusAreas),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _AnimatedReveal extends StatelessWidget {
  const _AnimatedReveal({required this.child, required this.delay});

  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 460 + delay),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 14),
            child: child,
          ),
        );
      },
    );
  }
}

class _YearHeroCard extends StatelessWidget {
  const _YearHeroCard({
    required this.periodLabel,
    required this.personalYearNumber,
    required this.keyword,
    required this.heroTitle,
  });

  final String periodLabel;
  final int personalYearNumber;
  final String keyword;
  final String heroTitle;

  @override
  Widget build(BuildContext context) {
    final String resolvedHeroTitle = heroTitle.isEmpty
        ? '${LocaleKey.todayYearValueLabel.tr} $personalYearNumber'
        : heroTitle;
    final String resolvedKeyword = keyword.isEmpty
        ? LocaleKey.todayYearKeyword.tr
        : keyword;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.mysticalCardGradient(),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.3)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.richGold.withValues(alpha: 0.18),
            blurRadius: 24,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: AppColors.deepViolet.withValues(alpha: 0.45),
            blurRadius: 26,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  periodLabel,
                  style: AppStyles.caption(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ).copyWith(letterSpacing: 1.1),
                ),
                8.height,
                Text(
                  resolvedHeroTitle,
                  style: AppStyles.h2(fontWeight: FontWeight.w700),
                ),
                4.height,
                Text(
                  resolvedKeyword,
                  style: AppStyles.bodyMedium(
                    color: AppColors.richGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          12.width,
          _NumberBadge(number: '$personalYearNumber'),
        ],
      ),
    );
  }
}

class _YearThemeCard extends StatelessWidget {
  const _YearThemeCard({required this.theme});

  final List<String> theme;

  @override
  Widget build(BuildContext context) {
    final TextStyle baseStyle = AppStyles.bodyMedium(
      color: AppColors.textPrimary.withValues(alpha: 0.92),
    );
    final List<String> themeValues = theme.isNotEmpty
        ? theme
        : <String>[
            '${LocaleKey.yearDetailThemeP1Prefix.tr}'
                '${LocaleKey.yearDetailThemeP1Highlight.tr}'
                '${LocaleKey.yearDetailThemeP1Suffix.tr}',
            LocaleKey.yearDetailThemeP2.tr,
            '${LocaleKey.yearDetailThemeP3Prefix.tr}'
                '${LocaleKey.yearDetailThemeP3Highlight.tr}'
                '${LocaleKey.yearDetailThemeP3Suffix.tr}',
          ];

    return _BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.star_rounded,
                color: AppColors.richGold,
                size: 20,
              ),
              8.width,
              Text(
                LocaleKey.yearDetailThemeTitle.tr,
                style: AppStyles.h5(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          for (int index = 0; index < themeValues.length; index++) ...<Widget>[
            if (index == 0) 14.height else 12.height,
            Text(themeValues[index], style: baseStyle),
          ],
        ],
      ),
    );
  }
}

class _YearPriorityCard extends StatelessWidget {
  const _YearPriorityCard({required this.lessons});

  final List<NumerologyPersonalMonthStep> lessons;

  @override
  Widget build(BuildContext context) {
    final List<NumerologyPersonalMonthStep> lessonValues = lessons.isNotEmpty
        ? lessons
        : <NumerologyPersonalMonthStep>[
            NumerologyPersonalMonthStep(
              title: LocaleKey.yearDetailLessonOneTitle.tr,
              body: LocaleKey.yearDetailLessonOneBody.tr,
            ),
            NumerologyPersonalMonthStep(
              title: LocaleKey.yearDetailLessonTwoTitle.tr,
              body: LocaleKey.yearDetailLessonTwoBody.tr,
            ),
            NumerologyPersonalMonthStep(
              title: LocaleKey.yearDetailLessonThreeTitle.tr,
              body: LocaleKey.yearDetailLessonThreeBody.tr,
            ),
          ];

    return _BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.track_changes_rounded,
                color: AppColors.richGold,
                size: 20,
              ),
              8.width,
              Text(
                LocaleKey.yearDetailPriorityTitle.tr,
                style: AppStyles.h5(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          for (int index = 0; index < lessonValues.length; index++) ...<Widget>[
            if (index == 0) 14.height else 10.height,
            _LessonTile(
              index: index + 1,
              title: lessonValues[index].title,
              body: lessonValues[index].body,
            ),
          ],
        ],
      ),
    );
  }
}

class _YearFocusAreasCard extends StatelessWidget {
  const _YearFocusAreasCard({required this.focusAreas});

  final List<NumerologyPersonalMonthStep> focusAreas;

  @override
  Widget build(BuildContext context) {
    final List<NumerologyPersonalMonthStep> focusAreaValues =
        focusAreas.isNotEmpty
        ? focusAreas
        : <NumerologyPersonalMonthStep>[
            NumerologyPersonalMonthStep(
              title: LocaleKey.yearDetailFocusCareerTitle.tr,
              body: LocaleKey.yearDetailFocusCareerBody.tr,
            ),
            NumerologyPersonalMonthStep(
              title: LocaleKey.yearDetailFocusFinanceTitle.tr,
              body: LocaleKey.yearDetailFocusFinanceBody.tr,
            ),
            NumerologyPersonalMonthStep(
              title: LocaleKey.yearDetailFocusGoalTitle.tr,
              body: LocaleKey.yearDetailFocusGoalBody.tr,
            ),
            NumerologyPersonalMonthStep(
              title: LocaleKey.yearDetailFocusBalanceTitle.tr,
              body: LocaleKey.yearDetailFocusBalanceBody.tr,
            ),
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.violetAccent.withValues(alpha: 0.24),
            AppColors.deepViolet.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.violetAccent.withValues(alpha: 0.34),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.menu_book_rounded,
                color: AppColors.richGold,
                size: 20,
              ),
              8.width,
              Text(
                LocaleKey.yearDetailFocusAreaTitle.tr,
                style: AppStyles.h5(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          for (
            int index = 0;
            index < focusAreaValues.length;
            index++
          ) ...<Widget>[
            if (index == 0) 14.height else 10.height,
            _FocusAreaTile(
              title: focusAreaValues[index].title,
              body: focusAreaValues[index].body,
            ),
          ],
        ],
      ),
    );
  }
}

class _BaseCard extends StatelessWidget {
  const _BaseCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number});

  final String number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.richGold.withValues(alpha: 0.3),
            AppColors.violetAccent.withValues(alpha: 0.3),
            AppColors.richGold.withValues(alpha: 0.2),
          ],
        ),
        border: Border.all(
          color: AppColors.richGold.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.richGold.withValues(alpha: 0.2),
            blurRadius: 18,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        number,
        style: AppStyles.numberMedium(
          color: AppColors.richGold,
          fontWeight: FontWeight.w700,
        ).copyWith(fontSize: 40, height: 1.05),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.index,
    required this.title,
    required this.body,
  });

  final int index;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.richGold.withValues(alpha: 0.1),
            AppColors.richGold.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.richGold.withValues(alpha: 0.3),
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: AppStyles.h4(
                color: AppColors.richGold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          10.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AppStyles.h5(fontWeight: FontWeight.w600)),
                2.height,
                Text(
                  body,
                  style: AppStyles.bodySmall(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusAreaTile extends StatelessWidget {
  const _FocusAreaTile({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: AppStyles.bodyMedium(fontWeight: FontWeight.w600)),
          2.height,
          Text(body, style: AppStyles.bodySmall(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
