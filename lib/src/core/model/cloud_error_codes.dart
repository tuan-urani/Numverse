import 'package:dio/dio.dart';

const String kCloudErrorProfileLimitReached = 'profile_limit_reached';

String? extractCloudErrorCode(Object error) {
  final List<String> candidates = <String>[];

  if (error is StateError) {
    candidates.add(error.message.toString());
  }

  if (error is DioException) {
    final dynamic raw = error.response?.data;
    if (raw is Map<String, dynamic>) {
      candidates
        ..add(raw['error'] as String? ?? '')
        ..add(raw['message'] as String? ?? '')
        ..add(raw['msg'] as String? ?? '')
        ..add(raw['code'] as String? ?? '')
        ..add(raw['error_description'] as String? ?? '');
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

  if (RegExp(r'^[a-z0-9_]+$').hasMatch(value)) {
    return value;
  }

  return '';
}
