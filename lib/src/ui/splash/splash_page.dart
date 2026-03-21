import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/core/repository/interface/i_app_session_repository.dart';
import 'package:test/src/core/repository/interface/i_cloud_account_repository.dart';
import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/core/service/interface/i_daily_alarm_notification_service.dart';
import 'package:test/src/core/service/supabase_offline_coordinator.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/splash/components/splash_visual.dart';
import 'package:test/src/utils/app_shared.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_pages.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  static const Duration _minSplashDuration = Duration(seconds: 3);

  late final AnimationController _glowController;
  late final AnimationController _dotController;
  late final Future<void> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _setupAnimationControllers();
    _bootstrapFuture = _runBootstrapWithRetry();
    unawaited(_startNavigationFlow());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SplashVisual(
        glowAnimation: _glowController,
        dotAnimation: _dotController,
      ),
    );
  }

  void _setupAnimationControllers() {
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  Future<void> _startNavigationFlow() async {
    await Future.wait<void>(<Future<void>>[
      Future<void>.delayed(_minSplashDuration),
      _bootstrapFuture,
    ]);
    if (!mounted) {
      return;
    }
    await _navigateAfterSplash();
  }

  Future<void> _runBootstrapWithRetry() async {
    if (!mounted) {
      return;
    }

    final SupabaseOfflineCoordinator offlineCoordinator =
        Get.find<SupabaseOfflineCoordinator>();
    offlineCoordinator.beginLaunchGuard();
    try {
      while (mounted) {
        offlineCoordinator.resetLaunchOfflineFlag();
        Object? launchError;
        StackTrace? launchStackTrace;
        try {
          await _prepareTimeLifeSnapshots();
        } catch (error, stackTrace) {
          launchError = error;
          launchStackTrace = stackTrace;
        }
        if (!mounted) {
          return;
        }

        if (!offlineCoordinator.didHitLaunchOfflineError) {
          if (launchError != null) {
            Error.throwWithStackTrace(
              launchError,
              launchStackTrace ?? StackTrace.current,
            );
          }
          break;
        }

        final Completer<void> retryCompleter = Completer<void>();
        await offlineCoordinator.showLaunchRetryPopup(
          onRetry: () {
            if (!retryCompleter.isCompleted) {
              retryCompleter.complete();
            }
          },
        );
        await retryCompleter.future;
      }
    } finally {
      offlineCoordinator.endLaunchGuard();
    }
  }

  Future<void> _navigateAfterSplash() async {
    if (_shouldSkipOnboarding()) {
      Get.offNamed(AppPages.main);
      return;
    }

    final AppShared appShared = Get.find<AppShared>();
    final bool hasVisited = appShared.getHasVisited();

    if (!hasVisited) {
      await appShared.setHasVisited(true);
      Get.offNamed(AppPages.onboarding);
      return;
    }

    final IDailyAlarmNotificationService dailyAlarmService =
        Get.find<IDailyAlarmNotificationService>();
    if (dailyAlarmService.consumeOpenTodayIntent()) {
      Get.offNamed(AppPages.today);
      return;
    }

    Get.offNamed(AppPages.main);
  }

  bool _shouldSkipOnboarding() {
    final dynamic rawArguments = Get.arguments;
    if (rawArguments is! Map<dynamic, dynamic>) {
      return false;
    }
    final dynamic rawSkipValue = rawArguments['skipOnboarding'];
    return rawSkipValue == true;
  }

  Future<void> _prepareTimeLifeSnapshots() async {
    final MainSessionBloc sessionBloc = Get.isRegistered<MainSessionBloc>()
        ? Get.find<MainSessionBloc>()
        : Get.put<MainSessionBloc>(
            MainSessionBloc(
              Get.find<IAppSessionRepository>(),
              Get.find<ICloudAccountRepository>(),
            ),
            permanent: true,
          );
    await sessionBloc.initialize();
    await Get.find<INumerologyContentRepository>().warmUp();
    await Get.find<IDailyAlarmNotificationService>().bootstrap(
      localeCode: Get.locale?.languageCode,
    );
  }

  @override
  void dispose() {
    _disposeAnimationControllers();
    super.dispose();
  }

  void _disposeAnimationControllers() {
    _glowController.dispose();
    _dotController.dispose();
  }
}
