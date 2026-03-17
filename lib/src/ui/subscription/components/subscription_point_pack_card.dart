import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/widgets/app_mystical_card.dart';
import 'package:test/src/ui/widgets/app_primary_button.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_dimensions.dart';
import 'package:test/src/utils/app_styles.dart';

class SubscriptionPointPackData {
  const SubscriptionPointPackData({
    required this.id,
    required this.nameKey,
    required this.points,
    required this.priceKey,
    required this.bonusKey,
    required this.valueKey,
    required this.icon,
    this.isPopular = false,
  });

  final String id;
  final String nameKey;
  final int points;
  final String priceKey;
  final String bonusKey;
  final String valueKey;
  final IconData icon;
  final bool isPopular;
}

class SubscriptionPointPackCard extends StatelessWidget {
  const SubscriptionPointPackCard({
    required this.pack,
    required this.onBuy,
    super.key,
  });

  final SubscriptionPointPackData pack;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final Color accentColor = pack.isPopular
        ? AppColors.richGold
        : AppColors.goldSoft;

    return AppMysticalCard(
      padding: EdgeInsets.zero,
      borderColor: accentColor.withValues(alpha: pack.isPopular ? 0.45 : 0.24),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      accentColor.withValues(
                        alpha: pack.isPopular ? 0.18 : 0.12,
                      ),
                      AppColors.transparent,
                      accentColor.withValues(alpha: 0.05),
                    ],
                    stops: const <double>[0, 0.46, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(top: -36, right: -26, child: _GlowOrb(color: accentColor)),
          Positioned(
            bottom: -40,
            left: -20,
            child: _GlowOrb(color: accentColor.withValues(alpha: 0.72)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _PackIconBadge(icon: pack.icon, accentColor: accentColor),
                    10.width,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            pack.nameKey.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyles.bodyMedium(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (pack.isPopular) ...<Widget>[
                            5.height,
                            const _PopularTag(),
                          ],
                        ],
                      ),
                    ),
                    10.width,
                    _PriceTag(
                      price: pack.priceKey.tr,
                      accentColor: accentColor,
                    ),
                  ],
                ),
                12.height,
                Text(
                  LocaleKey.subscriptionPackPointsLabel.trParams(
                    <String, String>{'points': '${pack.points}'},
                  ),
                  style: AppStyles.numberSmall(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                10.height,
                _InfoLine(
                  icon: Icons.auto_awesome_rounded,
                  text: pack.bonusKey.tr,
                  textColor: AppColors.textSecondary,
                ),
                5.height,
                _InfoLine(
                  icon: Icons.savings_rounded,
                  text: pack.valueKey.tr,
                  textColor: AppColors.textMuted,
                ),
                12.height,
                AppPrimaryButton(
                  label: LocaleKey.subscriptionBuyButton.tr,
                  onPressed: onBuy,
                  leading: const Icon(
                    Icons.shopping_bag_rounded,
                    size: AppDimensions.iconSmall,
                    color: AppColors.midnight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PackIconBadge extends StatelessWidget {
  const _PackIconBadge({required this.icon, required this.accentColor});

  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: SizedBox(
        width: AppDimensions.touchTarget,
        height: AppDimensions.touchTarget,
        child: Icon(icon, size: AppDimensions.iconLarge, color: accentColor),
      ),
    );
  }
}

class _PopularTag extends StatelessWidget {
  const _PopularTag();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient(),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          LocaleKey.subscriptionPopularTag.tr,
          style: AppStyles.caption(
            color: AppColors.midnight,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PriceTag extends StatelessWidget {
  const _PriceTag({required this.price, required this.accentColor});

  final String price;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accentColor.withValues(alpha: 0.38)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          price,
          style: AppStyles.bodySmall(
            color: accentColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.text,
    required this.textColor,
  });

  final IconData icon;
  final String text;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 15, color: AppColors.richGold),
        6.width,
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppStyles.caption(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.02),
          ],
        ),
      ),
      child: const SizedBox(width: 90, height: 90),
    );
  }
}
