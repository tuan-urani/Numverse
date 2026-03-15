import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/ui/universal_day/components/universal_day_content.dart';
import 'package:test/src/ui/universal_day/components/universal_day_header.dart';
import 'package:test/src/ui/universal_day/interactor/universal_day_bloc.dart';
import 'package:test/src/ui/universal_day/interactor/universal_day_state.dart';
import 'package:test/src/ui/widgets/app_mystical_scaffold.dart';
import 'package:test/src/utils/app_pages.dart';

class UniversalDayPage extends StatelessWidget {
  const UniversalDayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final UniversalDayBloc bloc = Get.isRegistered<UniversalDayBloc>()
        ? Get.find<UniversalDayBloc>()
        : Get.put<UniversalDayBloc>(
            UniversalDayBloc(
              contentRepository: Get.find<INumerologyContentRepository>(),
              languageCode: Get.locale?.languageCode ?? 'vi',
            ),
          );

    return AppMysticalScaffold(
      child: SafeArea(
        bottom: false,
        child: BlocBuilder<UniversalDayBloc, UniversalDayState>(
          bloc: bloc,
          builder: (BuildContext context, UniversalDayState state) {
            return Column(
              children: <Widget>[
                UniversalDayHeader(onBackTap: () => _onBack(context)),
                Expanded(
                  child: SingleChildScrollView(
                    child: UniversalDayContent(state: state),
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
}
