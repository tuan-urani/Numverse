import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/angel_numbers/interactor/angel_numbers_state.dart';
import 'package:test/src/ui/widgets/app_mystical_card.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class AngelNumbersContent extends StatefulWidget {
  const AngelNumbersContent({
    required this.state,
    required this.onSearchChanged,
    required this.onSearchTap,
    required this.onQuickSearchTap,
    super.key,
  });

  final AngelNumbersState state;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchTap;
  final ValueChanged<String> onQuickSearchTap;

  @override
  State<AngelNumbersContent> createState() => _AngelNumbersContentState();
}

class _AngelNumbersContentState extends State<AngelNumbersContent> {
  late final TextEditingController _searchController;
  final GlobalKey _actionPanelKey = GlobalKey();
  final GlobalKey _detailSectionKey = GlobalKey();
  double? _measuredActionHeaderExtent;
  bool _isIntroExpanded = false;

  static const double _actionHeaderVerticalPadding = 16;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.state.searchText);
    _queueActionHeaderMeasure();
  }

  @override
  void didUpdateWidget(covariant AngelNumbersContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_searchController.text != widget.state.searchText) {
      _searchController.value = TextEditingValue(
        text: widget.state.searchText,
        selection: TextSelection.collapsed(
          offset: widget.state.searchText.length,
        ),
      );
    }

    if (oldWidget.state.popularNumbers.length !=
        widget.state.popularNumbers.length) {
      _queueActionHeaderMeasure();
    }
    if (oldWidget.state.showInputError != widget.state.showInputError) {
      _queueActionHeaderMeasure();
    }

    final bool hadResult = oldWidget.state.hasResult;
    final bool hasResult = widget.state.hasResult;
    final bool changedNumber =
        oldWidget.state.displayNumber != widget.state.displayNumber;
    if (hasResult && (!hadResult || changedNumber)) {
      _queueDetailAutoScroll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double formulaExtent = _actionHeaderExtent(
          context,
          constraints.maxWidth,
        );
        final double fallbackExtent = formulaExtent + 8;
        final double actionHeaderExtent =
            _measuredActionHeaderExtent ?? fallbackExtent;

        return CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: Column(
                  children: <Widget>[
                    _IntroCard(
                      isExpanded: _isIntroExpanded,
                      onToggle: _toggleIntroExpanded,
                    ),
                    12.height,
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _ActionHeaderDelegate(
                extent: actionHeaderExtent,
                child: KeyedSubtree(
                  key: _actionPanelKey,
                  child: _ActionPanel(
                    controller: _searchController,
                    onChanged: widget.onSearchChanged,
                    onSearchTap: widget.onSearchTap,
                    numbers: widget.state.popularNumbers,
                    onQuickSearchTap: widget.onQuickSearchTap,
                    showInputError: widget.state.showInputError,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  key: _detailSectionKey,
                  children: <Widget>[
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            final Animation<Offset> slide = Tween<Offset>(
                              begin: const Offset(0, 0.08),
                              end: Offset.zero,
                            ).animate(animation);
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: slide,
                                child: child,
                              ),
                            );
                          },
                      child: widget.state.hasResult
                          ? _ResultSection(
                              key: ValueKey<String>(
                                'result-${widget.state.displayNumber}',
                              ),
                              result: widget.state.result!,
                              displayNumber: widget.state.displayNumber,
                            )
                          : const _TipsCard(key: ValueKey<String>('tips')),
                    ),
                    12.height,
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  double _actionHeaderExtent(BuildContext context, double viewportWidth) {
    const double sliverHorizontalPadding = 16 * 2;
    const double sliverVerticalPadding = 8 * 2;
    const double cardVerticalPadding = 16 * 2;

    final double contentWidth = (viewportWidth - sliverHorizontalPadding).clamp(
      0,
      double.infinity,
    );

    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final double titleHeight = scaler.scale(16 * 1.3);
    final double searchCardHeight = cardVerticalPadding + titleHeight + 10 + 46;

    const double chipSpacing = 8;
    const double chipHeight = 34;
    const double chipWidthEstimate = 62;
    final int popularCount = widget.state.popularNumbers.length;
    final int maxChipsPerRow = popularCount > 0 ? popularCount : 1;
    final int rawPerRow =
        ((contentWidth + chipSpacing) / (chipWidthEstimate + chipSpacing))
            .floor();
    final int chipsPerRow = rawPerRow < 1
        ? 1
        : (rawPerRow > maxChipsPerRow ? maxChipsPerRow : rawPerRow);
    final int rows = popularCount == 0
        ? 1
        : (popularCount / chipsPerRow).ceil();
    final double chipsHeight = popularCount == 0
        ? 0
        : (rows * chipHeight) + ((rows - 1) * chipSpacing);
    final double popularCardHeight =
        cardVerticalPadding + titleHeight + 10 + chipsHeight;

    const double safetyBuffer = 10;
    return searchCardHeight +
        12 +
        popularCardHeight +
        sliverVerticalPadding +
        safetyBuffer;
  }

  void _toggleIntroExpanded() {
    setState(() {
      _isIntroExpanded = !_isIntroExpanded;
    });
  }

  void _queueActionHeaderMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final BuildContext? context = _actionPanelKey.currentContext;
      if (context == null || !context.mounted) {
        return;
      }

      final Size? size = context.size;
      if (size == null || !size.height.isFinite || size.height <= 0) {
        return;
      }

      final double measuredExtent = size.height + _actionHeaderVerticalPadding;
      final double previous = _measuredActionHeaderExtent ?? 0;
      if ((previous - measuredExtent).abs() < 0.5) {
        return;
      }

      setState(() {
        _measuredActionHeaderExtent = measuredExtent;
      });
    });
  }

  void _queueDetailAutoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) {
          return;
        }
        final BuildContext? detailContext = _detailSectionKey.currentContext;
        if (detailContext == null || !detailContext.mounted) {
          return;
        }
        Scrollable.ensureVisible(
          detailContext,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          alignment: 0.02,
        );
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _ActionHeaderDelegate extends SliverPersistentHeaderDelegate {
  _ActionHeaderDelegate({required this.child, required this.extent});

  final Widget child;
  final double extent;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AppColors.background,
            AppColors.background,
            AppColors.background.withValues(alpha: 0.2),
          ],
          stops: const <double>[0, 0.86, 1],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ActionHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.extent != extent;
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.controller,
    required this.onChanged,
    required this.onSearchTap,
    required this.numbers,
    required this.onQuickSearchTap,
    required this.showInputError,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSearchTap;
  final List<String> numbers;
  final ValueChanged<String> onQuickSearchTap;
  final bool showInputError;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _SearchCard(
              controller: controller,
              onChanged: onChanged,
              onSearchTap: onSearchTap,
              showInputError: showInputError,
            ),
            12.height,
            _PopularNumbersCard(
              numbers: numbers,
              onQuickSearchTap: onQuickSearchTap,
            ),
          ],
        ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.isExpanded, required this.onToggle});

  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return AppMysticalCard(
      borderColor: AppColors.richGold.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppColors.richGold,
                ),
                8.width,
                Expanded(
                  child: Text(
                    LocaleKey.angelNumbersIntroTitle.tr,
                    style: AppStyles.h3(
                      fontWeight: FontWeight.w700,
                    ).copyWith(fontSize: 18, height: 1.35),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 24,
                    color: AppColors.richGold,
                  ),
                ),
              ],
            ),
          ),
          ClipRect(
            child: AnimatedAlign(
              alignment: Alignment.topCenter,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              heightFactor: isExpanded ? 1 : 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  10.height,
                  Text(
                    LocaleKey.angelNumbersIntroBody.tr,
                    style: AppStyles.bodyMedium(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  const _SearchCard({
    required this.controller,
    required this.onChanged,
    required this.onSearchTap,
    required this.showInputError,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSearchTap;
  final bool showInputError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          LocaleKey.angelNumbersInputTitle.tr,
          style: AppStyles.h3(
            fontWeight: FontWeight.w600,
          ).copyWith(fontSize: 16, height: 1.3),
        ),
        10.height,
        Row(
          children: <Widget>[
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: showInputError
                        ? AppColors.energyRed.withValues(alpha: 0.9)
                        : AppColors.border.withValues(alpha: 0.7),
                  ),
                ),
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.search,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  style: AppStyles.bodyMedium(),
                  onChanged: onChanged,
                  onSubmitted: (_) => onSearchTap(),
                  decoration: InputDecoration(
                    hintText: LocaleKey.angelNumbersSearchHint.tr,
                    hintStyle: AppStyles.bodySmall(color: AppColors.textMuted),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ),
            8.width,
            InkWell(
              onTap: onSearchTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.richGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.richGold.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.search,
                  size: 18,
                  color: AppColors.richGold,
                ),
              ),
            ),
          ],
        ),
        8.height,
        Text(
          showInputError
              ? LocaleKey.angelNumbersInputError.tr
              : LocaleKey.angelNumbersInputRule.tr,
          style: AppStyles.caption(
            color: showInputError ? AppColors.energyRed : AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PopularNumbersCard extends StatelessWidget {
  const _PopularNumbersCard({
    required this.numbers,
    required this.onQuickSearchTap,
  });

  final List<String> numbers;
  final ValueChanged<String> onQuickSearchTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          LocaleKey.angelNumbersPopularTitle.tr,
          style: AppStyles.h3(
            fontWeight: FontWeight.w600,
          ).copyWith(fontSize: 16, height: 1.3),
        ),
        10.height,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: numbers.map((String number) {
            return InkWell(
              onTap: () => onQuickSearchTap(number),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.richGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.richGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  number,
                  style: AppStyles.numberSmall().copyWith(fontSize: 14),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({
    required this.result,
    required this.displayNumber,
    super.key,
  });

  final AngelNumberMeaning result;
  final String displayNumber;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        AppMysticalCard(
          borderColor: AppColors.richGold.withValues(alpha: 0.4),
          child: Stack(
            children: <Widget>[
              Positioned(
                top: -42,
                right: -30,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.richGold.withValues(alpha: 0.16),
                  ),
                ),
              ),
              Column(
                children: <Widget>[
                  _NumberOrb(number: displayNumber),
                  12.height,
                  Text(
                    result.title,
                    textAlign: TextAlign.center,
                    style: AppStyles.titleLarge(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (result.coreMeanings.isNotEmpty) ...<Widget>[
          12.height,
          _SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.psychology_alt_outlined,
                      size: 20,
                      color: AppColors.richGold,
                    ),
                    8.width,
                    Text(
                      LocaleKey.angelNumbersCoreMeaningsTitle.tr,
                      style: AppStyles.h3(
                        fontWeight: FontWeight.w600,
                      ).copyWith(fontSize: 18, height: 1.35),
                    ),
                  ],
                ),
                10.height,
                _BulletTextList(items: result.coreMeanings),
              ],
            ),
          ),
        ],
        if (result.universeMessages.isNotEmpty) ...<Widget>[
          12.height,
          _SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.public,
                      size: 20,
                      color: AppColors.richGold,
                    ),
                    8.width,
                    Text(
                      LocaleKey.angelNumbersUniverseMessagesTitle.tr,
                      style: AppStyles.h3(
                        fontWeight: FontWeight.w600,
                      ).copyWith(fontSize: 18, height: 1.35),
                    ),
                  ],
                ),
                10.height,
                _BulletTextList(items: result.universeMessages),
              ],
            ),
          ),
        ],
        12.height,
        _SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.favorite_border,
                    size: 20,
                    color: AppColors.richGold,
                  ),
                  8.width,
                  Text(
                    LocaleKey.angelNumbersGuidanceTitle.tr,
                    style: AppStyles.h3(
                      fontWeight: FontWeight.w600,
                    ).copyWith(fontSize: 18, height: 1.35),
                  ),
                ],
              ),
              10.height,
              _BulletTextList(items: result.guidance),
            ],
          ),
        ),
      ],
    );
  }
}

class _BulletTextList extends StatelessWidget {
  const _BulletTextList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map((String item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.circle,
                      size: 8,
                      color: AppColors.richGold,
                    ),
                  ),
                  10.width,
                  Expanded(
                    child: Text(
                      item,
                      style: AppStyles.bodyMedium(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _NumberOrb extends StatefulWidget {
  const _NumberOrb({required this.number});

  final String number;

  @override
  State<_NumberOrb> createState() => _NumberOrbState();
}

class _NumberOrbState extends State<_NumberOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    final int digits = widget.number.length;
    final double fontSize = switch (digits) {
      >= 5 => 28,
      4 => 32,
      _ => 38,
    };

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double ringScale = 1 + (_controller.value * 0.16);
        final double ringOpacity = 0.22 * (1 - _controller.value);
        final double iconScale = 0.98 + (_controller.value * 0.07);

        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Transform.scale(
              scale: ringScale,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.richGold.withValues(alpha: ringOpacity),
                ),
              ),
            ),
            Transform.scale(
              scale: iconScale,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      AppColors.richGold.withValues(alpha: 0.3),
                      AppColors.violetAccent.withValues(alpha: 0.2),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.richGold.withValues(alpha: 0.5),
                    width: 4,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.richGold.withValues(alpha: 0.26),
                      blurRadius: 18,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.number,
                  style: AppStyles.numberLarge().copyWith(fontSize: fontSize),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> tips = <String>[
      LocaleKey.angelNumbersTipOne.tr,
      LocaleKey.angelNumbersTipTwo.tr,
      LocaleKey.angelNumbersTipThree.tr,
    ];

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            LocaleKey.angelNumbersTipsTitle.tr,
            style: AppStyles.h3(
              fontWeight: FontWeight.w600,
            ).copyWith(fontSize: 16, height: 1.3),
          ),
          10.height,
          for (final String tip in tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.circle,
                      size: 8,
                      color: AppColors.richGold,
                    ),
                  ),
                  10.width,
                  Expanded(
                    child: Text(
                      tip,
                      style: AppStyles.bodyMedium(
                        color: AppColors.textSecondary,
                      ),
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

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}
