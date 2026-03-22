import 'package:dio/dio.dart';

const String kCloudErrorProfileLimitReached = 'profile_limit_reached';
const String kCloudErrorPlanActive = 'plan_active';

String? extractCloudErrorCode(Object error) {
  final List<String> candidates = <String>[];

  if (error is StateError) {
    candidates.add(error.message.toString());
  }

  if (error is DioException) {
    final dynamic raw = error.response?.data;
    if (raw is Map) {
      candidates
        ..add(_cloudErrorFieldToString(raw['error']))
        ..add(_cloudErrorFieldToString(raw['message']))
        ..add(_cloudErrorFieldToString(raw['msg']))
        ..add(_cloudErrorFieldToString(raw['code']))
        ..add(_cloudErrorFieldToString(raw['error_description']));
    }
    candidates.add(error.message ?? '');
  }

  candidates.add(error.toString());

  for (final String candidate in candidates) {
    final String normalized = _normalizeCloudErrorCode(candidate);
    if (normalized.isNotEmpty) {
      return normalized;
    }
  }

  return null;
}

bool isCloudErrorCode(Object error, String expectedCode) {
  final String normalizedExpected = expectedCode.trim().toLowerCase();
  if (normalizedExpected.isEmpty) {
    return false;
  }
  final String? actualCode = extractCloudErrorCode(error);
  return actualCode == normalizedExpected;
}

String _normalizeCloudErrorCode(String raw) {
  String value = raw.trim().toLowerCase();
  if (value.isEmpty) {
    return '';
  }

  if (value.startsWith('bad state:')) {
    value = value.substring('bad state:'.length).trim();
  }

  if (value.contains(kCloudErrorProfileLimitReached)) {
    return kCloudErrorProfileLimitReached;
  }
  if (value.contains(kCloudErrorPlanActive)) {
    return kCloudErrorPlanActive;
  }

  if (RegExp(r'^[a-z0-9_]+$').hasMatch(value)) {
    return value;
  }

  return '';
}

String _cloudErrorFieldToString(dynamic value) {
  return switch (value) {
    null => '',
    final String stringValue => stringValue,
    final num numberValue => numberValue.toString(),
    final bool boolValue => boolValue.toString(),
    _ => '',
  };
}
