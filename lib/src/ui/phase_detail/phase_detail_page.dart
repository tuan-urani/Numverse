import 'package:flutter/material.dart';

import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/widgets/app_simple_page.dart';

class PhaseDetailPage extends StatelessWidget {
  const PhaseDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSimplePage(
      titleKey: LocaleKey.phaseDetailTitle,
      subtitleKey: LocaleKey.phaseDetailSubtitle,
      sections: const <AppSimpleSection>[
        AppSimpleSection(
          titleKey: LocaleKey.genericInsightTitle,
          descriptionKey: LocaleKey.genericAdviceOne,
          icon: Icons.auto_awesome,
        ),
        AppSimpleSection(
          titleKey: LocaleKey.genericAdviceTitle,
          icon: Icons.list_alt,
          bulletKeys: <String>[
            LocaleKey.genericAdviceOne,
            LocaleKey.genericAdviceTwo,
            LocaleKey.genericAdviceThree,
          ],
        ),
      ],
    );
  }
}
