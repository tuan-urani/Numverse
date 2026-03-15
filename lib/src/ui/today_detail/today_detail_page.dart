import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/core/model/numerology_content_models.dart';
import 'package:test/src/core/model/profile_time_life_snapshot.dart';
import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/helper/numerology_helper.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_state.dart';
import 'package:test/src/ui/today_detail/components/today_detail_content.dart';
import 'package:test/src/ui/widgets/app_detail_sticky_header.dart';
import 'package:test/src/ui/widgets/app_mystical_scaffold.dart';

class TodayDetailPage extends StatelessWidget {
  const TodayDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final MainSessionBloc sessionBloc = Get.find<MainSessionBloc>();

    return BlocBuilder<MainSessionBloc, MainSessionState>(
      bloc: sessionBloc,
      builder: (BuildContext context, MainSessionState state) {
        final String profileId =
            state.currentProfile?.id ?? MainSessionBloc.guestProfileId;
        final int personalDay =
            state.timeLifeByProfileId[profileId]?.valueOf(
              ProfileTimeLifeSnapshot.personalDayMetric,
            ) ??
            _fallbackPersonalDay(state);
        final INumerologyContentRepository contentRepository =
            Get.find<INumerologyContentRepository>();
        final String languageCode = Get.locale?.languageCode ?? 'vi';
        final NumerologyTodayPersonalNumberContent personalContent =
            contentRepository.getTodayPersonalNumberContent(
              number: personalDay,
              languageCode: languageCode,
            );

        return AppMysticalScaffold(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                AppDetailStickyHeader(title: LocaleKey.todayDetailTitle.tr),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    child: TodayDetailContent(
                      personalDayNumber: personalDay,
                      personalContent: personalContent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _fallbackPersonalDay(MainSessionState state) {
    final profile = state.currentProfile;
    if (profile == null) {
      return 0;
    }
    return NumerologyHelper.calculatePersonalDayNumber(
      birthDate: profile.birthDate,
      date: DateTime.now(),
    );
  }
}
