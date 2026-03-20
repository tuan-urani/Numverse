import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/login/interactor/login_bloc.dart';
import 'package:test/src/ui/login/interactor/login_state.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_error_resolver.dart';
import 'package:test/src/ui/widgets/app_glow_text.dart';
import 'package:test/src/ui/widgets/app_mystical_card.dart';
import 'package:test/src/ui/widgets/app_primary_button.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({
    super.key,
    this.onGuest,
    this.showGuestAction = true,
    this.title,
    this.subtitle,
    this.submitLabel,
    this.onLoginSuccess,
  });

  final VoidCallback? onGuest;
  final bool showGuestAction;
  final String? title;
  final String? subtitle;
  final String? submitLabel;
  final VoidCallback? onLoginSuccess;

  @override
  Widget build(BuildContext context) {
    final LoginBloc bloc = Get.isRegistered<LoginBloc>()
        ? Get.find<LoginBloc>()
        : Get.put<LoginBloc>(LoginBloc());

    return BlocBuilder<LoginBloc, LoginState>(
      bloc: bloc,
      builder: (BuildContext context, LoginState state) {
        return Column(
          children: <Widget>[
            AppGlowText(
              text: title ?? LocaleKey.loginTitle.tr,
              style: AppStyles.h2(),
            ),
            8.height,
            Text(
              subtitle ?? LocaleKey.loginSubtitle.tr,
              textAlign: TextAlign.center,
              style: AppStyles.bodyMedium(color: AppColors.textSecondary),
            ),
            20.height,
            AppMysticalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    LocaleKey.loginEmailLabel.tr,
                    style: AppStyles.bodySmall(color: AppColors.textMuted),
                  ),
                  8.height,
                  _InputField(
                    keyboardType: TextInputType.emailAddress,
                    onChanged: bloc.updateEmail,
                  ),
                  14.height,
                  Text(
                    LocaleKey.loginPasswordLabel.tr,
                    style: AppStyles.bodySmall(color: AppColors.textMuted),
                  ),
                  8.height,
                  _InputField(
                    obscureText: true,
                    onChanged: bloc.updatePassword,
                  ),
                  18.height,
                  AppPrimaryButton(
                    label: state.submitting
                        ? LocaleKey.commonLoading.tr
                        : (submitLabel ?? LocaleKey.loginAction.tr),
                    onPressed: state.canSubmit
                        ? () async {
                            final MainSessionBloc sessionCubit =
                                Get.find<MainSessionBloc>();
                            try {
                              await bloc.submit(() async {
                                await sessionCubit.login(
                                  email: state.email,
                                  password: state.password,
                                  name: state.email.split('@').first,
                                );
                              });
                              onLoginSuccess?.call();
                            } catch (error) {
                              if (!context.mounted) {
                                return;
                              }
                              Get.snackbar(
                                LocaleKey.commonError.tr,
                                _resolveErrorMessage(error),
                                backgroundColor: AppColors.deepViolet
                                    .withValues(alpha: 0.9),
                                colorText: AppColors.textPrimary,
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            }
                          }
                        : null,
                    leading: const Icon(Icons.login, color: AppColors.midnight),
                  ),
                  if (showGuestAction) ...<Widget>[
                    12.height,
                    AppPrimaryButton(
                      label: LocaleKey.loginGuestAction.tr,
                      onPressed: onGuest,
                      leading: const Icon(
                        Icons.auto_awesome,
                        color: AppColors.midnight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _resolveErrorMessage(Object error) {
    return resolveMainSessionErrorMessage(error);
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    this.keyboardType,
    this.obscureText = false,
    required this.onChanged,
  });

  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      style: AppStyles.bodyMedium(),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.deepViolet.withValues(alpha: 0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.richGold.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}
