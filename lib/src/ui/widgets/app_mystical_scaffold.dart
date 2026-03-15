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
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.appBackgroundGradient()),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: CustomPaint(painter: _SacredPatternPainter()),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _SacredPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint goldPaint = Paint()
      ..color = AppColors.richGold.withValues(alpha: 0.035)
      ..style = PaintingStyle.fill;
    final Paint violetPaint = Paint()
      ..color = AppColors.deepViolet.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    final Paint linePaint = Paint()
      ..color = AppColors.richGold.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.2),
      120,
      goldPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.3),
      160,
      violetPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.22, size.height * 0.8),
      130,
      violetPaint,
    );

    for (double y = 0; y < size.height; y += 6) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
