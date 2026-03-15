import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/universal_day/interactor/universal_day_state.dart';
import 'package:test/src/ui/widgets/app_glow_text.dart';
import 'package:test/src/ui/widgets/app_mystical_card.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class UniversalDayContent extends StatelessWidget {
  const UniversalDayContent({required this.state, super.key});

  final UniversalDayState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      child: Column(
        children: <Widget>[
          _DateCard(dateText: state.formattedDate),
          16.height,
          _UniversalNumberCard(
            dayNumber: state.dayNumber,
            numberTitle: state.numberTitle,
            keywords: state.keywords,
          ),
          16.height,
          _InsightCard(
            title: LocaleKey.universalDayEnergyThemeTitle.tr,
            icon: Icons.wb_sunny_outlined,
            body: state.energyTheme,
          ),
          12.height,
          _InsightCard(
            title: LocaleKey.universalDayMeaningTitle.tr,
            icon: Icons.auto_awesome,
            body: state.meaning,
          ),
          12.height,
          _InsightCard(
            title: LocaleKey.universalDayManifestationTitle.tr,
            icon: Icons.insights_outlined,
            body: state.energyManifestation,
          ),
          16.height,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              LocaleKey.universalDayInfoNote.tr,
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

class _DateCard extends StatelessWidget {
  const _DateCard({required this.dateText});

  final String dateText;

  @override
  Widget build(BuildContext context) {
    return AppMysticalCard(
      borderColor: AppColors.richGold.withValues(alpha: 0.3),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.calendar_month,
                size: 16,
                color: AppColors.textMuted,
              ),
              8.width,
              Flexible(
                child: Text(
                  dateText,
                  textAlign: TextAlign.center,
                  style: AppStyles.bodyMedium(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          8.height,
          Text(
            LocaleKey.universalDayEnergyLabel.tr,
            style: AppStyles.bodyMedium(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _UniversalNumberCard extends StatelessWidget {
  const _UniversalNumberCard({
    required this.dayNumber,
    required this.numberTitle,
    required this.keywords,
  });

  final int dayNumber;
  final String numberTitle;
  final List<String> keywords;

  @override
  Widget build(BuildContext context) {
    final (Color colorA, Color colorB) = _numberColors(dayNumber);

    return AppMysticalCard(
      borderColor: AppColors.richGold.withValues(alpha: 0.4),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -26,
            right: -16,
            child: Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.richGold.withValues(alpha: 0.18),
              ),
            ),
          ),
          Column(
            children: <Widget>[
              _PulsingNumberOrb(
                dayNumber: dayNumber,
                colorA: colorA,
                colorB: colorB,
              ),
              14.height,
              Text(
                numberTitle,
                textAlign: TextAlign.center,
                style: AppStyles.h2(fontWeight: FontWeight.w700),
              ),
              10.height,
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: keywords.map((String keyword) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.richGold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      keyword,
                      style: AppStyles.caption(
                        color: AppColors.richGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (Color, Color) _numberColors(int number) {
    final Map<int, (Color, Color)> colors = <int, (Color, Color)>{
      1: (AppColors.energyRed, AppColors.energyOrange),
      2: (AppColors.energyBlue, AppColors.energyCyan),
      3: (AppColors.energyYellow, AppColors.energyAmber),
      4: (AppColors.energyGreen, AppColors.energyEmerald),
      5: (AppColors.energyPurple, AppColors.energyPink),
      6: (AppColors.energyPink, AppColors.energyRose),
      7: (AppColors.energyIndigo, AppColors.energyViolet),
      8: (AppColors.energyAmber, AppColors.energyYellow),
      9: (AppColors.energyTeal, AppColors.energyCyan),
    };
    return colors[number] ?? colors[1]!;
  }
}

class _PulsingNumberOrb extends StatefulWidget {
  const _PulsingNumberOrb({
    required this.dayNumber,
    required this.colorA,
    required this.colorB,
  });

  final int dayNumber;
  final Color colorA;
  final Color colorB;

  @override
  State<_PulsingNumberOrb> createState() => _PulsingNumberOrbState();
}

class _PulsingNumberOrbState extends State<_PulsingNumberOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2900),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double scale = 0.97 + (_controller.value * 0.08);
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: 128,
        height: 128,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              widget.colorA.withValues(alpha: 0.26),
              widget.colorB.withValues(alpha: 0.22),
            ],
          ),
          border: Border.all(
            color: AppColors.richGold.withValues(alpha: 0.5),
            width: 4,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.richGold.withValues(alpha: 0.3),
              blurRadius: 22,
              spreadRadius: 1,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: AppGlowText(
          text: '${widget.dayNumber}',
          style: AppStyles.numberLarge().copyWith(fontSize: 56),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.icon,
    required this.body,
  });

  final String title;
  final IconData icon;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 20, color: AppColors.richGold),
              8.width,
              Text(title, style: AppStyles.h4(fontWeight: FontWeight.w600)),
            ],
          ),
          10.height,
          Text(
            body,
            style: AppStyles.bodyMedium(color: AppColors.textSecondary),
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
