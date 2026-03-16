import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/widgets/app_primary_button.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class AdminLoginPanel extends StatelessWidget {
  const AdminLoginPanel({
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onLoginTap,
    super.key,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onLoginTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                LocaleKey.adminLoginTitle.tr,
                style: AppStyles.h4(fontWeight: FontWeight.w700),
              ),
              6.height,
              Text(
                LocaleKey.adminLoginSubtitle.tr,
                style: AppStyles.bodySmall(color: AppColors.textMuted),
              ),
              16.height,
              Text(
                LocaleKey.adminEmailLabel.tr,
                style: AppStyles.caption(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              6.height,
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: LocaleKey.adminEmailHint.tr,
                ),
              ),
              12.height,
              Text(
                LocaleKey.adminPasswordLabel.tr,
                style: AppStyles.caption(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              6.height,
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: LocaleKey.adminPasswordHint.tr,
                ),
              ),
              16.height,
              AppPrimaryButton(
                label: isLoading
                    ? LocaleKey.commonLoading.tr
                    : LocaleKey.adminLoginAction.tr,
                onPressed: isLoading ? null : onLoginTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
