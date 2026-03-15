import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/ui/personal_portrait/components/personal_portrait_content.dart';
import 'package:test/src/ui/personal_portrait/components/personal_portrait_header.dart';
import 'package:test/src/ui/personal_portrait/interactor/personal_portrait_bloc.dart';
import 'package:test/src/ui/personal_portrait/interactor/personal_portrait_state.dart';
import 'package:test/src/ui/widgets/app_mystical_scaffold.dart';
import 'package:test/src/utils/app_pages.dart';

class PersonalPortraitPage extends StatelessWidget {
  const PersonalPortraitPage({super.key});

  @override
  Widget build(BuildContext context) {
    final PersonalPortraitBloc bloc = Get.isRegistered<PersonalPortraitBloc>()
        ? Get.find<PersonalPortraitBloc>()
        : Get.put<PersonalPortraitBloc>(PersonalPortraitBloc());

    return AppMysticalScaffold(
      child: SafeArea(
        bottom: false,
        child: BlocBuilder<PersonalPortraitBloc, PersonalPortraitState>(
          bloc: bloc,
          builder: (BuildContext context, PersonalPortraitState state) {
            return Column(
              children: <Widget>[
                PersonalPortraitHeader(onBackTap: () => _onBack(context)),
                Expanded(
                  child: SingleChildScrollView(
                    child: PersonalPortraitContent(state: state),
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
