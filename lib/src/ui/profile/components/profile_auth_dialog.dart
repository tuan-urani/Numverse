import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_error_resolver.dart';
import 'package:test/src/ui/widgets/app_glow_text.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

enum ProfileAuthDialogTab { login, register }

class ProfileAuthDialog extends StatefulWidget {
  const ProfileAuthDialog({
    super.key,
    this.defaultTab = ProfileAuthDialogTab.register,
    this.onSuccess,
  });

  final ProfileAuthDialogTab defaultTab;
  final VoidCallback? onSuccess;

  static Future<void> show(
    BuildContext _, {
    ProfileAuthDialogTab defaultTab = ProfileAuthDialogTab.register,
    VoidCallback? onSuccess,
  }) {
    return Get.dialog<void>(
      ProfileAuthDialog(defaultTab: defaultTab, onSuccess: onSuccess),
      barrierDismissible: false,
    );
  }

  @override
  State<ProfileAuthDialog> createState() => _ProfileAuthDialogState();
}

class _ProfileAuthDialogState extends State<ProfileAuthDialog> {
  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  late ProfileAuthDialogTab _activeTab;
  late final MainSessionBloc _sessionBloc;

  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();
  final TextEditingController _registerEmailController =
      TextEditingController();
  final TextEditingController _registerPasswordController =
      TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _showLoginPassword = false;
  bool _showRegisterPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoginLoading = false;
  bool _isRegisterLoading = false;
  bool _isSuccess = false;
  bool _showSuccessSubtitle = true;
  String _successMessage = '';
  String? _formError;
  Map<String, String> _loginErrors = <String, String>{};
  Map<String, String> _registerErrors = <String, String>{};

  bool get _isBusy => _isLoginLoading || _isRegisterLoading || _isSuccess;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.defaultTab;
    _sessionBloc = Get.find<MainSessionBloc>();
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _setActiveTab(ProfileAuthDialogTab tab) {
    if (_isBusy || _activeTab == tab) {
      return;
    }
    setState(() {
      _activeTab = tab;
      _formError = null;
    });
  }

  Future<void> _submitLogin() async {
    if (_isBusy) {
      return;
    }
    if (!_validateLogin()) {
      return;
    }

    setState(() {
      _isLoginLoading = true;
      _formError = null;
    });

    try {
      final String email = _loginEmailController.text.trim().toLowerCase();
      final String password = _loginPasswordController.text.trim();
      await _sessionBloc.login(
        email: email,
        password: password,
        name: _nameFromEmail(email),
      );
      await _showSuccessAndClose(
        LocaleKey.profileAuthLoginSuccess.tr,
        showSubtitle: false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _formError = _resolveErrorMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoginLoading = false;
        });
      }
    }
  }

  Future<void> _submitRegister() async {
    if (_isBusy) {
      return;
    }
    if (!_validateRegister()) {
      return;
    }

    setState(() {
      _isRegisterLoading = true;
      _formError = null;
    });

    try {
      final String email = _registerEmailController.text.trim().toLowerCase();
      final String password = _registerPasswordController.text.trim();
      final String name = _resolveRegisterName(email);
      await _sessionBloc.register(email: email, password: password, name: name);
      await _showSuccessAndClose(
        LocaleKey.profileAuthRegisterSuccess.tr,
        showSubtitle: true,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _formError = _resolveErrorMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRegisterLoading = false;
        });
      }
    }
  }

  Future<void> _showSuccessAndClose(
    String successMessage, {
    required bool showSubtitle,
  }) async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isSuccess = true;
      _showSuccessSubtitle = showSubtitle;
      _successMessage = successMessage;
    });
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) {
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    widget.onSuccess?.call();
  }

  bool _validateLogin() {
    final Map<String, String> errors = <String, String>{};
    final String email = _loginEmailController.text.trim();
    final String password = _loginPasswordController.text.trim();

    if (email.isEmpty) {
      errors['email'] = LocaleKey.profileAuthValidateEmailRequired.tr;
    } else if (!_emailRegex.hasMatch(email)) {
      errors['email'] = LocaleKey.profileAuthValidateEmailInvalid.tr;
    }

    if (password.isEmpty) {
      errors['password'] = LocaleKey.profileAuthValidatePasswordRequired.tr;
    }

    setState(() {
      _loginErrors = errors;
    });
    return errors.isEmpty;
  }

  bool _validateRegister() {
    final Map<String, String> errors = <String, String>{};
    final String email = _registerEmailController.text.trim();
    final String password = _registerPasswordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty) {
      errors['email'] = LocaleKey.profileAuthValidateEmailRequired.tr;
    } else if (!_emailRegex.hasMatch(email)) {
      errors['email'] = LocaleKey.profileAuthValidateEmailInvalid.tr;
    }

    if (password.isEmpty) {
      errors['password'] = LocaleKey.profileAuthValidatePasswordRequired.tr;
    } else if (password.length < 6) {
      errors['password'] = LocaleKey.profileAuthValidatePasswordMin.tr;
    }

    if (confirmPassword.isEmpty) {
      errors['confirmPassword'] =
          LocaleKey.profileAuthValidateConfirmRequired.tr;
    } else if (password != confirmPassword) {
      errors['confirmPassword'] =
          LocaleKey.profileAuthValidateConfirmMismatch.tr;
    }

    setState(() {
      _registerErrors = errors;
    });
    return errors.isEmpty;
  }

  void _closeDialog() {
    if (_isBusy) {
      return;
    }
    Navigator.of(context).pop();
  }

  String _nameFromEmail(String email) {
    final List<String> segments = email.split('@');
    if (segments.isEmpty) {
      return email;
    }
    return segments.first.trim();
  }

  String _resolveRegisterName(String email) {
    final String profileName = (_sessionBloc.state.currentProfile?.name ?? '')
        .trim();
    if (profileName.isNotEmpty) {
      return profileName;
    }
    final String emailName = _nameFromEmail(email);
    if (emailName.isNotEmpty) {
      return emailName;
    }
    return 'Numverse User';
  }

  String _resolveErrorMessage(Object error) {
    return resolveMainSessionErrorMessage(error);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isBusy,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: AppColors.transparent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.98),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.9),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.midnight.withValues(alpha: 0.65),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: AppColors.richGold.withValues(alpha: 0.18),
                  blurRadius: 24,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: _isSuccess ? _buildSuccess() : _buildAuthContent(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      key: const ValueKey<String>('auth_success'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                AppColors.success.withValues(alpha: 0.28),
                AppColors.energyEmerald.withValues(alpha: 0.24),
              ],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.3),
                blurRadius: 22,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 54,
            ),
          ),
        ),
        18.height,
        AppGlowText(
          text: _successMessage,
          textAlign: TextAlign.center,
          style: AppStyles.h3(
            color: AppColors.success,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (_showSuccessSubtitle) ...<Widget>[
          8.height,
          Text(
            LocaleKey.profileAuthSuccessSubtitle.tr,
            textAlign: TextAlign.center,
            style: AppStyles.bodyMedium(color: AppColors.textSecondary),
          ),
        ],
        10.height,
      ],
    );
  }

  Widget _buildAuthContent() {
    return Column(
      key: const ValueKey<String>('auth_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    AppColors.energyAmber.withValues(alpha: 0.25),
                    AppColors.energyOrange.withValues(alpha: 0.22),
                  ],
                ),
              ),
              child: const Icon(
                Icons.security,
                size: 18,
                color: AppColors.energyAmber,
              ),
            ),
            10.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    LocaleKey.profileAuthDialogTitle.tr,
                    style: AppStyles.h4(fontWeight: FontWeight.w700),
                  ),
                  4.height,
                  Text(
                    LocaleKey.profileAuthDialogSubtitle.tr,
                    style: AppStyles.bodySmall(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _isBusy ? null : _closeDialog,
              icon: const Icon(Icons.close_rounded),
              color: AppColors.textMuted,
              splashRadius: 20,
            ),
          ],
        ),
        16.height,
        _buildTabs(),
        14.height,
        _activeTab == ProfileAuthDialogTab.login
            ? _buildLoginForm()
            : _buildRegisterForm(),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.deepViolet.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
      ),
      child: Row(
        children: <Widget>[
          _AuthTabButton(
            selected: _activeTab == ProfileAuthDialogTab.login,
            label: LocaleKey.profileAuthTabLogin.tr,
            onTap: () => _setActiveTab(ProfileAuthDialogTab.login),
          ),
          _AuthTabButton(
            selected: _activeTab == ProfileAuthDialogTab.register,
            label: LocaleKey.profileAuthTabRegister.tr,
            onTap: () => _setActiveTab(ProfileAuthDialogTab.register),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _AuthInputField(
          label: LocaleKey.loginEmailLabel.tr,
          hint: LocaleKey.profileAuthEmailHint.tr,
          icon: Icons.mail_outline_rounded,
          enabled: !_isLoginLoading,
          controller: _loginEmailController,
          keyboardType: TextInputType.emailAddress,
          errorText: _loginErrors['email'],
          onChanged: (_) {
            if (_loginErrors.containsKey('email') || _formError != null) {
              setState(() {
                _loginErrors = Map<String, String>.from(_loginErrors)
                  ..remove('email');
                _formError = null;
              });
            }
          },
        ),
        12.height,
        _AuthInputField(
          label: LocaleKey.loginPasswordLabel.tr,
          hint: LocaleKey.profileAuthPasswordHint.tr,
          icon: Icons.lock_outline_rounded,
          enabled: !_isLoginLoading,
          controller: _loginPasswordController,
          obscureText: !_showLoginPassword,
          errorText: _loginErrors['password'],
          onChanged: (_) {
            if (_loginErrors.containsKey('password') || _formError != null) {
              setState(() {
                _loginErrors = Map<String, String>.from(_loginErrors)
                  ..remove('password');
                _formError = null;
              });
            }
          },
          suffixIcon: IconButton(
            onPressed: _isLoginLoading
                ? null
                : () {
                    setState(() {
                      _showLoginPassword = !_showLoginPassword;
                    });
                  },
            splashRadius: 20,
            icon: Icon(
              _showLoginPassword
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: AppColors.textMuted,
            ),
          ),
        ),
        if (_formError != null) ...<Widget>[
          10.height,
          _FormErrorMessage(message: _formError!),
        ],
        16.height,
        _ActionButton(
          isLoading: _isLoginLoading,
          label: LocaleKey.loginAction.tr,
          processingLabel: LocaleKey.profileAuthProcessing.tr,
          icon: Icons.login_rounded,
          gradientColors: <Color>[
            AppColors.richGold.withValues(alpha: 0.92),
            AppColors.goldBright.withValues(alpha: 0.94),
          ],
          onTap: _submitLogin,
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _AuthInputField(
          label: LocaleKey.loginEmailLabel.tr,
          hint: LocaleKey.profileAuthEmailHint.tr,
          icon: Icons.mail_outline_rounded,
          enabled: !_isRegisterLoading,
          controller: _registerEmailController,
          keyboardType: TextInputType.emailAddress,
          errorText: _registerErrors['email'],
          onChanged: (_) {
            if (_registerErrors.containsKey('email') || _formError != null) {
              setState(() {
                _registerErrors = Map<String, String>.from(_registerErrors)
                  ..remove('email');
                _formError = null;
              });
            }
          },
        ),
        12.height,
        _AuthInputField(
          label: LocaleKey.loginPasswordLabel.tr,
          hint: LocaleKey.profileAuthPasswordHint.tr,
          icon: Icons.lock_outline_rounded,
          enabled: !_isRegisterLoading,
          controller: _registerPasswordController,
          obscureText: !_showRegisterPassword,
          errorText: _registerErrors['password'],
          onChanged: (_) {
            if (_registerErrors.containsKey('password') || _formError != null) {
              setState(() {
                _registerErrors = Map<String, String>.from(_registerErrors)
                  ..remove('password');
                _formError = null;
              });
            }
          },
          suffixIcon: IconButton(
            onPressed: _isRegisterLoading
                ? null
                : () {
                    setState(() {
                      _showRegisterPassword = !_showRegisterPassword;
                    });
                  },
            splashRadius: 20,
            icon: Icon(
              _showRegisterPassword
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: AppColors.textMuted,
            ),
          ),
        ),
        12.height,
        _AuthInputField(
          label: LocaleKey.profileAuthConfirmPasswordLabel.tr,
          hint: LocaleKey.profileAuthConfirmPasswordHint.tr,
          icon: Icons.lock_outline_rounded,
          enabled: !_isRegisterLoading,
          controller: _confirmPasswordController,
          obscureText: !_showConfirmPassword,
          errorText: _registerErrors['confirmPassword'],
          onChanged: (_) {
            if (_registerErrors.containsKey('confirmPassword') ||
                _formError != null) {
              setState(() {
                _registerErrors = Map<String, String>.from(_registerErrors)
                  ..remove('confirmPassword');
                _formError = null;
              });
            }
          },
          suffixIcon: IconButton(
            onPressed: _isRegisterLoading
                ? null
                : () {
                    setState(() {
                      _showConfirmPassword = !_showConfirmPassword;
                    });
                  },
            splashRadius: 20,
            icon: Icon(
              _showConfirmPassword
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: AppColors.textMuted,
            ),
          ),
        ),
        if (_formError != null) ...<Widget>[
          10.height,
          _FormErrorMessage(message: _formError!),
        ],
        16.height,
        _ActionButton(
          isLoading: _isRegisterLoading,
          label: LocaleKey.profileAuthRegisterAction.tr,
          processingLabel: LocaleKey.profileAuthProcessing.tr,
          icon: Icons.auto_awesome_rounded,
          gradientColors: <Color>[AppColors.richGold, AppColors.goldBright],
          onTap: _submitRegister,
        ),
        12.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              LocaleKey.profileAuthHaveAccountPrompt.tr,
              style: AppStyles.bodySmall(color: AppColors.textMuted),
            ),
            TextButton(
              onPressed: _isRegisterLoading
                  ? null
                  : () => _setActiveTab(ProfileAuthDialogTab.login),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                LocaleKey.profileAuthSwitchToLogin.tr,
                style: AppStyles.bodySmall(
                  color: AppColors.richGold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AuthTabButton extends StatelessWidget {
  const _AuthTabButton({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      AppColors.richGold.withValues(alpha: 0.94),
                      AppColors.goldBright.withValues(alpha: 0.94),
                    ],
                  )
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppStyles.bodyMedium(
                color: selected ? AppColors.midnight : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthInputField extends StatelessWidget {
  const _AuthInputField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.enabled,
    required this.controller,
    required this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.errorText,
    this.suffixIcon,
  });

  final String label;
  final String hint;
  final IconData icon;
  final bool enabled;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? errorText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppStyles.bodySmall(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        6.height,
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          style: AppStyles.bodyMedium(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppStyles.bodySmall(color: AppColors.textMuted),
            filled: true,
            fillColor: enabled
                ? AppColors.deepViolet.withValues(alpha: 0.72)
                : AppColors.deepViolet.withValues(alpha: 0.35),
            prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: (errorText == null)
                    ? AppColors.border.withValues(alpha: 0.9)
                    : AppColors.error.withValues(alpha: 0.75),
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.border.withValues(alpha: 0.55),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: (errorText == null)
                    ? AppColors.richGold.withValues(alpha: 0.8)
                    : AppColors.error,
                width: 1.1,
              ),
            ),
          ),
        ),
        if (errorText != null && errorText!.trim().isNotEmpty) ...<Widget>[
          6.height,
          _FormErrorMessage(message: errorText!),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.isLoading,
    required this.label,
    required this.processingLabel,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
  });

  final bool isLoading;
  final String label;
  final String processingLabel;
  final IconData icon;
  final List<Color> gradientColors;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: isLoading ? 0.9 : 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: gradientColors,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: gradientColors.first.withValues(alpha: 0.28),
                  blurRadius: 18,
                  spreadRadius: 0.4,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (isLoading) ...<Widget>[
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.midnight.withValues(alpha: 0.86),
                        ),
                      ),
                    ),
                    8.width,
                    Text(
                      processingLabel,
                      style: AppStyles.bodyMedium(
                        color: AppColors.midnight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ] else ...<Widget>[
                    Icon(icon, size: 18, color: AppColors.midnight),
                    8.width,
                    Text(
                      label,
                      style: AppStyles.bodyMedium(
                        color: AppColors.midnight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormErrorMessage extends StatelessWidget {
  const _FormErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          Icons.error_outline_rounded,
          size: 14,
          color: AppColors.error.withValues(alpha: 0.9),
        ),
        4.width,
        Expanded(
          child: Text(
            message,
            style: AppStyles.caption(
              color: AppColors.error.withValues(alpha: 0.95),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
