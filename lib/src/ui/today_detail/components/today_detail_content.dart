import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/core/model/numerology_content_models.dart';
import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class TodayDetailContent extends StatefulWidget {
  const TodayDetailContent({
    required this.personalDayNumber,
    required this.personalContent,
    super.key,
  });

  static const bool _showSuggestionSection = false;

  final int personalDayNumber;
  final NumerologyTodayPersonalNumberContent personalContent;

  @override
  State<TodayDetailContent> createState() => _TodayDetailContentState();
}

class _TodayDetailContentState extends State<TodayDetailContent> {
  int? _expandedSectionIndex = 0;

  void _toggleSection(int index) {
    setState(() {
      _expandedSectionIndex = _expandedSectionIndex == index ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const int interpretationIndex = 0;
    final int shouldDoIndex = TodayDetailContent._showSuggestionSection ? 2 : 1;
    final int shouldAvoidIndex = shouldDoIndex + 1;
    final int? suggestionIndex = TodayDetailContent._showSuggestionSection
        ? 1
        : null;
    final List<String> shouldDo = _resolveShouldDo();
    final List<String> shouldAvoid = _resolveShouldAvoid();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _AnimatedReveal(
          delay: 0,
          child: _PersonalDayCard(
            personalDayNumber: widget.personalDayNumber,
            content: widget.personalContent,
          ),
        ),
        const SizedBox(height: 24),
        _AnimatedReveal(
          delay: 80,
          child: _InterpretationCard(
            content: widget.personalContent,
            isExpanded: _expandedSectionIndex == interpretationIndex,
            onToggle: () => _toggleSection(interpretationIndex),
          ),
        ),
        if (TodayDetailContent._showSuggestionSection) ...<Widget>[
          const SizedBox(height: 24),
          _AnimatedReveal(
            delay: 160,
            child: _SuggestionCard(
              content: widget.personalContent,
              isExpanded: _expandedSectionIndex == suggestionIndex,
              onToggle: () => _toggleSection(suggestionIndex!),
            ),
          ),
        ],
        const SizedBox(height: 24),
        _AnimatedReveal(
          delay: TodayDetailContent._showSuggestionSection ? 220 : 160,
          child: _ActionSectionCard(
            title: LocaleKey.todayActionDo.tr,
            items: shouldDo,
            accentColor: AppColors.richGold,
            icon: Icons.check_circle_rounded,
            isExpanded: _expandedSectionIndex == shouldDoIndex,
            onToggle: () => _toggleSection(shouldDoIndex),
          ),
        ),
        const SizedBox(height: 24),
        _AnimatedReveal(
          delay: TodayDetailContent._showSuggestionSection ? 280 : 220,
          child: _ActionSectionCard(
            title: LocaleKey.todayActionAvoid.tr,
            items: shouldAvoid,
            accentColor: AppColors.energyPink,
            icon: Icons.block_rounded,
            isExpanded: _expandedSectionIndex == shouldAvoidIndex,
            onToggle: () => _toggleSection(shouldAvoidIndex),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  List<String> _resolveShouldDo() {
    if (widget.personalContent.shouldDoActions.isNotEmpty) {
      return widget.personalContent.shouldDoActions;
    }
    if (widget.personalContent.hintActions.length >= 2) {
      return widget.personalContent.hintActions.take(2).toList(growable: false);
    }
    return <String>[
      LocaleKey.todayActionDoOne.tr,
      LocaleKey.todayActionDoTwo.tr,
    ];
  }

  List<String> _resolveShouldAvoid() {
    if (widget.personalContent.shouldAvoidActions.isNotEmpty) {
      return widget.personalContent.shouldAvoidActions;
    }
    return <String>[
      LocaleKey.todayActionAvoidOne.tr,
      LocaleKey.todayActionAvoidTwo.tr,
    ];
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

class _PersonalDayCard extends StatelessWidget {
  const _PersonalDayCard({
    required this.personalDayNumber,
    required this.content,
  });

  final int personalDayNumber;
  final NumerologyTodayPersonalNumberContent content;

  @override
  Widget build(BuildContext context) {
    final String title = _resolveTitle();
    final String subtitle = _resolveSubtitle();
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
      child: Column(
        children: <Widget>[
          _PulsingDayNumber(personalDayNumber: personalDayNumber),
          16.height,
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppStyles.h4(fontWeight: FontWeight.w600),
          ),
          4.height,
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppStyles.bodySmall(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  String _resolveTitle() {
    String normalized(String source) {
      return source
          .replaceAll('{number}', '')
          .replaceAll(RegExp(r'\d+'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    if (content.dayCardTitle.isNotEmpty) {
      final String title = normalized(content.dayCardTitle);
      if (title.isNotEmpty) {
        return title;
      }
    }
    final String fallback = normalized(LocaleKey.todayDetailDayCardTitle.tr);
    if (fallback.isNotEmpty) {
      return fallback;
    }
    return LocaleKey.todayDetailDayCardTitle.tr;
  }

  String _resolveSubtitle() {
    if (content.dayCardSubtitle.isNotEmpty) {
      return content.dayCardSubtitle;
    }
    if (content.dailyRhythm.isNotEmpty) {
      return content.dailyRhythm;
    }
    return LocaleKey.todayDetailDayCardSubtitle.tr;
  }
}

class _PulsingDayNumber extends StatefulWidget {
  const _PulsingDayNumber({required this.personalDayNumber});

  final int personalDayNumber;

  @override
  State<_PulsingDayNumber> createState() => _PulsingDayNumberState();
}

class _PulsingDayNumberState extends State<_PulsingDayNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double pulse = _controller.value;
        final double ringScale = 1 + (0.25 * pulse);
        final double ringOpacity = 0.28 * (1 - pulse);
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Transform.scale(
              scale: ringScale,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.richGold.withValues(alpha: ringOpacity),
                ),
              ),
            ),
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
                    AppColors.violetAccent.withValues(alpha: 0.28),
                    AppColors.richGold.withValues(alpha: 0.2),
                  ],
                ),
                border: Border.all(
                  color: AppColors.richGold.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.richGold.withValues(alpha: 0.28),
                    blurRadius: 20,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '${widget.personalDayNumber}',
                style: AppStyles.numberLarge(
                  color: AppColors.richGold,
                  fontWeight: FontWeight.w700,
                ).copyWith(fontSize: 48, height: 1.08),
              ),
            ),
          ],
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

class _InterpretationCard extends StatelessWidget {
  const _InterpretationCard({
    required this.content,
    required this.isExpanded,
    required this.onToggle,
  });

  final NumerologyTodayPersonalNumberContent content;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final TextStyle baseStyle = AppStyles.bodyMedium(
      color: AppColors.textPrimary.withValues(alpha: 0.92),
    );
    final List<String> details = _resolveDetails();

    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.richGold,
                  size: 20,
                ),
                8.width,
                Expanded(
                  child: Text(
                    LocaleKey.todayDetailInterpretationTitle.tr,
                    style: AppStyles.h5(fontWeight: FontWeight.w600),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.richGold,
                    size: 20,
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
                    index < details.length;
                    index++
                  ) ...<Widget>[
                    if (index > 0) 12.height,
                    Text(details[index], style: baseStyle),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _resolveDetails() {
    if (content.detail.isNotEmpty) {
      return content.detail;
    }
    return <String>[
      '${LocaleKey.todayDetailInterpretationP1Prefix.tr}'
          '${LocaleKey.todayDetailInterpretationP1Highlight.tr}'
          '${LocaleKey.todayDetailInterpretationP1Suffix.tr}',
      LocaleKey.todayDetailInterpretationP2.tr,
      LocaleKey.todayDetailInterpretationP3.tr,
    ];
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.content,
    required this.isExpanded,
    required this.onToggle,
  });

  final NumerologyTodayPersonalNumberContent content;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final List<String> suggestions = _resolveSuggestions();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.richGold.withValues(alpha: 0.12),
            AppColors.violetAccent.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    LocaleKey.todayDetailSuggestionTitle.tr,
                    style: AppStyles.h5(fontWeight: FontWeight.w600),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.richGold,
                    size: 20,
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
                    index < suggestions.length;
                    index++
                  ) ...<Widget>[
                    if (index > 0) 12.height,
                    _BulletRow(text: suggestions[index]),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _resolveSuggestions() {
    if (content.hintActions.isNotEmpty) {
      return content.hintActions;
    }
    return <String>[
      LocaleKey.todayDetailSuggestionOne.tr,
      LocaleKey.todayDetailSuggestionTwo.tr,
      LocaleKey.todayDetailSuggestionThree.tr,
      LocaleKey.todayDetailSuggestionFour.tr,
    ];
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.34)),
      ),
      child: child,
    );
  }
}

class _ActionSectionCard extends StatelessWidget {
  const _ActionSectionCard({
    required this.title,
    required this.items,
    required this.accentColor,
    required this.icon,
    required this.isExpanded,
    required this.onToggle,
  });

  final String title;
  final List<String> items;
  final Color accentColor;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Row(
              children: <Widget>[
                Icon(icon, color: accentColor, size: 18),
                8.width,
                Expanded(
                  child: Text(
                    title,
                    style: AppStyles.h5(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: accentColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          _AccordionBody(
            isExpanded: isExpanded,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (
                    int index = 0;
                    index < items.length;
                    index++
                  ) ...<Widget>[
                    if (index > 0) 10.height,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          margin: const EdgeInsets.only(top: 7),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accentColor.withValues(alpha: 0.95),
                          ),
                        ),
                        10.width,
                        Expanded(
                          child: Text(
                            items[index],
                            style: AppStyles.bodyMedium(
                              color: AppColors.textPrimary.withValues(
                                alpha: 0.92,
                              ),
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

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text});

  final String text;

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
            color: AppColors.richGold.withValues(alpha: 0.2),
          ),
          alignment: Alignment.center,
          child: Text(
            '✦',
            style: AppStyles.bodySmall(
              color: AppColors.richGold,
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
