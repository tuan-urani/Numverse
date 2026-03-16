import 'package:get/get.dart';

import 'package:test/src/core/model/profile_time_life_snapshot.dart';
import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/helper/numerology_helper.dart';
import 'package:test/src/ui/lucky_number/interactor/lucky_number_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';

class LuckyNumberBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LuckyNumberBloc>()) {
      Get.lazyPut<LuckyNumberBloc>(() {
        return LuckyNumberBloc(
          contentRepository: Get.find<INumerologyContentRepository>(),
          languageCode: Get.locale?.languageCode ?? 'vi',
          luckyNumberProvider: _resolveLuckyNumber,
        );
      });
    }
  }

  int _resolveLuckyNumber() {
    if (!Get.isRegistered<MainSessionBloc>()) {
      return NumerologyHelper.luckyNumber();
    }

    final MainSessionBloc sessionBloc = Get.find<MainSessionBloc>();
    final String profileId =
        sessionBloc.state.currentProfile?.id ??
        ProfileTimeLifeSnapshot.guestProfileId;
    final int? value = sessionBloc.state.timeLifeByProfileId[profileId]
        ?.valueOf(ProfileTimeLifeSnapshot.luckyNumberMetric);
    return value ?? NumerologyHelper.luckyNumber();
  }
}
