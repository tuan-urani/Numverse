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
    super.key,
  });

  final ChartMatrixState state;
  final VoidCallback onToggleBirthChart;
  final VoidCallback onToggleNameChart;

  @override
  Widget build(BuildContext context) {
    if (!state.hasProfile) {
      return const _NoProfileCard();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
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
                        title: 'Ma trận Pythagorean',
                        chart: state.birthChart,
                        numberColor: AppColors.richGold,
                        cellColor: AppColors.richGold.withValues(alpha: 0.22),
                        borderColor: AppColors.richGold.withValues(alpha: 0.45),
                        glowColor: AppColors.richGold.withValues(alpha: 0.16),
                      ),
                      12.height,
                      _BirthChartAnalysisCard(state: state),
                      12.height,
                      _MissingNumbersCard(
                        numbers: state.birthChart.missingNumbers,
                        data: state.birthChartData,
                        resolvedLessonByNumber:
                            state.birthResolvedContent.lessonByNumber,
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          16.height,
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
                        title: 'Ma trận Pythagorean (Tên)',
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
            Text(title, style: AppStyles.h4(fontWeight: FontWeight.w600)),
            12.height,
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
            10.height,
            const Divider(color: AppColors.border),
            10.height,
            _AxisBlock(
              title: data.mentalAxis.name,
              score: state.birthAxes.mental,
              description:
                  resolved.axisDescriptionByKey['mental'] ??
                  (state.birthAxes.mental.present
                      ? data.mentalAxis.presentDescription
                      : data.mentalAxis.missingDescription),
              icon: Icons.psychology_rounded,
            ),
            10.height,
            _AxisBlock(
              title: data.emotionalAxis.name,
              score: state.birthAxes.emotional,
              description:
                  resolved.axisDescriptionByKey['emotional'] ??
                  (state.birthAxes.emotional.present
                      ? data.emotionalAxis.presentDescription
                      : data.emotionalAxis.missingDescription),
              icon: Icons.favorite_rounded,
            ),
            10.height,
            _AxisBlock(
              title: data.physicalAxis.name,
              score: state.birthAxes.physical,
              description:
                  resolved.axisDescriptionByKey['physical'] ??
                  (state.birthAxes.physical.present
                      ? data.physicalAxis.presentDescription
                      : data.physicalAxis.missingDescription),
              icon: Icons.trending_up_rounded,
            ),
            if (resolved.hasArrowInsights) ...<Widget>[
              10.height,
              const Divider(color: AppColors.border),
              10.height,
              _ArrowInsightsCard(
                activeArrows: resolved.activeArrows,
                inactiveArrows: resolved.inactiveArrows,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MissingNumbersCard extends StatelessWidget {
  const _MissingNumbersCard({
    required this.numbers,
    required this.data,
    this.resolvedLessonByNumber = const <int, String>{},
  });

  final List<int> numbers;
  final BirthChartDataSet data;
  final Map<int, String> resolvedLessonByNumber;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
        gradient: LinearGradient(
          colors: <Color>[
            AppColors.warning.withValues(alpha: 0.16),
            AppColors.warning.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Số trống (Bài học cần học)',
              style: AppStyles.h4(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
            10.height,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: numbers.map((int number) {
                return Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.45),
                    ),
                    color: AppColors.warning.withValues(alpha: 0.15),
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: AppStyles.numberSmall(color: AppColors.warning),
                    ),
                  ),
                );
              }).toList(),
            ),
            10.height,
            for (final int number in numbers)
              _MeaningLine(
                number: number,
                text:
                    resolvedLessonByNumber[number] ??
                    data.numbers[number]?.lesson ??
                    '',
                color: AppColors.warning,
              ),
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
            10.height,
            if (state.nameDominantNumbers.isNotEmpty)
              _MiniPanel(
                title: 'Năng lượng thống trị',
                color: AppColors.energyPurple,
                child: Column(
                  children: state.nameDominantNumbers.map((
                    DominantNumber item,
                  ) {
                    return _MeaningLine(
                      number: item.number,
                      text:
                          '${resolved.strengthByNumber[item.number] ?? data.numbers[item.number]?.strength ?? ''} (x${item.count})',
                      color: AppColors.energyPurple,
                    );
                  }).toList(),
                ),
              ),
            if (state.nameDominantNumbers.isNotEmpty) 8.height,
            _MiniPanel(
              title: 'Năng lượng có trong tên',
              color: AppColors.energyPurple,
              child: Column(
                children: state.nameChart.presentNumbers.map((int number) {
                  final int count = state.nameChart.numbers[number] ?? 0;
                  final String prefix = count > 1
                      ? '$number (x$count)'
                      : '$number';
                  return _MeaningLine(
                    numberLabel: prefix,
                    text:
                        resolved.strengthByNumber[number] ??
                        data.numbers[number]?.strength ??
                        '',
                    color: AppColors.energyPurple,
                  );
                }).toList(),
              ),
            ),
            if (state.nameChart.missingNumbers.isNotEmpty) ...<Widget>[
              8.height,
              _MiniPanel(
                title: 'Số thiếu trong tên',
                color: AppColors.violetAccent,
                child: Column(
                  children: state.nameChart.missingNumbers.map((int number) {
                    return _MeaningLine(
                      number: number,
                      text:
                          resolved.lessonByNumber[number] ??
                          data.numbers[number]?.lesson ??
                          '',
                      color: AppColors.violetAccent,
                    );
                  }).toList(),
                ),
              ),
            ],
            8.height,
            _MiniPanel(
              title: 'Phân tích 3 trục',
              color: AppColors.energyPurple,
              child: Column(
                children: <Widget>[
                  _AxisMiniBar(
                    label: data.mentalAxis.name,
                    count: state.nameAxes.mental.count,
                    color: AppColors.energyPurple,
                  ),
                  _AxisMiniBar(
                    label: data.emotionalAxis.name,
                    count: state.nameAxes.emotional.count,
                    color: AppColors.energyPurple,
                  ),
                  _AxisMiniBar(
                    label: data.physicalAxis.name,
                    count: state.nameAxes.physical.count,
                    color: AppColors.energyPurple,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPanel extends StatelessWidget {
  const _MiniPanel({
    required this.title,
    required this.color,
    required this.child,
  });

  final String title;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        color: color.withValues(alpha: 0.12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: AppStyles.bodySmall(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            8.height,
            child,
          ],
        ),
      ),
    );
  }
}

class _ArrowInsightsCard extends StatelessWidget {
  const _ArrowInsightsCard({
    required this.activeArrows,
    required this.inactiveArrows,
  });

  final List<ResolvedArrowInsight> activeArrows;
  final List<ResolvedArrowInsight> inactiveArrows;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.3)),
        color: AppColors.richGold.withValues(alpha: 0.08),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Mũi tên trong biểu đồ',
              style: AppStyles.bodySmall(fontWeight: FontWeight.w600),
            ),
            if (activeArrows.isNotEmpty) ...<Widget>[
              8.height,
              _SectionTitle(
                color: AppColors.richGold,
                title: 'Mũi tên nổi bật',
              ),
              6.height,
              for (final ResolvedArrowInsight item in activeArrows)
                _MeaningLine(
                  numberLabel: '${item.title} (${item.numbers.join('-')})',
                  text: item.text,
                  color: AppColors.richGold,
                ),
            ],
            if (inactiveArrows.isNotEmpty) ...<Widget>[
              if (activeArrows.isNotEmpty) 6.height,
              _SectionTitle(
                color: AppColors.warning,
                title: 'Mũi tên cần chú ý',
              ),
              6.height,
              for (final ResolvedArrowInsight item in inactiveArrows)
                _MeaningLine(
                  numberLabel: '${item.title} (${item.numbers.join('-')})',
                  text: item.text,
                  color: AppColors.warning,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AxisBlock extends StatelessWidget {
  const _AxisBlock({
    required this.title,
    required this.score,
    required this.description,
    required this.icon,
  });

  final String title;
  final ChartAxisScore score;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final double progress = score.count / 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 14, color: AppColors.richGold),
            6.width,
            Expanded(
              child: Text(
                title,
                style: AppStyles.bodySmall(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '${score.count}/3',
              style: AppStyles.caption(color: AppColors.textMuted),
            ),
          ],
        ),
        6.height,
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.background.withValues(alpha: 0.4),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.richGold),
          ),
        ),
        6.height,
        Text(
          description,
          style: AppStyles.caption(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _AxisMiniBar extends StatelessWidget {
  const _AxisMiniBar({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: AppStyles.caption(color: AppColors.textSecondary),
                ),
              ),
              Text(
                '$count/3',
                style: AppStyles.caption(color: AppColors.textMuted),
              ),
            ],
          ),
          4.height,
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: count / 3,
              minHeight: 4,
              backgroundColor: AppColors.background.withValues(alpha: 0.35),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
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
          style: AppStyles.bodySmall(color: color, fontWeight: FontWeight.w600),
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
            style: AppStyles.caption(color: color, fontWeight: FontWeight.w700),
          ),
          Expanded(
            child: Text(
              text,
              style: AppStyles.caption(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
