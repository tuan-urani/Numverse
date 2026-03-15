import 'package:flutter/material.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/ui/personal_portrait/interactor/personal_portrait_state.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class PersonalPortraitContent extends StatelessWidget {
  const PersonalPortraitContent({required this.state, super.key});

  final PersonalPortraitState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: <Widget>[
          _IntroCard(),
          12.height,
          for (final PortraitAspect aspect in state.aspects) ...<Widget>[
            _AspectCard(aspect: aspect),
            12.height,
          ],
          _StrengthCard(items: state.strengths),
          12.height,
          _GrowthCard(items: state.growthAreas),
          12.height,
          _CareerCard(careers: state.careerRecommendations),
          12.height,
          _QuoteCard(quote: state.quote),
          8.height,
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.mysticalCardGradient(),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: AppColors.richGold,
                ),
                8.width,
                Text(
                  'Chân dung toàn diện',
                  style: AppStyles.h4(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            8.height,
            Text(
              'Phân tích đa chiều về tính cách, giao tiếp, mối quan hệ và sự nghiệp dựa trên các chỉ số thần số học của bạn.',
              style: AppStyles.bodySmall(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _AspectCard extends StatelessWidget {
  const _AspectCard({required this.aspect});

  final PortraitAspect aspect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.richGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(aspect.icon, size: 18, color: AppColors.richGold),
                ),
                10.width,
                Expanded(
                  child: Text(
                    aspect.title,
                    style: AppStyles.h4(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            12.height,
            for (final PortraitTrait trait in aspect.traits) ...<Widget>[
              _TraitBar(trait: trait),
              9.height,
            ],
            const Divider(color: AppColors.border),
            8.height,
            Text(
              aspect.summary,
              style: AppStyles.bodySmall(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _TraitBar extends StatelessWidget {
  const _TraitBar({required this.trait});

  final PortraitTrait trait;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                trait.label,
                style: AppStyles.bodySmall(color: AppColors.textSecondary),
              ),
            ),
            Text(
              '${trait.score}/10',
              style: AppStyles.caption(
                color: AppColors.richGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        4.height,
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: trait.score / 10,
            minHeight: 6,
            backgroundColor: AppColors.background.withValues(alpha: 0.35),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.richGold),
          ),
        ),
      ],
    );
  }
}

class _StrengthCard extends StatelessWidget {
  const _StrengthCard({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.35)),
        gradient: LinearGradient(
          colors: <Color>[
            AppColors.richGold.withValues(alpha: 0.15),
            AppColors.violetAccent.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '✨ Điểm mạnh',
              style: AppStyles.h4(fontWeight: FontWeight.w600),
            ),
            10.height,
            for (int i = 0; i < items.length; i++) ...<Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.richGold.withValues(alpha: 0.18),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: AppStyles.caption(
                          color: AppColors.richGold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  10.width,
                  Expanded(
                    child: Text(
                      items[i],
                      style: AppStyles.bodySmall(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              if (i != items.length - 1) 8.height,
            ],
          ],
        ),
      ),
    );
  }
}

class _GrowthCard extends StatelessWidget {
  const _GrowthCard({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.energyPurple.withValues(alpha: 0.35),
        ),
        gradient: LinearGradient(
          colors: <Color>[
            AppColors.energyPurple.withValues(alpha: 0.14),
            AppColors.deepViolet.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '🌱 Hướng phát triển',
              style: AppStyles.h4(fontWeight: FontWeight.w600),
            ),
            10.height,
            for (int i = 0; i < items.length; i++) ...<Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.energyPurple.withValues(alpha: 0.2),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_right_alt_rounded,
                        size: 14,
                        color: AppColors.energyPurple,
                      ),
                    ),
                  ),
                  10.width,
                  Expanded(
                    child: Text(
                      items[i],
                      style: AppStyles.bodySmall(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              if (i != items.length - 1) 8.height,
            ],
          ],
        ),
      ),
    );
  }
}

class _CareerCard extends StatelessWidget {
  const _CareerCard({required this.careers});

  final List<String> careers;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.mysticalCardGradient(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Nghề nghiệp phù hợp',
              style: AppStyles.h4(fontWeight: FontWeight.w600),
            ),
            10.height,
            GridView.builder(
              itemCount: careers.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                mainAxisExtent: 38,
              ),
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.richGold.withValues(alpha: 0.26),
                    ),
                    color: AppColors.richGold.withValues(alpha: 0.1),
                  ),
                  child: Text(
                    careers[index],
                    style: AppStyles.caption(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});

  final String quote;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: <Color>[
              AppColors.richGold.withValues(alpha: 0.14),
              AppColors.energyPurple.withValues(alpha: 0.12),
            ],
          ),
          border: Border.all(color: AppColors.richGold.withValues(alpha: 0.24)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            quote,
            style: AppStyles.bodySmall(
              color: AppColors.richGold,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
