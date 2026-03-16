class SessionCheckInUpdate {
  const SessionCheckInUpdate({
    required this.dailyEarnings,
    required this.currentStreak,
    required this.soulPoints,
    required this.lastCheckInAt,
  });

  final int dailyEarnings;
  final int currentStreak;
  final int soulPoints;
  final DateTime lastCheckInAt;
}

class SessionRewardService {
  const SessionRewardService();

  int addSoulPoints({required int currentSoulPoints, required int amount}) {
    return currentSoulPoints + amount;
  }

  int? deductSoulPoints({required int currentSoulPoints, required int amount}) {
    if (currentSoulPoints < amount) {
      return null;
    }
    return currentSoulPoints - amount;
  }

  SessionCheckInUpdate? computeCheckIn({
    required bool hasCheckedInToday,
    required int dailyEarnings,
    required int dailyLimit,
    required int currentStreak,
    required int soulPoints,
    DateTime? now,
  }) {
    if (hasCheckedInToday || dailyEarnings >= dailyLimit) {
      return null;
    }
    final int reward = _rewardByStreak(currentStreak);
    final int nextEarning = (dailyEarnings + reward).clamp(0, dailyLimit);
    final DateTime checkedInAt = now ?? DateTime.now();
    return SessionCheckInUpdate(
      dailyEarnings: nextEarning,
      currentStreak: currentStreak + 1,
      soulPoints: soulPoints + reward,
      lastCheckInAt: checkedInAt,
    );
  }

  int _rewardByStreak(int streak) {
    if (streak >= 30) {
      return 30;
    }
    if (streak >= 14) {
      return 20;
    }
    if (streak >= 7) {
      return 15;
    }
    return 10;
  }
}
