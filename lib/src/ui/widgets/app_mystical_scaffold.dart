import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:test/src/utils/app_colors.dart';

class AppMysticalScaffold extends StatelessWidget {
  const AppMysticalScaffold({
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    super.key,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.appBackgroundGradient(),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.nebulaOverlayGradient(),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _SacredPatternPainter()),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _SacredPatternPainter extends CustomPainter {
  static const int _starCount = 176;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect fullRect = Offset.zero & size;

    final Paint leftNebulaPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.72, -0.82),
        radius: 0.92,
        colors: <Color>[
          AppColors.nebulaMagenta.withValues(alpha: 0.32),
          AppColors.transparent,
        ],
      ).createShader(fullRect);
    final Paint rightNebulaPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.86, -0.2),
        radius: 0.84,
        colors: <Color>[
          AppColors.cosmicPurple.withValues(alpha: 0.3),
          AppColors.transparent,
        ],
      ).createShader(fullRect);
    final Paint lowerNebulaPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.18, 1),
        radius: 1,
        colors: <Color>[
          AppColors.deepViolet.withValues(alpha: 0.38),
          AppColors.transparent,
        ],
      ).createShader(fullRect);

    canvas.drawRect(fullRect, leftNebulaPaint);
    canvas.drawRect(fullRect, rightNebulaPaint);
    canvas.drawRect(fullRect, lowerNebulaPaint);

    final Paint starPaint = Paint()..style = PaintingStyle.fill;
    final Paint glowPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < _starCount; i++) {
      final double dx = (((i * 53) + (i * i * 3)) % 1000) / 1000 * size.width;
      final double dy = (((i * 97) + (i * i * 7)) % 1000) / 1000 * size.height;
      final double radius = 0.35 + ((i % 4) * 0.2);
      final bool isAccent = i % 13 == 0;

      starPaint.color = (isAccent ? AppColors.starlight : AppColors.white)
          .withValues(alpha: isAccent ? 0.72 : 0.33);
      canvas.drawCircle(Offset(dx, dy), radius, starPaint);

      if (isAccent) {
        glowPaint.color = AppColors.richGold.withValues(alpha: 0.12);
        canvas.drawCircle(Offset(dx, dy), radius * 4.5, glowPaint);
      }
    }

    final Paint orbitPaint = Paint()
      ..color = AppColors.richGold.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.28),
        radius: math.min(size.width * 0.45, 210),
      ),
      math.pi * 0.12,
      math.pi * 1.3,
      false,
      orbitPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.32, size.height * 0.82),
        radius: math.min(size.width * 0.58, 260),
      ),
      -math.pi * 0.2,
      math.pi * 0.9,
      false,
      orbitPaint,
    );

    final Paint shimmerLinePaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 14) {
      canvas.drawLine(
        Offset(size.width * 0.08, y),
        Offset(size.width * 0.92, y + 2),
        shimmerLinePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
