import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:test/src/core/model/daily_alarm_settings.dart';
import 'package:test/src/core/repository/interface/i_cloud_account_repository.dart';
import 'package:test/src/core/service/interface/i_daily_alarm_notification_service.dart';
import 'package:test/src/ui/settings/interactor/settings_event.dart';
import 'package:test/src/ui/settings/interactor/settings_state.dart';
import 'package:test/src/utils/app_shared.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({
    required ICloudAccountRepository cloudAccountRepository,
    required AppShared appShared,
    required IDailyAlarmNotificationService dailyAlarmNotificationService,
    required String Function() localeCodeProvider,
  }) : _cloudAccountRepository = cloudAccountRepository,
       _appShared = appShared,
       _dailyAlarmNotificationService = dailyAlarmNotificationService,
       _localeCodeProvider = localeCodeProvider,
       super(SettingsState.initial()) {
    on<SettingsInitialized>(_onInitialized);
    on<SettingsThemeChanged>(_onThemeChanged);
    on<SettingsLanguageChanged>(_onLanguageChanged);
    on<SettingsSoundToggled>(_onSoundToggled);
    on<SettingsNotificationsToggled>(_onNotificationsToggled);
    on<SettingsDailyAlarmToggled>(_onDailyAlarmToggled);

    add(const SettingsInitialized());
  }

  final ICloudAccountRepository _cloudAccountRepository;
  final AppShared _appShared;
  final IDailyAlarmNotificationService _dailyAlarmNotificationService;
  final String Function() _localeCodeProvider;

  Future<void> _onInitialized(
    SettingsInitialized event,
    Emitter<SettingsState> emit,
  ) async {
    DailyAlarmSettings effectiveSettings = _loadCachedAlarmSettings();
    _emitAlarmSettings(
      emit,
      settings: effectiveSettings,
      syncing: state.dailyAlarmSyncing,
    );

    if (_cloudAccountRepository.isConfigured) {
      try {
        final DailyAlarmSettings settings = await _cloudAccountRepository
            .fetchDailyAlarmSettings();
        effectiveSettings = settings;
        await _persistAlarmSettings(settings);
        _emitAlarmSettings(
          emit,
          settings: effectiveSettings,
          syncing: state.dailyAlarmSyncing,
        );
      } catch (_) {
        // Keep local cache when cloud read fails.
      }
    }

    await _dailyAlarmNotificationService.applyAlarmPreference(
      settings: effectiveSettings,
      localeCode: _localeCodeProvider(),
    );
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

  Future<void> _onDailyAlarmToggled(
    SettingsDailyAlarmToggled event,
    Emitter<SettingsState> emit,
  ) async {
    if (state.dailyAlarmSyncing) {
      return;
    }

    final DailyAlarmSettings previousSettings = DailyAlarmSettings(
      enabled: state.dailyAlarmEnabled,
      time: state.dailyAlarmTime,
      timezone: state.dailyAlarmTimezone,
    );
    final DailyAlarmSettings nextSettings = previousSettings.copyWith(
      enabled: !previousSettings.enabled,
    );
    final String localeCode = _localeCodeProvider();

    _emitAlarmSettings(emit, settings: nextSettings, syncing: true);

    try {
      await _persistAlarmSettings(nextSettings);
      await _dailyAlarmNotificationService.applyAlarmPreference(
        settings: nextSettings,
        localeCode: localeCode,
      );

      if (_cloudAccountRepository.isConfigured) {
        final String timezoneId = await _dailyAlarmNotificationService
            .resolveCurrentTimezoneId();
        final DailyAlarmSettings cloudSettings = await _cloudAccountRepository
            .updateDailyAlarmSettings(
              enabled: nextSettings.enabled,
              time: nextSettings.time,
              timezone: timezoneId,
            );
        await _persistAlarmSettings(cloudSettings);
        await _dailyAlarmNotificationService.applyAlarmPreference(
          settings: cloudSettings,
          localeCode: localeCode,
        );
        _emitAlarmSettings(emit, settings: cloudSettings, syncing: false);
        return;
      }

      _emitAlarmSettings(emit, settings: nextSettings, syncing: false);
    } catch (_) {
      await _persistAlarmSettings(previousSettings);
      await _dailyAlarmNotificationService.applyAlarmPreference(
        settings: previousSettings,
        localeCode: localeCode,
      );
      _emitAlarmSettings(emit, settings: previousSettings, syncing: false);
    }
  }

  DailyAlarmSettings _loadCachedAlarmSettings() {
    final String time =
        _appShared.getDailyAlarmTime() ?? DailyAlarmSettings.defaultTime;
    final String timezone =
        _appShared.getDailyAlarmTimezone() ??
        DailyAlarmSettings.defaultTimezone;
    return DailyAlarmSettings(
      enabled: _appShared.getDailyAlarmEnabled(),
      time: time,
      timezone: timezone,
    );
  }

  Future<void> _persistAlarmSettings(DailyAlarmSettings settings) async {
    await _appShared.setDailyAlarmEnabled(settings.enabled);
    await _appShared.setDailyAlarmTime(settings.time);
    await _appShared.setDailyAlarmTimezone(settings.timezone);
  }

  void _emitAlarmSettings(
    Emitter<SettingsState> emit, {
    required DailyAlarmSettings settings,
    required bool syncing,
  }) {
    final bool isUnchanged =
        state.dailyAlarmEnabled == settings.enabled &&
        state.dailyAlarmTime == settings.time &&
        state.dailyAlarmTimezone == settings.timezone &&
        state.dailyAlarmSyncing == syncing;
    if (isUnchanged) {
      return;
    }

    emit(
      state.copyWith(
        dailyAlarmEnabled: settings.enabled,
        dailyAlarmTime: settings.time,
        dailyAlarmTimezone: settings.timezone,
        dailyAlarmSyncing: syncing,
      ),
    );
  }
}
