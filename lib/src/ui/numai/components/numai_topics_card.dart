import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/numai/interactor/numai_state.dart';
import 'package:test/src/ui/widgets/app_mystical_card.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class NumAiTopicsCard extends StatelessWidget {
  const NumAiTopicsCard({required this.topics, super.key});

  final List<NumAiAskTopic> topics;

  @override
  Widget build(BuildContext context) {
    return AppMysticalCard(
      borderColor: AppColors.border.withValues(alpha: 0.75),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            LocaleKey.numaiAskTopicsTitle.tr,
            style: AppStyles.h5(fontWeight: FontWeight.w600),
          ),
          14.height,
          for (int index = 0; index < topics.length; index++) ...<Widget>[
            _TopicRow(topic: topics[index]),
            if (index != topics.length - 1) 12.height,
          ],
        ],
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.topic});

  final NumAiAskTopic topic;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.richGold.withValues(alpha: 0.16),
            border: Border.all(
              color: AppColors.richGold.withValues(alpha: 0.3),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            topic.iconSymbol,
            style: AppStyles.caption(
              color: AppColors.richGold,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        10.width,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                topic.titleKey.tr,
                style: AppStyles.bodySmall(fontWeight: FontWeight.w600),
              ),
              2.height,
              Text(
                topic.descriptionKey.tr,
                style: AppStyles.caption(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
