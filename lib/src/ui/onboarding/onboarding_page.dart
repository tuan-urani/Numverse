import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_error_resolver.dart';
import 'package:test/src/ui/widgets/app_glow_text.dart';
import 'package:test/src/ui/widgets/app_mystical_card.dart';
import 'package:test/src/ui/widgets/app_mystical_scaffold.dart';
import 'package:test/src/utils/app_assets.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_pages.dart';
import 'package:test/src/utils/app_styles.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  static const int _profileStep = 3;
  static const int _loadingStep = 4;
  static const int _analysisStepsTotal = 4;

  int _step = 0;
  int _analysisProgress = 0;
  bool _isSubmitting = false;
  Map<_OnboardingField, String> _errors = <_OnboardingField, String>{};
  DateTime? _selectedBirthDate;
  Timer? _analysisTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectIfProfileExists();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return AppMysticalScaffold(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(16, 20, 16, 24 + keyboardInset),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (_step < _loadingStep) ...<Widget>[
                      _OnboardingProgressDots(currentStep: _step),
                      30.height,
                    ],
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 360),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              final Animation<Offset> slideAnimation =
                                  Tween<Offset>(
                                    begin: const Offset(0.05, 0),
                                    end: Offset.zero,
                                  ).animate(animation);
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: slideAnimation,
                                  child: child,
                                ),
                              );
                            },
                        child: _buildStepContent(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    return switch (_step) {
      0 => _buildCuriosityStep(),
      1 => _buildValueStep(),
      2 => _buildUseCaseStep(),
      3 => _buildProfileStep(),
      _ => _buildLoadingStep(),
    };
  }

  Widget _buildCuriosityStep() {
    return KeyedSubtree(
      key: const ValueKey<int>(0),
      child: Column(
        children: <Widget>[
          const _OnboardingOrbIcon(
            iconAsset: AppAssets.iconCalendarSvg,
            size: 128,
            iconSize: 56,
          ),
          32.height,
          AppGlowText(
            text: LocaleKey.onboardingIntroTitle.tr,
            textAlign: TextAlign.center,
            style: AppStyles.h1(
              fontWeight: FontWeight.w700,
            ).copyWith(height: 1.22, color: AppColors.textPrimary),
          ),
          12.height,
          Text(
            LocaleKey.onboardingIntroSubtitle.tr,
            textAlign: TextAlign.center,
            style: AppStyles.bodyMedium(
              color: AppColors.textMuted,
            ).copyWith(fontSize: 15, height: 1.5),
          ),
          32.height,
          _OnboardingPrimaryButton(
            label: LocaleKey.onboardingIntroPrimary.tr,
            onPressed: _handleNext,
          ),
        ],
      ),
    );
  }

  Widget _buildValueStep() {
    return KeyedSubtree(
      key: const ValueKey<int>(1),
      child: Column(
        children: <Widget>[
          const _OnboardingOrbIcon(
            iconAsset: AppAssets.iconSelfSvg,
            size: 104,
            iconSize: 40,
          ),
          26.height,
          Text(
            LocaleKey.onboardingValueTitle.tr,
            textAlign: TextAlign.center,
            style: AppStyles.h2(
              fontWeight: FontWeight.w700,
            ).copyWith(fontSize: 30, height: 1.23),
          ),
          20.height,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _OnboardingFeatureItem(
                  iconText: '12',
                  label: LocaleKey.onboardingValueFeatureCore.tr,
                ),
              ),
              10.width,
              Expanded(
                child: _OnboardingFeatureItem(
                  icon: Icons.psychology_alt_rounded,
                  label: LocaleKey.onboardingValueFeaturePotential.tr,
                ),
              ),
              10.width,
              Expanded(
                child: _OnboardingFeatureItem(
                  icon: Icons.bolt_rounded,
                  label: LocaleKey.onboardingValueFeatureEnergy.tr,
                ),
              ),
            ],
          ),
          30.height,
          _OnboardingPrimaryButton(
            label: LocaleKey.commonContinue.tr,
            onPressed: _handleNext,
          ),
        ],
      ),
    );
  }

  Widget _buildUseCaseStep() {
    return KeyedSubtree(
      key: const ValueKey<int>(2),
      child: Column(
        children: <Widget>[
          Text(
            LocaleKey.onboardingUseCaseTitle.tr,
            textAlign: TextAlign.center,
            style: AppStyles.h2(
              fontWeight: FontWeight.w700,
            ).copyWith(fontSize: 30, height: 1.23),
          ),
          20.height,
          _OnboardingUseCaseCard(
            iconAsset: AppAssets.iconLoveSvg,
            iconColor: AppColors.energyPink,
            iconBackgroundColor: AppColors.energyPink.withValues(alpha: 0.16),
            iconBorderColor: AppColors.energyPink.withValues(alpha: 0.35),
            title: LocaleKey.onboardingUseCaseLoveTitle.tr,
            subtitle: LocaleKey.onboardingUseCaseLoveSubtitle.tr,
          ),
          10.height,
          _OnboardingUseCaseCard(
            iconAsset: AppAssets.iconCareerSvg,
            iconColor: AppColors.energyBlue,
            iconBackgroundColor: AppColors.energyBlue.withValues(alpha: 0.16),
            iconBorderColor: AppColors.energyBlue.withValues(alpha: 0.35),
            title: LocaleKey.onboardingUseCaseCareerTitle.tr,
            subtitle: LocaleKey.onboardingUseCaseCareerSubtitle.tr,
          ),
          10.height,
          _OnboardingUseCaseCard(
            icon: Icons.groups_rounded,
            iconColor: AppColors.energyViolet,
            iconBackgroundColor: AppColors.energyViolet.withValues(alpha: 0.16),
            iconBorderColor: AppColors.energyViolet.withValues(alpha: 0.35),
            title: LocaleKey.onboardingUseCaseRelationsTitle.tr,
            subtitle: LocaleKey.onboardingUseCaseRelationsSubtitle.tr,
          ),
          28.height,
          _OnboardingPrimaryButton(
            label: LocaleKey.commonContinue.tr,
            onPressed: _handleNext,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStep() {
    final String? nameError = _errors[_OnboardingField.name];
    final String? birthDateError = _errors[_OnboardingField.date];

    return KeyedSubtree(
      key: const ValueKey<int>(3),
      child: Column(
        children: <Widget>[
          Text(
            LocaleKey.onboardingProfileTitle.tr,
            textAlign: TextAlign.center,
            style: AppStyles.h2(
              fontWeight: FontWeight.w700,
            ).copyWith(fontSize: 29, height: 1.24),
          ),
          10.height,
          Text(
            LocaleKey.onboardingProfileSubtitle.tr,
            textAlign: TextAlign.center,
            style: AppStyles.bodyMedium(color: AppColors.textMuted),
          ),
          24.height,
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              LocaleKey.onboardingProfileNameLabel.tr,
              style: AppStyles.bodySmall(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          8.height,
          _OnboardingTextField(
            controller: _nameController,
            hintText: LocaleKey.onboardingProfileNameHint.tr,
            errorText: nameError,
            onChanged: (_) => _clearError(_OnboardingField.name),
          ),
          if (nameError != null) ...<Widget>[
            6.height,
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                nameError,
                style: AppStyles.caption(color: AppColors.error),
              ),
            ),
          ],
          16.height,
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              LocaleKey.onboardingProfileBirthDateLabel.tr,
              style: AppStyles.bodySmall(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          8.height,
          _OnboardingTextField(
            controller: _birthDateController,
            hintText:
                '${LocaleKey.onboardingProfileDayHint.tr}/'
                '${LocaleKey.onboardingProfileMonthHint.tr}/'
                '${LocaleKey.onboardingProfileYearHint.tr}',
            readOnly: true,
            onTap: _isSubmitting ? null : _pickBirthDate,
            errorText: birthDateError,
            suffixIcon: Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: AppColors.textMuted.withValues(alpha: 0.9),
            ),
          ),
          if (birthDateError != null) ...<Widget>[
            6.height,
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                birthDateError,
                style: AppStyles.caption(color: AppColors.error),
              ),
            ),
          ],
          24.height,
          _OnboardingPrimaryButton(
            label: LocaleKey.onboardingProfileSubmit.tr,
            isBusy: _isSubmitting,
            onPressed: _isSubmitting ? null : _handleSubmit,
          ),
          10.height,
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _isSubmitting ? null : _handleExploreFirst,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(
                LocaleKey.onboardingProfileExploreFirst.tr,
                style: AppStyles.bodySmall(color: AppColors.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStep() {
    final List<_AnalysisStepData> analysisSteps = _analysisSteps;
    final int activeIndex = _analysisProgress < analysisSteps.length
        ? _analysisProgress
        : -1;
    final double progress = _analysisProgress / analysisSteps.length;
    final int progressPercent = (progress * 100).round();

    return KeyedSubtree(
      key: const ValueKey<int>(4),
      child: AppMysticalCard(
        borderColor: AppColors.richGold.withValues(alpha: 0.3),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          children: <Widget>[
            const _OnboardingLoadingHero(),
            14.height,
            AppGlowText(
              text: LocaleKey.onboardingLoadingTitle.tr,
              textAlign: TextAlign.center,
              style: AppStyles.h2(
                fontWeight: FontWeight.w700,
              ).copyWith(fontSize: 28, height: 1.24),
            ),
            8.height,
            Text(
              LocaleKey.onboardingLoadingSubtitle.tr,
              textAlign: TextAlign.center,
              style: AppStyles.bodySmall(color: AppColors.textMuted),
            ),
            18.height,
            Column(
              children: <Widget>[
                for (final (int index, _AnalysisStepData item)
                    in analysisSteps.indexed)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: index == analysisSteps.length - 1 ? 0 : 8,
                    ),
                    child: _OnboardingAnalysisStatusRow(
                      icon: item.icon,
                      text: item.text,
                      isActive: index == activeIndex,
                      isCompleted: index < _analysisProgress,
                    ),
                  ),
              ],
            ),
            18.height,
            _OnboardingProgressBar(
              progress: progress,
              progressLabel: LocaleKey.onboardingLoadingProgress.tr,
              progressPercent: progressPercent,
            ),
            16.height,
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.energyBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.energyBlue.withValues(alpha: 0.22),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Text(
                  LocaleKey.onboardingLoadingQuote.tr,
                  textAlign: TextAlign.center,
                  style: AppStyles.bodySmall(
                    color: AppColors.textMuted,
                  ).copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_AnalysisStepData> get _analysisSteps => <_AnalysisStepData>[
    _AnalysisStepData(
      icon: Icons.tag_rounded,
      text: LocaleKey.onboardingLoadingStepCore.tr,
    ),
    _AnalysisStepData(
      icon: Icons.psychology_alt_rounded,
      text: LocaleKey.onboardingLoadingStepPersonality.tr,
    ),
    _AnalysisStepData(
      icon: Icons.star_rounded,
      text: LocaleKey.onboardingLoadingStepDirection.tr,
    ),
    _AnalysisStepData(
      icon: Icons.auto_awesome_rounded,
      text: LocaleKey.onboardingLoadingStepFinalize.tr,
    ),
  ];

  void _handleNext() {
    if (_step < _profileStep) {
      setState(() {
        _step += 1;
      });
    }
  }

  void _clearError(_OnboardingField field) {
    if (!_errors.containsKey(field)) {
      return;
    }
    setState(() {
      _errors = Map<_OnboardingField, String>.from(_errors)..remove(field);
    });
  }

  String _formatBirthDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _pickBirthDate() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate =
        _selectedBirthDate ?? DateTime(now.year - 20, now.month, now.day);
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? now : initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.richGold,
              onPrimary: AppColors.midnight,
              surface: AppColors.midnightSoft,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.midnightSoft,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _selectedBirthDate = selected;
      _birthDateController.text = _formatBirthDate(selected);
      _errors = Map<_OnboardingField, String>.from(_errors)
        ..remove(_OnboardingField.date);
    });
  }

  Future<void> _redirectIfProfileExists() async {
    final MainSessionBloc sessionBloc = Get.find<MainSessionBloc>();
    if (sessionBloc.state.hasAnyProfile && mounted) {
      await Get.offAllNamed(AppPages.main);
    }
  }

  void _handleExploreFirst() {
    _analysisTimer?.cancel();
    Get.offAllNamed(AppPages.home);
  }

  void _handleSubmit() {
    if (_isSubmitting) {
      return;
    }
    final Map<_OnboardingField, String> validationErrors = _validateForm();
    if (validationErrors.isNotEmpty) {
      setState(() {
        _errors = validationErrors;
      });
      return;
    }
    setState(() {
      _errors = <_OnboardingField, String>{};
      _step = _loadingStep;
      _analysisProgress = 0;
      _isSubmitting = true;
    });
    _startAnalysis();
  }

  Map<_OnboardingField, String> _validateForm() {
    final Map<_OnboardingField, String> validationErrors =
        <_OnboardingField, String>{};

    final String trimmedName = _nameController.text.trim();
    final DateTime? birthDate = _selectedBirthDate;
    final DateTime now = DateTime.now();

    if (trimmedName.isEmpty) {
      validationErrors[_OnboardingField.name] =
          LocaleKey.onboardingErrorNameRequired.tr;
    } else if (trimmedName.length < 2) {
      validationErrors[_OnboardingField.name] =
          LocaleKey.onboardingErrorNameMinLength.tr;
    }

    if (birthDate == null || birthDate.year < 1900 || birthDate.isAfter(now)) {
      validationErrors[_OnboardingField.date] =
          LocaleKey.onboardingErrorDateInvalid.tr;
    }

    return validationErrors;
  }

  void _startAnalysis() {
    _analysisTimer?.cancel();
    _analysisTimer = Timer.periodic(const Duration(seconds: 1), (
      Timer timer,
    ) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_analysisProgress < _analysisStepsTotal) {
        setState(() {
          _analysisProgress += 1;
        });
      }

      if (_analysisProgress >= _analysisStepsTotal) {
        timer.cancel();
        await _completeOnboarding();
      }
    });
  }

  Future<void> _completeOnboarding() async {
    final String name = _nameController.text.trim();
    final DateTime? birthDate = _selectedBirthDate;
    if (birthDate == null) {
      setState(() {
        _isSubmitting = false;
        _step = _profileStep;
        _analysisProgress = 0;
        _errors = <_OnboardingField, String>{
          _OnboardingField.date: LocaleKey.onboardingErrorDateInvalid.tr,
        };
      });
      return;
    }

    try {
      final MainSessionBloc sessionBloc = Get.find<MainSessionBloc>();
      await sessionBloc.addProfile(name: name, birthDate: birthDate);
      if (!mounted) {
        return;
      }
      await Get.offAllNamed(AppPages.main);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _step = _profileStep;
        _analysisProgress = 0;
      });
      Get.snackbar(
        LocaleKey.commonError.tr,
        resolveMainSessionErrorMessage(error),
        backgroundColor: AppColors.deepViolet.withValues(alpha: 0.9),
        colorText: AppColors.textPrimary,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();
    _nameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }
}

enum _OnboardingField { name, date }

class _OnboardingProgressDots extends StatelessWidget {
  const _OnboardingProgressDots({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(4, (int index) {
        final bool isActive = index == currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 34 : 7,
          height: 7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: isActive
                ? AppColors.richGold
                : AppColors.textMuted.withValues(alpha: 0.3),
          ),
        );
      }),
    );
  }
}

class _OnboardingOrbIcon extends StatelessWidget {
  const _OnboardingOrbIcon({
    this.icon,
    this.iconAsset,
    required this.size,
    required this.iconSize,
  }) : assert(icon != null || iconAsset != null);

  final IconData? icon;
  final String? iconAsset;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.richGold.withValues(alpha: 0.22),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.richGold.withValues(alpha: 0.25),
                  blurRadius: 34,
                ),
              ],
            ),
          ),
          Container(
            width: size * 0.82,
            height: size * 0.82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  AppColors.richGold.withValues(alpha: 0.24),
                  AppColors.energyBlue.withValues(alpha: 0.2),
                ],
              ),
              border: Border.all(
                color: AppColors.richGold.withValues(alpha: 0.25),
              ),
            ),
            child: Center(
              child: SizedBox.square(
                dimension: iconSize,
                child: iconAsset == null
                    ? Icon(icon, size: iconSize, color: AppColors.richGold)
                    : SvgPicture.asset(
                        iconAsset!,
                        fit: BoxFit.contain,
                        colorFilter: const ColorFilter.mode(
                          AppColors.richGold,
                          BlendMode.srcIn,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPrimaryButton extends StatelessWidget {
  const _OnboardingPrimaryButton({
    required this.label,
    this.onPressed,
    this.isBusy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !isBusy;
    return SizedBox(
      width: double.infinity,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.55,
        duration: const Duration(milliseconds: 220),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: enabled ? onPressed : null,
            child: Ink(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient(),
                borderRadius: BorderRadius.circular(16),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.richGold.withValues(alpha: 0.28),
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (isBusy) ...<Widget>[
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.midnight,
                          ),
                        ),
                      ),
                      10.width,
                    ],
                    Text(
                      label,
                      style: AppStyles.buttonLarge(
                        color: AppColors.midnight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingFeatureItem extends StatelessWidget {
  const _OnboardingFeatureItem({
    this.icon,
    this.iconAsset,
    this.iconText,
    required this.label,
  }) : assert(icon != null || iconAsset != null || iconText != null);

  final IconData? icon;
  final String? iconAsset;
  final String? iconText;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                AppColors.richGold.withValues(alpha: 0.2),
                AppColors.richGold.withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(
              color: AppColors.richGold.withValues(alpha: 0.25),
            ),
          ),
          child: iconText != null
              ? Center(
                  child: Text(
                    iconText!,
                    style: AppStyles.numberSmall(color: AppColors.richGold),
                  ),
                )
              : iconAsset == null
              ? Icon(icon, color: AppColors.richGold, size: 28)
              : SvgPicture.asset(
                  iconAsset!,
                  width: 28,
                  height: 28,
                  colorFilter: const ColorFilter.mode(
                    AppColors.richGold,
                    BlendMode.srcIn,
                  ),
                ),
        ),
        8.height,
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppStyles.bodySmall(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _OnboardingUseCaseCard extends StatelessWidget {
  const _OnboardingUseCaseCard({
    this.icon,
    this.iconAsset,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.iconBorderColor,
    required this.title,
    required this.subtitle,
  }) : assert(icon != null || iconAsset != null);

  final IconData? icon;
  final String? iconAsset;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color iconBorderColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppColors.richGold.withValues(alpha: 0.12),
            AppColors.deepViolet.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: iconBorderColor),
              ),
              child: SizedBox(
                width: 46,
                height: 46,
                child: Center(
                  child: SizedBox.square(
                    dimension: 24,
                    child: iconAsset == null
                        ? Icon(icon, color: iconColor, size: 24)
                        : SvgPicture.asset(
                            iconAsset!,
                            fit: BoxFit.contain,
                            colorFilter: ColorFilter.mode(
                              iconColor,
                              BlendMode.srcIn,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            12.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppStyles.bodyLarge(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  2.height,
                  Text(
                    subtitle,
                    style: AppStyles.caption(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.star_rounded,
              color: AppColors.richGold.withValues(alpha: 0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingTextField extends StatelessWidget {
  const _OnboardingTextField({
    required this.controller,
    required this.hintText,
    this.errorText,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final bool hasError = errorText != null;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      readOnly: readOnly,
      onTap: onTap,
      showCursor: !readOnly,
      style: AppStyles.bodyMedium(),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppStyles.bodyMedium(color: AppColors.textMuted),
        suffixIcon: suffixIcon == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 12),
                child: suffixIcon,
              ),
        suffixIconConstraints: const BoxConstraints(minHeight: 0, minWidth: 0),
        errorText: hasError ? '' : null,
        errorStyle: const TextStyle(height: 0, fontSize: 0),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        filled: true,
        fillColor: AppColors.deepViolet.withValues(alpha: 0.48),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.white.withValues(alpha: 0.34),
            width: 1.2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: hasError
                ? AppColors.error.withValues(alpha: 0.9)
                : AppColors.white.withValues(alpha: 0.46),
            width: 1.3,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: hasError
                ? AppColors.error
                : AppColors.white.withValues(alpha: 0.86),
            width: 1.6,
          ),
        ),
      ),
    );
  }
}

class _OnboardingLoadingHero extends StatelessWidget {
  const _OnboardingLoadingHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.richGold.withValues(alpha: 0.2),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.richGold.withValues(alpha: 0.25),
                  blurRadius: 24,
                ),
              ],
            ),
          ),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  AppColors.richGold.withValues(alpha: 0.24),
                  AppColors.energyBlue.withValues(alpha: 0.2),
                ],
              ),
              border: Border.all(
                color: AppColors.richGold.withValues(alpha: 0.4),
                width: 1.3,
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.richGold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingAnalysisStatusRow extends StatelessWidget {
  const _OnboardingAnalysisStatusRow({
    required this.icon,
    required this.text,
    required this.isActive,
    required this.isCompleted,
  });

  final IconData icon;
  final String text;
  final bool isActive;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final Color tileColor = isActive
        ? AppColors.richGold.withValues(alpha: 0.12)
        : isCompleted
        ? AppColors.richGold.withValues(alpha: 0.07)
        : AppColors.deepViolet.withValues(alpha: 0.35);

    final Color borderColor = isActive
        ? AppColors.richGold.withValues(alpha: 0.35)
        : isCompleted
        ? AppColors.richGold.withValues(alpha: 0.18)
        : AppColors.border.withValues(alpha: 0.45);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: <Widget>[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? AppColors.richGold.withValues(alpha: 0.18)
                    : AppColors.deepViolet.withValues(alpha: 0.5),
                border: Border.all(
                  color: isActive
                      ? AppColors.richGold.withValues(alpha: 0.45)
                      : AppColors.border.withValues(alpha: 0.6),
                ),
              ),
              child: Icon(
                isCompleted ? Icons.star_rounded : icon,
                size: 16,
                color: isCompleted || isActive
                    ? AppColors.richGold
                    : AppColors.textMuted,
              ),
            ),
            10.width,
            Expanded(
              child: Text(
                text,
                style: AppStyles.bodySmall(
                  color: isActive ? AppColors.textPrimary : AppColors.textMuted,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isActive)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.richGold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingProgressBar extends StatelessWidget {
  const _OnboardingProgressBar({
    required this.progress,
    required this.progressLabel,
    required this.progressPercent,
  });

  final double progress;
  final String progressLabel;
  final int progressPercent;

  @override
  Widget build(BuildContext context) {
    final double clampedProgress = progress.clamp(0, 1);
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                progressLabel,
                style: AppStyles.caption(color: AppColors.textMuted),
              ),
            ),
            Text(
              '$progressPercent%',
              style: AppStyles.caption(
                color: AppColors.richGold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        8.height,
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 8,
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.deepViolet.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: clampedProgress,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[
                              AppColors.richGold,
                              AppColors.energyBlue.withValues(alpha: 0.85),
                              AppColors.richGold,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AnalysisStepData {
  const _AnalysisStepData({required this.icon, required this.text});

  final IconData icon;
  final String text;
}
