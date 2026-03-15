import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/lucky_number/interactor/lucky_number_state.dart';
import 'package:test/src/ui/widgets/app_glow_text.dart';
import 'package:test/src/ui/widgets/app_mystical_card.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class LuckyNumberContent extends StatelessWidget {
  const LuckyNumberContent({required this.state, super.key});

  final LuckyNumberState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      child: Column(
        children: <Widget>[
          Text(
            state.formattedDate,
            textAlign: TextAlign.center,
            style: AppStyles.bodyMedium(color: AppColors.textMuted),
          ),
          16.height,
          _LuckyDisplayCard(state: state),
          12.height,
          _MeaningCard(state: state),
          12.height,
          _UsageCard(howToUse: state.howToUse),
          12.height,
          _SituationsCard(situations: state.situations),
          16.height,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              LocaleKey.luckyNumberNote.tr,
              textAlign: TextAlign.center,
              style: AppStyles.caption(color: AppColors.textMuted),
            ),
          ),
          12.height,
        ],
      ),
    );
  }
}

class _LuckyDisplayCard extends StatefulWidget {
  const _LuckyDisplayCard({required this.state});

  final LuckyNumberState state;

  @override
  State<_LuckyDisplayCard> createState() => _LuckyDisplayCardState();
}

class _LuckyDisplayCardState extends State<_LuckyDisplayCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    final (Color colorA, Color colorB) = _orbColors(widget.state.luckyNumber);

    return AppMysticalCard(
      borderColor: AppColors.richGold.withValues(alpha: 0.4),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.richGold.withValues(alpha: 0.16),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.violetAccent.withValues(alpha: 0.24),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? child) {
              final double starOpacity = 0.55 + (_controller.value * 0.45);
              final double ringScale = 1 + (_controller.value * 0.28);
              final double ringOpacity = 0.24 * (1 - _controller.value);
              final double orbScale = 0.98 + (_controller.value * 0.06);

              return Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.star,
                        size: 20,
                        color: AppColors.richGold.withValues(
                          alpha: starOpacity,
                        ),
                      ),
                      8.width,
                      Text(
                        LocaleKey.luckyNumberTodayLabel.tr,
                        style: AppStyles.bodyMedium(
                          color: AppColors.richGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      8.width,
                      Icon(
                        Icons.star,
                        size: 20,
                        color: AppColors.richGold.withValues(
                          alpha: starOpacity,
                        ),
                      ),
                    ],
                  ),
                  12.height,
                  Transform.scale(
                    scale: orbScale,
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        Transform.scale(
                          scale: ringScale,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.richGold.withValues(
                                alpha: ringOpacity,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[
                                colorA.withValues(alpha: 0.3),
                                colorB.withValues(alpha: 0.22),
                              ],
                            ),
                            border: Border.all(
                              color: AppColors.richGold.withValues(alpha: 0.5),
                              width: 4,
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: AppColors.richGold.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 24,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: AppGlowText(
                            text: '${widget.state.luckyNumber}',
                            style: AppStyles.numberLarge().copyWith(
                              fontSize: 70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  14.height,
                  Text(
                    widget.state.message,
                    textAlign: TextAlign.center,
                    style: AppStyles.bodyMedium(color: AppColors.textSecondary),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  (Color, Color) _orbColors(int number) {
    final Map<int, (Color, Color)> colors = <int, (Color, Color)>{
      1: (AppColors.energyRed, AppColors.energyOrange),
      2: (AppColors.energyOrange, AppColors.energyAmber),
      3: (AppColors.energyYellow, AppColors.energyAmber),
      4: (AppColors.energyGreen, AppColors.energyEmerald),
      5: (AppColors.energyBlue, AppColors.energyCyan),
      6: (AppColors.energyPink, AppColors.energyRose),
      7: (AppColors.energyPurple, AppColors.energyViolet),
      8: (AppColors.energyAmber, AppColors.energyYellow),
      9: (AppColors.energyIndigo, AppColors.energyViolet),
    };
    return colors[number] ?? colors[1]!;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _MeaningCard extends StatelessWidget {
  const _MeaningCard({required this.state});

  final LuckyNumberState state;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.auto_awesome,
                size: 20,
                color: AppColors.richGold,
              ),
              8.width,
              Expanded(
                child: Text(
                  LocaleKey.luckyNumberMeaningTitle.trParams(<String, String>{
                    'number': '${state.luckyNumber}',
                  }),
                  style: AppStyles.h4(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          10.height,
          Text(
            state.title,
            style: AppStyles.bodyMedium(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          8.height,
          Text(
            state.meaning,
            style: AppStyles.bodyMedium(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.howToUse});

  final List<String> howToUse;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            LocaleKey.luckyNumberUsageTitle.tr,
            style: AppStyles.h4(fontWeight: FontWeight.w600),
          ),
          10.height,
          for (final String item in howToUse)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.circle,
                      size: 8,
                      color: AppColors.richGold,
                    ),
                  ),
                  10.width,
                  Expanded(
                    child: Text(
                      item,
                      style: AppStyles.bodyMedium(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SituationsCard extends StatelessWidget {
  const _SituationsCard({required this.situations});

  final List<String> situations;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            LocaleKey.luckyNumberSituationsTitle.tr,
            style: AppStyles.h4(fontWeight: FontWeight.w600),
          ),
          10.height,
          for (final String situation in situations)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.circle,
                      size: 8,
                      color: AppColors.richGold,
                    ),
                  ),
                  10.width,
                  Expanded(
                    child: Text(
                      situation,
                      style: AppStyles.bodyMedium(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}
