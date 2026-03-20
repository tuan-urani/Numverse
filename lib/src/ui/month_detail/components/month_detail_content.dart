import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/core/model/numerology_content_models.dart';
import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class MonthDetailContent extends StatefulWidget {
  const MonthDetailContent({
    required this.personalMonthNumber,
    required this.periodLabel,
    required this.content,
    super.key,
  });

  final int personalMonthNumber;
  final String periodLabel;
  final NumerologyPersonalMonthContent content;

  @override
  State<MonthDetailContent> createState() => _MonthDetailContentState();
}

class _MonthDetailContentState extends State<MonthDetailContent> {
  int? _expandedSectionIndex = 0;

  void _toggleSection(int index) {
    setState(() {
      _expandedSectionIndex = _expandedSectionIndex == index ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _AnimatedReveal(
          delay: 0,
          child: _MonthHeroCard(
            personalMonthNumber: widget.personalMonthNumber,
            keyword: widget.content.keyword,
          ),
        ),
        const SizedBox(height: 24),
        _AnimatedReveal(
          delay: 80,
          child: _MonthFocusCard(
            focus: widget.content.focus,
            steps: widget.content.steps,
            showFocusSteps: false,
            isExpanded: _expandedSectionIndex == 0,
            onToggle: () => _toggleSection(0),
          ),
        ),
        const SizedBox(height: 24),
        _AnimatedReveal(
          delay: 160,
          child: _MonthPriorityCard(
            widget.content.priorities,
            isExpanded: _expandedSectionIndex == 1,
            onToggle: () => _toggleSection(1),
          ),
        ),
        const SizedBox(height: 24),
        _AnimatedReveal(
          delay: 240,
          child: _MonthCautionCard(
            widget.content.cautions,
            isExpanded: _expandedSectionIndex == 2,
            onToggle: () => _toggleSection(2),
          ),
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

class _MonthHeroCard extends StatelessWidget {
  const _MonthHeroCard({
    required this.personalMonthNumber,
    required this.keyword,
  });

  final int personalMonthNumber;
  final String keyword;

  @override
  Widget build(BuildContext context) {
    final String resolvedHeroTitle = LocaleKey.todayMonthValueLabel.tr;
    final String resolvedKeyword = keyword.isEmpty
        ? LocaleKey.todayMonthKeyword.tr
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
          _NumberBadge(number: '$personalMonthNumber'),
        ],
      ),
    );
  }
}

class _MonthFocusCard extends StatelessWidget {
  const _MonthFocusCard({
    required this.focus,
    required this.steps,
    required this.isExpanded,
    required this.onToggle,
    this.showFocusSteps = false,
  });

  final List<String> focus;
  final List<NumerologyPersonalMonthStep> steps;
  final bool isExpanded;
  final VoidCallback onToggle;
  final bool showFocusSteps;

  @override
  Widget build(BuildContext context) {
    final List<String> focusValues = focus.isNotEmpty
        ? focus
        : <String>[
            LocaleKey.monthDetailFocusP1.tr,
            LocaleKey.monthDetailFocusP2.tr,
          ];
    final List<NumerologyPersonalMonthStep> stepValues = steps.isNotEmpty
        ? steps
        : <NumerologyPersonalMonthStep>[
            NumerologyPersonalMonthStep(
              title: LocaleKey.monthDetailStepOneTitle.tr,
              body: LocaleKey.monthDetailStepOneBody.tr,
            ),
            NumerologyPersonalMonthStep(
              title: LocaleKey.monthDetailStepTwoTitle.tr,
              body: LocaleKey.monthDetailStepTwoBody.tr,
            ),
            NumerologyPersonalMonthStep(
              title: LocaleKey.monthDetailStepThreeTitle.tr,
              body: LocaleKey.monthDetailStepThreeBody.tr,
            ),
          ];

    return _BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.richGold,
                  size: 20,
                ),
                8.width,
                Expanded(
                  child: Text(
                    LocaleKey.monthDetailFocusTitle.tr,
                    style: AppStyles.h5(fontWeight: FontWeight.w600),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppColors.richGold,
                  ),
                ),
              ],
            ),
          ),
          _AccordionBody(
            isExpanded: isExpanded,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (
                    int index = 0;
                    index < focusValues.length;
                    index++
                  ) ...<Widget>[
                    if (index > 0) 12.height,
                    Text(
                      focusValues[index],
                      style: AppStyles.bodyMedium(
                        color: AppColors.textPrimary.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                  if (showFocusSteps) ...<Widget>[
                    14.height,
                    for (
                      int index = 0;
                      index < stepValues.length;
                      index++
                    ) ...<Widget>[
                      if (index > 0) 10.height,
                      _StepTile(
                        index: index + 1,
                        title: stepValues[index].title,
                        body: stepValues[index].body,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthPriorityCard extends StatelessWidget {
  const _MonthPriorityCard(
    this.priorities, {
    required this.isExpanded,
    required this.onToggle,
  });

  final List<String> priorities;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final List<String> priorityValues = priorities.isNotEmpty
        ? priorities
        : <String>[
            LocaleKey.monthDetailPriorityOne.tr,
            LocaleKey.monthDetailPriorityTwo.tr,
            LocaleKey.monthDetailPriorityThree.tr,
            LocaleKey.monthDetailPriorityFour.tr,
          ];

    return _BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.richGold,
                  size: 20,
                ),
                8.width,
                Expanded(
                  child: Text(
                    LocaleKey.monthDetailPriorityTitle.tr,
                    style: AppStyles.h5(fontWeight: FontWeight.w600),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppColors.richGold,
                  ),
                ),
              ],
            ),
          ),
          _AccordionBody(
            isExpanded: isExpanded,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (
                    int index = 0;
                    index < priorityValues.length;
                    index++
                  ) ...<Widget>[
                    if (index > 0) 12.height,
                    _BulletRow(text: priorityValues[index]),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthCautionCard extends StatelessWidget {
  const _MonthCautionCard(
    this.cautions, {
    required this.isExpanded,
    required this.onToggle,
  });

  final List<String> cautions;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final List<String> cautionValues = cautions.isNotEmpty
        ? cautions
        : <String>[
            LocaleKey.monthDetailCautionOne.tr,
            LocaleKey.monthDetailCautionTwo.tr,
            LocaleKey.monthDetailCautionThree.tr,
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.error.withValues(alpha: 0.14),
            AppColors.error.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
                8.width,
                Expanded(
                  child: Text(
                    LocaleKey.monthDetailCautionTitle.tr,
                    style: AppStyles.h5(fontWeight: FontWeight.w600),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          _AccordionBody(
            isExpanded: isExpanded,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (
                    int index = 0;
                    index < cautionValues.length;
                    index++
                  ) ...<Widget>[
                    if (index > 0) 12.height,
                    _BulletRow(
                      text: cautionValues[index],
                      marker: '!',
                      markerColor: AppColors.error,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccordionBody extends StatelessWidget {
  const _AccordionBody({required this.isExpanded, required this.child});

  final bool isExpanded;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: isExpanded ? 1 : 0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      child: child,
      builder: (BuildContext context, double animationValue, Widget? child) {
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: animationValue,
            child: Opacity(opacity: animationValue, child: child),
          ),
        );
      },
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
        color: AppColors.card.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.richGold.withValues(alpha: 0.34),
          width: 1.1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.richGold.withValues(alpha: 0.12),
            blurRadius: 16,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.deepViolet.withValues(alpha: 0.18),
            blurRadius: 18,
            spreadRadius: 0,
          ),
        ],
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

class _StepTile extends StatelessWidget {
  const _StepTile({
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.richGold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.richGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: AppStyles.bodyMedium(
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
                Text(
                  title,
                  style: AppStyles.bodyMedium(fontWeight: FontWeight.w600),
                ),
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

class _BulletRow extends StatelessWidget {
  const _BulletRow({
    required this.text,
    this.marker = '✦',
    this.markerColor = AppColors.richGold,
  });

  final String text;
  final String marker;
  final Color markerColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: markerColor.withValues(alpha: 0.2),
          ),
          alignment: Alignment.center,
          child: Text(
            marker,
            style: AppStyles.bodySmall(
              color: markerColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        10.width,
        Expanded(
          child: Text(
            text,
            style: AppStyles.bodyMedium(
              color: AppColors.textPrimary.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }
}
