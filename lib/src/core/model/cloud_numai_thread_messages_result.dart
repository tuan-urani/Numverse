class CloudNumAiThreadMessagesResult {
  const CloudNumAiThreadMessagesResult({
    required this.threadId,
    required this.messages,
  });

  final String threadId;
  final List<CloudNumAiThreadMessage> messages;

  factory CloudNumAiThreadMessagesResult.fromEnvelope(
    Map<String, dynamic> json,
  ) {
    final Map<String, dynamic> data = _toMap(json['data']);
    return CloudNumAiThreadMessagesResult(
      threadId: (data['thread_id'] as String? ?? '').trim(),
      messages: _toMessageList(data['messages']),
    );
  }

  static List<CloudNumAiThreadMessage> _toMessageList(Object? raw) {
    if (raw is! List) {
      return const <CloudNumAiThreadMessage>[];
    }

    return raw
        .whereType<Map>()
        .map(
          (Map<dynamic, dynamic> item) =>
              CloudNumAiThreadMessage.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  static Map<String, dynamic> _toMap(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return <String, dynamic>{};
  }
}

class CloudNumAiThreadMessage {
  const CloudNumAiThreadMessage({
    required this.id,
    required this.senderType,
    required this.messageText,
    required this.createdAt,
    required this.followUpSuggestions,
    required this.fallbackReason,
    required this.requiresProfileInfo,
  });

  final String id;
  final String senderType;
  final String messageText;
  final DateTime createdAt;
  final List<String> followUpSuggestions;
  final String? fallbackReason;
  final bool requiresProfileInfo;

  factory CloudNumAiThreadMessage.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> metadata = _toMap(json['metadata_json']);
    final DateTime parsedCreatedAt =
        DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.now();
    return CloudNumAiThreadMessage(
      id: (json['id'] as String? ?? '').trim(),
      senderType: (json['sender_type'] as String? ?? '').trim(),
      messageText: (json['message_text'] as String? ?? '').trim(),
      createdAt: parsedCreatedAt.toLocal(),
      followUpSuggestions: _toStringList(metadata['follow_up_suggestions']),
      fallbackReason: (metadata['fallback_reason'] as String?)?.trim(),
      requiresProfileInfo: metadata['requires_profile_info'] is bool
          ? metadata['requires_profile_info'] as bool
          : false,
    );
  }

  static Map<String, dynamic> _toMap(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return <String, dynamic>{};
  }

  static List<String> _toStringList(Object? raw) {
    if (raw is! List) {
      return const <String>[];
    }
    return raw
        .whereType<String>()
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList();
  }
}
