import 'package:test/src/core/model/profile_life_based_snapshot.dart';
import 'package:test/src/core/model/profile_time_life_snapshot.dart';
import 'package:test/src/core/model/user_profile.dart';
import 'package:test/src/helper/numerology_helper.dart';

class LifeBasedRefreshResult {
  const LifeBasedRefreshResult({
    required this.profileId,
    required this.snapshot,
  });

  final String profileId;
  final ProfileLifeBasedSnapshot snapshot;
}

class TimeLifeRefreshResult {
  const TimeLifeRefreshResult({
    required this.profileId,
    required this.snapshot,
  });

  final String profileId;
  final ProfileTimeLifeSnapshot snapshot;
}

class SessionMetricsService {
  const SessionMetricsService();

  LifeBasedRefreshResult? ensureLifeBasedForCurrentProfile({
    required UserProfile? profile,
    required Map<String, ProfileLifeBasedSnapshot> lifeBasedByProfileId,
    DateTime? now,
    bool force = false,
  }) {
    if (profile == null) {
      return null;
    }
    final ProfileLifeBasedSnapshot? existing = lifeBasedByProfileId[profile.id];
    if (!force && existing != null && existing.metrics.isNotEmpty) {
      return null;
    }

    final DateTime currentTime = now ?? DateTime.now();
    final ProfileLifeBasedSnapshot snapshot = ProfileLifeBasedSnapshot(
      computedAt: currentTime,
      metrics: <String, int>{
        ProfileLifeBasedSnapshot.lifePathMetric:
            NumerologyHelper.getLifePathNumber(profile.birthDate),
        ProfileLifeBasedSnapshot.expressionMetric:
            NumerologyHelper.getExpressionNumber(profile.name),
        ProfileLifeBasedSnapshot.soulUrgeMetric:
            NumerologyHelper.getSoulUrgeNumber(profile.name),
        ProfileLifeBasedSnapshot.personalityMetric:
            NumerologyHelper.getPersonalityNumber(profile.name),
        ProfileLifeBasedSnapshot.missionMetric:
            NumerologyHelper.getMissionNumber(profile.birthDate, profile.name),
      },
    );
    return LifeBasedRefreshResult(profileId: profile.id, snapshot: snapshot);
  }

  TimeLifeRefreshResult? refreshTimeLifeForCurrentProfile({
    required UserProfile? profile,
    required Map<String, ProfileTimeLifeSnapshot> timeLifeByProfileId,
    required String guestProfileId,
    DateTime? now,
    bool force = false,
  }) {
    final DateTime currentTime = now ?? DateTime.now();
    final String profileId = _activeTimeLifeProfileId(profile, guestProfileId);
    final ProfileTimeLifeSnapshot existing =
        timeLifeByProfileId[profileId] ?? ProfileTimeLifeSnapshot.initial();

    final bool shouldRefreshUniversalDay =
        force ||
        existing.needsRefresh(
          ProfileTimeLifeSnapshot.universalDayMetric,
          currentTime,
        );
    final bool shouldRefreshLuckyNumber =
        force ||
        existing.needsRefresh(
          ProfileTimeLifeSnapshot.luckyNumberMetric,
          currentTime,
        );
    final bool shouldRefreshDailyMessage =
        force ||
        existing.needsRefresh(
          ProfileTimeLifeSnapshot.dailyMessageNumberMetric,
          currentTime,
        );
    final bool shouldRefreshDaily =
        shouldRefreshUniversalDay ||
        shouldRefreshLuckyNumber ||
        shouldRefreshDailyMessage;

    final bool shouldRefreshUniversalYear =
        force ||
        existing.needsRefresh(
          ProfileTimeLifeSnapshot.universalYearMetric,
          currentTime,
        );
    final bool shouldRefreshUniversalMonth =
        force ||
        existing.needsRefresh(
          ProfileTimeLifeSnapshot.universalMonthMetric,
          currentTime,
        );

    final bool shouldRefreshPersonalYear =
        profile != null &&
        (force ||
            existing.needsRefresh(
              ProfileTimeLifeSnapshot.personalYearMetric,
              currentTime,
            ));
    final bool shouldRefreshPersonalMonth =
        profile != null &&
        (force ||
            existing.needsRefresh(
              ProfileTimeLifeSnapshot.personalMonthMetric,
              currentTime,
            ));
    final bool shouldRefreshPersonalDay =
        profile != null &&
        (force ||
            existing.needsRefresh(
              ProfileTimeLifeSnapshot.personalDayMetric,
              currentTime,
            ));

    if (!shouldRefreshDaily &&
        !shouldRefreshUniversalYear &&
        !shouldRefreshUniversalMonth &&
        !shouldRefreshPersonalYear &&
        !shouldRefreshPersonalMonth &&
        !shouldRefreshPersonalDay) {
      return null;
    }

    ProfileTimeLifeSnapshot snapshot = existing;

    if (shouldRefreshDaily) {
      final int universalDay = NumerologyHelper.calculateUniversalDayNumber(
        currentTime,
      );
      final int luckyNumber = NumerologyHelper.luckyNumber(currentTime);
      final DateTime dailyRefreshAt = _nextDailyRefreshAt(currentTime);

      if (shouldRefreshUniversalDay) {
        snapshot = snapshot.upsertMetric(
          key: ProfileTimeLifeSnapshot.universalDayMetric,
          snapshot: TimeLifeMetricSnapshot(
            value: universalDay,
            computedAt: currentTime,
            refreshAt: dailyRefreshAt,
          ),
        );
      }
      if (shouldRefreshLuckyNumber) {
        snapshot = snapshot.upsertMetric(
          key: ProfileTimeLifeSnapshot.luckyNumberMetric,
          snapshot: TimeLifeMetricSnapshot(
            value: luckyNumber,
            computedAt: currentTime,
            refreshAt: dailyRefreshAt,
          ),
        );
      }
      if (shouldRefreshDailyMessage) {
        snapshot = snapshot.upsertMetric(
          key: ProfileTimeLifeSnapshot.dailyMessageNumberMetric,
          snapshot: TimeLifeMetricSnapshot(
            value: universalDay,
            computedAt: currentTime,
            refreshAt: dailyRefreshAt,
          ),
        );
      }
    }

    if (shouldRefreshUniversalYear) {
      snapshot = snapshot.upsertMetric(
        key: ProfileTimeLifeSnapshot.universalYearMetric,
        snapshot: TimeLifeMetricSnapshot(
          value: NumerologyHelper.calculateUniversalYearNumber(currentTime),
          computedAt: currentTime,
          refreshAt: _nextYearlyRefreshAt(currentTime),
        ),
      );
    }
    if (shouldRefreshUniversalMonth) {
      snapshot = snapshot.upsertMetric(
        key: ProfileTimeLifeSnapshot.universalMonthMetric,
        snapshot: TimeLifeMetricSnapshot(
          value: NumerologyHelper.calculateUniversalMonthNumber(currentTime),
          computedAt: currentTime,
          refreshAt: _nextMonthlyRefreshAt(currentTime),
        ),
      );
    }

    if (profile != null) {
      if (shouldRefreshPersonalYear) {
        snapshot = snapshot.upsertMetric(
          key: ProfileTimeLifeSnapshot.personalYearMetric,
          snapshot: TimeLifeMetricSnapshot(
            value: NumerologyHelper.calculatePersonalYearNumber(
              birthDate: profile.birthDate,
              date: currentTime,
            ),
            computedAt: currentTime,
            refreshAt: _nextYearlyRefreshAt(currentTime),
          ),
        );
      }
      if (shouldRefreshPersonalMonth) {
        snapshot = snapshot.upsertMetric(
          key: ProfileTimeLifeSnapshot.personalMonthMetric,
          snapshot: TimeLifeMetricSnapshot(
            value: NumerologyHelper.calculatePersonalMonthNumber(
              birthDate: profile.birthDate,
              date: currentTime,
            ),
            computedAt: currentTime,
            refreshAt: _nextMonthlyRefreshAt(currentTime),
          ),
        );
      }
      if (shouldRefreshPersonalDay) {
        snapshot = snapshot.upsertMetric(
          key: ProfileTimeLifeSnapshot.personalDayMetric,
          snapshot: TimeLifeMetricSnapshot(
            value: NumerologyHelper.calculatePersonalDayNumber(
              birthDate: profile.birthDate,
              date: currentTime,
            ),
            computedAt: currentTime,
            refreshAt: _nextDailyRefreshAt(currentTime),
          ),
        );
      }
    }

    return TimeLifeRefreshResult(profileId: profileId, snapshot: snapshot);
  }

  String _activeTimeLifeProfileId(UserProfile? profile, String guestProfileId) {
    return profile?.id ?? guestProfileId;
  }

  DateTime _nextDailyRefreshAt(DateTime now) {
    return DateTime(now.year, now.month, now.day + 1);
  }

  DateTime _nextMonthlyRefreshAt(DateTime now) {
    return DateTime(now.year, now.month + 1, 1);
  }

  DateTime _nextYearlyRefreshAt(DateTime now) {
    return DateTime(now.year + 1, 1, 1);
  }
}
