class CloudNumAiSendMessageResult {
  const CloudNumAiSendMessageResult({
    required this.threadId,
    required this.assistantText,
    required this.suggestions,
    required this.chargedSoulPoints,
    required this.walletBalance,
    required this.fallbackReason,
    required this.requiresProfileInfo,
  });

  final String threadId;
  final String assistantText;
  final List<String> suggestions;
  final int chargedSoulPoints;
  final int walletBalance;
  final String? fallbackReason;
  final bool requiresProfileInfo;

  factory CloudNumAiSendMessageResult.fromEnvelope(Map<String, dynamic> json) {
    final Map<String, dynamic> data = _toMap(json['data']);
    final Map<String, dynamic> assistantMessage = _toMap(
      data['assistant_message'],
    );
    final Map<String, dynamic> metadata = _toMap(
      assistantMessage['metadata_json'],
    );

    return CloudNumAiSendMessageResult(
      threadId: (data['thread_id'] as String? ?? '').trim(),
      assistantText: (assistantMessage['message_text'] as String? ?? '').trim(),
      suggestions: _toStringList(
        metadata['follow_up_suggestions'] ?? data['assistant_suggestions'],
      ),
      chargedSoulPoints: (data['charged_soul_points'] as num?)?.toInt() ?? 0,
      walletBalance: (data['wallet_balance'] as num?)?.toInt() ?? 0,
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
      return <String>[];
    }
    return raw
        .whereType<String>()
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList();
  }
}
