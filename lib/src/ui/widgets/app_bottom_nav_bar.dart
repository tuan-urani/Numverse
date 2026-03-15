import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_dimensions.dart';
import 'package:test/src/utils/app_styles.dart';

class AppBottomNavItem {
  const AppBottomNavItem({
    required this.labelKey,
    required this.icon,
    required this.activeIcon,
  });

  final String labelKey;
  final IconData icon;
  final IconData activeIcon;
}

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final List<AppBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const double maxNavigationWidth = 512;
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    const double navigationHeight = 64;
    final double totalBarHeight = navigationHeight + bottomInset;

    return SizedBox(
      height: totalBarHeight,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.9),
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: maxNavigationWidth,
                  ),
                  child: SizedBox(
                    height: navigationHeight,
                    child: Row(
                      children: items.asMap().entries.map((
                        MapEntry<int, AppBottomNavItem> entry,
                      ) {
                        final bool isActive = entry.key == currentIndex;
                        final AppBottomNavItem item = entry.value;
                        final IconData currentIcon = isActive
                            ? item.activeIcon
                            : item.icon;

                        return Expanded(
                          child: InkWell(
                            onTap: () => onTap(entry.key),
                            splashColor: AppColors.transparent,
                            highlightColor: AppColors.transparent,
                            child: Center(
                              child: TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                tween: Tween<double>(
                                  begin: 0,
                                  end: isActive ? 1 : 0,
                                ),
                                builder:
                                    (
                                      BuildContext context,
                                      double value,
                                      Widget? child,
                                    ) {
                                      final Color foregroundColor =
                                          Color.lerp(
                                            AppColors.textMuted,
                                            AppColors.richGold,
                                            value,
                                          ) ??
                                          AppColors.textMuted;
                                      final List<Shadow> iconShadows = value > 0
                                          ? <Shadow>[
                                              Shadow(
                                                color: AppColors.richGold
                                                    .withValues(
                                                      alpha: 0.6 * value,
                                                    ),
                                                blurRadius: 8 * value,
                                              ),
                                            ]
                                          : const <Shadow>[];

                                      return Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          IconTheme(
                                            data: IconThemeData(
                                              size: AppDimensions.iconMedium,
                                              color: foregroundColor,
                                              shadows: iconShadows,
                                            ),
                                            child: Icon(currentIcon),
                                          ),
                                          4.height,
                                          Text(
                                            item.labelKey.tr,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                AppStyles.caption(
                                                  color: foregroundColor,
                                                  fontWeight: FontWeight.w500,
                                                ).copyWith(
                                                  fontSize: 10,
                                                  height: 1.2,
                                                ),
                                          ),
                                        ],
                                      );
                                    },
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<AppBottomNavItem> buildMainBottomNavItems() => const <AppBottomNavItem>[
  AppBottomNavItem(
    labelKey: LocaleKey.mainTabToday,
    icon: Icons.home_outlined,
    activeIcon: Icons.home_outlined,
  ),
  AppBottomNavItem(
    labelKey: LocaleKey.mainTabCompatibility,
    icon: Icons.favorite_border_rounded,
    activeIcon: Icons.favorite_border_rounded,
  ),
  AppBottomNavItem(
    labelKey: LocaleKey.mainTabNumAi,
    icon: Icons.auto_awesome_outlined,
    activeIcon: Icons.auto_awesome_outlined,
  ),
  AppBottomNavItem(
    labelKey: LocaleKey.mainTabProfile,
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_outline_rounded,
  ),
];
