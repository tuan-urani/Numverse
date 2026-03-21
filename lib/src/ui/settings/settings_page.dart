import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/core/repository/interface/i_cloud_account_repository.dart';
import 'package:test/src/core/service/interface/i_daily_alarm_notification_service.dart';
import 'package:test/src/ui/settings/components/settings_header.dart';
import 'package:test/src/ui/settings/components/settings_sound_card.dart';
import 'package:test/src/ui/settings/interactor/settings_bloc.dart';
import 'package:test/src/ui/settings/interactor/settings_event.dart';
import 'package:test/src/ui/settings/interactor/settings_state.dart';
import 'package:test/src/ui/widgets/app_mystical_scaffold.dart';
import 'package:test/src/utils/app_pages.dart';
import 'package:test/src/utils/app_shared.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsBloc bloc = Get.isRegistered<SettingsBloc>()
        ? Get.find<SettingsBloc>()
        : Get.put<SettingsBloc>(
            SettingsBloc(
              cloudAccountRepository: Get.find<ICloudAccountRepository>(),
              appShared: Get.find<AppShared>(),
              dailyAlarmNotificationService:
                  Get.find<IDailyAlarmNotificationService>(),
              localeCodeProvider: () => Get.locale?.languageCode ?? 'vi',
            ),
          );

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
                        SettingsSoundCard(
                          state: state,
                          onToggleDailyAlarm: () {
                            bloc.add(const SettingsDailyAlarmToggled());
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
}
