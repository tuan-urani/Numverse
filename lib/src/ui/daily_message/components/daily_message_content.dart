import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/daily_message/interactor/daily_message_state.dart';
import 'package:test/src/ui/widgets/app_mystical_card.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class DailyMessageContent extends StatelessWidget {
  const DailyMessageContent({required this.state, super.key});

  final DailyMessageState state;

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
          _MessageCard(state: state),
          12.height,
          _SoftCard(
            title: LocaleKey.dailyMessageActionTitle.tr,
            icon: Icons.lightbulb_outline,
            body: state.hintAction,
          ),
          12.height,
          _SoftCard(
            title: LocaleKey.dailyMessageReflectionTitle.tr,
            icon: Icons.favorite_border,
            body: state.thinking,
          ),
          12.height,
          _PracticeCard(tips: state.tips),
          16.height,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              LocaleKey.dailyMessageNote.tr,
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

class _MessageCard extends StatefulWidget {
  const _MessageCard({required this.state});

  final DailyMessageState state;

  @override
  State<_MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<_MessageCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AppMysticalCard(
      borderColor: AppColors.richGold.withValues(alpha: 0.4),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.richGold.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.violetAccent.withValues(alpha: 0.1),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? child) {
              final double ringScale = 1 + (_controller.value * 0.25);
              final double ringOpacity = 0.22 * (1 - _controller.value);
              final double iconScale = 0.96 + (_controller.value * 0.08);
              final double sparkleOpacity = 0.55 + (_controller.value * 0.45);

              return Column(
                children: <Widget>[
                  Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Transform.scale(
                        scale: ringScale,
                        child: Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.richGold.withValues(
                              alpha: ringOpacity,
                            ),
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: iconScale,
                        child: Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[
                                AppColors.richGold.withValues(alpha: 0.3),
                                AppColors.violetAccent.withValues(alpha: 0.22),
                              ],
                            ),
                            border: Border.all(
                              color: AppColors.richGold.withValues(alpha: 0.5),
                              width: 2,
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: AppColors.richGold.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            size: 40,
                            color: AppColors.richGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  16.height,
                  _SparkleDivider(opacity: sparkleOpacity),
                  12.height,
                  Text(
                    widget.state.mainMessage,
                    textAlign: TextAlign.center,
                    style: AppStyles.titleLarge(fontWeight: FontWeight.w700),
                  ),
                  10.height,
                  Text(
                    widget.state.subMessage,
                    textAlign: TextAlign.center,
                    style: AppStyles.bodyMedium(color: AppColors.textSecondary),
                  ),
                  12.height,
                  _SparkleDivider(opacity: sparkleOpacity),
                  14.height,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.richGold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.richGold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          LocaleKey.dailyMessageBasedOn.tr,
                          style: AppStyles.caption(color: AppColors.textMuted),
                        ),
                        8.width,
                        Text(
                          '${widget.state.dayNumber}',
                          style: AppStyles.numberSmall(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _SparkleDivider extends StatelessWidget {
  const _SparkleDivider({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 34,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                AppColors.transparent,
                AppColors.richGold.withValues(alpha: 0.5),
              ],
            ),
          ),
        ),
        8.width,
        Icon(
          Icons.auto_awesome,
          size: 14,
          color: AppColors.richGold.withValues(alpha: opacity),
        ),
        8.width,
        Container(
          width: 34,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                AppColors.richGold.withValues(alpha: 0.5),
                AppColors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.title,
    required this.icon,
    required this.body,
  });

  final String title;
  final IconData icon;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 20, color: AppColors.richGold),
                8.width,
                Expanded(
                  child: Text(
                    title,
                    style: AppStyles.h3(
                      fontWeight: FontWeight.w600,
                    ).copyWith(fontSize: 18, height: 1.35),
                  ),
                ),
              ],
            ),
            10.height,
            Text(
              body,
              style: AppStyles.bodyMedium(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({required this.tips});

  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              LocaleKey.dailyMessagePracticeTitle.tr,
              style: AppStyles.h3(
                fontWeight: FontWeight.w600,
              ).copyWith(fontSize: 18, height: 1.35),
            ),
            10.height,
            for (final String tip in tips)
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
                        tip,
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
      ),
    );
  }
}
