import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/privacy/interactor/privacy_state.dart';
import 'package:test/src/ui/widgets/app_mystical_card.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class PrivacyDocumentsCard extends StatelessWidget {
  const PrivacyDocumentsCard({required this.documents, super.key});

  final List<PrivacyDocumentItem> documents;

  @override
  Widget build(BuildContext context) {
    return AppMysticalCard(
      borderColor: AppColors.border.withValues(alpha: 0.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            LocaleKey.privacyLegalSectionTitle.tr,
            style: AppStyles.h5(fontWeight: FontWeight.w700),
          ),
          12.height,
          for (int index = 0; index < documents.length; index++) ...<Widget>[
            _DocumentRow(item: documents[index]),
            if (index != documents.length - 1) 8.height,
          ],
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.item});

  final PrivacyDocumentItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: <Widget>[
          Icon(item.icon, size: 18, color: AppColors.richGold),
          10.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.titleKey.tr,
                  style: AppStyles.bodySmall(fontWeight: FontWeight.w600),
                ),
                2.height,
                Text(
                  LocaleKey.privacyDocUpdatedAt.tr,
                  style: AppStyles.caption(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
