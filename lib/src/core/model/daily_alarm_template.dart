class DailyAlarmTemplate {
  const DailyAlarmTemplate({
    required this.locale,
    required this.title,
    required this.body,
  });

  factory DailyAlarmTemplate.fallback(String localeCode) {
    final String normalized = _normalizeLocale(localeCode);
    return switch (normalized) {
      'en' => const DailyAlarmTemplate(
        locale: 'en',
        title: 'Numverse Daily Energy',
        body: 'Open app to check your energy today.',
      ),
      'ja' => const DailyAlarmTemplate(
        locale: 'ja',
        title: 'Numverse 今日のエネルギー',
        body: 'アプリを開いて今日のエネルギーを確認しましょう。',
      ),
      _ => const DailyAlarmTemplate(
        locale: 'vi',
        title: 'Năng lượng hôm nay',
        body: 'Mở app để xem năng lượng hôm nay của bạn.',
      ),
    };
  }

  factory DailyAlarmTemplate.fromJson(Map<String, dynamic> json) {
    final String locale = _normalizeLocale(json['locale'] as String? ?? 'vi');
    final String title = (json['title'] as String? ?? '').trim();
    final String body = (json['body'] as String? ?? '').trim();

    if (title.isEmpty || body.isEmpty) {
      return DailyAlarmTemplate.fallback(locale);
    }

    return DailyAlarmTemplate(locale: locale, title: title, body: body);
  }

  final String locale;
  final String title;
  final String body;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'locale': locale, 'title': title, 'body': body};
  }

  static String _normalizeLocale(String raw) {
    final String normalized = raw.trim().toLowerCase().replaceAll('-', '_');
    if (normalized.startsWith('ja')) {
      return 'ja';
    }
    if (normalized.startsWith('en')) {
      return 'en';
    }
    return 'vi';
  }
}
