import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/ui/lucky_number/components/lucky_number_content.dart';
import 'package:test/src/ui/lucky_number/components/lucky_number_header.dart';
import 'package:test/src/ui/lucky_number/interactor/lucky_number_bloc.dart';
import 'package:test/src/ui/lucky_number/interactor/lucky_number_state.dart';
import 'package:test/src/ui/widgets/app_mystical_scaffold.dart';
import 'package:test/src/utils/app_pages.dart';

class LuckyNumberPage extends StatelessWidget {
  const LuckyNumberPage({super.key});

  @override
  Widget build(BuildContext context) {
    final LuckyNumberBloc bloc = Get.find<LuckyNumberBloc>();

    return AppMysticalScaffold(
      child: SafeArea(
        bottom: false,
        child: BlocBuilder<LuckyNumberBloc, LuckyNumberState>(
          bloc: bloc,
          builder: (BuildContext context, LuckyNumberState state) {
            return Column(
              children: <Widget>[
                LuckyNumberHeader(onBackTap: () => _onBack(context)),
                Expanded(
                  child: SingleChildScrollView(
                    child: LuckyNumberContent(state: state),
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
