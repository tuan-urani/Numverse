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
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.navigationGradient(),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.richGold.withValues(alpha: 0.22),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 18,
                right: 18,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          AppColors.transparent,
                          AppColors.richGold.withValues(alpha: 0.48),
                          AppColors.transparent,
                        ],
                      ),
                    ),
                    child: const SizedBox(height: 1),
                  ),
                ),
              ),
              SafeArea(
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
                                        final List<Shadow> iconShadows =
                                            value > 0
                                            ? <Shadow>[
                                                Shadow(
                                                  color: AppColors.richGold
                                                      .withValues(
                                                        alpha: 0.62 * value,
                                                      ),
                                                  blurRadius: 8 * value,
                                                ),
                                              ]
                                            : const <Shadow>[];

                                        return Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            SizedBox(
                                              width: 30,
                                              height: 30,
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: <Widget>[
                                                  if (value > 0)
                                                    Opacity(
                                                      opacity: value,
                                                      child: DecoratedBox(
                                                        decoration: BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          gradient:
                                                              AppColors.cosmicAuraGradient(),
                                                        ),
                                                        child: const SizedBox(
                                                          width: 30,
                                                          height: 30,
                                                        ),
                                                      ),
                                                    ),
                                                  IconTheme(
                                                    data: IconThemeData(
                                                      size: AppDimensions
                                                          .iconMedium,
                                                      color: foregroundColor,
                                                      shadows: iconShadows,
                                                    ),
                                                    child: Icon(currentIcon),
                                                  ),
                                                ],
                                              ),
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
                                            AnimatedOpacity(
                                              duration: const Duration(
                                                milliseconds: 220,
                                              ),
                                              opacity: value,
                                              child: Container(
                                                width: 12,
                                                height: 2,
                                                margin: const EdgeInsets.only(
                                                  top: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                  gradient:
                                                      AppColors.primaryGradient(),
                                                ),
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
            ],
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
