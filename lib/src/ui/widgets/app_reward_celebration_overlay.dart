import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class AppRewardCelebrationOverlay {
  const AppRewardCelebrationOverlay._();

  static OverlayEntry? _activeEntry;

  static void show(
    BuildContext context, {
    required int reward,
    required String title,
    String? subtitle,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    final int safeReward = reward.clamp(0, 9999);
    if (safeReward <= 0) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _activeEntry?.remove();
      final OverlayState overlayState = Overlay.of(context, rootOverlay: true);
      final OverlayEntry entry = OverlayEntry(
        builder: (BuildContext context) {
          return Positioned.fill(
            child: IgnorePointer(
              child: Material(
                color: AppColors.midnight.withValues(alpha: 0.74),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 230),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    decoration: BoxDecoration(
                      color: AppColors.midnightSoft.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.richGold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.emoji_events_rounded,
                          size: 36,
                          color: AppColors.richGold,
                        ),
                        8.height,
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: AppStyles.h5(
                            color: AppColors.richGold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        8.height,
                        Text(
                          '+$safeReward ${LocaleKey.todayRewardPointsSuffix.tr}',
                          style: AppStyles.h3(
                            color: AppColors.richGold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if ((subtitle ?? '').trim().isNotEmpty) ...<Widget>[
                          4.height,
                          Text(
                            subtitle!,
                            textAlign: TextAlign.center,
                            style: AppStyles.caption(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );

      overlayState.insert(entry);
      _activeEntry = entry;

      Future<void>.delayed(duration, () {
        if (_activeEntry == entry) {
          entry.remove();
          _activeEntry = null;
        }
      });
    });
  }
}
