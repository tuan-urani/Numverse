import 'package:test/src/core/model/comparison_profile.dart';
import 'package:test/src/core/model/profile_life_based_snapshot.dart';
import 'package:test/src/core/model/profile_time_life_snapshot.dart';
import 'package:test/src/core/model/user_profile.dart';

class AppSessionSnapshot {
  const AppSessionSnapshot({
    required this.isAuthenticated,
    required this.userEmail,
    required this.userName,
    required this.profiles,
    required this.lifeBasedByProfileId,
    required this.timeLifeByProfileId,
    required this.currentProfileId,
    required this.soulPoints,
    required this.currentStreak,
    required this.dailyEarnings,
    required this.lastCheckInAt,
    required this.compareProfiles,
    required this.selectedCompareProfileId,
  });

  factory AppSessionSnapshot.initial() {
    return const AppSessionSnapshot(
      isAuthenticated: false,
      userEmail: null,
      userName: null,
      profiles: <UserProfile>[],
      lifeBasedByProfileId: <String, ProfileLifeBasedSnapshot>{},
      timeLifeByProfileId: <String, ProfileTimeLifeSnapshot>{},
      currentProfileId: null,
      soulPoints: 124,
      currentStreak: 5,
      dailyEarnings: 45,
      lastCheckInAt: null,
      compareProfiles: <ComparisonProfile>[],
      selectedCompareProfileId: null,
    );
  }

  final bool isAuthenticated;
  final String? userEmail;
  final String? userName;
  final List<UserProfile> profiles;
  final Map<String, ProfileLifeBasedSnapshot> lifeBasedByProfileId;
  final Map<String, ProfileTimeLifeSnapshot> timeLifeByProfileId;
  final String? currentProfileId;
  final int soulPoints;
  final int currentStreak;
  final int dailyEarnings;
  final DateTime? lastCheckInAt;
  final List<ComparisonProfile> compareProfiles;
  final String? selectedCompareProfileId;

  AppSessionSnapshot copyWith({
    bool? isAuthenticated,
    String? userEmail,
    bool clearUserEmail = false,
    String? userName,
    bool clearUserName = false,
    List<UserProfile>? profiles,
    Map<String, ProfileLifeBasedSnapshot>? lifeBasedByProfileId,
    Map<String, ProfileTimeLifeSnapshot>? timeLifeByProfileId,
    String? currentProfileId,
    bool clearCurrentProfileId = false,
    int? soulPoints,
    int? currentStreak,
    int? dailyEarnings,
    DateTime? lastCheckInAt,
    bool clearLastCheckInAt = false,
    List<ComparisonProfile>? compareProfiles,
    String? selectedCompareProfileId,
    bool clearSelectedCompareProfileId = false,
  }) {
    return AppSessionSnapshot(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userEmail: clearUserEmail ? null : userEmail ?? this.userEmail,
      userName: clearUserName ? null : userName ?? this.userName,
      profiles: profiles ?? this.profiles,
      lifeBasedByProfileId: lifeBasedByProfileId ?? this.lifeBasedByProfileId,
      timeLifeByProfileId: timeLifeByProfileId ?? this.timeLifeByProfileId,
      currentProfileId: clearCurrentProfileId
          ? null
          : currentProfileId ?? this.currentProfileId,
      soulPoints: soulPoints ?? this.soulPoints,
      currentStreak: currentStreak ?? this.currentStreak,
      dailyEarnings: dailyEarnings ?? this.dailyEarnings,
      lastCheckInAt: clearLastCheckInAt
          ? null
          : lastCheckInAt ?? this.lastCheckInAt,
      compareProfiles: compareProfiles ?? this.compareProfiles,
      selectedCompareProfileId: clearSelectedCompareProfileId
          ? null
          : selectedCompareProfileId ?? this.selectedCompareProfileId,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'isAuthenticated': isAuthenticated,
      'userEmail': userEmail,
      'userName': userName,
      'profiles': profiles
          .map((UserProfile profile) => profile.toJson())
          .toList(),
      'lifeBasedByProfileId': lifeBasedByProfileId.map((
        String profileId,
        ProfileLifeBasedSnapshot snapshot,
      ) {
        return MapEntry<String, dynamic>(profileId, snapshot.toJson());
      }),
      'timeLifeByProfileId': timeLifeByProfileId.map((
        String profileId,
        ProfileTimeLifeSnapshot snapshot,
      ) {
        return MapEntry<String, dynamic>(profileId, snapshot.toJson());
      }),
      'currentProfileId': currentProfileId,
      'soulPoints': soulPoints,
      'currentStreak': currentStreak,
      'dailyEarnings': dailyEarnings,
      'lastCheckInAt': lastCheckInAt?.toIso8601String(),
      'compareProfiles': compareProfiles
          .map((ComparisonProfile profile) => profile.toJson())
          .toList(),
      'selectedCompareProfileId': selectedCompareProfileId,
    };
  }

  factory AppSessionSnapshot.fromJson(Map<String, dynamic> json) {
    final List<UserProfile> profiles =
        ((json['profiles'] as List<dynamic>?) ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(UserProfile.fromJson)
            .toList();
    final Map<String, ProfileLifeBasedSnapshot> lifeBasedByProfileId =
        <String, ProfileLifeBasedSnapshot>{};
    final Object? rawLifeBasedSnapshots = json['lifeBasedByProfileId'];
    if (rawLifeBasedSnapshots is Map<String, dynamic>) {
      for (final MapEntry<String, dynamic> entry
          in rawLifeBasedSnapshots.entries) {
        if (entry.value is! Map<String, dynamic>) {
          continue;
        }

        try {
          lifeBasedByProfileId[entry.key] = ProfileLifeBasedSnapshot.fromJson(
            entry.value as Map<String, dynamic>,
          );
        } catch (_) {
          continue;
        }
      }
    }

    final Map<String, ProfileTimeLifeSnapshot> timeLifeByProfileId =
        <String, ProfileTimeLifeSnapshot>{};
    final Object? rawSnapshots = json['timeLifeByProfileId'];
    if (rawSnapshots is Map<String, dynamic>) {
      for (final MapEntry<String, dynamic> entry in rawSnapshots.entries) {
        if (entry.value is! Map<String, dynamic>) {
          continue;
        }

        try {
          timeLifeByProfileId[entry.key] = ProfileTimeLifeSnapshot.fromJson(
            entry.value as Map<String, dynamic>,
          );
        } catch (_) {
          continue;
        }
      }
    }
    final Set<String> activeProfileIds = profiles
        .map((UserProfile profile) => profile.id)
        .toSet();
    lifeBasedByProfileId.removeWhere((String profileId, _) {
      return !activeProfileIds.contains(profileId);
    });
    timeLifeByProfileId.removeWhere((String profileId, _) {
      if (profileId == ProfileTimeLifeSnapshot.guestProfileId) {
        return false;
      }
      return !activeProfileIds.contains(profileId);
    });

    final String? currentProfileId = json['currentProfileId'] as String?;
    final bool hasCurrentProfile = profiles.any(
      (UserProfile profile) => profile.id == currentProfileId,
    );
    final List<ComparisonProfile> compareProfiles =
        ((json['compareProfiles'] as List<dynamic>?) ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(ComparisonProfile.fromJson)
            .toList();
    final Set<String> compareProfileIds = compareProfiles
        .map((ComparisonProfile profile) => profile.id)
        .toSet();
    final String? selectedCompareProfileId =
        json['selectedCompareProfileId'] as String?;
    final String? resolvedSelectedCompareProfileId =
        compareProfileIds.contains(selectedCompareProfileId)
        ? selectedCompareProfileId
        : null;

    return AppSessionSnapshot(
      isAuthenticated: json['isAuthenticated'] as bool? ?? false,
      userEmail: json['userEmail'] as String?,
      userName: json['userName'] as String?,
      profiles: profiles,
      lifeBasedByProfileId: lifeBasedByProfileId,
      timeLifeByProfileId: timeLifeByProfileId,
      currentProfileId: hasCurrentProfile
          ? currentProfileId
          : (profiles.isNotEmpty ? profiles.first.id : null),
      soulPoints: json['soulPoints'] as int? ?? 124,
      currentStreak: json['currentStreak'] as int? ?? 5,
      dailyEarnings: json['dailyEarnings'] as int? ?? 45,
      lastCheckInAt: DateTime.tryParse(json['lastCheckInAt'] as String? ?? ''),
      compareProfiles: compareProfiles,
      selectedCompareProfileId: resolvedSelectedCompareProfileId,
    );
  }
}
