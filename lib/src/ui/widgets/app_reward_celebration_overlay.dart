import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_dimensions.dart';
import 'package:test/src/utils/app_styles.dart';
import 'package:test/src/ui/widgets/app_text_gradient.dart';

import 'dart:math' as math;

class AppRewardCelebrationOverlay {
  const AppRewardCelebrationOverlay._();

  static OverlayEntry? _activeEntry;

  static void show(
    BuildContext context, {
    required int reward,
    required String title,
    String? subtitle,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    final int safeReward = reward.clamp(0, 9999);
    if (safeReward <= 0) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _activeEntry?.remove();
      final OverlayState? overlayState = Overlay.maybeOf(
        context,
        rootOverlay: true,
      );
      if (overlayState == null) {
        return;
      }
      final OverlayEntry entry = OverlayEntry(
        builder: (BuildContext context) {
          return _RewardCelebrationLayer(
            reward: safeReward,
            title: title,
            subtitle: subtitle,
            duration: duration,
          );
        },
      );

      overlayState.insert(entry);
      _activeEntry = entry;

      Future<void>.delayed(duration, () {
        if (_activeEntry == entry) {
          entry.remove();
          _activeEntry = null;
        }
      });
    });
  }
}

class _RewardCelebrationLayer extends StatefulWidget {
  const _RewardCelebrationLayer({
    required this.reward,
    required this.title,
    required this.subtitle,
    required this.duration,
  });

  final int reward;
  final String title;
  final String? subtitle;
  final Duration duration;

  @override
  State<_RewardCelebrationLayer> createState() =>
      _RewardCelebrationLayerState();
}

class _RewardCelebrationLayerState extends State<_RewardCelebrationLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _timeline = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();

  late final Animation<double> _overlayOpacity =
      TweenSequence<double>(<TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(
            begin: 0,
            end: 1,
          ).chain(CurveTween(curve: Curves.easeOutCubic)),
          weight: 16,
        ),
        TweenSequenceItem<double>(tween: ConstantTween<double>(1), weight: 62),
        TweenSequenceItem<double>(
          tween: Tween<double>(
            begin: 1,
            end: 0,
          ).chain(CurveTween(curve: Curves.easeInCubic)),
          weight: 22,
        ),
      ]).animate(_timeline);

  late final Animation<double> _cardScale =
      TweenSequence<double>(<TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(
            begin: 0.82,
            end: 1.06,
          ).chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 22,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(
            begin: 1.06,
            end: 1,
          ).chain(CurveTween(curve: Curves.easeOutQuad)),
          weight: 18,
        ),
        TweenSequenceItem<double>(tween: ConstantTween<double>(1), weight: 44),
        TweenSequenceItem<double>(
          tween: Tween<double>(
            begin: 1,
            end: 0.95,
          ).chain(CurveTween(curve: Curves.easeInQuad)),
          weight: 16,
        ),
      ]).animate(_timeline);

  late final Animation<double> _cardOpacity =
      TweenSequence<double>(<TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(
            begin: 0,
            end: 1,
          ).chain(CurveTween(curve: Curves.easeOut)),
          weight: 20,
        ),
        TweenSequenceItem<double>(tween: ConstantTween<double>(1), weight: 58),
        TweenSequenceItem<double>(
          tween: Tween<double>(
            begin: 1,
            end: 0,
          ).chain(CurveTween(curve: Curves.easeIn)),
          weight: 22,
        ),
      ]).animate(_timeline);

  @override
  void dispose() {
    _timeline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _timeline,
          builder: (BuildContext context, Widget? child) {
            return Material(
              color: AppColors.midnight.withValues(
                alpha: 0.82 * _overlayOpacity.value,
              ),
              child: Center(
                child: Opacity(
                  opacity: _cardOpacity.value,
                  child: Transform.scale(
                    scale: _cardScale.value,
                    child: _RewardCelebrationCard(
                      reward: widget.reward,
                      title: widget.title,
                      subtitle: widget.subtitle,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RewardCelebrationCard extends StatelessWidget {
  const _RewardCelebrationCard({
    required this.reward,
    required this.title,
    required this.subtitle,
  });

  final int reward;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDimensions.xxl * 12,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    AppColors.richGold.withValues(alpha: 0.28),
                    AppColors.goldSoft.withValues(alpha: 0.16),
                    AppColors.transparent,
                  ],
                  stops: const <double>[0, 0.42, 1],
                ),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _RewardSparklePainter())),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  AppColors.midnightSoft.withValues(alpha: 0.98),
                  AppColors.deepViolet.withValues(alpha: 0.97),
                  AppColors.cosmicIndigo.withValues(alpha: 0.98),
                ],
                stops: const <double>[0, 0.56, 1],
              ),
              borderRadius: AppDimensions.radiusXl.toInt().borderRadiusAll,
              border: Border.all(
                color: AppColors.richGold.withValues(alpha: 0.58),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.richGold.withValues(alpha: 0.28),
                  blurRadius: AppDimensions.xxl * 2.1,
                  spreadRadius: AppDimensions.xs / 2,
                ),
                BoxShadow(
                  color: AppColors.cosmicPurple.withValues(alpha: 0.42),
                  blurRadius: AppDimensions.xxl * 1.2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimensions.xl,
                AppDimensions.lg + AppDimensions.xs,
                AppDimensions.xl,
                AppDimensions.lg + AppDimensions.xs,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const _RewardMedal(),
                  AppDimensions.md.toInt().height,
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppStyles.h4(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  AppDimensions.sm.toInt().height,
                  AppTextGradient(
                    text: '+$reward ${LocaleKey.todayRewardPointsSuffix.tr}',
                    textAlign: TextAlign.center,
                    gradient: AppColors.goldTextGradient(),
                    style: AppStyles.numberMedium(
                      color: AppColors.richGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if ((subtitle ?? '').trim().isNotEmpty) ...<Widget>[
                    AppDimensions.sm.toInt().height,
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      style: AppStyles.bodySmall(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
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

class _RewardMedal extends StatelessWidget {
  const _RewardMedal();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDimensions.touchTarget + AppDimensions.lg,
      height: AppDimensions.touchTarget + AppDimensions.lg,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  AppColors.starlight.withValues(alpha: 0.92),
                  AppColors.goldBright.withValues(alpha: 0.75),
                  AppColors.richGold.withValues(alpha: 0.45),
                ],
                stops: const <double>[0, 0.58, 1],
              ),
              border: Border.all(
                color: AppColors.starlight.withValues(alpha: 0.82),
              ),
            ),
            child: SizedBox(
              width: AppDimensions.touchTarget,
              height: AppDimensions.touchTarget,
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: AppDimensions.iconLarge,
                color: AppColors.white,
              ),
            ),
          ),
          // Positioned(
          //   left: -AppDimensions.lg,
          //   top: AppDimensions.sm,
          //   child: const Icon(
          //     Icons.star_rounded,
          //     color: AppColors.starlight,
          //     size: AppDimensions.iconSmall,
          //   ),
          // ),
          // Positioned(
          //   right: -AppDimensions.md,
          //   top: AppDimensions.xs,
          //   child: const Icon(
          //     Icons.star_rounded,
          //     color: AppColors.goldSoft,
          //     size: AppDimensions.iconMedium,
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _RewardSparklePainter extends CustomPainter {
  const _RewardSparklePainter();

  static const int _sparkleCount = 18;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint dotPaint = Paint()..style = PaintingStyle.fill;
    final Paint beamPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double baseRadius = size.shortestSide * 0.34;

    for (int index = 0; index < _sparkleCount; index++) {
      final double seed = (index + 1) / _sparkleCount;
      final double angle = math.pi * 2 * seed;
      final double orbit = baseRadius + (math.sin(angle * 2.2) * 8);
      final Offset point = Offset(
        center.dx + (math.cos(angle) * orbit),
        center.dy + (math.sin(angle) * orbit * 0.72),
      );
      final bool highlight = index.isEven;

      dotPaint.color = (highlight ? AppColors.starlight : AppColors.goldSoft)
          .withValues(alpha: highlight ? 0.78 : 0.56);
      final double radius = highlight ? 2.4 : 1.6;
      canvas.drawCircle(point, radius, dotPaint);

      if (!highlight) {
        continue;
      }

      beamPaint
        ..color = AppColors.richGold.withValues(alpha: 0.42)
        ..strokeWidth = 1.2;
      canvas.drawLine(
        Offset(point.dx - 3, point.dy),
        Offset(point.dx + 3, point.dy),
        beamPaint,
      );
      canvas.drawLine(
        Offset(point.dx, point.dy - 3),
        Offset(point.dx, point.dy + 3),
        beamPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
