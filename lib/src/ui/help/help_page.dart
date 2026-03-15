import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/ui/help/components/help_faq_section.dart';
import 'package:test/src/ui/help/components/help_header.dart';
import 'package:test/src/ui/help/components/help_support_card.dart';
import 'package:test/src/ui/help/interactor/help_bloc.dart';
import 'package:test/src/ui/help/interactor/help_state.dart';
import 'package:test/src/ui/widgets/app_mystical_scaffold.dart';
import 'package:test/src/utils/app_pages.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final HelpBloc bloc = Get.isRegistered<HelpBloc>()
        ? Get.find<HelpBloc>()
        : Get.put<HelpBloc>(HelpBloc());

    return AppMysticalScaffold(
      child: SafeArea(
        bottom: false,
        child: BlocBuilder<HelpBloc, HelpState>(
          bloc: bloc,
          builder: (BuildContext context, HelpState state) {
            return Column(
              children: <Widget>[
                HelpHeader(onBackTap: () => _onBackTap(context)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      children: <Widget>[
                        const HelpSupportCard(),
                        const SizedBox(height: 16),
                        HelpFaqSection(
                          state: state,
                          onToggleFaq: bloc.toggleFaq,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onBackTap(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Get.offAllNamed(AppPages.main);
  }
}
