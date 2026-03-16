import 'package:test/src/core/model/app_session_snapshot.dart';
import 'package:test/src/ui/main/interactor/main_session_state.dart';

class NormalizedIdentity {
  const NormalizedIdentity({required this.email, required this.name});

  final String email;
  final String name;
}

class SessionAuthService {
  const SessionAuthService();

  NormalizedIdentity normalizeIdentity({
    required String email,
    required String name,
  }) {
    return NormalizedIdentity(
      email: email.trim().toLowerCase(),
      name: name.trim(),
    );
  }

  AppSessionSnapshot buildLocalSnapshotBeforeAuth({
    required MainSessionState state,
    required NormalizedIdentity identity,
  }) {
    return AppSessionSnapshot(
      isAuthenticated: true,
      userEmail: identity.email,
      userName: identity.name,
      profiles: state.profiles,
      lifeBasedByProfileId: state.lifeBasedByProfileId,
      timeLifeByProfileId: state.timeLifeByProfileId,
      currentProfileId: state.currentProfile?.id,
      soulPoints: state.soulPoints,
      currentStreak: state.currentStreak,
      dailyEarnings: state.dailyEarnings,
      lastCheckInAt: state.lastCheckInAt,
      compareProfiles: state.compareProfiles,
      selectedCompareProfileId: state.selectedCompareProfileId,
    );
  }
}
