class CloudNumAiImportGuestHistoryResult {
  const CloudNumAiImportGuestHistoryResult({
    required this.threadId,
    required this.importedCount,
    required this.skippedCount,
  });

  final String threadId;
  final int importedCount;
  final int skippedCount;

  factory CloudNumAiImportGuestHistoryResult.fromEnvelope(
    Map<String, dynamic> json,
  ) {
    final Map<String, dynamic> data = _toMap(json['data']);
    return CloudNumAiImportGuestHistoryResult(
      threadId: (data['thread_id'] as String? ?? '').trim(),
      importedCount: (data['imported_count'] as num?)?.toInt() ?? 0,
      skippedCount: (data['skipped_count'] as num?)?.toInt() ?? 0,
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
}
