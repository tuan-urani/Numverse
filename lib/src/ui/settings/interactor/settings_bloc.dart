import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:test/src/ui/settings/interactor/settings_event.dart';
import 'package:test/src/ui/settings/interactor/settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(SettingsState.initial()) {
    on<SettingsThemeChanged>(_onThemeChanged);
    on<SettingsLanguageChanged>(_onLanguageChanged);
    on<SettingsSoundToggled>(_onSoundToggled);
    on<SettingsNotificationsToggled>(_onNotificationsToggled);
  }

  void _onThemeChanged(
    SettingsThemeChanged event,
    Emitter<SettingsState> emit,
  ) {
    final SettingsThemeMode mode = event.mode;
    if (state.theme == mode) {
      return;
    }
    emit(state.copyWith(theme: mode));
  }

  void _onLanguageChanged(
    SettingsLanguageChanged event,
    Emitter<SettingsState> emit,
  ) {
    final SettingsLanguage language = event.language;
    if (state.language == language) {
      return;
    }
    emit(state.copyWith(language: language));
  }

  void _onSoundToggled(
    SettingsSoundToggled event,
    Emitter<SettingsState> emit,
  ) {
    emit(state.copyWith(soundEnabled: !state.soundEnabled));
  }

  void _onNotificationsToggled(
    SettingsNotificationsToggled event,
    Emitter<SettingsState> emit,
  ) {
    emit(
      state.copyWith(pushNotificationsEnabled: !state.pushNotificationsEnabled),
    );
  }
}
