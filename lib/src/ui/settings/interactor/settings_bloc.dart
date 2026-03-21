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
    bool effectiveEnabled = _appShared.getDailyAlarmEnabled();
    if (state.dailyAlarmEnabled != effectiveEnabled) {
      emit(state.copyWith(dailyAlarmEnabled: effectiveEnabled));
    }

    if (_cloudAccountRepository.isConfigured) {
      try {
        final DailyAlarmSettings settings = await _cloudAccountRepository
            .fetchDailyAlarmSettings();
        effectiveEnabled = settings.enabled;
        await _appShared.setDailyAlarmEnabled(effectiveEnabled);
        if (state.dailyAlarmEnabled != effectiveEnabled) {
          emit(state.copyWith(dailyAlarmEnabled: effectiveEnabled));
        }
      } catch (_) {
        // Keep local cache when cloud read fails.
      }
    }

    await _dailyAlarmNotificationService.applyAlarmPreference(
      enabled: effectiveEnabled,
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

    final bool previousValue = state.dailyAlarmEnabled;
    final bool nextValue = !previousValue;
    final String localeCode = _localeCodeProvider();

    emit(state.copyWith(dailyAlarmEnabled: nextValue, dailyAlarmSyncing: true));

    try {
      await _appShared.setDailyAlarmEnabled(nextValue);
      await _dailyAlarmNotificationService.applyAlarmPreference(
        enabled: nextValue,
        localeCode: localeCode,
      );

      if (_cloudAccountRepository.isConfigured) {
        final String timezoneId = await _dailyAlarmNotificationService
            .resolveCurrentTimezoneId();
        final DailyAlarmSettings cloudSettings = await _cloudAccountRepository
            .updateDailyAlarmSettings(
              enabled: nextValue,
              time: DailyAlarmSettings.defaultTime,
              timezone: timezoneId,
            );
        await _appShared.setDailyAlarmEnabled(cloudSettings.enabled);
        emit(
          state.copyWith(
            dailyAlarmEnabled: cloudSettings.enabled,
            dailyAlarmSyncing: false,
          ),
        );
        return;
      }

      emit(state.copyWith(dailyAlarmSyncing: false));
    } catch (_) {
      await _appShared.setDailyAlarmEnabled(previousValue);
      await _dailyAlarmNotificationService.applyAlarmPreference(
        enabled: previousValue,
        localeCode: localeCode,
      );
      emit(
        state.copyWith(
          dailyAlarmEnabled: previousValue,
          dailyAlarmSyncing: false,
        ),
      );
    }
  }
}
