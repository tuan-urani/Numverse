class CloudAdRewardStatusResult {
  const CloudAdRewardStatusResult({
    required this.placementCode,
    required this.rewardPerWatch,
    required this.dailyLimit,
    required this.todayEarned,
    required this.remaining,
    required this.canWatch,
    required this.soulPoints,
    required this.lastRewardAt,
  });

  final String placementCode;
  final int rewardPerWatch;
  final int dailyLimit;
  final int todayEarned;
  final int remaining;
  final bool canWatch;
  final int soulPoints;
  final DateTime? lastRewardAt;

  factory CloudAdRewardStatusResult.fromJson(Map<String, dynamic> json) {
    return CloudAdRewardStatusResult(
      placementCode: (json['placementCode'] as String? ?? '').trim(),
      rewardPerWatch: (json['rewardPerWatch'] as num?)?.toInt() ?? 0,
      dailyLimit: (json['dailyLimit'] as num?)?.toInt() ?? 0,
      todayEarned: (json['todayEarned'] as num?)?.toInt() ?? 0,
      remaining: (json['remaining'] as num?)?.toInt() ?? 0,
      canWatch: json['canWatch'] == true,
      soulPoints: (json['soulPoints'] as num?)?.toInt() ?? 0,
      lastRewardAt: DateTime.tryParse(json['lastRewardAt'] as String? ?? ''),
    );
  }
}
