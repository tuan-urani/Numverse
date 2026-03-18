import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/core/model/user_profile.dart';
import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_state.dart';
import 'package:test/src/ui/widgets/app_profile_list.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_dimensions.dart';
import 'package:test/src/utils/app_pages.dart';
import 'package:test/src/utils/app_styles.dart';
import 'package:test/src/utils/tab_navigation_helper.dart';

class TodayHeader extends StatelessWidget {
  const TodayHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainSessionBloc, MainSessionState>(
      bloc: Get.find<MainSessionBloc>(),
      builder: (BuildContext context, MainSessionState state) {
        final String greeting = _greeting();
        final String firstName = _firstName(state.currentProfile?.name);
        final String profileDisplayName = _profileDisplayName(firstName);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: _GreetingHeadline(
                    greeting: greeting,
                    profileDisplayName: profileDisplayName,
                  ),
                ),
                10.width,
                _ProfileEntryAvatar(
                  currentProfile: state.currentProfile,
                  onTap: _openProfileHub,
                ),
              ],
            ),
            Text(
              LocaleKey.todaySubtitle.tr,
              style: AppStyles.bodyMedium(color: AppColors.textSecondary),
            ),
          ],
        );
      },
    );
  }

  void _openProfileHub() {
    TabNavigationHelper.navigateFromMain(AppPages.profile);
  }

  String _greeting() {
    final int hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return LocaleKey.todayGreetingMorning.tr;
    }
    if (hour >= 11 && hour < 13) {
      return LocaleKey.todayGreetingNoon.tr;
    }
    if (hour >= 13 && hour < 18) {
      return LocaleKey.todayGreetingAfternoon.tr;
    }
    if (hour >= 18 && hour < 22) {
      return LocaleKey.todayGreetingEvening.tr;
    }
    return LocaleKey.todayGreetingNight.tr;
  }

  String _firstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) {
      return '';
    }
    final List<String> parts = fullName
        .trim()
        .split(' ')
        .where((String part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '';
    }
    return parts.first;
  }

  String _profileDisplayName(String firstName) {
    if (firstName.isEmpty) {
      return '';
    }
    return firstName.trim();
  }
}

class _GreetingHeadline extends StatelessWidget {
  const _GreetingHeadline({
    required this.greeting,
    required this.profileDisplayName,
  });

  final String greeting;
  final String profileDisplayName;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width <= 390;
    final TextStyle greetingStyle = compact
        ? AppStyles.h4(fontWeight: FontWeight.w700)
        : AppStyles.h3(fontWeight: FontWeight.w700);
    final TextStyle nameStyle = greetingStyle.copyWith(
      color: AppColors.richGold,
      fontWeight: FontWeight.w700,
    );

    if (profileDisplayName.isEmpty) {
      return Text(
        '$greeting ✨',
        style: greetingStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Row(
      children: <Widget>[
        Text(
          '$greeting, ',
          style: greetingStyle,
          maxLines: 1,
          overflow: TextOverflow.clip,
          softWrap: false,
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(text: profileDisplayName, style: nameStyle),
                TextSpan(text: ' ✨', style: greetingStyle),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ProfileEntryAvatar extends StatelessWidget {
  const _ProfileEntryAvatar({
    required this.currentProfile,
    required this.onTap,
  });

  final UserProfile? currentProfile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final UserProfile? profile = currentProfile;

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: AppDimensions.touchTarget,
        height: AppDimensions.touchTarget,
        child: Align(
          alignment: Alignment.center,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: profile == null
                  ? null
                  : appProfileAvatarGradient(profile.id),
              color: profile == null
                  ? AppColors.card.withValues(alpha: 0.7)
                  : null,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.richGold.withValues(alpha: 0.45),
                width: 2,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.richGold.withValues(alpha: 0.2),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: profile == null
                ? const Icon(
                    Icons.person_rounded,
                    size: 20,
                    color: AppColors.richGold,
                  )
                : Text(
                    appProfileInitials(profile.name),
                    style: AppStyles.bodySmall(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
