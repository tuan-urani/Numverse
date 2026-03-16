import 'package:equatable/equatable.dart';

class AdminLedgerContent extends Equatable {
  const AdminLedgerContent({
    required this.id,
    required this.releaseId,
    required this.contentType,
    required this.numberKey,
    required this.payloadJsonb,
    required this.updatedAt,
  });

  final String id;
  final String releaseId;
  final String contentType;
  final String numberKey;
  final Map<String, dynamic> payloadJsonb;
  final DateTime? updatedAt;

  factory AdminLedgerContent.fromJson(Map<String, dynamic> json) {
    final Object? rawPayload = json['payload_jsonb'];
    final Map<String, dynamic> payloadJsonb = rawPayload is Map<String, dynamic>
        ? rawPayload
        : <String, dynamic>{};

    return AdminLedgerContent(
      id: (json['id'] as String? ?? '').trim(),
      releaseId: (json['release_id'] as String? ?? '').trim(),
      contentType: (json['content_type'] as String? ?? '').trim().toLowerCase(),
      numberKey: (json['number_key'] as String? ?? '').trim(),
      payloadJsonb: payloadJsonb,
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    releaseId,
    contentType,
    numberKey,
    payloadJsonb,
    updatedAt,
  ];
}
