import 'dart:io';

import 'package:dio/dio.dart';

bool isSupabaseOfflineError(Object error) {
  if (error is! DioException) {
    return false;
  }

  if (error.response != null) {
    return false;
  }

  switch (error.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
      return true;
    case DioExceptionType.unknown:
      final Object? innerError = error.error;
      if (innerError is SocketException) {
        return true;
      }
      return error.response == null;
    case DioExceptionType.badResponse:
    case DioExceptionType.badCertificate:
    case DioExceptionType.cancel:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
      return false;
  }
}
