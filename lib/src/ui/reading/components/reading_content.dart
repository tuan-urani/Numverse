import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/core/model/user_profile.dart';
import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/helper/numerology_helper.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_pages.dart';
import 'package:test/src/utils/app_styles.dart';
import 'package:test/src/utils/tab_navigation_helper.dart';

class ReadingContent extends StatelessWidget {
  const ReadingContent({
    required this.profile,
    required this.onLockedTap,
    super.key,
  });

  final UserProfile? profile;
  final VoidCallback onLockedTap;

  bool get _hasProfile => profile != null;

  @override
  Widget build(BuildContext context) {
    final List<_ReadingSection> sections = <_ReadingSection>[
      _ReadingSection(
        icon: Icons.star_rounded,
        title: LocaleKey.readingCoreNumbersTitle.tr,
        description: LocaleKey.readingCoreNumbersBody.tr,
        lockedDescription:
            'Khám phá Số chủ đạo, Linh hồn, Nhân cách và Sứ mệnh - những con số định hình bản chất thật của bạn',
        gradient: <Color>[
          AppColors.richGold.withValues(alpha: 0.2),
          AppColors.richGold.withValues(alpha: 0.05),
        ],
        onTap: () => TabNavigationHelper.pushCommonRoute(AppPages.coreNumbers),
      ),
      _ReadingSection(
        icon: Icons.grid_view_rounded,
        title: LocaleKey.readingChartMatrixTitle.tr,
        description: LocaleKey.readingChartMatrixBody.tr,
        lockedDescription:
            'Phân tích biểu đồ ngày sinh và ma trận khía cạnh - bản đồ năng lượng của cuộc đời bạn',
        gradient: <Color>[
          AppColors.deepViolet.withValues(alpha: 0.2),
          AppColors.deepViolet.withValues(alpha: 0.05),
        ],
        onTap: () => TabNavigationHelper.pushCommonRoute(AppPages.chartMatrix),
      ),
      _ReadingSection(
        icon: Icons.trending_up_rounded,
        title: LocaleKey.readingLifePathTitle.tr,
        description: LocaleKey.readingLifePathBody.tr,
        lockedDescription:
            'Hiểu rõ 4 đỉnh cao và 4 thử thách định hình hành trình trưởng thành của bạn',
        gradient: <Color>[
          AppColors.violetAccent.withValues(alpha: 0.2),
          AppColors.violetAccent.withValues(alpha: 0.05),
        ],
        onTap: () => TabNavigationHelper.pushCommonRoute(AppPages.lifePath),
      ),
      _ReadingSection(
        icon: Icons.account_circle_outlined,
        title: LocaleKey.readingPortraitTitle.tr,
        description: LocaleKey.readingPortraitBody.tr,
        lockedDescription:
            'Luận giải sâu về tính cách, giao tiếp, tình cảm và con đường sự nghiệp của bạn',
        gradient: <Color>[
          AppColors.richGold.withValues(alpha: 0.2),
          AppColors.violetAccent.withValues(alpha: 0.1),
        ],
        onTap: () =>
            TabNavigationHelper.pushCommonRoute(AppPages.personalPortrait),
      ),
    ];

    final int lifePathNumber = _hasProfile
        ? NumerologyHelper.getLifePathNumber(profile!.birthDate)
        : 0;
    final int missionNumber = _hasProfile
        ? NumerologyHelper.getMissionNumber(profile!.birthDate, profile!.name)
        : 0;
    final int soulUrgeNumber = _hasProfile
        ? NumerologyHelper.getSoulUrgeNumber(profile!.name)
        : 0;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              LocaleKey.readingTitle.tr,
              style: AppStyles.numberSmall(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ).copyWith(height: 1.3),
            ),
            8.height,
            Text(
              LocaleKey.readingSubtitle.tr,
              style: AppStyles.bodyMedium(color: AppColors.textMuted),
            ),
            24.height,
            _ProfileSummaryCard(
              profile: profile,
              lifePathNumber: lifePathNumber,
              missionNumber: missionNumber,
              soulUrgeNumber: soulUrgeNumber,
              onLockedTap: onLockedTap,
            ),
            24.height,
            for (final _ReadingSection section in sections) ...<Widget>[
              _FeatureCard(
                section: section,
                hasProfile: _hasProfile,
                onLockedTap: onLockedTap,
              ),
              12.height,
            ],
            74.height,
          ],
        ),
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.profile,
    required this.lifePathNumber,
    required this.missionNumber,
    required this.soulUrgeNumber,
    required this.onLockedTap,
  });

  final UserProfile? profile;
  final int lifePathNumber;
  final int missionNumber;
  final int soulUrgeNumber;
  final VoidCallback onLockedTap;

  bool get _hasProfile => profile != null;

  @override
  Widget build(BuildContext context) {
    final String avatarText = _hasProfile
        ? profile!.name.characters.first.toUpperCase()
        : '?';
    final String name = _hasProfile ? profile!.name : 'Tên của bạn';
    final String birthDate = _hasProfile
        ? '${profile!.birthDate.day.toString().padLeft(2, '0')}/'
              '${profile!.birthDate.month.toString().padLeft(2, '0')}/'
              '${profile!.birthDate.year}'
        : 'DD/MM/YYYY';

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.mysticalCardGradient(),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.2)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.richGold.withValues(alpha: 0.2),
            blurRadius: 22,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: <Color>[
                        AppColors.richGold.withValues(alpha: 0.3),
                        AppColors.violetAccent.withValues(alpha: 0.3),
                      ],
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.richGold.withValues(alpha: 0.22),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: Center(
                      child: Text(avatarText, style: AppStyles.numberMedium()),
                    ),
                  ),
                ),
                14.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        name,
                        style: AppStyles.h3(
                          fontWeight: FontWeight.w600,
                        ).copyWith(fontSize: 18, height: 1.4),
                      ),
                      2.height,
                      Text(
                        birthDate,
                        style: AppStyles.bodyMedium(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            12.height,
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: <Widget>[
                    _NumberStat(
                      title: 'Số chủ đạo',
                      value: _hasProfile ? '$lifePathNumber' : '•',
                    ),
                    _NumberStat(
                      title: 'Sứ mệnh',
                      value: _hasProfile ? '$missionNumber' : '•',
                    ),
                    _NumberStat(
                      title: 'Linh hồn',
                      value: _hasProfile ? '$soulUrgeNumber' : '•',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberStat extends StatelessWidget {
  const _NumberStat({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(value, style: AppStyles.numberMedium()),
          4.height,
          Text(
            title,
            style: AppStyles.bodySmall(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.section,
    required this.hasProfile,
    required this.onLockedTap,
  });

  final _ReadingSection section;
  final bool hasProfile;
  final VoidCallback onLockedTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 90),
      child: Stack(
        children: <Widget>[
          Opacity(
            opacity: hasProfile ? 1 : 0.5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
              ),
              child: Material(
                color: AppColors.transparent,
                child: InkWell(
                  onTap: hasProfile ? section.onTap : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
                    child: Row(
                      children: <Widget>[
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: section.gradient),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(
                              section.icon,
                              size: 24,
                              color: AppColors.richGold,
                            ),
                          ),
                        ),
                        16.width,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                section.title,
                                style: AppStyles.h4(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              4.height,
                              Text(
                                section.description,
                                style: AppStyles.bodySmall(
                                  color: AppColors.textMuted,
                                ).copyWith(height: 1.35),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (!hasProfile)
            Positioned.fill(
              child: Material(
                color: AppColors.transparent,
                child: InkWell(
                  onTap: onLockedTap,
                  borderRadius: BorderRadius.circular(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.richGold.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.richGold.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.lock_rounded,
                                  color: AppColors.richGold,
                                  size: 20,
                                ),
                              ),
                              12.width,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      section.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppStyles.h3(
                                        color: AppColors.richGold,
                                        fontWeight: FontWeight.w600,
                                      ).copyWith(fontSize: 14, height: 1.4),
                                    ),
                                    2.height,
                                    Text(
                                      section.lockedDescription,
                                      style: AppStyles.bodySmall(
                                        color: AppColors.textMuted,
                                      ).copyWith(height: 1.35),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    2.height,
                                    Text(
                                      'Nhấn để mở khóa',
                                      style: AppStyles.bodySmall(
                                        color: AppColors.richGold.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReadingSection {
  const _ReadingSection({
    required this.icon,
    required this.title,
    required this.description,
    required this.lockedDescription,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String lockedDescription;
  final List<Color> gradient;
  final VoidCallback onTap;
}
