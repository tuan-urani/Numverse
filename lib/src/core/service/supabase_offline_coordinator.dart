import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

enum SupabaseOfflinePopupAction { retry, close }

class SupabaseOfflineCoordinator {
  SupabaseOfflineCoordinator({bool dialogsEnabled = true})
    : _dialogsEnabled = dialogsEnabled;

  final bool _dialogsEnabled;
  bool _isLaunchGuardActive = false;
  bool _didHitLaunchOfflineError = false;
  bool _isPopupShowing = false;
  Completer<SupabaseOfflinePopupAction>? _inAppPopupCompleter;
  Completer<void>? _launchPopupCompleter;

  bool get isLaunchGuardActive => _isLaunchGuardActive;
  bool get didHitLaunchOfflineError => _didHitLaunchOfflineError;
  bool get isPopupShowing => _isPopupShowing;

  void beginLaunchGuard() {
    _isLaunchGuardActive = true;
  }

  void endLaunchGuard() {
    _isLaunchGuardActive = false;
    _didHitLaunchOfflineError = false;
  }

  void resetLaunchOfflineFlag() {
    _didHitLaunchOfflineError = false;
  }

  void markLaunchOfflineError() {
    _didHitLaunchOfflineError = true;
  }

  Future<void> showLaunchRetryPopup({required VoidCallback onRetry}) async {
    if (!_dialogsEnabled) {
      onRetry();
      return;
    }

    final Completer<void>? existingCompleter = _launchPopupCompleter;
    if (existingCompleter != null) {
      await existingCompleter.future;
      return;
    }

    final Completer<void> completer = Completer<void>();
    _launchPopupCompleter = completer;
    _isPopupShowing = true;

    try {
      await Get.dialog<void>(
        PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: AppColors.card,
            title: Text(
              LocaleKey.commonError.tr,
              style: AppStyles.h5(fontWeight: FontWeight.w600),
            ),
            content: Text(
              LocaleKey.commonNoInternetConnection.tr,
              style: AppStyles.bodyMedium(color: AppColors.textSecondary),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Get.back<void>();
                  onRetry();
                },
                child: Text(
                  LocaleKey.commonRetry.tr,
                  style: AppStyles.bodyMedium(color: AppColors.richGold),
                ),
              ),
            ],
          ),
        ),
        barrierDismissible: false,
      );
    } catch (_) {
      onRetry();
    }

    _isPopupShowing = false;
    _launchPopupCompleter = null;
    if (!completer.isCompleted) {
      completer.complete();
    }
  }

  Future<SupabaseOfflinePopupAction> showInAppRetryPopup() async {
    if (!_dialogsEnabled) {
      return SupabaseOfflinePopupAction.close;
    }

    final Completer<SupabaseOfflinePopupAction>? existingCompleter =
        _inAppPopupCompleter;
    if (existingCompleter != null) {
      return existingCompleter.future;
    }

    final Completer<SupabaseOfflinePopupAction> completer =
        Completer<SupabaseOfflinePopupAction>();
    _inAppPopupCompleter = completer;
    _isPopupShowing = true;

    try {
      await Get.dialog<void>(
        PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: AppColors.card,
            title: Text(
              LocaleKey.commonError.tr,
              style: AppStyles.h5(fontWeight: FontWeight.w600),
            ),
            content: Text(
              LocaleKey.commonNoInternetConnection.tr,
              style: AppStyles.bodyMedium(color: AppColors.textSecondary),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  if (!completer.isCompleted) {
                    completer.complete(SupabaseOfflinePopupAction.close);
                  }
                  Get.back<void>();
                },
                child: Text(
                  LocaleKey.commonClose.tr,
                  style: AppStyles.bodyMedium(color: AppColors.textMuted),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (!completer.isCompleted) {
                    completer.complete(SupabaseOfflinePopupAction.retry);
                  }
                  Get.back<void>();
                },
                child: Text(
                  LocaleKey.commonRetry.tr,
                  style: AppStyles.bodyMedium(color: AppColors.richGold),
                ),
              ),
            ],
          ),
        ),
        barrierDismissible: false,
      );
    } catch (_) {
      if (!completer.isCompleted) {
        completer.complete(SupabaseOfflinePopupAction.close);
      }
    }

    _isPopupShowing = false;
    _inAppPopupCompleter = null;
    if (!completer.isCompleted) {
      completer.complete(SupabaseOfflinePopupAction.close);
    }
    return completer.future;
  }
}
