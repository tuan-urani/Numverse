import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/comparison_result/interactor/comparison_result_state.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class ComparisonResultContent extends StatelessWidget {
  const ComparisonResultContent({required this.state, super.key});

  final ComparisonResultState state;

  @override
  Widget build(BuildContext context) {
    final List<_AspectData> aspects = <_AspectData>[
      _AspectData(
        title: LocaleKey.comparisonAspectCoreTitle.tr,
        score: state.coreScore,
        icon: Icons.auto_awesome_rounded,
        description: LocaleKey.comparisonAspectCoreDescription.trParams(
          <String, String>{
            'a': '${state.selfLifePath}',
            'b': '${state.targetLifePath}',
          },
        ),
      ),
      _AspectData(
        title: LocaleKey.comparisonAspectCommunicationTitle.tr,
        score: state.communicationScore,
        icon: Icons.trending_up_rounded,
        description: LocaleKey.comparisonAspectCommunicationDescription
            .trParams(<String, String>{
              'a': '${state.selfExpression}',
              'b': '${state.targetExpression}',
            }),
      ),
      _AspectData(
        title: LocaleKey.comparisonAspectSoulTitle.tr,
        score: state.soulScore,
        icon: Icons.favorite_rounded,
        description: LocaleKey.comparisonAspectSoulDescription.trParams(
          <String, String>{
            'a': '${state.selfSoul}',
            'b': '${state.targetSoul}',
          },
        ),
      ),
      _AspectData(
        title: LocaleKey.comparisonAspectPersonalityTitle.tr,
        score: state.personalityScore,
        icon: Icons.lightbulb_outline_rounded,
        description: LocaleKey.comparisonAspectPersonalityDescription.trParams(
          <String, String>{
            'a': '${state.selfPersonality}',
            'b': '${state.targetPersonality}',
          },
        ),
      ),
    ];

    final List<String> strengths = state.strengths.isNotEmpty
        ? state.strengths
        : <String>[
            LocaleKey.comparisonStrengthOne.tr,
            LocaleKey.comparisonStrengthTwo.tr,
            LocaleKey.comparisonStrengthThree.tr,
            LocaleKey.comparisonStrengthFour.tr,
          ];
    final List<String> challenges = state.challenges.isNotEmpty
        ? state.challenges
        : <String>[
            LocaleKey.comparisonChallengeOne.tr,
            LocaleKey.comparisonChallengeTwo.tr,
            LocaleKey.comparisonChallengeThree.tr,
          ];
    final List<String> advice = state.advice.isNotEmpty
        ? state.advice
        : <String>[
            LocaleKey.comparisonAdviceOne.tr,
            LocaleKey.comparisonAdviceTwo.tr,
            LocaleKey.comparisonAdviceThree.tr,
            LocaleKey.comparisonAdviceFour.tr,
          ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        children: <Widget>[
          _OverallScoreCard(state: state),
          16.height,
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              LocaleKey.comparisonDetailTitle.tr,
              style: AppStyles.h4(fontWeight: FontWeight.w600),
            ),
          ),
          10.height,
          for (final _AspectData aspect in aspects) ...<Widget>[
            _AspectCard(aspect: aspect),
            10.height,
          ],
          _ListCard(
            title: LocaleKey.comparisonStrengthTitle.tr,
            icon: Icons.trending_up_rounded,
            items: strengths,
            color: AppColors.richGold,
            numbered: false,
            marker: '✦',
          ),
          10.height,
          _ListCard(
            title: LocaleKey.comparisonChallengeTitle.tr,
            icon: Icons.warning_amber_rounded,
            items: challenges,
            color: AppColors.error,
            numbered: false,
            marker: '!',
          ),
          10.height,
          _ListCard(
            title: LocaleKey.comparisonAdviceTitle.tr,
            icon: Icons.lightbulb_outline_rounded,
            items: advice,
            color: AppColors.richGold,
            numbered: true,
            marker: '',
          ),
          16.height,
          _QuoteCard(
            quote: state.quote.isNotEmpty
                ? state.quote
                : LocaleKey.comparisonQuote.tr,
          ),
          10.height,
        ],
      ),
    );
  }
}

class _OverallScoreCard extends StatefulWidget {
  const _OverallScoreCard({required this.state});

  final ComparisonResultState state;

  @override
  State<_OverallScoreCard> createState() => _OverallScoreCardState();
}

class _OverallScoreCardState extends State<_OverallScoreCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    final String status = _statusLabel(widget.state.overallScore);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.mysticalCardGradient(),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.34)),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          final double ringScale = 1 + (_controller.value * 0.22);
          final double ringOpacity = 0.24 * (1 - _controller.value);
          return Column(
            children: <Widget>[
              Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Transform.scale(
                    scale: ringScale,
                    child: Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.richGold.withValues(
                          alpha: ringOpacity,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: <Color>[
                          AppColors.richGold.withValues(alpha: 0.34),
                          AppColors.violetAccent.withValues(alpha: 0.3),
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.richGold.withValues(alpha: 0.52),
                        width: 2,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppColors.richGold.withValues(alpha: 0.28),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${widget.state.overallScore}',
                      style: AppStyles.numberLarge(
                        color: AppColors.richGold,
                        fontWeight: FontWeight.w700,
                      ).copyWith(fontSize: 42),
                    ),
                  ),
                ],
              ),
              12.height,
              Text(status, style: AppStyles.h2(fontWeight: FontWeight.w700)),
              4.height,
              Text(
                LocaleKey.comparisonOverallLabel.tr,
                style: AppStyles.bodySmall(color: AppColors.textMuted),
              ),
              14.height,
              Row(
                children: <Widget>[
                  Expanded(
                    child: _PersonBadge(
                      number: widget.state.selfLifePath,
                      name: _lastName(widget.state.selfName),
                      subtitle: widget.state.selfDate,
                    ),
                  ),
                  10.width,
                  Expanded(
                    child: _PersonBadge(
                      number: widget.state.targetLifePath,
                      name: widget.state.targetName,
                      subtitle: _relationLabel(widget.state.targetRelation),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  String _statusLabel(int score) {
    if (score >= 80) {
      return LocaleKey.comparisonStatusExcellent.tr;
    }
    if (score >= 70) {
      return LocaleKey.comparisonStatusGood.tr;
    }
    if (score >= 60) {
      return LocaleKey.comparisonStatusModerate.tr;
    }
    return LocaleKey.comparisonStatusEffort.tr;
  }

  String _lastName(String value) {
    final List<String> parts = value.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? value : parts.last;
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _PersonBadge extends StatelessWidget {
  const _PersonBadge({
    required this.number,
    required this.name,
    required this.subtitle,
  });

  final int number;
  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.richGold.withValues(alpha: 0.18),
            border: Border.all(
              color: AppColors.richGold.withValues(alpha: 0.35),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: AppStyles.h4(
              color: AppColors.richGold,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        6.height,
        Text(
          name,
          textAlign: TextAlign.center,
          style: AppStyles.bodySmall(fontWeight: FontWeight.w600),
        ),
        2.height,
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppStyles.caption(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _AspectCard extends StatelessWidget {
  const _AspectCard({required this.aspect});

  final _AspectData aspect;

  @override
  Widget build(BuildContext context) {
    final Color scoreColor = switch (aspect.score) {
      >= 80 => AppColors.richGold,
      >= 60 => AppColors.warning,
      _ => AppColors.textMuted,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.richGold.withValues(alpha: 0.2),
                ),
                child: Icon(aspect.icon, size: 18, color: AppColors.richGold),
              ),
              10.width,
              Expanded(
                child: Text(
                  aspect.title,
                  style: AppStyles.h5(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${aspect.score}',
                style: AppStyles.h3(
                  color: scoreColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              3.width,
              Text('%', style: AppStyles.caption(color: AppColors.textMuted)),
            ],
          ),
          10.height,
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: aspect.score / 100,
              minHeight: 7,
              backgroundColor: AppColors.background.withValues(alpha: 0.35),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.richGold,
              ),
            ),
          ),
          10.height,
          Text(
            aspect.description,
            style: AppStyles.bodySmall(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.title,
    required this.icon,
    required this.items,
    required this.color,
    required this.numbered,
    required this.marker,
  });

  final String title;
  final IconData icon;
  final List<String> items;
  final Color color;
  final bool numbered;
  final String marker;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            color.withValues(alpha: 0.14),
            AppColors.card.withValues(alpha: 0.46),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 20, color: color),
              8.width,
              Text(title, style: AppStyles.h4(fontWeight: FontWeight.w600)),
            ],
          ),
          12.height,
          for (int i = 0; i < items.length; i++) ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    numbered ? '${i + 1}' : marker,
                    style: AppStyles.caption(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                10.width,
                Expanded(
                  child: Text(
                    items[i],
                    style: AppStyles.bodySmall(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            if (i != items.length - 1) 8.height,
          ],
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});

  final String quote;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: <Color>[
            AppColors.richGold.withValues(alpha: 0.12),
            AppColors.violetAccent.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.favorite_rounded,
            size: 20,
            color: AppColors.richGold,
          ),
          8.height,
          Text(
            quote,
            textAlign: TextAlign.center,
            style: AppStyles.bodyMedium(
              color: AppColors.richGold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AspectData {
  const _AspectData({
    required this.title,
    required this.score,
    required this.icon,
    required this.description,
  });

  final String title;
  final int score;
  final IconData icon;
  final String description;
}
