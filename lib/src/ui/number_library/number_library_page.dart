import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/ui/number_library/components/number_library_content.dart';
import 'package:test/src/ui/number_library/components/number_library_header.dart';
import 'package:test/src/ui/number_library/interactor/number_library_bloc.dart';
import 'package:test/src/ui/number_library/interactor/number_library_state.dart';
import 'package:test/src/ui/widgets/app_mystical_scaffold.dart';
import 'package:test/src/utils/app_pages.dart';

class NumberLibraryPage extends StatelessWidget {
  const NumberLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final NumberLibraryBloc bloc = Get.isRegistered<NumberLibraryBloc>()
        ? Get.find<NumberLibraryBloc>()
        : Get.put<NumberLibraryBloc>(
            NumberLibraryBloc(
              contentRepository: Get.find<INumerologyContentRepository>(),
              languageCode: Get.locale?.languageCode ?? 'vi',
            ),
          );

    return AppMysticalScaffold(
      child: SafeArea(
        bottom: false,
        child: BlocBuilder<NumberLibraryBloc, NumberLibraryState>(
          bloc: bloc,
          builder: (BuildContext context, NumberLibraryState state) {
            return Column(
              children: <Widget>[
                NumberLibraryHeader(onBackTap: () => _onBack(context)),
                Expanded(
                  child: NumberLibraryContent(
                    state: state,
                    onToggleBasicNumbers: bloc.toggleBasicNumbersExpanded,
                    onToggleMasterNumbers: bloc.toggleMasterNumbersExpanded,
                    onNumberTap: bloc.selectNumber,
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
