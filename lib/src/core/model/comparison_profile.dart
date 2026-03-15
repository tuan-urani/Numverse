import 'package:equatable/equatable.dart';

class ComparisonProfile extends Equatable {
  const ComparisonProfile({
    required this.id,
    required this.name,
    required this.relation,
    required this.birthDate,
    required this.lifePathNumber,
  });

  final String id;
  final String name;
  final String relation;
  final DateTime birthDate;
  final int lifePathNumber;

  ComparisonProfile copyWith({
    String? id,
    String? name,
    String? relation,
    DateTime? birthDate,
    int? lifePathNumber,
  }) {
    return ComparisonProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      relation: relation ?? this.relation,
      birthDate: birthDate ?? this.birthDate,
      lifePathNumber: lifePathNumber ?? this.lifePathNumber,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'relation': relation,
      'birthDate': birthDate.toIso8601String(),
      'lifePathNumber': lifePathNumber,
    };
  }

  factory ComparisonProfile.fromJson(Map<String, dynamic> json) {
    final DateTime birthDate =
        DateTime.tryParse(json['birthDate'] as String? ?? '') ??
        DateTime(2000, 1, 1);

    return ComparisonProfile(
      id:
          json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? '',
      relation: json['relation'] as String? ?? '',
      birthDate: birthDate,
      lifePathNumber: json['lifePathNumber'] as int? ?? 1,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    relation,
    birthDate,
    lifePathNumber,
  ];
}
