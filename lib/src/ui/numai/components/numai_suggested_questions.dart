import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/numai/interactor/numai_state.dart';
import 'package:test/src/ui/widgets/app_mystical_card.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class NumAiSuggestedQuestions extends StatelessWidget {
  const NumAiSuggestedQuestions({
    required this.questions,
    required this.hasAnyProfile,
    required this.onQuestionTap,
    super.key,
  });

  final List<NumAiSuggestedQuestion> questions;
  final bool hasAnyProfile;
  final ValueChanged<NumAiSuggestedQuestion> onQuestionTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          LocaleKey.numaiSuggestedTitle.tr.toUpperCase(),
          style: AppStyles.caption(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        10.height,
        ...questions.map(
          (NumAiSuggestedQuestion question) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppMysticalCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              borderColor: AppColors.border.withValues(alpha: 0.68),
              onTap: () => onQuestionTap(question),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: AppColors.richGold,
                  ),
                  10.width,
                  Expanded(
                    child: Text(
                      question.textKey.tr,
                      style: AppStyles.bodySmall(color: AppColors.textPrimary),
                    ),
                  ),
                  if (question.needsProfile && !hasAnyProfile)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.richGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.richGold.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Text(
                        LocaleKey.numaiNeedProfileTag.tr,
                        style: AppStyles.caption(
                          color: AppColors.richGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
