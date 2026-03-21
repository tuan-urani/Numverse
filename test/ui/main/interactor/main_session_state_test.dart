import 'package:flutter_test/flutter_test.dart';

import 'package:test/src/core/model/compatibility_history_item.dart';
import 'package:test/src/core/model/user_profile.dart';
import 'package:test/src/ui/main/interactor/main_session_state.dart';

void main() {
  group('MainSessionState.compatibilityHistoryForCurrentProfile', () {
    test('returns only history items of current profile', () {
      final UserProfile profileA = _profile(id: 'profile-a', name: 'Profile A');
      final UserProfile profileB = _profile(id: 'profile-b', name: 'Profile B');
      final List<CompatibilityHistoryItem> history = <CompatibilityHistoryItem>[
        _historyItem(id: 'b-1', primaryProfileId: profileB.id),
        _historyItem(id: 'a-1', primaryProfileId: profileA.id),
        _historyItem(id: 'a-2', primaryProfileId: profileA.id),
      ];

      final MainSessionState state = MainSessionState.initial().copyWith(
        currentProfile: profileA,
        compatibilityHistory: history,
      );

      expect(
        state.compatibilityHistoryForCurrentProfile.map((item) => item.id),
        <String>['a-1', 'a-2'],
      );
    });

    test('returns empty list when current profile is null', () {
      final MainSessionState state = MainSessionState.initial().copyWith(
        compatibilityHistory: <CompatibilityHistoryItem>[
          _historyItem(id: 'a-1', primaryProfileId: 'profile-a'),
        ],
      );

      expect(state.compatibilityHistoryForCurrentProfile, isEmpty);
    });
  });
}

UserProfile _profile({required String id, required String name}) {
  return UserProfile(
    id: id,
    name: name,
    birthDate: DateTime(1990, 1, 1),
    createdAt: DateTime(2024, 1, 1),
  );
}

CompatibilityHistoryItem _historyItem({
  required String id,
  required String primaryProfileId,
}) {
  return CompatibilityHistoryItem(
    id: id,
    requestId: id,
    primaryProfileId: primaryProfileId,
    primaryName: 'Self',
    primaryBirthDate: DateTime(1990, 1, 1),
    primaryLifePath: 1,
    primarySoul: 2,
    primaryPersonality: 3,
    primaryExpression: 4,
    targetProfileId: 'target-$id',
    targetName: 'Target',
    targetRelation: 'friend',
    targetBirthDate: DateTime(1992, 2, 2),
    targetLifePath: 2,
    targetSoul: 3,
    targetPersonality: 4,
    targetExpression: 5,
    overallScore: 80,
    coreScore: 75,
    communicationScore: 82,
    soulScore: 79,
    personalityScore: 84,
    createdAt: DateTime(2026, 3, 20),
  );
}
