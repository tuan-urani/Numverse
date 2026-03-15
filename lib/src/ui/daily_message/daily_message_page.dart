import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/core/model/profile_time_life_snapshot.dart';
import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/helper/numerology_helper.dart';
import 'package:test/src/ui/daily_message/components/daily_message_content.dart';
import 'package:test/src/ui/daily_message/components/daily_message_header.dart';
import 'package:test/src/ui/daily_message/interactor/daily_message_bloc.dart';
import 'package:test/src/ui/daily_message/interactor/daily_message_state.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/widgets/app_mystical_scaffold.dart';
import 'package:test/src/utils/app_pages.dart';

class DailyMessagePage extends StatelessWidget {
  const DailyMessagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final DailyMessageBloc bloc = Get.isRegistered<DailyMessageBloc>()
        ? Get.find<DailyMessageBloc>()
        : Get.put<DailyMessageBloc>(
            DailyMessageBloc(
              contentRepository: Get.find<INumerologyContentRepository>(),
              languageCode: Get.locale?.languageCode ?? 'vi',
              dayNumberProvider: _resolveDailyMessageNumber,
            ),
          );

    return AppMysticalScaffold(
      child: SafeArea(
        bottom: false,
        child: BlocBuilder<DailyMessageBloc, DailyMessageState>(
          bloc: bloc,
          builder: (BuildContext context, DailyMessageState state) {
            return Column(
              children: <Widget>[
                DailyMessageHeader(onBackTap: () => _onBack(context)),
                Expanded(
                  child: SingleChildScrollView(
                    child: DailyMessageContent(state: state),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Get.offAllNamed(AppPages.main);
  }

  static int _resolveDailyMessageNumber() {
    if (!Get.isRegistered<MainSessionBloc>()) {
      return NumerologyHelper.calculateUniversalDayNumber();
    }

    final MainSessionBloc sessionCubit = Get.find<MainSessionBloc>();
    final String profileId =
        sessionCubit.state.currentProfile?.id ??
        ProfileTimeLifeSnapshot.guestProfileId;
    final int? value = sessionCubit.state.timeLifeByProfileId[profileId]
        ?.valueOf(ProfileTimeLifeSnapshot.dailyMessageNumberMetric);
    return value ?? NumerologyHelper.calculateUniversalDayNumber();
  }
}
