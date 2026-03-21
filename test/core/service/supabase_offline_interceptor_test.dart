import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test/src/core/service/supabase_offline_coordinator.dart';
import 'package:test/src/core/service/supabase_offline_interceptor.dart';

class _FakeOfflineCoordinator extends SupabaseOfflineCoordinator {
  _FakeOfflineCoordinator({
    required this.popupAction,
    bool launchGuardActive = false,
  }) : _launchGuardActive = launchGuardActive,
       super(dialogsEnabled: false);

  final SupabaseOfflinePopupAction popupAction;
  final bool _launchGuardActive;
  int inAppPopupCallCount = 0;
  int markLaunchOfflineErrorCount = 0;

  @override
  bool get isLaunchGuardActive => _launchGuardActive;

  @override
  void markLaunchOfflineError() {
    markLaunchOfflineErrorCount += 1;
    super.markLaunchOfflineError();
  }

  @override
  Future<SupabaseOfflinePopupAction> showInAppRetryPopup() async {
    inAppPopupCallCount += 1;
    return popupAction;
  }
}

class _MockAdapter implements HttpClientAdapter {
  _MockAdapter(this._fetcher);

  final Future<ResponseBody> Function(RequestOptions options) _fetcher;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _fetcher(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  ResponseBody okResponse() {
    return ResponseBody.fromString(
      jsonEncode(<String, dynamic>{'ok': true}),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  DioException offlineError(RequestOptions options) {
    return DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
      error: const SocketException('Failed host lookup'),
    );
  }

  test('retries request once when user chooses retry', () async {
    int fetchCount = 0;
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
    dio.httpClientAdapter = _MockAdapter((RequestOptions options) async {
      fetchCount += 1;
      final bool retried =
          options.extra[kSupabaseOfflineRetriedRequestExtraKey] == true;
      if (!retried) {
        throw offlineError(options);
      }
      return okResponse();
    });

    final _FakeOfflineCoordinator coordinator = _FakeOfflineCoordinator(
      popupAction: SupabaseOfflinePopupAction.retry,
    );
    dio.interceptors.add(
      SupabaseOfflineInterceptor(dio: dio, coordinator: coordinator),
    );

    final Response<dynamic> response = await dio.get<dynamic>('/rpc/test');
    expect(response.statusCode, 200);
    expect(fetchCount, 2);
    expect(coordinator.inAppPopupCallCount, 1);
  });

  test('propagates original error when user chooses close', () async {
    int fetchCount = 0;
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
    dio.httpClientAdapter = _MockAdapter((RequestOptions options) async {
      fetchCount += 1;
      throw offlineError(options);
    });

    final _FakeOfflineCoordinator coordinator = _FakeOfflineCoordinator(
      popupAction: SupabaseOfflinePopupAction.close,
    );
    dio.interceptors.add(
      SupabaseOfflineInterceptor(dio: dio, coordinator: coordinator),
    );

    await expectLater(
      () => dio.get<dynamic>('/rpc/test'),
      throwsA(isA<DioException>()),
    );
    expect(fetchCount, 1);
    expect(coordinator.inAppPopupCallCount, 1);
  });

  test(
    'does not retry indefinitely when retried request still fails',
    () async {
      int fetchCount = 0;
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
      dio.httpClientAdapter = _MockAdapter((RequestOptions options) async {
        fetchCount += 1;
        throw offlineError(options);
      });

      final _FakeOfflineCoordinator coordinator = _FakeOfflineCoordinator(
        popupAction: SupabaseOfflinePopupAction.retry,
      );
      dio.interceptors.add(
        SupabaseOfflineInterceptor(dio: dio, coordinator: coordinator),
      );

      await expectLater(
        () => dio.get<dynamic>('/rpc/test'),
        throwsA(isA<DioException>()),
      );
      expect(fetchCount, 2);
      expect(coordinator.inAppPopupCallCount, 1);
    },
  );

  test(
    'marks launch offline error and skips in-app popup during splash guard',
    () async {
      int fetchCount = 0;
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
      dio.httpClientAdapter = _MockAdapter((RequestOptions options) async {
        fetchCount += 1;
        throw offlineError(options);
      });

      final _FakeOfflineCoordinator coordinator = _FakeOfflineCoordinator(
        popupAction: SupabaseOfflinePopupAction.retry,
        launchGuardActive: true,
      );
      dio.interceptors.add(
        SupabaseOfflineInterceptor(dio: dio, coordinator: coordinator),
      );

      await expectLater(
        () => dio.get<dynamic>('/rpc/test'),
        throwsA(isA<DioException>()),
      );
      expect(fetchCount, 1);
      expect(coordinator.inAppPopupCallCount, 0);
      expect(coordinator.markLaunchOfflineErrorCount, 1);
    },
  );
}
