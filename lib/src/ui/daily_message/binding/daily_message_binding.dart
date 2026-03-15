import 'package:get/get.dart';

import 'package:test/src/core/model/profile_time_life_snapshot.dart';
import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/helper/numerology_helper.dart';
import 'package:test/src/ui/daily_message/interactor/daily_message_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';

class DailyMessageBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<DailyMessageBloc>()) {
      Get.lazyPut<DailyMessageBloc>(() {
        return DailyMessageBloc(
          contentRepository: Get.find<INumerologyContentRepository>(),
          languageCode: Get.locale?.languageCode ?? 'vi',
          dayNumberProvider: _resolveDailyMessageNumber,
        );
      });
    }
  }

  int _resolveDailyMessageNumber() {
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
