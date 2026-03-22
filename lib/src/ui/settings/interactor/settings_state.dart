import 'package:equatable/equatable.dart';
import 'package:test/src/core/model/daily_alarm_settings.dart';

enum SettingsThemeMode { light, dark }

enum SettingsLanguage { vi, en }

class SettingsState extends Equatable {
  const SettingsState({
    required this.theme,
    required this.language,
    required this.soundEnabled,
    required this.pushNotificationsEnabled,
    required this.dailyAlarmEnabled,
    required this.dailyAlarmTime,
    required this.dailyAlarmTimezone,
    required this.dailyAlarmSyncing,
  });

  factory SettingsState.initial() {
    return const SettingsState(
      theme: SettingsThemeMode.dark,
      language: SettingsLanguage.vi,
      soundEnabled: true,
      pushNotificationsEnabled: true,
      dailyAlarmEnabled: true,
      dailyAlarmTime: DailyAlarmSettings.defaultTime,
      dailyAlarmTimezone: DailyAlarmSettings.defaultTimezone,
      dailyAlarmSyncing: false,
    );
  }

  final SettingsThemeMode theme;
  final SettingsLanguage language;
  final bool soundEnabled;
  final bool pushNotificationsEnabled;
  final bool dailyAlarmEnabled;
  final String dailyAlarmTime;
  final String dailyAlarmTimezone;
  final bool dailyAlarmSyncing;

  SettingsState copyWith({
    SettingsThemeMode? theme,
    SettingsLanguage? language,
    bool? soundEnabled,
    bool? pushNotificationsEnabled,
    bool? dailyAlarmEnabled,
    String? dailyAlarmTime,
    String? dailyAlarmTimezone,
    bool? dailyAlarmSyncing,
  }) {
    return SettingsState(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      dailyAlarmEnabled: dailyAlarmEnabled ?? this.dailyAlarmEnabled,
      dailyAlarmTime: (dailyAlarmTime ?? this.dailyAlarmTime).trim(),
      dailyAlarmTimezone: (dailyAlarmTimezone ?? this.dailyAlarmTimezone)
          .trim(),
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
    dailyAlarmTime,
    dailyAlarmTimezone,
    dailyAlarmSyncing,
  ];
}
