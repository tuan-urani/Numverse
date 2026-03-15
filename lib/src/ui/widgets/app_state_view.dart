import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/widgets/app_primary_button.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

enum AppViewStateStatus { loading, success, empty, error }

class AppStateView extends StatelessWidget {
  const AppStateView({
    required this.status,
    required this.success,
    this.emptyTitle,
    this.emptySubtitle,
    this.errorTitle,
    this.errorSubtitle,
    this.onRetry,
    super.key,
  });

  final AppViewStateStatus status;
  final Widget success;
  final String? emptyTitle;
  final String? emptySubtitle;
  final String? errorTitle;
  final String? errorSubtitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case AppViewStateStatus.loading:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.richGold),
        );
      case AppViewStateStatus.empty:
        return _InfoState(
          title: emptyTitle ?? LocaleKey.stateNoDataTitle.tr,
          subtitle: emptySubtitle ?? LocaleKey.stateNoDataSubtitle.tr,
          onRetry: onRetry,
        );
      case AppViewStateStatus.error:
        return _InfoState(
          title: errorTitle ?? LocaleKey.stateErrorTitle.tr,
          subtitle: errorSubtitle ?? LocaleKey.stateErrorSubtitle.tr,
          onRetry: onRetry,
        );
      case AppViewStateStatus.success:
        return success;
    }
  }
}

class _InfoState extends StatelessWidget {
  const _InfoState({required this.title, required this.subtitle, this.onRetry});

  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(title, style: AppStyles.h4()),
            8.height,
            Text(
              subtitle,
              style: AppStyles.bodyMedium(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...<Widget>[
              16.height,
              AppPrimaryButton(
                label: LocaleKey.commonRetry.tr,
                onPressed: onRetry,
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
