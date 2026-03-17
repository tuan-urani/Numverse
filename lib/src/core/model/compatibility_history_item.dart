import 'package:equatable/equatable.dart';

class CompatibilityHistoryItem extends Equatable {
  const CompatibilityHistoryItem({
    required this.id,
    required this.requestId,
    required this.primaryProfileId,
    required this.primaryName,
    required this.primaryBirthDate,
    required this.primaryLifePath,
    required this.primarySoul,
    required this.primaryPersonality,
    required this.primaryExpression,
    required this.targetProfileId,
    required this.targetName,
    required this.targetRelation,
    required this.targetBirthDate,
    required this.targetLifePath,
    required this.targetSoul,
    required this.targetPersonality,
    required this.targetExpression,
    required this.overallScore,
    required this.coreScore,
    required this.communicationScore,
    required this.soulScore,
    required this.personalityScore,
    required this.createdAt,
  });

  final String id;
  final String requestId;
  final String primaryProfileId;
  final String primaryName;
  final DateTime primaryBirthDate;
  final int primaryLifePath;
  final int primarySoul;
  final int primaryPersonality;
  final int primaryExpression;
  final String targetProfileId;
  final String targetName;
  final String targetRelation;
  final DateTime targetBirthDate;
  final int targetLifePath;
  final int targetSoul;
  final int targetPersonality;
  final int targetExpression;
  final int overallScore;
  final int coreScore;
  final int communicationScore;
  final int soulScore;
  final int personalityScore;
  final DateTime createdAt;

  CompatibilityHistoryItem copyWith({
    String? id,
    String? requestId,
    String? primaryProfileId,
    String? primaryName,
    DateTime? primaryBirthDate,
    int? primaryLifePath,
    int? primarySoul,
    int? primaryPersonality,
    int? primaryExpression,
    String? targetProfileId,
    String? targetName,
    String? targetRelation,
    DateTime? targetBirthDate,
    int? targetLifePath,
    int? targetSoul,
    int? targetPersonality,
    int? targetExpression,
    int? overallScore,
    int? coreScore,
    int? communicationScore,
    int? soulScore,
    int? personalityScore,
    DateTime? createdAt,
  }) {
    return CompatibilityHistoryItem(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      primaryProfileId: primaryProfileId ?? this.primaryProfileId,
      primaryName: primaryName ?? this.primaryName,
      primaryBirthDate: primaryBirthDate ?? this.primaryBirthDate,
      primaryLifePath: primaryLifePath ?? this.primaryLifePath,
      primarySoul: primarySoul ?? this.primarySoul,
      primaryPersonality: primaryPersonality ?? this.primaryPersonality,
      primaryExpression: primaryExpression ?? this.primaryExpression,
      targetProfileId: targetProfileId ?? this.targetProfileId,
      targetName: targetName ?? this.targetName,
      targetRelation: targetRelation ?? this.targetRelation,
      targetBirthDate: targetBirthDate ?? this.targetBirthDate,
      targetLifePath: targetLifePath ?? this.targetLifePath,
      targetSoul: targetSoul ?? this.targetSoul,
      targetPersonality: targetPersonality ?? this.targetPersonality,
      targetExpression: targetExpression ?? this.targetExpression,
      overallScore: overallScore ?? this.overallScore,
      coreScore: coreScore ?? this.coreScore,
      communicationScore: communicationScore ?? this.communicationScore,
      soulScore: soulScore ?? this.soulScore,
      personalityScore: personalityScore ?? this.personalityScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'requestId': requestId,
      'primaryProfileId': primaryProfileId,
      'primaryName': primaryName,
      'primaryBirthDate': primaryBirthDate.toIso8601String(),
      'primaryLifePath': primaryLifePath,
      'primarySoul': primarySoul,
      'primaryPersonality': primaryPersonality,
      'primaryExpression': primaryExpression,
      'targetProfileId': targetProfileId,
      'targetName': targetName,
      'targetRelation': targetRelation,
      'targetBirthDate': targetBirthDate.toIso8601String(),
      'targetLifePath': targetLifePath,
      'targetSoul': targetSoul,
      'targetPersonality': targetPersonality,
      'targetExpression': targetExpression,
      'overallScore': overallScore,
      'coreScore': coreScore,
      'communicationScore': communicationScore,
      'soulScore': soulScore,
      'personalityScore': personalityScore,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CompatibilityHistoryItem.fromJson(Map<String, dynamic> json) {
    final DateTime now = DateTime.now();
    final String requestId = _readString(json['requestId']);
    final String fallbackId = requestId.isNotEmpty
        ? requestId
        : now.microsecondsSinceEpoch.toString();

    return CompatibilityHistoryItem(
      id: _readString(json['id'], fallback: fallbackId),
      requestId: requestId,
      primaryProfileId: _readString(json['primaryProfileId']),
      primaryName: _readString(json['primaryName']),
      primaryBirthDate: _readDateTime(json['primaryBirthDate'], fallback: now),
      primaryLifePath: _readInt(json['primaryLifePath']),
      primarySoul: _readInt(json['primarySoul']),
      primaryPersonality: _readInt(json['primaryPersonality']),
      primaryExpression: _readInt(json['primaryExpression']),
      targetProfileId: _readString(json['targetProfileId']),
      targetName: _readString(json['targetName']),
      targetRelation: _readString(json['targetRelation'], fallback: 'other'),
      targetBirthDate: _readDateTime(json['targetBirthDate'], fallback: now),
      targetLifePath: _readInt(json['targetLifePath']),
      targetSoul: _readInt(json['targetSoul']),
      targetPersonality: _readInt(json['targetPersonality']),
      targetExpression: _readInt(json['targetExpression']),
      overallScore: _readInt(json['overallScore']),
      coreScore: _readInt(json['coreScore']),
      communicationScore: _readInt(json['communicationScore']),
      soulScore: _readInt(json['soulScore']),
      personalityScore: _readInt(json['personalityScore']),
      createdAt: _readDateTime(json['createdAt'], fallback: now),
    );
  }

  static String _readString(Object? value, {String fallback = ''}) {
    if (value is String) {
      final String trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return fallback;
  }

  static int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim()) ?? fallback;
    }
    return fallback;
  }

  static DateTime _readDateTime(Object? value, {required DateTime fallback}) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      final DateTime? parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
      if (value.length >= 10) {
        final DateTime? parsedDate = DateTime.tryParse(value.substring(0, 10));
        if (parsedDate != null) {
          return parsedDate;
        }
      }
    }
    return fallback;
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    requestId,
    primaryProfileId,
    primaryName,
    primaryBirthDate,
    primaryLifePath,
    primarySoul,
    primaryPersonality,
    primaryExpression,
    targetProfileId,
    targetName,
    targetRelation,
    targetBirthDate,
    targetLifePath,
    targetSoul,
    targetPersonality,
    targetExpression,
    overallScore,
    coreScore,
    communicationScore,
    soulScore,
    personalityScore,
    createdAt,
  ];
}
