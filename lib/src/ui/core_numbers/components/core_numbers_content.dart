import 'package:flutter/material.dart';

import 'package:test/src/core/model/numerology_reading_models.dart';
import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/ui/core_numbers/interactor/core_numbers_state.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_pages.dart';
import 'package:test/src/utils/app_styles.dart';
import 'package:test/src/utils/tab_navigation_helper.dart';

class CoreNumbersContent extends StatelessWidget {
  const CoreNumbersContent({required this.state, super.key});

  final CoreNumbersState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: state.hasProfile
            ? _LoadedContent(
                key: const ValueKey<String>('loaded'),
                state: state,
              )
            : _EmptyContent(key: const ValueKey<String>('empty')),
      ),
    );
  }
}

class _LoadedContent extends StatelessWidget {
  const _LoadedContent({required this.state, super.key});

  final CoreNumbersState state;

  @override
  Widget build(BuildContext context) {
    final List<_CoreNumberCardData> cards = <_CoreNumberCardData>[
      _CoreNumberCardData(
        number: state.lifePathNumber,
        title: 'Số chủ đạo',
        subtitle: 'Life Path Number',
        icon: Icons.star_rounded,
        intro:
            'Con số định hướng cuộc đời, mục đích sống và bài học lớn nhất bạn cần trải nghiệm.',
        content: state.lifePathContent,
      ),
      _CoreNumberCardData(
        number: state.soulUrgeNumber,
        title: 'Số linh hồn',
        subtitle: 'Soul Urge Number',
        icon: Icons.favorite_rounded,
        intro:
            'Khát khao sâu thẳm bên trong, động lực thúc đẩy và mong muốn của trái tim.',
        content: state.soulUrgeContent,
      ),
      _CoreNumberCardData(
        number: state.expressionNumber,
        title: 'Số biểu đạt',
        subtitle: 'Expression Number',
        icon: Icons.person_rounded,
        intro:
            'Nguồn năng lượng biểu đạt và cách bạn thể hiện tài năng ra thế giới.',
        content: state.expressionContent,
      ),
      _CoreNumberCardData(
        number: state.missionNumber,
        title: 'Số sứ mệnh',
        subtitle: 'Mission Number',
        icon: Icons.track_changes_rounded,
        intro:
            'Sứ mệnh và mục đích cuộc đời, điều bạn được sinh ra để hoàn thành.',
        content: state.missionContent,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _IntroCard(),
        12.height,
        _SummaryCard(state: state),
        12.height,
        for (final _CoreNumberCardData card in cards) ...<Widget>[
          _CoreNumberCard(data: card),
          12.height,
        ],
        8.height,
      ],
    );
  }
}

class _EmptyContent extends StatelessWidget {
  const _EmptyContent({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.mysticalCardGradient(),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: <Widget>[
            const Icon(
              Icons.lock_outline_rounded,
              size: 26,
              color: AppColors.richGold,
            ),
            10.height,
            Text(
              'Bạn chưa có hồ sơ',
              style: AppStyles.h4(fontWeight: FontWeight.w600),
            ),
            6.height,
            Text(
              'Tạo hồ sơ để hệ thống tính 4 chỉ số cốt lõi của bạn.',
              style: AppStyles.bodySmall(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            14.height,
            InkWell(
              onTap: () =>
                  TabNavigationHelper.pushCommonRoute(AppPages.onboarding),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Tạo hồ sơ ngay', style: AppStyles.buttonSmall()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.mysticalCardGradient(),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '4 Con số định hình bạn',
              style: AppStyles.h4(fontWeight: FontWeight.w600),
            ),
            6.height,
            Text(
              'Đây là 4 con số quan trọng nhất, tạo nên nền tảng con người bạn. Chúng được tính từ tên và ngày sinh.',
              style: AppStyles.bodySmall(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state});

  final CoreNumbersState state;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: <Color>[
            AppColors.richGold.withValues(alpha: 0.18),
            AppColors.violetAccent.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: AppColors.richGold,
                ),
                8.width,
                Text(
                  'Tổng quan',
                  style: AppStyles.h4(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            8.height,
            RichText(
              text: TextSpan(
                style: AppStyles.bodySmall(color: AppColors.textSecondary),
                children: <InlineSpan>[
                  const TextSpan(text: 'Bạn là '),
                  TextSpan(
                    text: '${state.lifePathContent.title.toLowerCase()} ',
                    style: AppStyles.bodySmall(
                      color: AppColors.richGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: '(Số ${state.lifePathNumber}), '),
                  const TextSpan(text: 'được thúc đẩy bởi '),
                  TextSpan(
                    text: '${state.soulUrgeContent.title.toLowerCase()} ',
                    style: AppStyles.bodySmall(
                      color: AppColors.richGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: '(Số ${state.soulUrgeNumber}), '),
                  const TextSpan(text: 'được nhìn nhận như '),
                  TextSpan(
                    text: '${state.expressionContent.title.toLowerCase()} ',
                    style: AppStyles.bodySmall(
                      color: AppColors.richGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: '(Số ${state.expressionNumber}), '),
                  const TextSpan(text: 'với '),
                  TextSpan(
                    text: '${state.missionContent.title.toLowerCase()} ',
                    style: AppStyles.bodySmall(
                      color: AppColors.richGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: '(Số ${state.missionNumber}).'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoreNumberCard extends StatelessWidget {
  const _CoreNumberCard({required this.data});

  final _CoreNumberCardData data;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.richGold.withValues(alpha: 0.14),
                      ),
                    ),
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: <Color>[
                            AppColors.richGold.withValues(alpha: 0.35),
                            AppColors.violetAccent.withValues(alpha: 0.22),
                          ],
                        ),
                        border: Border.all(
                          color: AppColors.richGold.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${data.number}',
                          style: AppStyles.numberMedium(),
                        ),
                      ),
                    ),
                  ],
                ),
                12.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(data.icon, size: 16, color: AppColors.richGold),
                          6.width,
                          Text(
                            data.title,
                            style: AppStyles.h4(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      3.height,
                      Text(
                        data.subtitle,
                        style: AppStyles.caption(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            12.height,
            Text(
              data.intro,
              style: AppStyles.bodySmall(color: AppColors.textSecondary),
            ),
            10.height,
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.richGold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.richGold.withValues(alpha: 0.2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  data.content.interpretation,
                  style: AppStyles.bodySmall(color: AppColors.textSecondary),
                ),
              ),
            ),
            10.height,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: data.content.keywords.map((String keyword) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: AppColors.richGold.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppColors.richGold.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    keyword,
                    style: AppStyles.caption(
                      color: AppColors.richGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoreNumberCardData {
  const _CoreNumberCardData({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.intro,
    required this.content,
  });

  final int number;
  final String title;
  final String subtitle;
  final IconData icon;
  final String intro;
  final CoreNumberContent content;
}
