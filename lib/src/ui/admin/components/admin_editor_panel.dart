import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/widgets/app_primary_button.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class AdminEditorPanel extends StatelessWidget {
  const AdminEditorPanel({
    required this.contentTypeController,
    required this.numberKeyController,
    required this.payloadController,
    required this.isDraftRelease,
    required this.isSaving,
    required this.canSave,
    required this.onContentTypeChanged,
    required this.onNumberKeyChanged,
    required this.onPayloadChanged,
    required this.onSaveTap,
    super.key,
  });

  final TextEditingController contentTypeController;
  final TextEditingController numberKeyController;
  final TextEditingController payloadController;
  final bool isDraftRelease;
  final bool isSaving;
  final bool canSave;
  final ValueChanged<String> onContentTypeChanged;
  final ValueChanged<String> onNumberKeyChanged;
  final ValueChanged<String> onPayloadChanged;
  final VoidCallback onSaveTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                LocaleKey.adminEditorTitle.tr,
                style: AppStyles.h5(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  color: isDraftRelease
                      ? AppColors.richGold.withValues(alpha: 0.15)
                      : AppColors.textMuted.withValues(alpha: 0.2),
                ),
                child: Text(
                  isDraftRelease
                      ? LocaleKey.adminDraftTag.tr
                      : LocaleKey.adminReadOnlyTag.tr,
                  style: AppStyles.caption(
                    color: isDraftRelease
                        ? AppColors.richGold
                        : AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          12.height,
          Text(
            LocaleKey.adminTypeLabel.tr,
            style: AppStyles.caption(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          6.height,
          TextField(
            controller: contentTypeController,
            enabled: isDraftRelease,
            onChanged: onContentTypeChanged,
          ),
          10.height,
          Text(
            LocaleKey.adminNumberKeyLabel.tr,
            style: AppStyles.caption(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          6.height,
          TextField(
            controller: numberKeyController,
            enabled: isDraftRelease,
            onChanged: onNumberKeyChanged,
          ),
          10.height,
          Text(
            LocaleKey.adminPayloadLabel.tr,
            style: AppStyles.caption(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          6.height,
          Expanded(
            child: TextField(
              controller: payloadController,
              enabled: isDraftRelease,
              onChanged: onPayloadChanged,
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
              style: AppStyles.bodySmall(),
              decoration: InputDecoration(
                hintText: '{\n  "title": "..."\n}',
                alignLabelWithHint: true,
              ),
            ),
          ),
          12.height,
          AppPrimaryButton(
            label: isSaving
                ? LocaleKey.commonLoading.tr
                : LocaleKey.adminSaveAction.tr,
            onPressed: isDraftRelease && canSave && !isSaving
                ? onSaveTap
                : null,
          ),
        ],
      ),
    );
  }
}
