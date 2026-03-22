import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:test/src/ui/widgets/custom_circular_progress.dart';
import 'package:test/src/utils/app_colors.dart';

class AppInAppWebView extends StatefulWidget {
  final String url;
  final Function(List<dynamic>)? callback;

  const AppInAppWebView({super.key, required this.url, this.callback});

  @override
  State<AppInAppWebView> createState() => _AppInAppWebViewState();
}

class _AppInAppWebViewState extends State<AppInAppWebView> {
  // InAppWebViewController? _webViewController;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        InAppWebView(
          gestureRecognizers: {Factory(() => EagerGestureRecognizer())},
          initialUrlRequest: URLRequest(url: WebUri(widget.url)),
          initialSettings: InAppWebViewSettings(
            useShouldOverrideUrlLoading: false,
            transparentBackground: true,
            javaScriptEnabled: true,
          ),
          onWebViewCreated: (controller) {
            // _webViewController = controller;
          },
          onLoadStart: (_, _) => _setLoading(true),
          onLoadStop: (_, _) => _setLoading(false),
          onReceivedError: (_, _, _) {
            _setLoading(false);
            // TODO: Show error alert message (Error in receive data from server)
          },
          onReceivedHttpError: (_, _, _) {
            _setLoading(false);
            // TODO: Show error alert message (Error in receive data from server)
          },
          onConsoleMessage: (_, _) {},
        ),
        if (_isLoading)
          const Positioned.fill(
            child: ColoredBox(
              color: AppColors.background,
              child: CustomCircularProgress(),
            ),
          ),
      ],
    );
  }

  void _setLoading(bool value) {
    if (!mounted || _isLoading == value) {
      return;
    }
    setState(() {
      _isLoading = value;
    });
  }
}
