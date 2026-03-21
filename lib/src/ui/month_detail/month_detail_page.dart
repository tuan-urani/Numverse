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
import 'package:test/src/ui/month_detail/components/month_detail_content.dart';
import 'package:test/src/ui/widgets/app_detail_sticky_header.dart';
import 'package:test/src/ui/widgets/app_mystical_scaffold.dart';

class MonthDetailPage extends StatelessWidget {
  const MonthDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final MainSessionBloc sessionBloc = Get.find<MainSessionBloc>();
    return BlocBuilder<MainSessionBloc, MainSessionState>(
      bloc: sessionBloc,
      builder: (BuildContext context, MainSessionState state) {
        final int personalMonth = _resolvePersonalMonthNumber(state);
        final INumerologyContentRepository contentRepository =
            Get.find<INumerologyContentRepository>();
        final String languageCode = Get.locale?.languageCode ?? 'vi';
        final NumerologyPersonalMonthContent monthContent = contentRepository
            .getPersonalMonthContent(
              number: personalMonth,
              languageCode: languageCode,
            );
        final DateTime now = DateTime.now();
        final String periodLabel =
            '${now.month.toString().padLeft(2, '0')}/${now.year}';

        return AppMysticalScaffold(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                AppDetailStickyHeader(title: LocaleKey.monthDetailTitle.tr),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    child: MonthDetailContent(
                      personalMonthNumber: personalMonth,
                      periodLabel: periodLabel,
                      content: monthContent,
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

  int _resolvePersonalMonthNumber(MainSessionState state) {
    final String profileId =
        state.currentProfile?.id ?? MainSessionBloc.guestProfileId;
    final ProfileTimeLifeSnapshot? snapshot =
        state.timeLifeByProfileId[profileId];
    final profile = state.currentProfile;
    if (profile == null) {
      final int? universalNumber = snapshot?.valueOf(
        ProfileTimeLifeSnapshot.universalMonthMetric,
      );
      if (universalNumber != null) {
        return universalNumber;
      }
      return NumerologyHelper.calculateUniversalMonthNumber(DateTime.now());
    }
    final int? personalNumber = snapshot?.valueOf(
      ProfileTimeLifeSnapshot.personalMonthMetric,
    );
    if (personalNumber != null) {
      return personalNumber;
    }
    return NumerologyHelper.calculatePersonalMonthNumber(
      birthDate: profile.birthDate,
      date: DateTime.now(),
    );
  }
}
