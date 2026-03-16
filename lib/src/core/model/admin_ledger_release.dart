import 'package:equatable/equatable.dart';

class AdminLedgerRelease extends Equatable {
  const AdminLedgerRelease({
    required this.id,
    required this.locale,
    required this.version,
    required this.status,
    required this.checksum,
    required this.notes,
    required this.contentCount,
    required this.createdAt,
    required this.updatedAt,
    required this.activatedAt,
  });

  final String id;
  final String locale;
  final String version;
  final String status;
  final String? checksum;
  final String? notes;
  final int contentCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? activatedAt;

  bool get isActive => status == 'active';
  bool get isDraft => status == 'draft';

  factory AdminLedgerRelease.fromJson(Map<String, dynamic> json) {
    return AdminLedgerRelease(
      id: (json['id'] as String? ?? '').trim(),
      locale: (json['locale'] as String? ?? '').trim().toLowerCase(),
      version: (json['version'] as String? ?? '').trim(),
      status: (json['status'] as String? ?? '').trim(),
      checksum: (json['checksum'] as String?)?.trim(),
      notes: (json['notes'] as String?)?.trim(),
      contentCount: (json['content_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
      activatedAt: DateTime.tryParse(json['activated_at'] as String? ?? ''),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    locale,
    version,
    status,
    checksum,
    notes,
    contentCount,
    createdAt,
    updatedAt,
    activatedAt,
  ];
}
