import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class NumAiChatInputBar extends StatelessWidget {
  const NumAiChatInputBar({
    required this.controller,
    required this.isLoading,
    required this.canAffordMessage,
    required this.showInsufficientPointsWarning,
    required this.onTextChanged,
    required this.onSendTap,
    required this.onClearTap,
    super.key,
  });

  final TextEditingController controller;
  final bool isLoading;
  final bool canAffordMessage;
  final bool showInsufficientPointsWarning;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onSendTap;
  final VoidCallback onClearTap;

  @override
  Widget build(BuildContext context) {
    final bool canSend = controller.text.trim().isNotEmpty && !isLoading;
    final bool shouldShowWarning =
        showInsufficientPointsWarning || !canAffordMessage;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        12 + Get.mediaQuery.padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.86),
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.55)),
        ),
      ),
      child: Column(
        children: <Widget>[
          if (shouldShowWarning) ...<Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                LocaleKey.numaiChatInsufficientWarning.tr,
                style: AppStyles.caption(color: AppColors.error),
              ),
            ),
            10.height,
          ],
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onChanged: onTextChanged,
                  onSubmitted: (_) {
                    if (canSend) {
                      onSendTap();
                    }
                  },
                  style: AppStyles.bodyMedium(),
                  decoration: InputDecoration(
                    hintText: LocaleKey.numaiChatHint.tr,
                    hintStyle: AppStyles.bodyMedium(color: AppColors.textMuted),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: AppColors.deepViolet.withValues(alpha: 0.48),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.7),
                        width: 1.1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.7),
                        width: 1.1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.richGold,
                        width: 1.4,
                      ),
                    ),
                    suffixIcon: controller.text.isEmpty
                        ? null
                        : InkWell(
                            onTap: onClearTap,
                            borderRadius: BorderRadius.circular(999),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                    suffixIconConstraints: const BoxConstraints(
                      minHeight: 0,
                      minWidth: 0,
                    ),
                  ),
                ),
              ),
              8.width,
              InkWell(
                onTap: canSend ? onSendTap : null,
                borderRadius: BorderRadius.circular(12),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: canSend ? 1 : 0.48,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient(),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppColors.richGold.withValues(alpha: 0.24),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      size: 20,
                      color: AppColors.midnight,
                    ),
                  ),
                ),
              ),
            ],
          ),
          6.height,
          Text(
            canAffordMessage
                ? LocaleKey.numaiChatCostLabel.tr
                : LocaleKey.numaiChatNoPoints.tr,
            style: AppStyles.caption(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
