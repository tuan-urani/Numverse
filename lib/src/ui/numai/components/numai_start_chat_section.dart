import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/widgets/app_primary_button.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class NumAiStartChatSection extends StatefulWidget {
  const NumAiStartChatSection({
    required this.canStart,
    required this.onStartTap,
    super.key,
  });

  final bool canStart;
  final VoidCallback? onStartTap;

  @override
  State<NumAiStartChatSection> createState() => _NumAiStartChatSectionState();
}

class _NumAiStartChatSectionState extends State<NumAiStartChatSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double scale = widget.canStart
            ? 1 + (math.sin(_controller.value * math.pi) * 0.015)
            : 1;

        return Transform.scale(scale: scale, child: child);
      },
      child: Column(
        children: <Widget>[
          AppPrimaryButton(
            label: widget.canStart
                ? LocaleKey.numaiStartChat.tr
                : LocaleKey.numaiStartChatDisabled.tr,
            onPressed: widget.canStart ? widget.onStartTap : null,
            leading: Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: widget.canStart ? AppColors.midnight : AppColors.textMuted,
            ),
          ),
          if (!widget.canStart) ...<Widget>[
            10.height,
            Text(
              LocaleKey.numaiNotEnoughStart.tr,
              textAlign: TextAlign.center,
              style: AppStyles.caption(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}
