import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/ui/login/components/login_form.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/widgets/app_mystical_scaffold.dart';
import 'package:test/src/utils/app_pages.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppMysticalScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: LoginForm(
            onGuest: () {
              final MainSessionBloc sessionCubit = Get.find<MainSessionBloc>();
              if (sessionCubit.state.hasAnyProfile) {
                Get.offAllNamed(AppPages.main);
                return;
              }
              Get.toNamed(AppPages.onboarding);
            },
          ),
        ),
      ),
    );
  }
}
