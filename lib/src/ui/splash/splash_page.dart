import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/core/repository/interface/i_app_session_repository.dart';
import 'package:test/src/core/repository/interface/i_cloud_account_repository.dart';
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
  static const Duration _fadeStartDelay = Duration(milliseconds: 2000);
  static const Duration _completeDelay = Duration(milliseconds: 2800);
  static const Duration _fadeDuration = Duration(milliseconds: 800);

  late final AnimationController _outerRingController;
  late final AnimationController _middleRingController;
  late final AnimationController _glowController;
  late final AnimationController _dotController;
  Timer? _fadeTimer;
  Timer? _completeTimer;
  bool _fadeOut = false;

  @override
  void initState() {
    super.initState();
    _setupAnimationControllers();
    _scheduleSplashTimers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedOpacity(
        opacity: _fadeOut ? 0 : 1,
        duration: _fadeDuration,
        curve: Curves.easeOut,
        child: SplashVisual(
          outerRingAnimation: _outerRingController,
          middleRingAnimation: _middleRingController,
          glowAnimation: _glowController,
          dotAnimation: _dotController,
        ),
      ),
    );
  }

  void _setupAnimationControllers() {
    _outerRingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _middleRingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  void _scheduleSplashTimers() {
    _fadeTimer = Timer(_fadeStartDelay, _handleFadeStart);
    _completeTimer = Timer(_completeDelay, _completeSplash);
  }

  void _handleFadeStart() {
    if (!mounted) {
      return;
    }
    setState(() {
      _fadeOut = true;
    });
  }

  Future<void> _completeSplash() async {
    if (!mounted) {
      return;
    }

    await _prepareTimeLifeSnapshots();
    if (!mounted) {
      return;
    }

    final AppShared appShared = Get.find<AppShared>();
    final bool hasVisited = appShared.getHasVisited();

    if (!hasVisited) {
      await appShared.setHasVisited(true);
      Get.offNamed(AppPages.onboarding);
      return;
    }

    Get.offNamed(AppPages.main);
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
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    _completeTimer?.cancel();
    _disposeAnimationControllers();
    super.dispose();
  }

  void _disposeAnimationControllers() {
    _outerRingController.dispose();
    _middleRingController.dispose();
    _glowController.dispose();
    _dotController.dispose();
  }
}
