import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/widgets/app_mystical_card.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class NumAiHeroCard extends StatefulWidget {
  const NumAiHeroCard({super.key});

  @override
  State<NumAiHeroCard> createState() => _NumAiHeroCardState();
}

class _NumAiHeroCardState extends State<NumAiHeroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppMysticalCard(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            final double value = _controller.value;
            final double topRightDx = math.sin(value * math.pi * 2) * 12;
            final double topRightDy = math.cos(value * math.pi * 2) * 8;
            final double bottomLeftDx = math.cos(value * math.pi * 2) * 10;
            final double bottomLeftDy = math.sin(value * math.pi * 2) * 7;
            final double iconScale =
                0.95 + (math.sin(value * math.pi * 2) * 0.08);

            return Stack(
              children: <Widget>[
                Positioned(
                  right: -28 + topRightDx,
                  top: -30 + topRightDy,
                  child: _GlowOrb(
                    size: 150,
                    color: AppColors.richGold.withValues(alpha: 0.16),
                  ),
                ),
                Positioned(
                  left: -24 + bottomLeftDx,
                  bottom: -36 + bottomLeftDy,
                  child: _GlowOrb(
                    size: 128,
                    color: AppColors.violetAccent.withValues(alpha: 0.2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  child: Column(
                    children: <Widget>[
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              AppColors.richGold.withValues(alpha: 0.28),
                              AppColors.deepViolet.withValues(alpha: 0.45),
                            ],
                          ),
                          border: Border.all(
                            color: AppColors.richGold.withValues(alpha: 0.38),
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppColors.richGold.withValues(alpha: 0.2),
                              blurRadius: 26,
                            ),
                          ],
                        ),
                        child: Transform.scale(
                          scale: iconScale,
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 40,
                            color: AppColors.richGold,
                          ),
                        ),
                      ),
                      16.height,
                      Text(
                        LocaleKey.numaiHeroTitle.tr,
                        textAlign: TextAlign.center,
                        style: AppStyles.h3(fontWeight: FontWeight.w700),
                      ),
                      8.height,
                      Text(
                        LocaleKey.numaiHeroBody.tr,
                        textAlign: TextAlign.center,
                        style: AppStyles.bodySmall(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: <BoxShadow>[BoxShadow(color: color, blurRadius: 60)],
        ),
      ),
    );
  }
}
