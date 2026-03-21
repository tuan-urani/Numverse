import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test/src/core/service/supabase_offline_error_classifier.dart';

void main() {
  group('isSupabaseOfflineError', () {
    test('returns true for connection timeout', () {
      final DioException error = DioException(
        requestOptions: RequestOptions(path: '/rpc/test'),
        type: DioExceptionType.connectionTimeout,
      );

      expect(isSupabaseOfflineError(error), isTrue);
    });

    test('returns true for connection error', () {
      final DioException error = DioException(
        requestOptions: RequestOptions(path: '/rpc/test'),
        type: DioExceptionType.connectionError,
      );

      expect(isSupabaseOfflineError(error), isTrue);
    });

    test('returns true for unknown socket exception', () {
      final DioException error = DioException(
        requestOptions: RequestOptions(path: '/rpc/test'),
        type: DioExceptionType.unknown,
        error: const SocketException('Failed host lookup'),
      );

      expect(isSupabaseOfflineError(error), isTrue);
    });

    test('returns false for bad response with status code', () {
      final RequestOptions requestOptions = RequestOptions(path: '/rpc/test');
      final DioException error = DioException.badResponse(
        statusCode: 500,
        requestOptions: requestOptions,
        response: Response<dynamic>(
          requestOptions: requestOptions,
          statusCode: 500,
          data: <String, dynamic>{'error': 'internal'},
        ),
      );

      expect(isSupabaseOfflineError(error), isFalse);
    });
  });
}
