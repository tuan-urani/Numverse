class CloudAdRewardGrantResult {
  const CloudAdRewardGrantResult({
    required this.granted,
    required this.idempotent,
    required this.rewardAwarded,
    required this.rewardPerWatch,
    required this.dailyLimit,
    required this.todayEarned,
    required this.remaining,
    required this.soulPoints,
  });

  final bool granted;
  final bool idempotent;
  final int rewardAwarded;
  final int rewardPerWatch;
  final int dailyLimit;
  final int todayEarned;
  final int remaining;
  final int soulPoints;

  factory CloudAdRewardGrantResult.fromJson(Map<String, dynamic> json) {
    return CloudAdRewardGrantResult(
      granted: json['granted'] == true,
      idempotent: json['idempotent'] == true,
      rewardAwarded: (json['rewardAwarded'] as num?)?.toInt() ?? 0,
      rewardPerWatch: (json['rewardPerWatch'] as num?)?.toInt() ?? 0,
      dailyLimit: (json['dailyLimit'] as num?)?.toInt() ?? 0,
      todayEarned: (json['todayEarned'] as num?)?.toInt() ?? 0,
      remaining: (json['remaining'] as num?)?.toInt() ?? 0,
      soulPoints: (json['soulPoints'] as num?)?.toInt() ?? 0,
    );
  }
}
