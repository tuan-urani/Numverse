import 'package:equatable/equatable.dart';

import 'package:test/src/core/model/comparison_profile.dart';
import 'package:test/src/core/model/profile_life_based_snapshot.dart';
import 'package:test/src/core/model/profile_time_life_snapshot.dart';
import 'package:test/src/core/model/user_profile.dart';
import 'package:test/src/ui/widgets/app_state_view.dart';

class MainSessionState extends Equatable {
  const MainSessionState({
    required this.viewState,
    required this.isAuthenticated,
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
    required this.lastCheckInAt,
    required this.currentPageInteraction,
    required this.interactionCount,
    required this.errorMessage,
    required this.compareProfiles,
    required this.selectedCompareProfileId,
  });

  factory MainSessionState.initial() {
    return const MainSessionState(
      viewState: AppViewStateStatus.loading,
      isAuthenticated: false,
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
      lastCheckInAt: null,
      currentPageInteraction: '',
      interactionCount: 0,
      errorMessage: null,
      compareProfiles: <ComparisonProfile>[],
      selectedCompareProfileId: null,
    );
  }

  final AppViewStateStatus viewState;
  final bool isAuthenticated;
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
  final DateTime? lastCheckInAt;
  final String currentPageInteraction;
  final int interactionCount;
  final String? errorMessage;
  final List<ComparisonProfile> compareProfiles;
  final String? selectedCompareProfileId;

  bool get hasAnyProfile => profiles.isNotEmpty;
  bool get hasCompareProfiles => compareProfiles.isNotEmpty;

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
    DateTime? lastCheckInAt,
    bool clearLastCheckInAt = false,
    String? currentPageInteraction,
    int? interactionCount,
    String? errorMessage,
    bool clearErrorMessage = false,
    List<ComparisonProfile>? compareProfiles,
    String? selectedCompareProfileId,
    bool clearSelectedCompareProfileId = false,
  }) {
    return MainSessionState(
      viewState: viewState ?? this.viewState,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
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
      lastCheckInAt: clearLastCheckInAt
          ? null
          : lastCheckInAt ?? this.lastCheckInAt,
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
    );
  }

  @override
  List<Object?> get props => <Object?>[
    viewState,
    isAuthenticated,
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
    lastCheckInAt,
    currentPageInteraction,
    interactionCount,
    errorMessage,
    compareProfiles,
    selectedCompareProfileId,
  ];
}
