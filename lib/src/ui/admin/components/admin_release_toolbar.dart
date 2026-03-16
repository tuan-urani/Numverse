import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/core/model/admin_ledger_release.dart';
import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class AdminReleaseToolbar extends StatelessWidget {
  const AdminReleaseToolbar({
    required this.locale,
    required this.releases,
    required this.selectedReleaseId,
    required this.selectedContentType,
    required this.contentTypeOptions,
    required this.searchController,
    required this.isPublishing,
    required this.isCreatingDraft,
    required this.onLocaleChanged,
    required this.onReleaseChanged,
    required this.onContentTypeChanged,
    required this.onSearchSubmitted,
    required this.onRefreshTap,
    required this.onPublishTap,
    required this.onCreateDraftTap,
    required this.onLogoutTap,
    super.key,
  });

  final String locale;
  final List<AdminLedgerRelease> releases;
  final String? selectedReleaseId;
  final String selectedContentType;
  final List<String> contentTypeOptions;
  final TextEditingController searchController;
  final bool isPublishing;
  final bool isCreatingDraft;
  final ValueChanged<String> onLocaleChanged;
  final ValueChanged<String> onReleaseChanged;
  final ValueChanged<String> onContentTypeChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onRefreshTap;
  final VoidCallback onPublishTap;
  final VoidCallback onCreateDraftTap;
  final VoidCallback onLogoutTap;

  static const List<String> _localeOptions = <String>['vi', 'en'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _LabeledDropdown(
                label: LocaleKey.adminLocaleLabel.tr,
                value: locale,
                options: _localeOptions,
                onChanged: onLocaleChanged,
                optionLabelBuilder: (String value) => value.toUpperCase(),
                width: 110,
              ),
              _LabeledDropdown(
                label: LocaleKey.adminReleaseLabel.tr,
                value: selectedReleaseId,
                options: releases
                    .map((AdminLedgerRelease item) => item.id)
                    .toList(),
                onChanged: onReleaseChanged,
                optionLabelBuilder: (String id) {
                  AdminLedgerRelease? release;
                  for (final AdminLedgerRelease item in releases) {
                    if (item.id == id) {
                      release = item;
                      break;
                    }
                  }
                  if (release == null) {
                    return id;
                  }
                  return '${release.version} (${_statusLabel(release.status)})';
                },
                width: 300,
              ),
              _LabeledDropdown(
                label: LocaleKey.adminContentTypeLabel.tr,
                value: selectedContentType,
                options: contentTypeOptions,
                onChanged: onContentTypeChanged,
                optionLabelBuilder: (String value) => value,
                width: 220,
              ),
              SizedBox(
                width: 260,
                child: TextField(
                  controller: searchController,
                  onSubmitted: onSearchSubmitted,
                  decoration: InputDecoration(
                    hintText: LocaleKey.adminSearchHint.tr,
                    suffixIcon: IconButton(
                      onPressed: () => onSearchSubmitted(searchController.text),
                      icon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.richGold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          12.height,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _ToolbarAction(
                icon: Icons.refresh_rounded,
                label: LocaleKey.adminRefreshAction.tr,
                onTap: onRefreshTap,
              ),
              _ToolbarAction(
                icon: Icons.add_circle_outline_rounded,
                label: isCreatingDraft
                    ? LocaleKey.commonLoading.tr
                    : LocaleKey.adminCreateDraftAction.tr,
                onTap: isCreatingDraft ? null : onCreateDraftTap,
              ),
              _ToolbarAction(
                icon: Icons.publish_rounded,
                label: isPublishing
                    ? LocaleKey.commonLoading.tr
                    : LocaleKey.adminPublishAction.tr,
                onTap: isPublishing ? null : onPublishTap,
              ),
              _ToolbarAction(
                icon: Icons.logout_rounded,
                label: LocaleKey.adminLogoutAction.tr,
                onTap: onLogoutTap,
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    return switch (status) {
      'active' => LocaleKey.adminReleaseStatusActive.tr,
      'draft' => LocaleKey.adminReleaseStatusDraft.tr,
      _ => LocaleKey.adminReleaseStatusArchived.tr,
    };
  }
}

class _LabeledDropdown extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.optionLabelBuilder,
    required this.width,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final String Function(String value) optionLabelBuilder;
  final double width;

  @override
  Widget build(BuildContext context) {
    final String? effectiveValue = options.contains(value) ? value : null;
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: AppStyles.caption(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          6.height,
          DropdownButtonFormField<String>(
            key: ValueKey<String?>(effectiveValue),
            initialValue: effectiveValue,
            isExpanded: true,
            items: options
                .map(
                  (String item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      optionLabelBuilder(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (String? item) {
              if (item == null) {
                return;
              }
              onChanged(item);
            },
          ),
        ],
      ),
    );
  }
}

class _ToolbarAction extends StatelessWidget {
  const _ToolbarAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.richGold,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: onTap == null ? 0.45 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.35)),
            color: color.withValues(alpha: 0.1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 16, color: color),
              6.width,
              Text(
                label,
                style: AppStyles.caption(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
