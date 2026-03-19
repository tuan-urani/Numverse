class LocalNumAiGuestMessage {
  const LocalNumAiGuestMessage({
    required this.id,
    required this.senderType,
    required this.messageText,
    required this.createdAt,
    required this.followUpSuggestions,
  });

  final String id;
  final String senderType;
  final String messageText;
  final DateTime createdAt;
  final List<String> followUpSuggestions;

  LocalNumAiGuestMessage copyWith({
    String? id,
    String? senderType,
    String? messageText,
    DateTime? createdAt,
    List<String>? followUpSuggestions,
  }) {
    return LocalNumAiGuestMessage(
      id: id ?? this.id,
      senderType: senderType ?? this.senderType,
      messageText: messageText ?? this.messageText,
      createdAt: createdAt ?? this.createdAt,
      followUpSuggestions: followUpSuggestions ?? this.followUpSuggestions,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'senderType': senderType,
      'messageText': messageText,
      'createdAt': createdAt.toIso8601String(),
      'followUpSuggestions': followUpSuggestions,
    };
  }

  factory LocalNumAiGuestMessage.fromJson(Map<String, dynamic> json) {
    final DateTime parsedCreatedAt =
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now();
    return LocalNumAiGuestMessage(
      id: (json['id'] as String? ?? '').trim(),
      senderType: (json['senderType'] as String? ?? '').trim(),
      messageText: (json['messageText'] as String? ?? '').trim(),
      createdAt: parsedCreatedAt.toLocal(),
      followUpSuggestions: _parseSuggestions(json['followUpSuggestions']),
    );
  }

  static List<String> _parseSuggestions(Object? raw) {
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
