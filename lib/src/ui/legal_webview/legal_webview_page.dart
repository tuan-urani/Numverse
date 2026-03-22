import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/legal_webview/components/legal_webview_header.dart';
import 'package:test/src/ui/widgets/app_inapp_webview.dart';
import 'package:test/src/ui/widgets/app_mystical_scaffold.dart';
import 'package:test/src/utils/app_pages.dart';

class LegalWebviewPage extends StatelessWidget {
  const LegalWebviewPage({
    required this.titleKey,
    required this.url,
    super.key,
  });

  static const String privacyPolicyUrl =
      'https://numverse-f5eef.firebaseapp.com/privacy-policy.html';
  static const String termsOfUseUrl =
      'https://numverse-f5eef.firebaseapp.com/terms-of-use.html';

  static LegalWebviewPage privacyPolicy() => const LegalWebviewPage(
    titleKey: LocaleKey.privacyDocPolicyTitle,
    url: privacyPolicyUrl,
  );

  static LegalWebviewPage termsOfUse() => const LegalWebviewPage(
    titleKey: LocaleKey.privacyDocTermsTitle,
    url: termsOfUseUrl,
  );

  final String titleKey;
  final String url;

  @override
  Widget build(BuildContext context) {
    return AppMysticalScaffold(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            LegalWebviewHeader(
              titleKey: titleKey,
              onBackTap: () => _onBackTap(context),
            ),
            Expanded(child: AppInAppWebView(url: url)),
          ],
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
