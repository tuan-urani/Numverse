import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/help/interactor/help_state.dart';
import 'package:test/src/ui/widgets/app_mystical_card.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class HelpFaqSection extends StatelessWidget {
  const HelpFaqSection({
    required this.state,
    required this.onToggleFaq,
    super.key,
  });

  final HelpState state;
  final ValueChanged<int> onToggleFaq;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            LocaleKey.helpFaqSectionTitle.tr,
            style: AppStyles.h5(fontWeight: FontWeight.w700),
          ),
        ),
        10.height,
        for (int index = 0; index < state.faqs.length; index++) ...<Widget>[
          _FaqCard(
            item: state.faqs[index],
            expanded: state.expandedFaqId == state.faqs[index].id,
            onTap: () => onToggleFaq(state.faqs[index].id),
          ),
          if (index != state.faqs.length - 1) 8.height,
        ],
      ],
    );
  }
}

class _FaqCard extends StatelessWidget {
  const _FaqCard({
    required this.item,
    required this.expanded,
    required this.onTap,
  });

  final HelpFaqItem item;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppMysticalCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderColor: AppColors.border.withValues(alpha: 0.65),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.help_outline_rounded,
              size: 18,
              color: AppColors.richGold,
            ),
          ),
          10.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.questionKey.tr,
                  style: AppStyles.bodySmall(fontWeight: FontWeight.w600),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: expanded
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            item.answerKey.tr,
                            style: AppStyles.bodySmall(
                              color: AppColors.textMuted,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          8.width,
          AnimatedRotation(
            turns: expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 220),
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
