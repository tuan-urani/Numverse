import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/di/di_graph_setup.dart';
import 'package:test/src/locale/translation_manager.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_pages.dart';
import 'package:test/src/utils/app_styles.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependenciesGraph();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData baseTheme = ThemeData.dark(useMaterial3: true);
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.splash,
      getPages: AppPages.pages,
      translations: TranslationManager(),
      locale: TranslationManager.defaultLocale,
      fallbackLocale: TranslationManager.fallbackLocale,
      builder: (BuildContext context, Widget? child) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: baseTheme.colorScheme.copyWith(
          primary: AppColors.richGold,
          secondary: AppColors.goldBright,
          tertiary: AppColors.starlight,
          surface: AppColors.card,
          onSurface: AppColors.textPrimary,
          onPrimary: AppColors.midnight,
          onSecondary: AppColors.midnight,
          error: AppColors.error,
        ),
        textTheme: baseTheme.textTheme.apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),
        appBarTheme: AppBarTheme(
          centerTitle: false,
          backgroundColor: AppColors.card.withValues(alpha: 0.88),
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          surfaceTintColor: AppColors.transparent,
          iconTheme: const IconThemeData(color: AppColors.richGold),
        ),
        dividerColor: AppColors.border.withValues(alpha: 0.68),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.deepViolet.withValues(alpha: 0.7),
          labelStyle: AppStyles.bodySmall(color: AppColors.textMuted),
          hintStyle: AppStyles.bodySmall(color: AppColors.textMuted),
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
            borderSide: BorderSide(color: AppColors.richGold),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.deepViolet.withValues(alpha: 0.92),
          contentTextStyle: AppStyles.bodyMedium(color: AppColors.textPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: AppColors.richGold.withValues(alpha: 0.3)),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      ),
    );
  }
}
