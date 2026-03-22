import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'package:test/src/core/model/cloud_error_codes.dart';
import 'package:test/src/locale/locale_key.dart';

String resolveMainSessionErrorMessage(Object error) {
  if (isCloudErrorCode(error, kCloudErrorProfileLimitReached)) {
    return LocaleKey.profileCreateLimitReached.tr;
  }
  if (isCloudErrorCode(error, kCloudErrorPlanActive)) {
    return LocaleKey.profileDeleteUserDataPlanActiveError.tr;
  }

  if (error is DioException) {
    final dynamic raw = error.response?.data;
    if (raw is Map) {
      final String message = _firstCloudMessage(<dynamic>[
        raw['msg'],
        raw['message'],
        raw['error_description'],
        raw['error'],
      ]);
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

String _firstCloudMessage(List<dynamic> values) {
  for (final dynamic value in values) {
    final String normalized = _normalizeCloudMessageValue(value);
    if (normalized.isNotEmpty) {
      return normalized;
    }
  }
  return '';
}

String _normalizeCloudMessageValue(dynamic value) {
  return switch (value) {
    null => '',
    final String stringValue => stringValue.trim(),
    final num numberValue => numberValue.toString(),
    final bool boolValue => boolValue.toString(),
    _ => '',
  };
}
