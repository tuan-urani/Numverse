import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/core/model/numerology_reading_models.dart';
import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/phase_detail/model/phase_detail_args.dart';
import 'package:test/src/ui/widgets/app_detail_sticky_header.dart';
import 'package:test/src/ui/widgets/app_mystical_scaffold.dart';
import 'package:test/src/ui/widgets/app_simple_page.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class PhaseDetailPage extends StatelessWidget {
  const PhaseDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Object? args = _resolveArgs(context);
    if (args is PhaseDetailStageArgs) {
      return _StageDetailView(args: args);
    }

    if (args is PhaseDetailArgs) {
      return _LegacyDetailView(args: args);
    }

    return AppSimplePage(
      titleKey: LocaleKey.phaseDetailTitle,
      subtitleKey: LocaleKey.phaseDetailSubtitle,
      sections: const <AppSimpleSection>[
        AppSimpleSection(
          titleKey: LocaleKey.genericInsightTitle,
          descriptionKey: LocaleKey.genericAdviceOne,
          icon: Icons.auto_awesome,
        ),
        AppSimpleSection(
          titleKey: LocaleKey.genericAdviceTitle,
          icon: Icons.list_alt,
          bulletKeys: <String>[
            LocaleKey.genericAdviceOne,
            LocaleKey.genericAdviceTwo,
            LocaleKey.genericAdviceThree,
          ],
        ),
      ],
    );
  }

  Object? _resolveArgs(BuildContext context) {
    final Object? routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs != null) {
      return routeArgs;
    }
    return Get.arguments;
  }
}

class _LegacyDetailView extends StatelessWidget {
  const _LegacyDetailView({required this.args});

  final PhaseDetailArgs args;

  @override
  Widget build(BuildContext context) {
    final bool challenge = args.type == PhaseDetailType.challenge;
    final _StatusMeta statusMeta = _statusMeta(
      args.status,
      challenge: challenge,
    );

    return AppMysticalScaffold(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            AppDetailStickyHeader(title: args.title),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Column(
                  children: <Widget>[
                    _DetailHeroCard(
                      args: args,
                      statusMeta: statusMeta,
                      challenge: challenge,
                    ),
                    12.height,
                    _DetailTextCard(
                      title: 'Mô tả',
                      icon: Icons.insights_rounded,
                      body: args.description,
                      color: AppColors.richGold,
                    ),
                    10.height,
                    _DetailTextCard(
                      title: args.opportunitiesTitle,
                      icon: Icons.auto_graph_rounded,
                      body: args.opportunities,
                      color: challenge
                          ? AppColors.warning
                          : AppColors.energyEmerald,
                    ),
                    10.height,
                    _DetailTextCard(
                      title: 'Lời khuyên',
                      icon: Icons.lightbulb_rounded,
                      body: args.advice,
                      color: AppColors.energyPurple,
                    ),
                    8.height,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageDetailView extends StatelessWidget {
  const _StageDetailView({required this.args});

  final PhaseDetailStageArgs args;

  @override
  Widget build(BuildContext context) {
    return AppMysticalScaffold(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            AppDetailStickyHeader(title: args.stageTitle),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Column(
                  children: <Widget>[
                    _StageHeroCard(
                      args: args,
                      statusMeta: _statusMeta(
                        args.status,
                        challenge: false,
                        activeColor: AppColors.primary,
                      ),
                    ),
                    12.height,
                    _StageSectionCard(
                      title: 'Cuộc đời',
                      icon: Icons.auto_graph_rounded,
                      color: AppColors.richGold,
                      args: args.pinnacle,
                    ),
                    10.height,
                    _StageSectionCard(
                      title: 'Thử thách',
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      args: args.challenge,
                    ),
                    8.height,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageHeroCard extends StatelessWidget {
  const _StageHeroCard({required this.args, required this.statusMeta});

  final PhaseDetailStageArgs args;
  final _StatusMeta statusMeta;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.mysticalCardGradient(),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.34)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.14),
            blurRadius: 18,
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.5),
                width: 2,
              ),
              color: AppColors.primary.withValues(alpha: 0.16),
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primaryLight,
              ),
            ),
          ),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  args.title,
                  style: AppStyles.h4(fontWeight: FontWeight.w600),
                ),
                2.height,
                Text(
                  args.periodLabel,
                  style: AppStyles.caption(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          _StatusChip(meta: statusMeta),
        ],
      ),
    );
  }
}

class _StageSectionCard extends StatelessWidget {
  const _StageSectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.args,
  });

  final String title;
  final IconData icon;
  final Color color;
  final PhaseDetailArgs args;

  @override
  Widget build(BuildContext context) {
    final bool challenge = args.type == PhaseDetailType.challenge;
    final _StatusMeta statusMeta = _statusMeta(
      args.status,
      challenge: challenge,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppColors.mysticalCardGradient(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
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
                  style: AppStyles.h5(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _StatusChip(meta: statusMeta),
            ],
          ),
          10.height,
          Row(
            children: <Widget>[
              _NumberOrb(number: args.number, color: color),
              12.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      args.title,
                      style: AppStyles.h5(fontWeight: FontWeight.w600),
                    ),
                    2.height,
                    Text(
                      args.period,
                      style: AppStyles.caption(color: AppColors.textMuted),
                    ),
                    if (args.theme.isNotEmpty) ...<Widget>[
                      2.height,
                      Text(
                        args.theme,
                        style: AppStyles.bodySmall(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          10.height,
          _DetailTextCard(
            title: 'Mô tả',
            icon: Icons.insights_rounded,
            body: args.description,
            color: AppColors.richGold,
          ),
          8.height,
          _DetailTextCard(
            title: args.opportunitiesTitle,
            icon: Icons.auto_graph_rounded,
            body: args.opportunities,
            color: challenge ? AppColors.warning : AppColors.energyEmerald,
          ),
          8.height,
          _DetailTextCard(
            title: 'Lời khuyên',
            icon: Icons.lightbulb_rounded,
            body: args.advice,
            color: AppColors.energyPurple,
          ),
        ],
      ),
    );
  }
}

class _DetailHeroCard extends StatelessWidget {
  const _DetailHeroCard({
    required this.args,
    required this.statusMeta,
    required this.challenge,
  });

  final PhaseDetailArgs args;
  final _StatusMeta statusMeta;
  final bool challenge;

  @override
  Widget build(BuildContext context) {
    final Color accentColor = challenge
        ? AppColors.warning
        : AppColors.richGold;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.mysticalCardGradient(),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.34)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: accentColor.withValues(alpha: 0.14), blurRadius: 18),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _NumberOrb(number: args.number, color: accentColor),
              12.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      args.title,
                      style: AppStyles.h4(fontWeight: FontWeight.w600),
                    ),
                    2.height,
                    Text(
                      args.period,
                      style: AppStyles.caption(color: AppColors.textMuted),
                    ),
                    if (args.theme.isNotEmpty) ...<Widget>[
                      2.height,
                      Text(
                        args.theme,
                        style: AppStyles.bodySmall(
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _StatusChip(meta: statusMeta),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailTextCard extends StatelessWidget {
  const _DetailTextCard({
    required this.title,
    required this.icon,
    required this.body,
    required this.color,
  });

  final String title;
  final IconData icon;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.32)),
        color: color.withValues(alpha: 0.08),
      ),
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
                  style: AppStyles.h5(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          8.height,
          Text(
            body,
            style: AppStyles.bodyMedium(color: AppColors.textSecondary),
          ),
        ],
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
      width: 56,
      height: 56,
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

class _StatusMeta {
  const _StatusMeta({
    required this.label,
    required this.numberColor,
    required this.background,
  });

  final String label;
  final Color numberColor;
  final Color background;
}

_StatusMeta _statusMeta(
  LifeCycleStatus status, {
  required bool challenge,
  Color? activeColor,
}) {
  switch (status) {
    case LifeCycleStatus.active:
      final Color resolvedColor =
          activeColor ?? (challenge ? AppColors.warning : AppColors.richGold);
      return _StatusMeta(
        label: 'Đang hoạt động',
        numberColor: resolvedColor,
        background: resolvedColor.withValues(alpha: 0.2),
      );
    case LifeCycleStatus.passed:
      return _StatusMeta(
        label: 'Đã qua',
        numberColor: AppColors.textMuted,
        background: AppColors.textMuted.withValues(alpha: 0.14),
      );
    case LifeCycleStatus.future:
      return _StatusMeta(
        label: 'Tương lai',
        numberColor: AppColors.energyPurple,
        background: AppColors.energyPurple.withValues(alpha: 0.18),
      );
  }
}
