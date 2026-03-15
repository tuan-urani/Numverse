import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/ui/angel_numbers/components/angel_numbers_content.dart';
import 'package:test/src/ui/angel_numbers/components/angel_numbers_header.dart';
import 'package:test/src/ui/angel_numbers/interactor/angel_numbers_bloc.dart';
import 'package:test/src/ui/angel_numbers/interactor/angel_numbers_state.dart';
import 'package:test/src/ui/widgets/app_mystical_scaffold.dart';
import 'package:test/src/utils/app_pages.dart';

class AngelNumbersPage extends StatelessWidget {
  const AngelNumbersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AngelNumbersBloc bloc = Get.isRegistered<AngelNumbersBloc>()
        ? Get.find<AngelNumbersBloc>()
        : Get.put<AngelNumbersBloc>(
            AngelNumbersBloc(
              contentRepository: Get.find<INumerologyContentRepository>(),
              languageCode: Get.locale?.languageCode ?? 'vi',
            ),
          );

    return AppMysticalScaffold(
      child: SafeArea(
        bottom: false,
        child: BlocBuilder<AngelNumbersBloc, AngelNumbersState>(
          bloc: bloc,
          builder: (BuildContext context, AngelNumbersState state) {
            return Column(
              children: <Widget>[
                AngelNumbersHeader(onBackTap: () => _onBack(context)),
                Expanded(
                  child: AngelNumbersContent(
                    state: state,
                    onSearchChanged: bloc.onSearchTextChanged,
                    onSearchTap: bloc.onSearch,
                    onQuickSearchTap: bloc.onQuickSearch,
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
