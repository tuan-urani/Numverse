import 'package:flutter/material.dart';

import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/widgets/app_simple_page.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSimplePage(
      titleKey: LocaleKey.notificationsTitle,
      subtitleKey: LocaleKey.profileSubtitle,
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
