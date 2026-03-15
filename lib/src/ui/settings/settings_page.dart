import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/locale/translation_manager.dart';
import 'package:test/src/ui/settings/components/settings_appearance_card.dart';
import 'package:test/src/ui/settings/components/settings_header.dart';
import 'package:test/src/ui/settings/components/settings_sound_card.dart';
import 'package:test/src/ui/settings/interactor/settings_bloc.dart';
import 'package:test/src/ui/settings/interactor/settings_event.dart';
import 'package:test/src/ui/settings/interactor/settings_state.dart';
import 'package:test/src/ui/widgets/app_mystical_scaffold.dart';
import 'package:test/src/utils/app_pages.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsBloc bloc = Get.isRegistered<SettingsBloc>()
        ? Get.find<SettingsBloc>()
        : Get.put<SettingsBloc>(SettingsBloc());

    return AppMysticalScaffold(
      child: SafeArea(
        bottom: false,
        child: BlocBuilder<SettingsBloc, SettingsState>(
          bloc: bloc,
          builder: (BuildContext context, SettingsState state) {
            return Column(
              children: <Widget>[
                SettingsHeader(onBackTap: () => _onBackTap(context)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      children: <Widget>[
                        SettingsAppearanceCard(
                          state: state,
                          onThemeChanged: (SettingsThemeMode mode) {
                            bloc.add(SettingsThemeChanged(mode));
                          },
                          onLanguageChanged: (SettingsLanguage language) {
                            bloc.add(SettingsLanguageChanged(language));
                            _applyLocale(language);
                          },
                        ),
                        const SizedBox(height: 16),
                        SettingsSoundCard(
                          state: state,
                          onToggleSound: () {
                            bloc.add(const SettingsSoundToggled());
                          },
                          onToggleNotifications: () {
                            bloc.add(const SettingsNotificationsToggled());
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onBackTap(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Get.offAllNamed(AppPages.main);
  }

  void _applyLocale(SettingsLanguage language) {
    final Locale locale = switch (language) {
      SettingsLanguage.vi => TranslationManager.appLocales[0],
      SettingsLanguage.en => TranslationManager.appLocales[1],
    };
    Get.updateLocale(locale);
  }
}
