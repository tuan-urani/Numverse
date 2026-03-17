import 'package:test/src/core/model/comparison_profile.dart';
import 'package:test/src/core/model/profile_life_based_snapshot.dart';
import 'package:test/src/core/model/profile_time_life_snapshot.dart';
import 'package:test/src/core/model/session_auth_mode.dart';
import 'package:test/src/core/model/user_profile.dart';

class AppSessionSnapshot {
  const AppSessionSnapshot({
    required this.isAuthenticated,
    required this.authMode,
    required this.pendingAnonymousBootstrap,
    required this.cloudUserId,
    required this.userEmail,
    required this.userName,
    required this.profiles,
    required this.lifeBasedByProfileId,
    required this.timeLifeByProfileId,
    required this.currentProfileId,
    required this.soulPoints,
    required this.currentStreak,
    required this.dailyEarnings,
    required this.dailyAdEarnings,
    required this.dailyAdLimit,
    required this.lastCheckInAt,
    required this.lastAdRewardAt,
    required this.compareProfiles,
    required this.selectedCompareProfileId,
  });

  factory AppSessionSnapshot.initial() {
    return const AppSessionSnapshot(
      isAuthenticated: false,
      authMode: SessionAuthMode.anonymous,
      pendingAnonymousBootstrap: true,
      cloudUserId: null,
      userEmail: null,
      userName: null,
      profiles: <UserProfile>[],
      lifeBasedByProfileId: <String, ProfileLifeBasedSnapshot>{},
      timeLifeByProfileId: <String, ProfileTimeLifeSnapshot>{},
      currentProfileId: null,
      soulPoints: 0,
      currentStreak: 0,
      dailyEarnings: 0,
      dailyAdEarnings: 0,
      dailyAdLimit: 50,
      lastCheckInAt: null,
      lastAdRewardAt: null,
      compareProfiles: <ComparisonProfile>[],
      selectedCompareProfileId: null,
    );
  }

  final bool isAuthenticated;
  final SessionAuthMode authMode;
  final bool pendingAnonymousBootstrap;
  final String? cloudUserId;
  final String? userEmail;
  final String? userName;
  final List<UserProfile> profiles;
  final Map<String, ProfileLifeBasedSnapshot> lifeBasedByProfileId;
  final Map<String, ProfileTimeLifeSnapshot> timeLifeByProfileId;
  final String? currentProfileId;
  final int soulPoints;
  final int currentStreak;
  final int dailyEarnings;
  final int dailyAdEarnings;
  final int dailyAdLimit;
  final DateTime? lastCheckInAt;
  final DateTime? lastAdRewardAt;
  final List<ComparisonProfile> compareProfiles;
  final String? selectedCompareProfileId;

  bool get hasCloudSession =>
      isAuthenticated && (cloudUserId ?? '').trim().isNotEmpty;

  AppSessionSnapshot copyWith({
    bool? isAuthenticated,
    SessionAuthMode? authMode,
    bool? pendingAnonymousBootstrap,
    String? cloudUserId,
    bool clearCloudUserId = false,
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
    int? dailyAdEarnings,
    int? dailyAdLimit,
    DateTime? lastCheckInAt,
    bool clearLastCheckInAt = false,
    DateTime? lastAdRewardAt,
    bool clearLastAdRewardAt = false,
    List<ComparisonProfile>? compareProfiles,
    String? selectedCompareProfileId,
    bool clearSelectedCompareProfileId = false,
  }) {
    return AppSessionSnapshot(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      authMode: authMode ?? this.authMode,
      pendingAnonymousBootstrap:
          pendingAnonymousBootstrap ?? this.pendingAnonymousBootstrap,
      cloudUserId: clearCloudUserId ? null : cloudUserId ?? this.cloudUserId,
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
      dailyAdEarnings: dailyAdEarnings ?? this.dailyAdEarnings,
      dailyAdLimit: dailyAdLimit ?? this.dailyAdLimit,
      lastCheckInAt: clearLastCheckInAt
          ? null
          : lastCheckInAt ?? this.lastCheckInAt,
      lastAdRewardAt: clearLastAdRewardAt
          ? null
          : lastAdRewardAt ?? this.lastAdRewardAt,
      compareProfiles: compareProfiles ?? this.compareProfiles,
      selectedCompareProfileId: clearSelectedCompareProfileId
          ? null
          : selectedCompareProfileId ?? this.selectedCompareProfileId,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'isAuthenticated': isAuthenticated,
      'authMode': authMode.value,
      'pendingAnonymousBootstrap': pendingAnonymousBootstrap,
      'cloudUserId': cloudUserId,
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
      'dailyAdEarnings': dailyAdEarnings,
      'dailyAdLimit': dailyAdLimit,
      'lastCheckInAt': lastCheckInAt?.toIso8601String(),
      'lastAdRewardAt': lastAdRewardAt?.toIso8601String(),
      'compareProfiles': compareProfiles
          .map((ComparisonProfile profile) => profile.toJson())
          .toList(),
      'selectedCompareProfileId': selectedCompareProfileId,
    };
  }

  factory AppSessionSnapshot.fromJson(Map<String, dynamic> json) {
    final bool isAuthenticated = json['isAuthenticated'] as bool? ?? false;
    final String? userEmail = (json['userEmail'] as String?)?.trim();
    final SessionAuthMode authMode = _resolveAuthMode(
      rawAuthMode: json['authMode'] as String?,
      isAuthenticated: isAuthenticated,
      userEmail: userEmail,
    );
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
      isAuthenticated: isAuthenticated,
      authMode: authMode,
      pendingAnonymousBootstrap:
          json['pendingAnonymousBootstrap'] as bool? ?? false,
      cloudUserId: (json['cloudUserId'] as String?)?.trim().isNotEmpty == true
          ? (json['cloudUserId'] as String).trim()
          : null,
      userEmail: userEmail?.isNotEmpty == true ? userEmail : null,
      userName: json['userName'] as String?,
      profiles: profiles,
      lifeBasedByProfileId: lifeBasedByProfileId,
      timeLifeByProfileId: timeLifeByProfileId,
      currentProfileId: hasCurrentProfile
          ? currentProfileId
          : (profiles.isNotEmpty ? profiles.first.id : null),
      soulPoints: json['soulPoints'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      dailyEarnings: json['dailyEarnings'] as int? ?? 0,
      dailyAdEarnings: json['dailyAdEarnings'] as int? ?? 0,
      dailyAdLimit: json['dailyAdLimit'] as int? ?? 50,
      lastCheckInAt: DateTime.tryParse(json['lastCheckInAt'] as String? ?? ''),
      lastAdRewardAt: DateTime.tryParse(
        json['lastAdRewardAt'] as String? ?? '',
      ),
      compareProfiles: compareProfiles,
      selectedCompareProfileId: resolvedSelectedCompareProfileId,
    );
  }

  static SessionAuthMode _resolveAuthMode({
    required String? rawAuthMode,
    required bool isAuthenticated,
    required String? userEmail,
  }) {
    if (rawAuthMode != null && rawAuthMode.trim().isNotEmpty) {
      return SessionAuthMode.fromValue(rawAuthMode);
    }
    if (!isAuthenticated) {
      return SessionAuthMode.anonymous;
    }
    if ((userEmail ?? '').trim().isEmpty) {
      return SessionAuthMode.anonymous;
    }
    return SessionAuthMode.registered;
  }
}
