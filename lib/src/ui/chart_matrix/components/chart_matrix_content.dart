import 'package:flutter/material.dart';

import 'package:test/src/core/model/numerology_reading_models.dart';
import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/helper/birth_chart_content_resolver.dart';
import 'package:test/src/ui/chart_matrix/interactor/chart_matrix_state.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_pages.dart';
import 'package:test/src/utils/app_styles.dart';
import 'package:test/src/utils/tab_navigation_helper.dart';

class ChartMatrixContent extends StatelessWidget {
  const ChartMatrixContent({
    required this.state,
    required this.onToggleBirthChart,
    required this.onToggleNameChart,
    required this.birthSectionKey,
    required this.nameSectionKey,
    super.key,
  });

  final ChartMatrixState state;
  final VoidCallback onToggleBirthChart;
  final VoidCallback onToggleNameChart;
  final GlobalKey birthSectionKey;
  final GlobalKey nameSectionKey;

  @override
  Widget build(BuildContext context) {
    if (!state.hasProfile) {
      return const _NoProfileCard();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: <Widget>[
          Column(
            key: birthSectionKey,
            children: <Widget>[
              _ExpandableIntroCard(
                title: 'Biểu đồ ngày sinh',
                body:
                    'Từ ngày sinh ${state.formattedBirthDate}, ta có biểu đồ Pythagorean thể hiện năng lượng và tiềm năng của bạn.',
                icon: Icons.grid_4x4_rounded,
                isExpanded: state.expandedBirthChart,
                onTap: onToggleBirthChart,
                accentColor: AppColors.richGold,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: state.expandedBirthChart
                    ? Column(
                        children: <Widget>[
                          12.height,
                          _ChartGridCard(
                            title: '',
                            chart: state.birthChart,
                            numberColor: AppColors.richGold,
                            cellColor: AppColors.richGold.withValues(
                              alpha: 0.22,
                            ),
                            borderColor: AppColors.richGold.withValues(
                              alpha: 0.45,
                            ),
                            glowColor: AppColors.richGold.withValues(
                              alpha: 0.16,
                            ),
                          ),
                          12.height,
                          _BirthChartAnalysisCard(state: state),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          16.height,
          Column(
            key: nameSectionKey,
            children: <Widget>[
              _ExpandableIntroCard(
                title: 'Biểu đồ tên',
                body:
                    'Từ tên "${state.profileName.toUpperCase()}", ta có biểu đồ thể hiện cách bạn biểu đạt bản thân ra bên ngoài.',
                icon: Icons.text_fields_rounded,
                isExpanded: state.expandedNameChart,
                onTap: onToggleNameChart,
                accentColor: AppColors.energyPurple,
                backgroundGradient: <Color>[
                  AppColors.energyPurple.withValues(alpha: 0.18),
                  AppColors.violetAccent.withValues(alpha: 0.12),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: state.expandedNameChart
                    ? Column(
                        children: <Widget>[
                          12.height,
                          _ChartGridCard(
                            title: '',
                            chart: state.nameChart,
                            numberColor: AppColors.energyPurple,
                            cellColor: AppColors.energyPurple.withValues(
                              alpha: 0.26,
                            ),
                            borderColor: AppColors.energyPurple.withValues(
                              alpha: 0.45,
                            ),
                            glowColor: AppColors.energyPurple.withValues(
                              alpha: 0.2,
                            ),
                          ),
                          12.height,
                          _NameChartAnalysisCard(state: state),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
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
                'Tạo hồ sơ để hệ thống sinh biểu đồ ngày sinh và biểu đồ tên của bạn.',
                style: AppStyles.bodySmall(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              14.height,
              InkWell(
                onTap: () =>
                    TabNavigationHelper.pushCommonRoute(AppPages.onboarding),
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

class _ExpandableIntroCard extends StatelessWidget {
  const _ExpandableIntroCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.isExpanded,
    required this.onTap,
    required this.accentColor,
    this.backgroundGradient,
  });

  final String title;
  final String body;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onTap;
  final Color accentColor;
  final List<Color>? backgroundGradient;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: backgroundGradient == null
            ? AppColors.mysticalCardGradient()
            : LinearGradient(colors: backgroundGradient!),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.34)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(icon, size: 18, color: accentColor),
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
                    color: accentColor,
                  ),
                ],
              ),
              8.height,
              Text(
                body,
                style: AppStyles.bodySmall(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartGridCard extends StatelessWidget {
  const _ChartGridCard({
    required this.title,
    required this.chart,
    required this.numberColor,
    required this.cellColor,
    required this.borderColor,
    required this.glowColor,
  });

  final String title;
  final BirthChartGrid chart;
  final Color numberColor;
  final Color cellColor;
  final Color borderColor;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    final List<int?> gridValues = chart.grid
        .expand((List<int?> row) => row)
        .toList();
    const List<int> displayOrder = <int>[3, 6, 9, 2, 5, 8, 1, 4, 7];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            if (title.trim().isNotEmpty) ...<Widget>[
              Text(title, style: AppStyles.h4(fontWeight: FontWeight.w600)),
              12.height,
            ],
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 9,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemBuilder: (BuildContext context, int index) {
                final int? number = gridValues[index];
                final int displayNumber = displayOrder[index];
                final int count = number == null
                    ? 0
                    : (chart.numbers[number] ?? 0);

                return DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: number == null
                          ? AppColors.border.withValues(alpha: 0.35)
                          : borderColor,
                      width: number == null ? 1 : 2,
                    ),
                    color: number == null
                        ? AppColors.background.withValues(alpha: 0.2)
                        : cellColor,
                    boxShadow: number == null
                        ? null
                        : <BoxShadow>[
                            BoxShadow(color: glowColor, blurRadius: 14),
                          ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        '$displayNumber',
                        style: AppStyles.caption(color: AppColors.textMuted),
                      ),
                      if (number != null)
                        Text(
                          '$number',
                          style: AppStyles.numberMedium(color: numberColor),
                        ),
                      if (number != null && count > 1)
                        Text(
                          'x$count',
                          style: AppStyles.caption(
                            color: numberColor.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            10.height,
            Text(
              'Các số xuất hiện: ${chart.presentNumbers.map((int number) {
                final int count = chart.numbers[number] ?? 0;
                return count > 1 ? '$number (x$count)' : '$number';
              }).join(', ')}',
              style: AppStyles.caption(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _BirthChartAnalysisCard extends StatelessWidget {
  const _BirthChartAnalysisCard({required this.state});

  final ChartMatrixState state;

  @override
  Widget build(BuildContext context) {
    final BirthChartDataSet data = state.birthChartData;
    final BirthChartResolvedContent resolved = state.birthResolvedContent;

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
              'Phân tích biểu đồ',
              style: AppStyles.h4(fontWeight: FontWeight.w600),
            ),
            12.height,
            _SectionTitle(color: AppColors.richGold, title: 'Điểm mạnh'),
            8.height,
            for (final int number in state.birthChart.presentNumbers)
              _MeaningLine(
                number: number,
                text:
                    resolved.strengthByNumber[number] ??
                    data.numbers[number]?.strength ??
                    '',
                color: AppColors.richGold,
              ),
            10.height,
            const Divider(color: AppColors.border),
            10.height,
            _SectionTitle(
              color: AppColors.warning,
              title: 'Điểm yếu (Bài học)',
            ),
            8.height,
            for (final int number in state.birthChart.missingNumbers)
              _MeaningLine(
                number: number,
                text:
                    resolved.lessonByNumber[number] ??
                    data.numbers[number]?.lesson ??
                    '',
                color: AppColors.warning,
              ),
            if (resolved.hasArrowInsights) ...<Widget>[
              10.height,
              const Divider(color: AppColors.border),
              10.height,
              _ArrowInsightsCard(activeArrows: resolved.activeArrows),
            ],
          ],
        ),
      ),
    );
  }
}

class _NameChartAnalysisCard extends StatelessWidget {
  const _NameChartAnalysisCard({required this.state});

  final ChartMatrixState state;

  @override
  Widget build(BuildContext context) {
    final BirthChartDataSet data = state.nameChartData;
    final BirthChartResolvedContent resolved = state.nameResolvedContent;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.energyPurple.withValues(alpha: 0.4),
        ),
        gradient: LinearGradient(
          colors: <Color>[
            AppColors.energyPurple.withValues(alpha: 0.16),
            AppColors.violetAccent.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Phân tích biểu đồ tên',
              style: AppStyles.h4(fontWeight: FontWeight.w600),
            ),
            12.height,
            _SectionTitle(color: AppColors.energyPurple, title: 'Điểm mạnh'),
            8.height,
            for (final int number in state.nameChart.presentNumbers)
              _MeaningLine(
                numberLabel: _nameNumberLabel(state.nameChart, number),
                text:
                    resolved.strengthByNumber[number] ??
                    data.numbers[number]?.strength ??
                    '',
                color: AppColors.energyPurple,
              ),
            10.height,
            const Divider(color: AppColors.border),
            10.height,
            _SectionTitle(
              color: AppColors.energyPurple,
              title: 'Điểm yếu (Bài học)',
            ),
            8.height,
            for (final int number in state.nameChart.missingNumbers)
              _MeaningLine(
                number: number,
                text:
                    resolved.lessonByNumber[number] ??
                    data.numbers[number]?.lesson ??
                    '',
                color: AppColors.energyPurple,
              ),
            if (resolved.hasArrowInsights) ...<Widget>[
              10.height,
              const Divider(color: AppColors.border),
              10.height,
              _ArrowInsightsCard(
                activeArrows: resolved.activeArrows,
                accentColor: AppColors.energyPurple,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _nameNumberLabel(BirthChartGrid chart, int number) {
    final int count = chart.numbers[number] ?? 0;
    if (count > 1) {
      return '$number (x$count)';
    }
    return '$number';
  }
}

class _ArrowInsightsCard extends StatelessWidget {
  const _ArrowInsightsCard({
    required this.activeArrows,
    this.accentColor = AppColors.richGold,
  });

  final List<ResolvedArrowInsight> activeArrows;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        color: accentColor.withValues(alpha: 0.08),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Mũi tên đặc trưng của bạn',
              style: AppStyles.bodyMedium(fontWeight: FontWeight.w700),
            ),
            8.height,
            for (final ResolvedArrowInsight item in activeArrows)
              _ArrowMeaningItem(
                title:
                    '${_withArrowPrefix(item.title)} (${item.numbers.join('-')})',
                description: item.text,
                color: accentColor,
              ),
          ],
        ),
      ),
    );
  }

  static String _withArrowPrefix(String title) {
    final String trimmed = title.trim();
    final String normalized = trimmed.toLowerCase();
    if (normalized.startsWith('mũi tên') || normalized.startsWith('mui ten')) {
      return trimmed;
    }
    return 'Mũi tên $trimmed';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.color, required this.title});

  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        8.width,
        Text(
          title,
          style: AppStyles.bodyMedium(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MeaningLine extends StatelessWidget {
  const _MeaningLine({
    this.number,
    this.numberLabel,
    required this.text,
    required this.color,
  });

  final int? number;
  final String? numberLabel;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final String leading = numberLabel ?? '${number ?? ''}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '$leading: ',
            style: AppStyles.bodySmall(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppStyles.bodySmall(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowMeaningItem extends StatelessWidget {
  const _ArrowMeaningItem({
    required this.title,
    required this.description,
    required this.color,
  });

  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: AppStyles.bodySmall(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          2.height,
          Text(
            description,
            style: AppStyles.bodySmall(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
