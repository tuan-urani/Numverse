import 'package:test/src/core/model/comparison_profile.dart';
import 'package:test/src/helper/numerology_helper.dart';

class SessionCompareService {
  const SessionCompareService();

  ComparisonProfile createProfile({
    required String name,
    required String relation,
    required DateTime birthDate,
    DateTime? now,
  }) {
    final DateTime createdAt = now ?? DateTime.now();
    return ComparisonProfile(
      id: createdAt.microsecondsSinceEpoch.toString(),
      name: name.trim(),
      relation: relation.trim(),
      birthDate: birthDate,
      lifePathNumber: NumerologyHelper.getLifePathNumber(birthDate),
    );
  }

  bool containsProfile(List<ComparisonProfile> profiles, String profileId) {
    for (final ComparisonProfile profile in profiles) {
      if (profile.id == profileId) {
        return true;
      }
    }
    return false;
  }
}
