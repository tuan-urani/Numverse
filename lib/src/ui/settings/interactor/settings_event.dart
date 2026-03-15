import 'package:equatable/equatable.dart';

import 'package:test/src/ui/settings/interactor/settings_state.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();
}

final class SettingsThemeChanged extends SettingsEvent {
  const SettingsThemeChanged(this.mode);

  final SettingsThemeMode mode;

  @override
  List<Object?> get props => <Object?>[mode];
}

final class SettingsLanguageChanged extends SettingsEvent {
  const SettingsLanguageChanged(this.language);

  final SettingsLanguage language;

  @override
  List<Object?> get props => <Object?>[language];
}

final class SettingsSoundToggled extends SettingsEvent {
  const SettingsSoundToggled();

  @override
  List<Object?> get props => <Object?>[];
}

final class SettingsNotificationsToggled extends SettingsEvent {
  const SettingsNotificationsToggled();

  @override
  List<Object?> get props => <Object?>[];
}
