class CloudLoginResult {
  const CloudLoginResult({
    required this.userId,
    required this.email,
    required this.accessToken,
    required this.refreshToken,
    required this.firstSyncPerformed,
  });

  final String userId;
  final String email;
  final String accessToken;
  final String refreshToken;
  final bool firstSyncPerformed;
}
