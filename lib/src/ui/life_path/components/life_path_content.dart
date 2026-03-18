import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:test/src/core/model/numerology_reading_models.dart';
import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/ui/life_path/interactor/life_path_state.dart';
import 'package:test/src/ui/phase_detail/model/phase_detail_args.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_pages.dart';
import 'package:test/src/utils/app_styles.dart';
import 'package:test/src/utils/tab_navigation_helper.dart';

class LifePathContent extends StatelessWidget {
  const LifePathContent({required this.state, super.key});

  static const LifeCycleContent _emptyContent = LifeCycleContent(
    theme: '',
    description: '',
    opportunities: '',
    advice: '',
  );
  static const int _maxPhaseCount = 4;
  static const List<String> _pinnacleTitles = <String>[
    'Khởi đầu',
    'Phát triển',
    'Trưởng thành',
    'Viên mãn',
  ];

  final LifePathState state;

  @override
  Widget build(BuildContext context) {
    if (!state.hasProfile) {
      return const _NoProfileCard();
    }

    final List<_RadarChartItem> items = _buildStageItems(state);
    if (items.length < _maxPhaseCount) {
      return const _EmptyCycleCard();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: <Widget>[
          _IntroCard(currentAge: state.currentAge),
          12.height,
          _RadarCycleCard(
            title: '4 Giai đoạn cuộc đời',
            icon: Icons.auto_graph_rounded,
            accentColor: AppColors.primary,
            items: items,
          ),
          8.height,
        ],
      ),
    );
  }

  static List<_RadarChartItem> _buildStageItems(LifePathState state) {
    final int count = _boundedCount(
      _minInt(state.pinnacles.length, state.challenges.length),
    );
    final List<_RadarChartItem> items = <_RadarChartItem>[];
    for (int i = 0; i < count; i++) {
      final PinnacleCycle pinnacle = state.pinnacles[i];
      final ChallengeCycle challenge = state.challenges[i];
      final PhaseDetailArgs pinnacleArgs = _buildPhaseArgs(
        index: i,
        type: PhaseDetailType.pinnacle,
        cycleNumber: pinnacle.number,
        period: pinnacle.period,
        status: pinnacle.status,
        content: _resolveContent(
          state.pinnacleContentByNumber[pinnacle.number],
        ),
      );
      final PhaseDetailArgs challengeArgs = _buildPhaseArgs(
        index: i,
        type: PhaseDetailType.challenge,
        cycleNumber: challenge.number,
        period: challenge.period,
        status: challenge.status,
        content: _resolveContent(
          state.challengeContentByNumber[challenge.number],
        ),
      );
      final int startAge = _minInt(pinnacle.startAge, challenge.startAge);
      final int endAge = _maxInt(pinnacle.endAge, challenge.endAge);
      final String stageTitle = _titleAt(
        _pinnacleTitles,
        i,
        'Giai đoạn ${i + 1}',
      );
      final LifeCycleStatus stageStatus = _resolveStageStatus(
        pinnacle.status,
        challenge.status,
      );
      items.add(
        _RadarChartItem(
          code: 'GĐ${i + 1}',
          title: stageTitle,
          startAge: startAge,
          endAge: endAge,
          status: stageStatus,
          args: PhaseDetailStageArgs(
            index: i,
            stageTitle: stageTitle,
            periodLabel: _periodLabel(startAge, endAge),
            status: stageStatus,
            pinnacle: pinnacleArgs,
            challenge: challengeArgs,
          ),
        ),
      );
    }
    return items;
  }

  static PhaseDetailArgs _buildPhaseArgs({
    required int index,
    required PhaseDetailType type,
    required int cycleNumber,
    required String period,
    required LifeCycleStatus status,
    required LifeCycleContent content,
  }) {
    return PhaseDetailArgs(
      type: type,
      index: index,
      number: cycleNumber,
      period: period,
      status: status,
      theme: content.theme,
      description: content.description,
      opportunities: content.opportunities,
      advice: content.advice,
    );
  }

  static int _boundedCount(int sourceCount) {
    if (sourceCount <= 0) {
      return 0;
    }
    return sourceCount > _maxPhaseCount ? _maxPhaseCount : sourceCount;
  }

  static LifeCycleStatus _resolveStageStatus(
    LifeCycleStatus pinnacleStatus,
    LifeCycleStatus challengeStatus,
  ) {
    if (pinnacleStatus == LifeCycleStatus.active ||
        challengeStatus == LifeCycleStatus.active) {
      return LifeCycleStatus.active;
    }
    if (pinnacleStatus == LifeCycleStatus.passed &&
        challengeStatus == LifeCycleStatus.passed) {
      return LifeCycleStatus.passed;
    }
    return LifeCycleStatus.future;
  }

  static String _periodLabel(int startAge, int endAge) {
    if (endAge >= 999) {
      return '$startAge+ tuổi';
    }
    return '$startAge - $endAge tuổi';
  }

  static LifeCycleContent _resolveContent(LifeCycleContent? content) {
    return content ?? _emptyContent;
  }

  static String _titleAt(List<String> source, int index, String fallback) {
    if (index >= 0 && index < source.length) {
      return source[index];
    }
    return fallback;
  }

  static int _minInt(int a, int b) => a < b ? a : b;

  static int _maxInt(int a, int b) => a > b ? a : b;
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

class _EmptyCycleCard extends StatelessWidget {
  const _EmptyCycleCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.mysticalCardGradient(),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.hourglass_empty_rounded,
                size: 20,
                color: AppColors.textMuted.withValues(alpha: 0.9),
              ),
              10.width,
              Expanded(
                child: Text(
                  'Chưa có dữ liệu chu kỳ cho hồ sơ này.',
                  style: AppStyles.bodyMedium(color: AppColors.textSecondary),
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
  const _IntroCard({required this.currentAge});

  final int currentAge;

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
              'Biểu đồ 4 giai đoạn cuộc đời',
              style: AppStyles.h4(fontWeight: FontWeight.w600),
            ),
            6.height,
            Text(
              'Bạn đang ở tuổi $currentAge. Chạm vào từng đỉnh trong chart để xem chi tiết.',
              style: AppStyles.bodySmall(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarCycleCard extends StatelessWidget {
  const _RadarCycleCard({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final List<_RadarChartItem> items;

  @override
  Widget build(BuildContext context) {
    final _RadarChartItem? activeItem = _activePhase(items);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.mysticalCardGradient(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.34)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                    style: AppStyles.h5(fontWeight: FontWeight.w600),
                  ),
                ),
                if (activeItem != null)
                  _ActivePhaseChip(
                    label: 'Đang ở ${activeItem.code}',
                    color: accentColor,
                  ),
              ],
            ),
            10.height,
            _RadarChartView(items: items),
          ],
        ),
      ),
    );
  }

  _RadarChartItem? _activePhase(List<_RadarChartItem> source) {
    for (final _RadarChartItem item in source) {
      if (item.status == LifeCycleStatus.active) {
        return item;
      }
    }
    return null;
  }
}

class _RadarChartView extends StatefulWidget {
  const _RadarChartView({required this.items});

  final List<_RadarChartItem> items;

  @override
  State<_RadarChartView> createState() => _RadarChartViewState();
}

class _RadarChartViewState extends State<_RadarChartView>
    with SingleTickerProviderStateMixin {
  static const double _targetValue = 90;
  static const double _tracePhaseEnd = 0.8;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _RadarChartView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _controller
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _traceProgress {
    return (_controller.value / _tracePhaseEnd).clamp(0.0, 1.0).toDouble();
  }

  double get _fillRevealProgress {
    if (_controller.value <= _tracePhaseEnd) {
      return 0;
    }
    final double raw =
        (_controller.value - _tracePhaseEnd) / (1 - _tracePhaseEnd);
    return Curves.easeOut.transform(raw.clamp(0.0, 1.0).toDouble());
  }

  double get _traceLineOpacity {
    if (_controller.value <= _tracePhaseEnd) {
      return 1;
    }
    return (1 - _fillRevealProgress).clamp(0.0, 1.0).toDouble();
  }

  double _entryProgress(int index) {
    final int count = widget.items.length;
    if (count <= 0) {
      return 0;
    }
    final double timeline = _traceProgress;
    final double segment = 1 / count;
    final double start = segment * index;
    final double raw = (timeline - start) / segment;
    final double clamped = raw.clamp(0.0, 1.0).toDouble();
    return Curves.easeOutCubic.transform(clamped);
  }

  double _entryValue(int index) => _targetValue * _entryProgress(index);

  double _vertexOpacity(int index) {
    final double progress = _entryProgress(index);
    if (progress <= 0) {
      return 0;
    }
    return _clampDouble(0.32 + (progress * 0.68), min: 0, max: 1);
  }

  Offset? _runnerOffset(List<Offset> vertices) {
    final double timeline = _traceProgress;
    if (vertices.isEmpty || timeline >= 0.995) {
      return null;
    }
    final int count = vertices.length;
    final double segment = 1 / count;
    final double raw = timeline / segment;
    final int segmentIndex = raw.floor().clamp(0, count - 1);
    final double local = (raw - segmentIndex).clamp(0.0, 1.0).toDouble();
    final double t = Curves.easeInOut.transform(local);
    final Offset start = vertices[segmentIndex];
    final Offset end = vertices[(segmentIndex + 1) % count];
    return Offset.lerp(start, end, t);
  }

  List<Offset> _traceLinePoints(List<Offset> vertices) {
    if (vertices.isEmpty) {
      return const <Offset>[];
    }
    final double timeline = _traceProgress;
    if (timeline <= 0) {
      return <Offset>[vertices.first];
    }
    final int segmentCount = vertices.length;
    final double segment = 1 / segmentCount;
    final double raw = timeline / segment;
    final int completed = raw.floor().clamp(0, segmentCount);
    final double local = (raw - completed).clamp(0.0, 1.0).toDouble();
    final double t = Curves.easeInOut.transform(local);

    final List<Offset> points = <Offset>[vertices.first];
    for (int i = 0; i < completed; i++) {
      points.add(vertices[(i + 1) % segmentCount]);
    }
    if (completed < segmentCount) {
      final Offset start = vertices[completed % segmentCount];
      final Offset end = vertices[(completed + 1) % segmentCount];
      points.add(Offset.lerp(start, end, t) ?? start);
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double fillReveal = _fillRevealProgress;
        final List<RadarEntry> entries = List<RadarEntry>.generate(
          widget.items.length,
          (int index) => RadarEntry(value: _entryValue(index)),
          growable: false,
        );
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double maxWidth = constraints.maxWidth;
            const double sideLabelWidth = 70;
            const double sideGap = 10;
            const double sideMargin = 8;
            final double maxChartBySide =
                ((maxWidth / 2) - sideLabelWidth - sideGap - sideMargin) / 0.4;
            final double chartSize = _clampDouble(
              _minDouble(300, _minDouble(maxWidth - 30, maxChartBySide)),
              min: 186,
              max: 300,
            );
            final double chartLeft = (maxWidth - chartSize) / 2;
            const double chartTop = 28;
            final double containerHeight = chartSize + 96;
            final double centerX = chartLeft + (chartSize / 2);
            final double centerY = chartTop + (chartSize / 2);
            final double radarRadius = chartSize * 0.4;

            final List<Offset> vertexPoints = <Offset>[
              Offset(centerX, centerY - radarRadius),
              Offset(centerX + radarRadius, centerY),
              Offset(centerX, centerY + radarRadius),
              Offset(centerX - radarRadius, centerY),
            ];
            final List<Offset> tracePoints = _traceLinePoints(vertexPoints);
            final Offset? runner = _runnerOffset(vertexPoints);

            return SizedBox(
              height: containerHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    left: chartLeft,
                    top: chartTop,
                    width: chartSize,
                    height: chartSize,
                    child: RadarChart(
                      RadarChartData(
                        radarShape: RadarShape.polygon,
                        dataSets: <RadarDataSet>[
                          RadarDataSet(
                            dataEntries: entries,
                            fillGradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                AppColors.primary.withValues(
                                  alpha: 0.48 * fillReveal,
                                ),
                                AppColors.goldSoft.withValues(
                                  alpha: 0.30 * fillReveal,
                                ),
                              ],
                            ),
                            fillColor: AppColors.transparent,
                            borderColor: AppColors.primary.withValues(
                              alpha: 0.96 * fillReveal,
                            ),
                            borderWidth: 2.4,
                            entryRadius: 0.01,
                          ),
                        ],
                        tickCount: 1,
                        radarBackgroundColor: AppColors.transparent,
                        radarBorderData: const BorderSide(
                          color: AppColors.transparent,
                          width: 0,
                        ),
                        gridBorderData: const BorderSide(
                          color: AppColors.transparent,
                          width: 0,
                        ),
                        tickBorderData: const BorderSide(
                          color: AppColors.transparent,
                          width: 0,
                        ),
                        ticksTextStyle: AppStyles.caption(
                          color: AppColors.transparent,
                        ),
                        titleTextStyle: AppStyles.caption(
                          color: AppColors.transparent,
                        ),
                        getTitle: (int index, double angle) =>
                            const RadarChartTitle(text: ''),
                        radarTouchData: RadarTouchData(
                          touchSpotThreshold: 34,
                          touchCallback:
                              (
                                FlTouchEvent event,
                                RadarTouchResponse? response,
                              ) {
                                if (event is! FlTapUpEvent) {
                                  return;
                                }
                                final int? index = response
                                    ?.touchedSpot
                                    ?.touchedRadarEntryIndex;
                                if (index == null ||
                                    index < 0 ||
                                    index >= widget.items.length) {
                                  return;
                                }
                                TabNavigationHelper.pushCommonRoute(
                                  AppPages.phaseDetail,
                                  arguments: widget.items[index].args,
                                );
                              },
                        ),
                        borderData: FlBorderData(show: false),
                      ),
                      duration: Duration.zero,
                    ),
                  ),
                  if (tracePoints.length > 1 && _traceLineOpacity > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _TraceLinePainter(
                            points: tracePoints,
                            color: AppColors.primaryLight,
                            opacity: _traceLineOpacity,
                          ),
                        ),
                      ),
                    ),
                  if (runner != null)
                    Positioned(
                      left: runner.dx - 8,
                      top: runner.dy - 8,
                      child: IgnorePointer(
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryLight.withValues(
                              alpha: 0.96,
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: AppColors.primaryLight.withValues(
                                  alpha: 0.45,
                                ),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  for (
                    int index = 0;
                    index < widget.items.length;
                    index++
                  ) ...<Widget>[
                    _VertexMarker(
                      center: vertexPoints[index],
                      isActive:
                          widget.items[index].status == LifeCycleStatus.active,
                      opacity: _vertexOpacity(index),
                      onTap: () => TabNavigationHelper.pushCommonRoute(
                        AppPages.phaseDetail,
                        arguments: widget.items[index].args,
                      ),
                    ),
                    _VertexLabel(
                      item: widget.items[index],
                      center: vertexPoints[index],
                      index: index,
                      chartWidth: maxWidth,
                      sideLabelWidth: sideLabelWidth,
                      opacity: _vertexOpacity(index),
                      onTap: () => TabNavigationHelper.pushCommonRoute(
                        AppPages.phaseDetail,
                        arguments: widget.items[index].args,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TraceLinePainter extends CustomPainter {
  const _TraceLinePainter({
    required this.points,
    required this.color,
    required this.opacity,
  });

  final List<Offset> points;
  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || opacity <= 0) {
      return;
    }
    final Path path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final Paint glow = Paint()
      ..color = color.withValues(alpha: 0.36 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2);

    final Paint line = Paint()
      ..color = color.withValues(alpha: 0.98 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, glow);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _TraceLinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.opacity != opacity ||
        oldDelegate.color != color;
  }
}

class _VertexMarker extends StatelessWidget {
  const _VertexMarker({
    required this.center,
    required this.isActive,
    required this.opacity,
    required this.onTap,
  });

  final Offset center;
  final bool isActive;
  final double opacity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: center.dx - 16,
      top: center.dy - 16,
      child: Opacity(
        opacity: opacity,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            color: AppColors.transparent,
            child: Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.95),
                  width: 2.4,
                ),
                color: isActive
                    ? AppColors.goldBright.withValues(alpha: 0.95)
                    : AppColors.primary.withValues(alpha: 0.82),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.primaryLight.withValues(
                      alpha: isActive ? 0.35 : 0.2,
                    ),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VertexLabel extends StatelessWidget {
  const _VertexLabel({
    required this.item,
    required this.center,
    required this.index,
    required this.chartWidth,
    required this.sideLabelWidth,
    required this.opacity,
    required this.onTap,
  });

  final _RadarChartItem item;
  final Offset center;
  final int index;
  final double chartWidth;
  final double sideLabelWidth;
  final double opacity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final _Placement placement = _placementFor(
      index,
      center,
      chartWidth,
      sideLabelWidth,
    );
    final double safeLeft = _clampLeft(
      left: placement.left,
      width: placement.width,
      maxWidth: chartWidth,
    );
    final double safeTop = placement.top < 0 ? 0 : placement.top;
    return Positioned(
      left: safeLeft,
      top: safeTop,
      width: placement.width,
      child: Opacity(
        opacity: opacity,
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: placement.crossAxisAlignment,
            children: <Widget>[
              Text(
                item.title,
                style: AppStyles.bodySmall(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: placement.textAlign,
              ),
              1.height,
              Text(
                item.periodLabel,
                style: AppStyles.caption(
                  color: AppColors.white.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: placement.textAlign,
              ),
            ],
          ),
        ),
      ),
    );
  }

  _Placement _placementFor(
    int index,
    Offset center,
    double width,
    double sideWidth,
  ) {
    final double topWidth = (width * 0.44).clamp(130.0, 190.0);
    const double sideGap = 18;
    switch (index) {
      case 0:
        return _Placement(
          left: center.dx - (topWidth / 2),
          top: center.dy - 72,
          width: topWidth,
          crossAxisAlignment: CrossAxisAlignment.center,
          textAlign: TextAlign.center,
        );
      case 1:
        return _Placement(
          left: center.dx + sideGap,
          top: center.dy - 22,
          width: sideWidth,
          crossAxisAlignment: CrossAxisAlignment.start,
          textAlign: TextAlign.left,
        );
      case 2:
        return _Placement(
          left: center.dx - (topWidth / 2),
          top: center.dy + 16,
          width: topWidth,
          crossAxisAlignment: CrossAxisAlignment.center,
          textAlign: TextAlign.center,
        );
      default:
        return _Placement(
          left: center.dx - sideWidth - sideGap,
          top: center.dy - 22,
          width: sideWidth,
          crossAxisAlignment: CrossAxisAlignment.end,
          textAlign: TextAlign.right,
        );
    }
  }

  double _clampLeft({
    required double left,
    required double width,
    required double maxWidth,
  }) {
    final double minLeft = 8;
    final double maxLeft = maxWidth - width - 8;
    if (maxLeft <= minLeft) {
      return minLeft;
    }
    return left.clamp(minLeft, maxLeft).toDouble();
  }
}

class _Placement {
  const _Placement({
    required this.left,
    required this.top,
    required this.width,
    required this.crossAxisAlignment,
    required this.textAlign,
  });

  final double left;
  final double top;
  final double width;
  final CrossAxisAlignment crossAxisAlignment;
  final TextAlign textAlign;
}

double _minDouble(double a, double b) => a < b ? a : b;

double _clampDouble(double value, {required double min, required double max}) {
  if (value < min) {
    return min;
  }
  if (value > max) {
    return max;
  }
  return value;
}

class _ActivePhaseChip extends StatelessWidget {
  const _ActivePhaseChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppStyles.caption(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _RadarChartItem {
  const _RadarChartItem({
    required this.code,
    required this.title,
    required this.startAge,
    required this.endAge,
    required this.status,
    required this.args,
  });

  final String code;
  final String title;
  final int startAge;
  final int endAge;
  final LifeCycleStatus status;
  final PhaseDetailStageArgs args;

  String get periodLabel {
    if (endAge >= 999) {
      return '$startAge+ tuổi';
    }
    return '$startAge - $endAge tuổi';
  }
}
