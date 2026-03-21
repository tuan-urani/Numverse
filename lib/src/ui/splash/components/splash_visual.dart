import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/utils/app_assets.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class SplashVisual extends StatelessWidget {
  const SplashVisual({
    required this.glowAnimation,
    required this.dotAnimation,
    super.key,
  });

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
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AppColors.midnight,
            AppColors.cosmicIndigo,
            AppColors.deepViolet,
            AppColors.midnightSoft,
          ],
          stops: <double>[0, 0.36, 0.74, 1],
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
    required this.glowAnimation,
    required this.dotAnimation,
  });

  final Animation<double> glowAnimation;
  final Animation<double> dotAnimation;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _LogoOrb(glowAnimation: glowAnimation),
        16.height,
        Text(
          'NumVerse',
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
  const _LogoOrb({required this.glowAnimation});

  final Animation<double> glowAnimation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowAnimation,
      child: SvgPicture.asset(
        AppAssets.iconNumerologySvg,
        width: 136,
        height: 136,
        fit: BoxFit.contain,
        colorFilter: const ColorFilter.mode(
          AppColors.richGold,
          BlendMode.srcIn,
        ),
      ),
      builder: (BuildContext context, Widget? child) {
        final double scale = 1.02 + (glowAnimation.value * 0.14);
        final double glowAlpha = 0.08 + (glowAnimation.value * 0.08);
        return Transform.scale(
          scale: scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.richGold.withValues(alpha: glowAlpha),
                  blurRadius: 12,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
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
  static const int _starCount = 96;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect fullRect = Offset.zero & size;
    final Paint topLeftNebulaPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.72, -0.78),
        radius: 0.96,
        colors: <Color>[
          AppColors.cosmicPurple.withValues(alpha: 0.24),
          AppColors.transparent,
        ],
      ).createShader(fullRect);
    final Paint topRightNebulaPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.84, -0.2),
        radius: 0.86,
        colors: <Color>[
          AppColors.deepViolet.withValues(alpha: 0.3),
          AppColors.transparent,
        ],
      ).createShader(fullRect);
    final Paint bottomNebulaPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.16, 1.05),
        radius: 0.98,
        colors: <Color>[
          AppColors.cosmicIndigo.withValues(alpha: 0.34),
          AppColors.transparent,
        ],
      ).createShader(fullRect);

    canvas.drawRect(fullRect, topLeftNebulaPaint);
    canvas.drawRect(fullRect, topRightNebulaPaint);
    canvas.drawRect(fullRect, bottomNebulaPaint);

    final Paint starPaint = Paint()..style = PaintingStyle.fill;
    final Paint glowPaint = Paint()..style = PaintingStyle.fill;
    for (int index = 0; index < _starCount; index++) {
      final double dx =
          (((index * 41) + (index * index * 9)) % 1000) / 1000 * size.width;
      final double dy =
          (((index * 79) + (index * index * 5)) % 1000) / 1000 * size.height;
      final bool accentStar = index % 12 == 0;
      final double radius = accentStar ? 1.1 : 0.56;

      starPaint.color = (accentStar ? AppColors.starlight : AppColors.white)
          .withValues(alpha: accentStar ? 0.74 : 0.4);
      canvas.drawCircle(Offset(dx, dy), radius, starPaint);

      if (accentStar) {
        glowPaint.color = AppColors.richGold.withValues(alpha: 0.16);
        canvas.drawCircle(Offset(dx, dy), radius * 5.2, glowPaint);
      }
    }
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
