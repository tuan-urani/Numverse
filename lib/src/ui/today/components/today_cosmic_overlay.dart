import 'package:flutter/material.dart';

import 'package:test/src/utils/app_colors.dart';

class TodayCosmicOverlay extends StatelessWidget {
  const TodayCosmicOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    AppColors.nebulaMagenta.withValues(alpha: 0.04),
                    AppColors.transparent,
                    AppColors.cosmicPurple.withValues(alpha: 0.05),
                  ],
                  stops: const <double>[0, 0.46, 1],
                ),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _TodaySideStarPainter())),
        ],
      ),
    );
  }
}

class _TodaySideStarPainter extends CustomPainter {
  static const int _starCount = 92;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect fullRect = Offset.zero & size;
    final Paint leftGlowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.9, -0.2),
        radius: 0.82,
        colors: <Color>[
          AppColors.nebulaMagenta.withValues(alpha: 0.22),
          AppColors.transparent,
        ],
      ).createShader(fullRect);
    final Paint rightGlowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(1, 0.2),
        radius: 0.76,
        colors: <Color>[
          AppColors.cosmicPurple.withValues(alpha: 0.24),
          AppColors.transparent,
        ],
      ).createShader(fullRect);

    canvas.drawRect(fullRect, leftGlowPaint);
    canvas.drawRect(fullRect, rightGlowPaint);

    final Paint starPaint = Paint()..style = PaintingStyle.fill;
    final Paint glowPaint = Paint()..style = PaintingStyle.fill;
    final Paint sparklePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.9;

    for (int index = 0; index < _starCount; index++) {
      final bool leftBand = index.isEven;
      final double horizontalSeed =
          (((index * 29) + (index * index * 5)) % 1000) / 1000;
      final double verticalSeed =
          (((index * 83) + (index * index * 7)) % 1000) / 1000;
      final double sideOffset = 0.06 + (horizontalSeed * 0.22);
      final double normalizedX = leftBand ? sideOffset : 1 - sideOffset;
      final Offset center = Offset(
        size.width * normalizedX,
        size.height * verticalSeed,
      );

      final bool accentStar = index % 11 == 0;
      final double radius = accentStar ? 1.2 : 0.62 + ((index % 3) * 0.2);
      starPaint.color = (accentStar ? AppColors.starlight : AppColors.white)
          .withValues(alpha: accentStar ? 0.74 : 0.4);
      canvas.drawCircle(center, radius, starPaint);

      if (!accentStar) {
        continue;
      }

      glowPaint.color = AppColors.richGold.withValues(alpha: 0.12);
      canvas.drawCircle(center, radius * 4.8, glowPaint);

      sparklePaint.color = AppColors.starlight.withValues(alpha: 0.56);
      canvas.drawLine(
        Offset(center.dx - 2.4, center.dy),
        Offset(center.dx + 2.4, center.dy),
        sparklePaint,
      );
      canvas.drawLine(
        Offset(center.dx, center.dy - 2.4),
        Offset(center.dx, center.dy + 2.4),
        sparklePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
