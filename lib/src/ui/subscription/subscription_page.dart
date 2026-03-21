import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_state.dart';
import 'package:test/src/ui/subscription/components/subscription_balance_card.dart';
import 'package:test/src/ui/subscription/components/subscription_point_pack_card.dart';
import 'package:test/src/ui/widgets/app_mystical_app_bar.dart';
import 'package:test/src/ui/widgets/app_mystical_scaffold.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  late final MainSessionBloc? _sessionBloc;

  static const List<SubscriptionPointPackData> _pointPacks =
      <SubscriptionPointPackData>[
        SubscriptionPointPackData(
          id: 'smart',
          nameKey: LocaleKey.subscriptionPackSmartName,
          points: 160,
          priceKey: LocaleKey.subscriptionPackSmartPrice,
          bonusKey: LocaleKey.subscriptionPackSmartBonus,
          valueKey: LocaleKey.subscriptionPackSmartValue,
          icon: Icons.local_fire_department_rounded,
          isPopular: true,
        ),
        SubscriptionPointPackData(
          id: 'legend',
          nameKey: LocaleKey.subscriptionPackLegendName,
          points: 360,
          priceKey: LocaleKey.subscriptionPackLegendPrice,
          bonusKey: LocaleKey.subscriptionPackLegendBonus,
          valueKey: LocaleKey.subscriptionPackLegendValue,
          icon: Icons.diamond_rounded,
        ),
      ];

  @override
  void initState() {
    super.initState();
    _sessionBloc = Get.isRegistered<MainSessionBloc>()
        ? Get.find<MainSessionBloc>()
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return AppMysticalScaffold(
      appBar: AppMysticalAppBar(title: LocaleKey.subscriptionTitle.tr),
      child: SafeArea(
        top: false,
        child: _sessionBloc == null
            ? _SubscriptionContent(
                currentPoints: 0,
                packs: _pointPacks,
                onBuyPack: _onBuyPack,
              )
            : BlocBuilder<MainSessionBloc, MainSessionState>(
                bloc: _sessionBloc,
                builder: (BuildContext context, MainSessionState state) {
                  return _SubscriptionContent(
                    currentPoints: state.soulPoints,
                    packs: _pointPacks,
                    onBuyPack: _onBuyPack,
                  );
                },
              ),
      ),
    );
  }

  Future<void> _onBuyPack(SubscriptionPointPackData pack) async {
    final MainSessionBloc? sessionBloc = _sessionBloc;
    if (sessionBloc == null) {
      return;
    }
    await sessionBloc.addSoulPoints(pack.points);
    if (!mounted) {
      return;
    }
    Get.snackbar(
      LocaleKey.commonSuccess.tr,
      LocaleKey.subscriptionPurchaseSuccess.trParams(<String, String>{
        'points': '${pack.points}',
      }),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.card.withValues(alpha: 0.95),
      colorText: AppColors.textPrimary,
      borderColor: AppColors.richGold.withValues(alpha: 0.35),
      borderWidth: 1,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 2),
    );
  }
}

class _SubscriptionContent extends StatelessWidget {
  const _SubscriptionContent({
    required this.currentPoints,
    required this.packs,
    required this.onBuyPack,
  });

  final int currentPoints;
  final List<SubscriptionPointPackData> packs;
  final ValueChanged<SubscriptionPointPackData> onBuyPack;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SubscriptionBalanceCard(currentPoints: currentPoints),
          16.height,
          Text(
            LocaleKey.subscriptionPacksTitle.tr,
            style: AppStyles.h5(fontWeight: FontWeight.w700),
          ),
          4.height,
          Text(
            LocaleKey.subscriptionTopupHint.tr,
            style: AppStyles.caption(color: AppColors.textMuted),
          ),
          14.height,
          for (int index = 0; index < packs.length; index++) ...<Widget>[
            SubscriptionPointPackCard(
              pack: packs[index],
              onBuy: () => onBuyPack(packs[index]),
            ),
            if (index != packs.length - 1) 10.height,
          ],
        ],
      ),
    );
  }
}
