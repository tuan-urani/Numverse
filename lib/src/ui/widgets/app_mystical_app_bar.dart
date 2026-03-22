import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_dimensions.dart';
import 'package:test/src/utils/app_styles.dart';

class AppMysticalAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppMysticalAppBar({
    required this.title,
    this.showBack = true,
    this.actions = const <Widget>[],
    super.key,
  });

  final String title;
  final bool showBack;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: AppColors.transparent,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.transparent,
          border: Border(bottom: BorderSide(color: AppColors.transparent)),
        ),
      ),
      titleSpacing: AppDimensions.pageHorizontal,
      title: Row(
        children: <Widget>[
          if (showBack) ...<Widget>[
            InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              child: Container(
                width: AppDimensions.touchTarget,
                height: AppDimensions.touchTarget,
                decoration: BoxDecoration(
                  color: AppColors.richGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: AppColors.richGold.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.chevron_left,
                  color: AppColors.richGold,
                  size: AppDimensions.iconLarge,
                ),
              ),
            ),
            12.width,
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyles.h4(fontWeight: FontWeight.w600),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class AppTopActionButton extends StatelessWidget {
  const AppTopActionButton({required this.icon, this.onTap, super.key});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        width: AppDimensions.touchTarget,
        height: AppDimensions.touchTarget,
        decoration: BoxDecoration(
          color: AppColors.richGold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.richGold.withValues(alpha: 0.28)),
        ),
        child: Icon(
          icon,
          color: AppColors.richGold,
          size: AppDimensions.iconMedium,
        ),
      ),
    );
  }
}

class AppAppBarTitle extends StatelessWidget {
  const AppAppBarTitle({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title.tr, style: AppStyles.h4(fontWeight: FontWeight.w600));
  }
}
