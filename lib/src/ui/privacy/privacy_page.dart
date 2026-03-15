import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/ui/privacy/components/privacy_documents_card.dart';
import 'package:test/src/ui/privacy/components/privacy_header.dart';
import 'package:test/src/ui/privacy/components/privacy_overview_card.dart';
import 'package:test/src/ui/privacy/interactor/privacy_bloc.dart';
import 'package:test/src/ui/privacy/interactor/privacy_state.dart';
import 'package:test/src/ui/widgets/app_mystical_scaffold.dart';
import 'package:test/src/utils/app_pages.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final PrivacyBloc bloc = Get.isRegistered<PrivacyBloc>()
        ? Get.find<PrivacyBloc>()
        : Get.put<PrivacyBloc>(PrivacyBloc());

    return AppMysticalScaffold(
      child: SafeArea(
        bottom: false,
        child: BlocBuilder<PrivacyBloc, PrivacyState>(
          bloc: bloc,
          builder: (BuildContext context, PrivacyState state) {
            return Column(
              children: <Widget>[
                PrivacyHeader(onBackTap: () => _onBackTap(context)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      children: <Widget>[
                        const PrivacyOverviewCard(),
                        const SizedBox(height: 16),
                        PrivacyDocumentsCard(documents: state.documents),
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
