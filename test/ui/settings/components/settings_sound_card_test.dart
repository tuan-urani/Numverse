import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:test/src/ui/settings/components/settings_sound_card.dart';
import 'package:test/src/ui/settings/interactor/settings_state.dart';

void main() {
  testWidgets('tapping daily alarm switch triggers callback', (
    WidgetTester tester,
  ) async {
    bool didToggleDailyAlarm = false;

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: SettingsSoundCard(
            state: SettingsState.initial(),
            onToggleSound: () {},
            onToggleNotifications: () {},
            onToggleDailyAlarm: () {
              didToggleDailyAlarm = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(InkWell).at(2));
    await tester.pumpAndSettle();

    expect(didToggleDailyAlarm, isTrue);
  });
}
