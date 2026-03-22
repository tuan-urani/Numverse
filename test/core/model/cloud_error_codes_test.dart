import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:test/src/core/model/cloud_error_codes.dart';

void main() {
  group('extractCloudErrorCode', () {
    test('does not throw when server code is numeric', () {
      final DioException error = _dioError(const <String, dynamic>{
        'code': 429,
      });

      expect(extractCloudErrorCode(error), '429');
    });

    test('extracts known profile limit code from payload', () {
      final DioException error = _dioError(const <String, dynamic>{
        'error': kCloudErrorProfileLimitReached,
      });

      expect(isCloudErrorCode(error, kCloudErrorProfileLimitReached), isTrue);
    });

    test('extracts plan active code from state error payload', () {
      final DioException error = _dioError(const <String, dynamic>{
        'error': 'PLAN_ACTIVE',
      });

      expect(isCloudErrorCode(error, kCloudErrorPlanActive), isTrue);
    });
  });
}

DioException _dioError(Map<String, dynamic> payload) {
  final RequestOptions requestOptions = RequestOptions(path: '/auth/register');
  return DioException(
    requestOptions: requestOptions,
    response: Response<dynamic>(
      requestOptions: requestOptions,
      data: payload,
      statusCode: 400,
    ),
    type: DioExceptionType.badResponse,
  );
}
