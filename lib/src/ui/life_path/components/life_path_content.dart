import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/core/model/numerology_reading_models.dart';
import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/ui/life_path/interactor/life_path_state.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_pages.dart';
import 'package:test/src/utils/app_styles.dart';

class LifePathContent extends StatelessWidget {
  const LifePathContent({
    required this.state,
    required this.onTogglePinnacles,
    required this.onToggleChallenges,
    super.key,
  });

  final LifePathState state;
  final VoidCallback onTogglePinnacles;
  final VoidCallback onToggleChallenges;

  @override
  Widget build(BuildContext context) {
    if (!state.hasProfile) {
      return const _NoProfileCard();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: <Widget>[
          _IntroCard(),
          12.height,
          _SectionToggleCard(
            title: '4 Đỉnh cao (Pinnacles)',
            subtitle:
                'Các giai đoạn chính trong cuộc đời, mỗi giai đoạn mang năng lượng và cơ hội khác nhau.',
            icon: Icons.landscape_rounded,
            color: AppColors.richGold,
            isExpanded: state.expandedPinnacles,
            onTap: onTogglePinnacles,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: state.expandedPinnacles
                ? Column(
                    children: <Widget>[
                      12.height,
                      for (
                        int i = 0;
                        i < state.pinnacles.length;
                        i++
                      ) ...<Widget>[
                        _PinnacleCard(
                          index: i,
                          cycle: state.pinnacles[i],
                          content:
                              state.pinnacleContentByNumber[state
                                  .pinnacles[i]
                                  .number],
                        ),
                        10.height,
                      ],
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          12.height,
          _SectionToggleCard(
            title: '4 Thử thách (Challenges)',
            subtitle:
                'Những bài học cần vượt qua trong mỗi giai đoạn để phát triển và trưởng thành.',
            icon: Icons.warning_amber_rounded,
            color: AppColors.warning,
            isExpanded: state.expandedChallenges,
            onTap: onToggleChallenges,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: state.expandedChallenges
                ? Column(
                    children: <Widget>[
                      12.height,
                      for (
                        int i = 0;
                        i < state.challenges.length;
                        i++
                      ) ...<Widget>[
                        _ChallengeCard(
                          index: i,
                          cycle: state.challenges[i],
                          content:
                              state.challengeContentByNumber[state
                                  .challenges[i]
                                  .number],
                        ),
                        10.height,
                      ],
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          8.height,
        ],
      ),
    );
  }
}

class _NoProfileCard extends StatelessWidget {
  const _NoProfileCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.mysticalCardGradient(),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.richGold.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: <Widget>[
              const Icon(
                Icons.lock_outline_rounded,
                size: 26,
                color: AppColors.richGold,
              ),
              10.height,
              Text(
                'Bạn chưa có hồ sơ',
                style: AppStyles.h4(fontWeight: FontWeight.w600),
              ),
              6.height,
              Text(
                'Tạo hồ sơ để xem đầy đủ 4 đỉnh cao và 4 thử thách cuộc đời của bạn.',
                style: AppStyles.bodySmall(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              14.height,
              InkWell(
                onTap: () => Get.toNamed(AppPages.onboarding),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Tạo hồ sơ ngay', style: AppStyles.buttonSmall()),
                ),
              ),
            ],
          ),
        ),
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
            Text(
              'Hành trình của bạn',
              style: AppStyles.h4(fontWeight: FontWeight.w600),
            ),
            6.height,
            Text(
              'Cuộc đời được chia thành các giai đoạn với chủ đề và bài học riêng. Mỗi đỉnh cao mang cơ hội phát triển, mỗi thử thách giúp bạn trưởng thành.',
              style: AppStyles.bodySmall(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionToggleCard extends StatelessWidget {
  const _SectionToggleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isExpanded,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.mysticalCardGradient(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(icon, size: 18, color: color),
                  8.width,
                  Expanded(
                    child: Text(
                      title,
                      style: AppStyles.h4(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: color,
                  ),
                ],
              ),
              8.height,
              Text(
                subtitle,
                style: AppStyles.bodySmall(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinnacleCard extends StatelessWidget {
  const _PinnacleCard({
    required this.index,
    required this.cycle,
    required this.content,
  });

  final int index;
  final PinnacleCycle cycle;
  final LifeCycleContent? content;

  @override
  Widget build(BuildContext context) {
    final LifeCycleContent resolvedContent =
        content ??
        const LifeCycleContent(
          theme: '',
          description: '',
          opportunities: '',
          advice: '',
        );
    final _StatusMeta meta = _statusMeta(cycle.status);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: meta.isActive ? AppColors.mysticalCardGradient() : null,
        color: meta.isActive ? null : AppColors.card.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: meta.borderColor),
        boxShadow: meta.isActive
            ? <BoxShadow>[
                BoxShadow(
                  color: AppColors.richGold.withValues(alpha: 0.18),
                  blurRadius: 18,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                _NumberOrb(number: cycle.number, color: meta.numberColor),
                12.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            'Đỉnh cao ${index + 1}',
                            style: AppStyles.h5(fontWeight: FontWeight.w600),
                          ),
                          8.width,
                          _StatusChip(meta: meta),
                        ],
                      ),
                      2.height,
                      Text(
                        cycle.period,
                        style: AppStyles.caption(color: AppColors.textMuted),
                      ),
                      2.height,
                      Text(
                        resolvedContent.theme,
                        style: AppStyles.bodySmall(
                          color: meta.isActive
                              ? AppColors.richGold
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            10.height,
            Text(
              resolvedContent.description,
              style: AppStyles.bodySmall(color: AppColors.textSecondary),
            ),
            10.height,
            _MetaPanel(
              title: 'Cơ hội',
              body: resolvedContent.opportunities,
              color: AppColors.richGold,
            ),
            8.height,
            _MetaPanel(
              title: 'Lời khuyên',
              body: resolvedContent.advice,
              color: AppColors.energyPurple,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.index,
    required this.cycle,
    required this.content,
  });

  final int index;
  final ChallengeCycle cycle;
  final LifeCycleContent? content;

  @override
  Widget build(BuildContext context) {
    final LifeCycleContent resolvedContent =
        content ??
        const LifeCycleContent(
          theme: '',
          description: '',
          opportunities: '',
          advice: '',
        );
    final _StatusMeta meta = _statusMeta(cycle.status, challenge: true);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: meta.borderColor),
        color: AppColors.card.withValues(alpha: 0.52),
        gradient: meta.isActive
            ? LinearGradient(
                colors: <Color>[
                  AppColors.warning.withValues(alpha: 0.16),
                  AppColors.warning.withValues(alpha: 0.08),
                ],
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                _NumberOrb(number: cycle.number, color: meta.numberColor),
                12.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            'Thử thách ${index + 1}',
                            style: AppStyles.h5(fontWeight: FontWeight.w600),
                          ),
                          8.width,
                          _StatusChip(meta: meta),
                        ],
                      ),
                      2.height,
                      Text(
                        cycle.period,
                        style: AppStyles.caption(color: AppColors.textMuted),
                      ),
                      2.height,
                      Text(
                        resolvedContent.theme,
                        style: AppStyles.bodySmall(
                          color: meta.numberColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            10.height,
            Text(
              resolvedContent.description,
              style: AppStyles.bodySmall(color: AppColors.textSecondary),
            ),
            10.height,
            _MetaPanel(
              title: 'Cơ hội vượt qua',
              body: resolvedContent.opportunities,
              color: AppColors.warning,
            ),
            8.height,
            _MetaPanel(
              title: 'Lời khuyên',
              body: resolvedContent.advice,
              color: AppColors.energyPurple,
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberOrb extends StatelessWidget {
  const _NumberOrb({required this.number, required this.color});

  final int number;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
        color: color.withValues(alpha: 0.16),
      ),
      child: Center(
        child: Text('$number', style: AppStyles.numberMedium(color: color)),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.meta});

  final _StatusMeta meta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: meta.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        meta.label,
        style: AppStyles.caption(
          color: meta.numberColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MetaPanel extends StatelessWidget {
  const _MetaPanel({
    required this.title,
    required this.body,
    required this.color,
  });

  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        color: color.withValues(alpha: 0.1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: AppStyles.caption(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            4.height,
            Text(
              body,
              style: AppStyles.caption(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusMeta {
  const _StatusMeta({
    required this.label,
    required this.numberColor,
    required this.background,
    required this.borderColor,
    required this.isActive,
  });

  final String label;
  final Color numberColor;
  final Color background;
  final Color borderColor;
  final bool isActive;
}

_StatusMeta _statusMeta(LifeCycleStatus status, {bool challenge = false}) {
  switch (status) {
    case LifeCycleStatus.active:
      return _StatusMeta(
        label: 'Đang hoạt động',
        numberColor: challenge ? AppColors.warning : AppColors.richGold,
        background: (challenge ? AppColors.warning : AppColors.richGold)
            .withValues(alpha: 0.18),
        borderColor: (challenge ? AppColors.warning : AppColors.richGold)
            .withValues(alpha: 0.4),
        isActive: true,
      );
    case LifeCycleStatus.passed:
      return _StatusMeta(
        label: 'Đã qua',
        numberColor: AppColors.textMuted,
        background: AppColors.textMuted.withValues(alpha: 0.12),
        borderColor: AppColors.border.withValues(alpha: 0.45),
        isActive: false,
      );
    case LifeCycleStatus.future:
      return _StatusMeta(
        label: 'Tương lai',
        numberColor: AppColors.energyPurple,
        background: AppColors.energyPurple.withValues(alpha: 0.16),
        borderColor: AppColors.energyPurple.withValues(alpha: 0.32),
        isActive: false,
      );
  }
}
