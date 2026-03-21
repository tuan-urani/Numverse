import 'package:equatable/equatable.dart';

import 'package:test/src/core/model/comparison_profile.dart';
import 'package:test/src/core/model/compatibility_history_item.dart';
import 'package:test/src/core/model/profile_life_based_snapshot.dart';
import 'package:test/src/core/model/profile_time_life_snapshot.dart';
import 'package:test/src/core/model/session_auth_mode.dart';
import 'package:test/src/core/model/user_profile.dart';
import 'package:test/src/ui/widgets/app_state_view.dart';

class MainSessionState extends Equatable {
  const MainSessionState({
    required this.viewState,
    required this.isAuthenticated,
    required this.authMode,
    required this.pendingAnonymousBootstrap,
    required this.cloudUserId,
    required this.userEmail,
    required this.userName,
    required this.profiles,
    required this.lifeBasedByProfileId,
    required this.timeLifeByProfileId,
    required this.currentProfile,
    required this.soulPoints,
    required this.currentStreak,
    required this.dailyEarnings,
    required this.dailyLimit,
    required this.dailyAdEarnings,
    required this.dailyAdLimit,
    required this.dailyAngelNumber,
    required this.dailyAngelRefreshAt,
    required this.lastCheckInAt,
    required this.lastCheckInRewardAwarded,
    required this.lastCheckInEventId,
    required this.lastAdRewardAt,
    required this.currentPageInteraction,
    required this.interactionCount,
    required this.errorMessage,
    required this.compareProfiles,
    required this.selectedCompareProfileId,
    required this.compatibilityHistory,
  });

  factory MainSessionState.initial() {
    return const MainSessionState(
      viewState: AppViewStateStatus.loading,
      isAuthenticated: false,
      authMode: SessionAuthMode.anonymous,
      pendingAnonymousBootstrap: true,
      cloudUserId: null,
      userEmail: null,
      userName: null,
      profiles: <UserProfile>[],
      lifeBasedByProfileId: <String, ProfileLifeBasedSnapshot>{},
      timeLifeByProfileId: <String, ProfileTimeLifeSnapshot>{},
      currentProfile: null,
      soulPoints: 100,
      currentStreak: 0,
      dailyEarnings: 0,
      dailyLimit: 100,
      dailyAdEarnings: 0,
      dailyAdLimit: 50,
      dailyAngelNumber: null,
      dailyAngelRefreshAt: null,
      lastCheckInAt: null,
      lastCheckInRewardAwarded: 0,
      lastCheckInEventId: 0,
      lastAdRewardAt: null,
      currentPageInteraction: '',
      interactionCount: 0,
      errorMessage: null,
      compareProfiles: <ComparisonProfile>[],
      selectedCompareProfileId: null,
      compatibilityHistory: <CompatibilityHistoryItem>[],
    );
  }

  final AppViewStateStatus viewState;
  final bool isAuthenticated;
  final SessionAuthMode authMode;
  final bool pendingAnonymousBootstrap;
  final String? cloudUserId;
  final String? userEmail;
  final String? userName;
  final List<UserProfile> profiles;
  final Map<String, ProfileLifeBasedSnapshot> lifeBasedByProfileId;
  final Map<String, ProfileTimeLifeSnapshot> timeLifeByProfileId;
  final UserProfile? currentProfile;
  final int soulPoints;
  final int currentStreak;
  final int dailyEarnings;
  final int dailyLimit;
  final int dailyAdEarnings;
  final int dailyAdLimit;
  final int? dailyAngelNumber;
  final DateTime? dailyAngelRefreshAt;
  final DateTime? lastCheckInAt;
  final int lastCheckInRewardAwarded;
  final int lastCheckInEventId;
  final DateTime? lastAdRewardAt;
  final String currentPageInteraction;
  final int interactionCount;
  final String? errorMessage;
  final List<ComparisonProfile> compareProfiles;
  final String? selectedCompareProfileId;
  final List<CompatibilityHistoryItem> compatibilityHistory;

  List<CompatibilityHistoryItem> get compatibilityHistoryForCurrentProfile {
    final String currentProfileId = (currentProfile?.id ?? '').trim();
    if (currentProfileId.isEmpty) {
      return const <CompatibilityHistoryItem>[];
    }
    return compatibilityHistory.where((CompatibilityHistoryItem item) {
      return item.primaryProfileId.trim() == currentProfileId;
    }).toList();
  }

  bool get hasAnyProfile => profiles.isNotEmpty;
  bool get hasCompareProfiles => compareProfiles.isNotEmpty;
  bool get isAnonymousUser => authMode == SessionAuthMode.anonymous;
  bool get isRegisteredUser => authMode == SessionAuthMode.registered;
  bool get hasCloudSession =>
      isAuthenticated && (cloudUserId ?? '').trim().isNotEmpty;

  ComparisonProfile? get selectedCompareProfile {
    if (selectedCompareProfileId == null) {
      return null;
    }
    for (final ComparisonProfile profile in compareProfiles) {
      if (profile.id == selectedCompareProfileId) {
        return profile;
      }
    }
    return null;
  }

  bool get hasCheckedInToday {
    if (lastCheckInAt == null) {
      return false;
    }
    final DateTime now = DateTime.now();
    return now.year == lastCheckInAt!.year &&
        now.month == lastCheckInAt!.month &&
        now.day == lastCheckInAt!.day;
  }

  MainSessionState copyWith({
    AppViewStateStatus? viewState,
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
    UserProfile? currentProfile,
    bool clearCurrentProfile = false,
    int? soulPoints,
    int? currentStreak,
    int? dailyEarnings,
    int? dailyLimit,
    int? dailyAdEarnings,
    int? dailyAdLimit,
    int? dailyAngelNumber,
    bool clearDailyAngelNumber = false,
    DateTime? dailyAngelRefreshAt,
    bool clearDailyAngelRefreshAt = false,
    DateTime? lastCheckInAt,
    bool clearLastCheckInAt = false,
    int? lastCheckInRewardAwarded,
    int? lastCheckInEventId,
    DateTime? lastAdRewardAt,
    bool clearLastAdRewardAt = false,
    String? currentPageInteraction,
    int? interactionCount,
    String? errorMessage,
    bool clearErrorMessage = false,
    List<ComparisonProfile>? compareProfiles,
    String? selectedCompareProfileId,
    bool clearSelectedCompareProfileId = false,
    List<CompatibilityHistoryItem>? compatibilityHistory,
  }) {
    return MainSessionState(
      viewState: viewState ?? this.viewState,
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
      currentProfile: clearCurrentProfile
          ? null
          : currentProfile ?? this.currentProfile,
      soulPoints: soulPoints ?? this.soulPoints,
      currentStreak: currentStreak ?? this.currentStreak,
      dailyEarnings: dailyEarnings ?? this.dailyEarnings,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      dailyAdEarnings: dailyAdEarnings ?? this.dailyAdEarnings,
      dailyAdLimit: dailyAdLimit ?? this.dailyAdLimit,
      dailyAngelNumber: clearDailyAngelNumber
          ? null
          : dailyAngelNumber ?? this.dailyAngelNumber,
      dailyAngelRefreshAt: clearDailyAngelRefreshAt
          ? null
          : dailyAngelRefreshAt ?? this.dailyAngelRefreshAt,
      lastCheckInAt: clearLastCheckInAt
          ? null
          : lastCheckInAt ?? this.lastCheckInAt,
      lastCheckInRewardAwarded:
          lastCheckInRewardAwarded ?? this.lastCheckInRewardAwarded,
      lastCheckInEventId: lastCheckInEventId ?? this.lastCheckInEventId,
      lastAdRewardAt: clearLastAdRewardAt
          ? null
          : lastAdRewardAt ?? this.lastAdRewardAt,
      currentPageInteraction:
          currentPageInteraction ?? this.currentPageInteraction,
      interactionCount: interactionCount ?? this.interactionCount,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      compareProfiles: compareProfiles ?? this.compareProfiles,
      selectedCompareProfileId: clearSelectedCompareProfileId
          ? null
          : selectedCompareProfileId ?? this.selectedCompareProfileId,
      compatibilityHistory: compatibilityHistory ?? this.compatibilityHistory,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    viewState,
    isAuthenticated,
    authMode,
    pendingAnonymousBootstrap,
    cloudUserId,
    userEmail,
    userName,
    profiles,
    lifeBasedByProfileId,
    timeLifeByProfileId,
    currentProfile,
    soulPoints,
    currentStreak,
    dailyEarnings,
    dailyLimit,
    dailyAdEarnings,
    dailyAdLimit,
    dailyAngelNumber,
    dailyAngelRefreshAt,
    lastCheckInAt,
    lastCheckInRewardAwarded,
    lastCheckInEventId,
    lastAdRewardAt,
    currentPageInteraction,
    interactionCount,
    errorMessage,
    compareProfiles,
    selectedCompareProfileId,
    compatibilityHistory,
  ];
}
