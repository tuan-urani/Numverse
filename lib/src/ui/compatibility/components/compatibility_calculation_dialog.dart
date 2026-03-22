import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class CompatibilityCalculationDialog extends StatefulWidget {
  const CompatibilityCalculationDialog({
    required this.primaryName,
    required this.targetName,
    super.key,
  });

  static const Duration _displayDuration = Duration(milliseconds: 2800);

  final String primaryName;
  final String targetName;

  static Future<void> show(
    BuildContext context, {
    required String primaryName,
    required String targetName,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'compatibility-calculating',
      barrierColor: AppColors.black.withValues(alpha: 0.78),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return CompatibilityCalculationDialog(
              primaryName: primaryName,
              targetName: targetName,
            );
          },
      transitionBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final CurvedAnimation curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
                child: child,
              ),
            );
          },
    );
  }

  @override
  State<CompatibilityCalculationDialog> createState() =>
      _CompatibilityCalculationDialogState();
}

class _CompatibilityCalculationDialogState
    extends State<CompatibilityCalculationDialog> {
  static const int _stepCount = 3;
  static const Duration _stepDuration = Duration(milliseconds: 850);

  Timer? _stepTimer;
  Timer? _autoCloseTimer;
  int _stepIndex = 0;

  List<String> get _stepLabels => <String>[
    LocaleKey.compatibilityCalculatingStepSync.tr,
    LocaleKey.compatibilityCalculatingStepEnergy.tr,
    LocaleKey.compatibilityCalculatingStepInsight.tr,
  ];

  @override
  void initState() {
    super.initState();

    _stepTimer = Timer.periodic(_stepDuration, (Timer timer) {
      if (!mounted) {
        return;
      }
      setState(() {
        _stepIndex = (_stepIndex + 1) % _stepCount;
      });
    });

    _autoCloseTimer = Timer(
      CompatibilityCalculationDialog._displayDuration,
      _dismissIfMounted,
    );
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  void _dismissIfMounted() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  String _shortName(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    if (trimmed.characters.length <= 12) {
      return trimmed;
    }
    return '${trimmed.characters.take(12)}…';
  }

  String _initial(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    return trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final String primaryName = _shortName(widget.primaryName);
    final String targetName = _shortName(widget.targetName);
    final String primaryInitial = _initial(primaryName);
    final String targetInitial = _initial(targetName);
    final double progress = (_stepIndex + 1) / _stepCount;

    return PopScope(
      canPop: false,
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.midnightSoft.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.richGold.withValues(alpha: 0.28),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.45),
                        blurRadius: 26,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          LocaleKey.compatibilityCalculatingTitle.tr,
                          textAlign: TextAlign.center,
                          style: AppStyles.h3(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        8.height,
                        Text(
                          LocaleKey.compatibilityCalculatingSubtitle.trParams(
                            <String, String>{
                              'primary': primaryName,
                              'target': targetName,
                            },
                          ),
                          textAlign: TextAlign.center,
                          style: AppStyles.bodySmall(
                            color: AppColors.textMuted,
                          ),
                        ),
                        16.height,
                        _SimpleBridge(
                          primaryInitial: primaryInitial,
                          targetInitial: targetInitial,
                        ),
                        12.height,
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Text(
                            _stepLabels[_stepIndex],
                            key: ValueKey<int>(_stepIndex),
                            textAlign: TextAlign.center,
                            style: AppStyles.bodySmall(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        10.height,
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: AppColors.textMuted.withValues(
                              alpha: 0.22,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.richGold.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SimpleBridge extends StatelessWidget {
  const _SimpleBridge({
    required this.primaryInitial,
    required this.targetInitial,
  });

  final String primaryInitial;
  final String targetInitial;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _PersonNode(initial: primaryInitial),
        12.width,
        Expanded(
          child: SizedBox(
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    gradient: LinearGradient(
                      colors: <Color>[
                        AppColors.energyBlue.withValues(alpha: 0.28),
                        AppColors.richGold.withValues(alpha: 0.8),
                        AppColors.energyRose.withValues(alpha: 0.28),
                      ],
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.midnight,
                    border: Border.all(
                      color: AppColors.richGold.withValues(alpha: 0.42),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.richGold,
                        backgroundColor: AppColors.richGold.withValues(
                          alpha: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        12.width,
        _PersonNode(initial: targetInitial),
      ],
    );
  }
}

class _PersonNode extends StatelessWidget {
  const _PersonNode({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.richGold.withValues(alpha: 0.34),
            AppColors.violetAccent.withValues(alpha: 0.34),
          ],
        ),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.42)),
      ),
      child: Text(
        initial,
        style: AppStyles.h5(
          color: AppColors.richGold,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
