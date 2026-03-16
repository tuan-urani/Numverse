import 'package:test/src/core/model/user_profile.dart';

class SessionProfileService {
  const SessionProfileService();

  UserProfile createProfile({
    required String name,
    required DateTime birthDate,
    DateTime? now,
  }) {
    final DateTime createdAt = now ?? DateTime.now();
    return UserProfile(
      id: createdAt.microsecondsSinceEpoch.toString(),
      name: name,
      birthDate: birthDate,
      createdAt: createdAt,
    );
  }

  UserProfile? findProfileById(List<UserProfile> profiles, String profileId) {
    for (final UserProfile profile in profiles) {
      if (profile.id == profileId) {
        return profile;
      }
    }
    return null;
  }

  UserProfile? resolveCurrentProfile(
    List<UserProfile> profiles,
    String? profileId,
  ) {
    if (profiles.isEmpty) {
      return null;
    }
    if (profileId == null) {
      return profiles.first;
    }
    return findProfileById(profiles, profileId) ?? profiles.first;
  }

  List<UserProfile> updateProfile(
    List<UserProfile> profiles, {
    required String profileId,
    required String name,
    required DateTime birthDate,
  }) {
    return profiles
        .map(
          (UserProfile profile) => profile.id == profileId
              ? profile.copyWith(name: name, birthDate: birthDate)
              : profile,
        )
        .toList();
  }

  List<UserProfile> removeProfile(
    List<UserProfile> profiles, {
    required String profileId,
  }) {
    return profiles
        .where((UserProfile profile) => profile.id != profileId)
        .toList();
  }
}
