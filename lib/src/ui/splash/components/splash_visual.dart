import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class SplashVisual extends StatelessWidget {
  const SplashVisual({
    required this.outerRingAnimation,
    required this.middleRingAnimation,
    required this.glowAnimation,
    required this.dotAnimation,
    super.key,
  });

  final Animation<double> outerRingAnimation;
  final Animation<double> middleRingAnimation;
  final Animation<double> glowAnimation;
  final Animation<double> dotAnimation;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        const Positioned.fill(child: _BackgroundGradient()),
        const Positioned.fill(child: _PatternLayer()),
        Positioned(
          top: 80,
          left: 80,
          child: _PulsingOrb(
            size: 128,
            color: AppColors.richGold.withValues(alpha: 0.2),
            animation: glowAnimation,
          ),
        ),
        Positioned(
          bottom: 80,
          right: 80,
          child: _PulsingOrb(
            size: 160,
            color: AppColors.richGold.withValues(alpha: 0.1),
            animation: glowAnimation,
            delay: 0.35,
          ),
        ),
        Center(
          child: _CenterBrandSection(
            outerRingAnimation: outerRingAnimation,
            middleRingAnimation: middleRingAnimation,
            glowAnimation: glowAnimation,
            dotAnimation: dotAnimation,
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 48,
          child: _BottomGlyphDivider(),
        ),
      ],
    );
  }
}

class _BackgroundGradient extends StatelessWidget {
  const _BackgroundGradient();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.midnight,
            AppColors.deepViolet,
            AppColors.midnight,
          ],
          stops: <double>[0, 0.5, 1],
        ),
      ),
    );
  }
}

class _PatternLayer extends StatelessWidget {
  const _PatternLayer();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: CustomPaint(painter: _SplashPatternPainter()));
  }
}

class _CenterBrandSection extends StatelessWidget {
  const _CenterBrandSection({
    required this.outerRingAnimation,
    required this.middleRingAnimation,
    required this.glowAnimation,
    required this.dotAnimation,
  });

  final Animation<double> outerRingAnimation;
  final Animation<double> middleRingAnimation;
  final Animation<double> glowAnimation;
  final Animation<double> dotAnimation;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _LogoOrb(
          outerRingAnimation: outerRingAnimation,
          middleRingAnimation: middleRingAnimation,
          glowAnimation: glowAnimation,
        ),
        32.height,
        Text(
          'Numverse',
          style:
              AppStyles.h40(
                color: AppColors.richGold,
                fontWeight: FontWeight.w700,
              ).copyWith(
                letterSpacing: 0.6,
                shadows: <Shadow>[
                  Shadow(
                    color: AppColors.richGold.withValues(alpha: 0.8),
                    blurRadius: 10,
                  ),
                  Shadow(
                    color: AppColors.richGold.withValues(alpha: 0.6),
                    blurRadius: 20,
                  ),
                ],
              ),
        ),
        12.height,
        Text(
          LocaleKey.splashTagline.tr.toUpperCase(),
          style: AppStyles.caption(
            color: AppColors.textPrimary.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ).copyWith(letterSpacing: 2.4, height: 1.2),
        ),
        24.height,
        _BouncingDots(animation: dotAnimation),
      ],
    );
  }
}

class _LogoOrb extends StatelessWidget {
  const _LogoOrb({
    required this.outerRingAnimation,
    required this.middleRingAnimation,
    required this.glowAnimation,
  });

  final Animation<double> outerRingAnimation;
  final Animation<double> middleRingAnimation;
  final Animation<double> glowAnimation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      height: 128,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          AnimatedBuilder(
            animation: outerRingAnimation,
            builder: (BuildContext context, Widget? child) {
              return Transform.rotate(
                angle: outerRingAnimation.value * math.pi * 2,
                child: child,
              );
            },
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.richGold.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: middleRingAnimation,
            builder: (BuildContext context, Widget? child) {
              return Transform.rotate(
                angle: -middleRingAnimation.value * math.pi * 2,
                child: child,
              );
            },
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.richGold.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: glowAnimation,
            builder: (BuildContext context, Widget? child) {
              final double pulse = 0.94 + (glowAnimation.value * 0.12);
              return Transform.scale(scale: pulse, child: child);
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.richGold.withValues(alpha: 0.2),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.richGold.withValues(alpha: 0.35),
                    blurRadius: 28,
                  ),
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: glowAnimation,
            builder: (BuildContext context, Widget? child) {
              final double intensity = 0.45 + (glowAnimation.value * 0.55);
              return Icon(
                Icons.auto_awesome,
                size: 48,
                color: AppColors.richGold,
                shadows: <Shadow>[
                  Shadow(
                    color: AppColors.richGold.withValues(alpha: intensity),
                    blurRadius: 20,
                  ),
                  Shadow(
                    color: AppColors.richGold.withValues(
                      alpha: intensity * 0.7,
                    ),
                    blurRadius: 34,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BouncingDots extends StatelessWidget {
  const _BouncingDots({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(3, (int index) {
            final double phase = (animation.value + (index * 0.17)) % 1;
            final double bounce = math.sin(phase * math.pi);
            return Padding(
              padding: EdgeInsets.only(right: index == 2 ? 0 : 8),
              child: Transform.translate(
                offset: Offset(0, -bounce * 7),
                child: Opacity(
                  opacity: 0.5 + (bounce * 0.5),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.richGold,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _BottomGlyphDivider extends StatelessWidget {
  const _BottomGlyphDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 48,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                AppColors.transparent,
                AppColors.richGold.withValues(alpha: 0.75),
              ],
            ),
          ),
        ),
        16.width,
        Icon(
          Icons.auto_awesome,
          size: 10,
          color: AppColors.richGold.withValues(alpha: 0.75),
        ),
        16.width,
        Container(
          width: 48,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                AppColors.richGold.withValues(alpha: 0.75),
                AppColors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SplashPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect fullRect = Offset.zero & size;
    final Paint leftPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.6, 0),
        radius: 0.6,
        colors: <Color>[Color(0x1AD4AF37), AppColors.transparent],
      ).createShader(fullRect);
    final Paint rightPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.6, 0),
        radius: 0.6,
        colors: <Color>[Color(0x1A1E1438), AppColors.transparent],
      ).createShader(fullRect);

    canvas.drawRect(fullRect, leftPaint);
    canvas.drawRect(fullRect, rightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PulsingOrb extends StatelessWidget {
  const _PulsingOrb({
    required this.size,
    required this.color,
    required this.animation,
    this.delay = 0,
  });

  final double size;
  final Color color;
  final Animation<double> animation;
  final double delay;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          final double phase = (animation.value + delay) % 1;
          final double pulse = 0.92 + (math.sin(phase * math.pi) * 0.1);
          return Transform.scale(scale: pulse, child: child);
        },
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ),
      ),
    );
  }
}
