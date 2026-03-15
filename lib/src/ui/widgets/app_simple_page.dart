import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/ui/widgets/app_glow_text.dart';
import 'package:test/src/ui/widgets/app_mystical_app_bar.dart';
import 'package:test/src/ui/widgets/app_mystical_card.dart';
import 'package:test/src/ui/widgets/app_mystical_scaffold.dart';
import 'package:test/src/ui/widgets/app_primary_button.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_dimensions.dart';
import 'package:test/src/utils/app_styles.dart';

class AppSimpleSection {
  const AppSimpleSection({
    required this.titleKey,
    this.descriptionKey,
    this.bulletKeys = const <String>[],
    this.icon,
    this.value,
    this.onTap,
  });

  final String titleKey;
  final String? descriptionKey;
  final List<String> bulletKeys;
  final IconData? icon;
  final String? value;
  final VoidCallback? onTap;
}

class AppSimplePage extends StatelessWidget {
  const AppSimplePage({
    required this.titleKey,
    required this.sections,
    this.subtitleKey,
    this.primaryButtonKey,
    this.onPrimaryButton,
    this.showBack = true,
    this.floatingBadge,
    super.key,
  });

  final String titleKey;
  final String? subtitleKey;
  final List<AppSimpleSection> sections;
  final String? primaryButtonKey;
  final VoidCallback? onPrimaryButton;
  final bool showBack;
  final Widget? floatingBadge;

  @override
  Widget build(BuildContext context) {
    return AppMysticalScaffold(
      appBar: AppMysticalAppBar(title: titleKey.tr, showBack: showBack),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.pageHorizontal,
            AppDimensions.pageVertical,
            AppDimensions.pageHorizontal,
            AppDimensions.pageVertical,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (subtitleKey != null) ...<Widget>[
                Text(
                  subtitleKey!.tr,
                  style: AppStyles.bodyMedium(color: AppColors.textMuted),
                ),
                16.height,
              ],
              for (final AppSimpleSection section in sections) ...<Widget>[
                AppMysticalCard(
                  onTap: section.onTap,
                  child: _SectionContent(section: section),
                ),
                12.height,
              ],
              if (floatingBadge != null) ...<Widget>[floatingBadge!, 12.height],
              if (primaryButtonKey != null)
                AppPrimaryButton(
                  label: primaryButtonKey!.tr,
                  onPressed: onPrimaryButton,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionContent extends StatelessWidget {
  const _SectionContent({required this.section});

  final AppSimpleSection section;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (section.icon != null) ...<Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.richGold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(
              section.icon,
              color: AppColors.richGold,
              size: AppDimensions.iconMedium,
            ),
          ),
          12.width,
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                section.titleKey.tr,
                style: AppStyles.h4(fontWeight: FontWeight.w600),
              ),
              if (section.value != null) ...<Widget>[
                8.height,
                AppGlowText(
                  text: section.value!,
                  style: AppStyles.numberMedium(),
                ),
              ],
              if (section.descriptionKey != null) ...<Widget>[
                8.height,
                Text(
                  section.descriptionKey!.tr,
                  style: AppStyles.bodyMedium(color: AppColors.textSecondary),
                ),
              ],
              if (section.bulletKeys.isNotEmpty) ...<Widget>[
                10.height,
                for (final String bullet in section.bulletKeys)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '• ',
                          style: AppStyles.bodyMedium(
                            color: AppColors.richGold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            bullet.tr,
                            style: AppStyles.bodyMedium(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
        if (section.onTap != null)
          const Icon(
            Icons.chevron_right,
            color: AppColors.richGold,
            size: AppDimensions.iconLarge,
          ),
      ],
    );
  }
}
