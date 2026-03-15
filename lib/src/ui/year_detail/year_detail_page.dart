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
import 'package:test/src/ui/widgets/app_detail_sticky_header.dart';
import 'package:test/src/ui/widgets/app_mystical_scaffold.dart';
import 'package:test/src/ui/year_detail/components/year_detail_content.dart';

class YearDetailPage extends StatelessWidget {
  const YearDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final MainSessionBloc sessionBloc = Get.find<MainSessionBloc>();
    return BlocBuilder<MainSessionBloc, MainSessionState>(
      bloc: sessionBloc,
      builder: (BuildContext context, MainSessionState state) {
        final int personalYear = _resolvePersonalYearNumber(state);
        final INumerologyContentRepository contentRepository =
            Get.find<INumerologyContentRepository>();
        final String languageCode = Get.locale?.languageCode ?? 'vi';
        final NumerologyPersonalYearContent yearContent = contentRepository
            .getPersonalYearContent(
              number: personalYear,
              languageCode: languageCode,
            );
        final DateTime now = DateTime.now();
        final String periodLabel = '${now.year}';

        return AppMysticalScaffold(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                AppDetailStickyHeader(title: LocaleKey.yearDetailTitle.tr),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    child: YearDetailContent(
                      personalYearNumber: personalYear,
                      periodLabel: periodLabel,
                      content: yearContent,
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

  int _resolvePersonalYearNumber(MainSessionState state) {
    final String profileId =
        state.currentProfile?.id ?? MainSessionBloc.guestProfileId;
    final int? number = state.timeLifeByProfileId[profileId]?.valueOf(
      ProfileTimeLifeSnapshot.personalYearMetric,
    );
    if (number != null) {
      return number;
    }

    final profile = state.currentProfile;
    if (profile == null) {
      return NumerologyHelper.calculateUniversalYearNumber(DateTime.now());
    }
    return NumerologyHelper.calculatePersonalYearNumber(
      birthDate: profile.birthDate,
      date: DateTime.now(),
    );
  }
}
