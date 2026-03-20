import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'package:test/src/core/model/cloud_error_codes.dart';
import 'package:test/src/locale/locale_key.dart';

String resolveMainSessionErrorMessage(Object error) {
  if (isCloudErrorCode(error, kCloudErrorProfileLimitReached)) {
    return LocaleKey.profileCreateLimitReached.tr;
  }

  if (error is DioException) {
    final dynamic raw = error.response?.data;
    if (raw is Map<String, dynamic>) {
      final String message =
          (raw['msg'] as String? ??
                  raw['message'] as String? ??
                  raw['error_description'] as String? ??
                  raw['error'] as String? ??
                  '')
              .trim();
      if (message.isNotEmpty) {
        return message;
      }
    }

    final String dioMessage = (error.message ?? '').trim();
    if (dioMessage.isNotEmpty) {
      return dioMessage;
    }
  }

  return LocaleKey.stateErrorSubtitle.tr;
}
