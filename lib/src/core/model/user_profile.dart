class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.createdAt,
  });

  final String id;
  final String name;
  final DateTime birthDate;
  final DateTime createdAt;

  UserProfile copyWith({
    String? id,
    String? name,
    DateTime? birthDate,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'birthDate': birthDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final DateTime birthDate =
        DateTime.tryParse(json['birthDate'] as String? ?? '') ??
        DateTime(2000, 1, 1);
    final DateTime createdAt =
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now();

    return UserProfile(
      id:
          json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? '',
      birthDate: birthDate,
      createdAt: createdAt,
    );
  }
}
