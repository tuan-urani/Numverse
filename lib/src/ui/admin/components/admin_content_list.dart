import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/core/model/admin_ledger_content.dart';
import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class AdminContentList extends StatelessWidget {
  const AdminContentList({
    required this.contents,
    required this.selectedContentId,
    required this.onSelectContent,
    super.key,
  });

  final List<AdminLedgerContent> contents;
  final String? selectedContentId;
  final ValueChanged<String> onSelectContent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: <Widget>[
                Text(
                  LocaleKey.adminContentsTitle.tr,
                  style: AppStyles.h5(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  '${contents.length}',
                  style: AppStyles.caption(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: contents.isEmpty
                ? Center(
                    child: Text(
                      LocaleKey.adminEmptyContents.tr,
                      style: AppStyles.bodySmall(color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    itemCount: contents.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (BuildContext context, int index) {
                      final AdminLedgerContent item = contents[index];
                      final bool isSelected = item.id == selectedContentId;
                      return InkWell(
                        onTap: () => onSelectContent(item.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          color: isSelected
                              ? AppColors.richGold.withValues(alpha: 0.16)
                              : AppColors.transparent,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                '${item.contentType} / ${item.numberKey}',
                                style: AppStyles.bodySmall(
                                  color: isSelected
                                      ? AppColors.richGold
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              4.height,
                              Text(
                                item.updatedAt == null
                                    ? '-'
                                    : item.updatedAt!
                                          .toLocal()
                                          .toIso8601String()
                                          .replaceFirst('T', ' ')
                                          .split('.')
                                          .first,
                                style: AppStyles.caption(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
