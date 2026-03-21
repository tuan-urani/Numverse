import 'package:equatable/equatable.dart';

enum SettingsThemeMode { light, dark }

enum SettingsLanguage { vi, en }

class SettingsState extends Equatable {
  const SettingsState({
    required this.theme,
    required this.language,
    required this.soundEnabled,
    required this.pushNotificationsEnabled,
    required this.dailyAlarmEnabled,
    required this.dailyAlarmSyncing,
  });

  factory SettingsState.initial() {
    return const SettingsState(
      theme: SettingsThemeMode.dark,
      language: SettingsLanguage.vi,
      soundEnabled: true,
      pushNotificationsEnabled: true,
      dailyAlarmEnabled: true,
      dailyAlarmSyncing: false,
    );
  }

  final SettingsThemeMode theme;
  final SettingsLanguage language;
  final bool soundEnabled;
  final bool pushNotificationsEnabled;
  final bool dailyAlarmEnabled;
  final bool dailyAlarmSyncing;

  SettingsState copyWith({
    SettingsThemeMode? theme,
    SettingsLanguage? language,
    bool? soundEnabled,
    bool? pushNotificationsEnabled,
    bool? dailyAlarmEnabled,
    bool? dailyAlarmSyncing,
  }) {
    return SettingsState(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      dailyAlarmEnabled: dailyAlarmEnabled ?? this.dailyAlarmEnabled,
      dailyAlarmSyncing: dailyAlarmSyncing ?? this.dailyAlarmSyncing,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    theme,
    language,
    soundEnabled,
    pushNotificationsEnabled,
    dailyAlarmEnabled,
    dailyAlarmSyncing,
  ];
}
