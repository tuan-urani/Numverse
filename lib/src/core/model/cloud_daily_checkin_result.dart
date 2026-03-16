class CloudDailyCheckInResult {
  const CloudDailyCheckInResult({
    required this.alreadyClaimed,
    required this.rewardAwarded,
    required this.soulPoints,
    required this.currentStreak,
    required this.dailyEarnings,
    required this.lastCheckInAt,
  });

  final bool alreadyClaimed;
  final int rewardAwarded;
  final int soulPoints;
  final int currentStreak;
  final int dailyEarnings;
  final DateTime? lastCheckInAt;

  factory CloudDailyCheckInResult.fromJson(Map<String, dynamic> json) {
    return CloudDailyCheckInResult(
      alreadyClaimed: json['alreadyClaimed'] as bool? ?? false,
      rewardAwarded: json['rewardAwarded'] as int? ?? 0,
      soulPoints: json['soulPoints'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      dailyEarnings: json['dailyEarnings'] as int? ?? 0,
      lastCheckInAt: DateTime.tryParse(json['lastCheckInAt'] as String? ?? ''),
    );
  }
}
