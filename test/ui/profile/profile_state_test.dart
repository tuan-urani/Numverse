import 'package:flutter_test/flutter_test.dart';

import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/profile/interactor/profile_state.dart';
import 'package:test/src/utils/app_pages.dart';

void main() {
  group('ProfileState.initial', () {
    test('contains settings menu with legal links in expected order', () {
      final List<ProfileMenuItem> items = ProfileState.initial().menuItems;

      expect(items.map((ProfileMenuItem item) => item.id).toList(), <String>[
        'settings',
        'privacy-policy',
        'terms-of-use',
        'help',
      ]);
      expect(items.map((ProfileMenuItem item) => item.route).toList(), <String>[
        AppPages.settings,
        AppPages.privacyPolicy,
        AppPages.termsOfUse,
        AppPages.help,
      ]);
      expect(
        items.any((ProfileMenuItem item) => item.id == 'privacy'),
        isFalse,
      );
    });

    test('maps legal entries to existing locale keys', () {
      final List<ProfileMenuItem> items = ProfileState.initial().menuItems;
      final ProfileMenuItem privacyPolicy = items[1];
      final ProfileMenuItem termsOfUse = items[2];

      expect(privacyPolicy.titleKey, LocaleKey.privacyDocPolicyTitle);
      expect(privacyPolicy.subtitleKey, LocaleKey.profileMenuPrivacySubtitle);
      expect(termsOfUse.titleKey, LocaleKey.privacyDocTermsTitle);
      expect(termsOfUse.subtitleKey, LocaleKey.profileMenuPrivacySubtitle);
    });
  });
}
