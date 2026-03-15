import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/core/model/numerology_content_models.dart';
import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/number_library/interactor/number_library_state.dart';
import 'package:test/src/ui/widgets/app_mystical_card.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class NumberLibraryContent extends StatefulWidget {
  const NumberLibraryContent({
    required this.state,
    required this.onToggleBasicNumbers,
    required this.onToggleMasterNumbers,
    required this.onNumberTap,
    super.key,
  });

  final NumberLibraryState state;
  final VoidCallback onToggleBasicNumbers;
  final VoidCallback onToggleMasterNumbers;
  final ValueChanged<int> onNumberTap;

  @override
  State<NumberLibraryContent> createState() => _NumberLibraryContentState();
}

class _NumberLibraryContentState extends State<NumberLibraryContent> {
  final GlobalKey _detailsKey = GlobalKey();
  final GlobalKey _selectionCardKey = GlobalKey();
  double? _measuredSelectionHeaderExtent;

  static const double _selectionHeaderVerticalPadding = 16;

  @override
  void initState() {
    super.initState();
    _queueSelectionHeaderMeasure();
  }

  @override
  void didUpdateWidget(covariant NumberLibraryContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final int? oldSelected = oldWidget.state.selectedNumber;
    final int? newSelected = widget.state.selectedNumber;
    if (oldSelected == newSelected || newSelected == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) {
          return;
        }
        final BuildContext? detailContext = _detailsKey.currentContext;
        if (detailContext == null) {
          return;
        }
        if (!detailContext.mounted) {
          return;
        }
        Scrollable.ensureVisible(
          detailContext,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          alignment: 0.06,
        );
      });
    });

    _queueSelectionHeaderMeasure();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double formulaExtent = _selectionHeaderExtent(
          context,
          constraints.maxWidth,
        );
        // Keep an initial safe fallback, then converge to measured height.
        final double fallbackExtent = formulaExtent + 60;
        final double selectionHeaderExtent =
            _measuredSelectionHeaderExtent ?? fallbackExtent;

        return CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(
                  children: <Widget>[
                    const _IntroCard(),
                    12.height,
                    _ExpandableInfoCard(
                      icon: Icons.info_outline,
                      title: LocaleKey.numberLibraryBasicWhatTitle.tr,
                      isExpanded: widget.state.isBasicNumbersExpanded,
                      onTap: widget.onToggleBasicNumbers,
                      description: LocaleKey.numberLibraryBasicDesc.tr,
                      bullets: <String>[
                        LocaleKey.numberLibraryBasicPointOne.tr,
                        LocaleKey.numberLibraryBasicPointTwo.tr,
                        LocaleKey.numberLibraryBasicPointThree.tr,
                        LocaleKey.numberLibraryBasicPointFour.tr,
                      ],
                      isMasterCard: false,
                    ),
                    12.height,
                    _ExpandableInfoCard(
                      icon: Icons.auto_awesome_rounded,
                      title: LocaleKey.numberLibraryMasterWhatTitle.tr,
                      isExpanded: widget.state.isMasterNumbersExpanded,
                      onTap: widget.onToggleMasterNumbers,
                      description: LocaleKey.numberLibraryMasterDesc.tr,
                      bullets: <String>[
                        LocaleKey.numberLibraryMasterPointOne.tr,
                        LocaleKey.numberLibraryMasterPointTwo.tr,
                        LocaleKey.numberLibraryMasterPointThree.tr,
                        LocaleKey.numberLibraryMasterPointFour.tr,
                        LocaleKey.numberLibraryMasterPointFive.tr,
                      ],
                      isMasterCard: true,
                    ),
                    10.height,
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SelectionHeaderDelegate(
                extent: selectionHeaderExtent,
                child: KeyedSubtree(
                  key: _selectionCardKey,
                  child: _SelectionCard(
                    state: widget.state,
                    onNumberTap: widget.onNumberTap,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Container(
                  key: _detailsKey,
                  child: AnimatedSwitcher(
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
                    child: widget.state.hasSelection
                        ? _SelectedNumberSection(
                            key: ValueKey<int>(widget.state.selectedNumber!),
                            selectedNumber: widget.state.selectedNumber!,
                            meaning: widget.state.selectedMeaning!,
                          )
                        : _EmptyHint(key: const ValueKey<String>('empty')),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  double _selectionHeaderExtent(BuildContext context, double viewportWidth) {
    const double sliverHorizontalPadding = 16 * 2;
    const double sliverVerticalPadding = 8 * 2;
    const double cardInnerPadding = 14 * 2;

    const int basicCrossAxisCount = 9;
    const double basicSpacing = 6;
    const int masterCrossAxisCount = 3;
    const double masterSpacing = 8;
    const double masterAspectRatio = 1.15;

    final double cardWidth = (viewportWidth - sliverHorizontalPadding).clamp(
      0,
      double.infinity,
    );
    final double gridWidth = (cardWidth - cardInnerPadding).clamp(
      0,
      double.infinity,
    );

    final int basicRows =
        (widget.state.basicNumbers.length / basicCrossAxisCount).ceil();
    final int masterRows =
        (widget.state.masterNumbers.length / masterCrossAxisCount).ceil();

    final double basicTileWidth =
        (gridWidth - ((basicCrossAxisCount - 1) * basicSpacing)) /
        basicCrossAxisCount;
    final double masterTileWidth =
        (gridWidth - ((masterCrossAxisCount - 1) * masterSpacing)) /
        masterCrossAxisCount;
    final double masterTileHeight = masterTileWidth / masterAspectRatio;

    final double basicGridHeight = basicRows == 0
        ? 0
        : (basicRows * basicTileWidth) + ((basicRows - 1) * basicSpacing);
    final double masterGridHeight = masterRows == 0
        ? 0
        : (masterRows * masterTileHeight) + ((masterRows - 1) * masterSpacing);

    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final double sectionTitleHeight = scaler.scale(14 * 1.3);
    final double tagHeight = scaler.scale(11 * 1.35);
    final double masterHeaderHeight = sectionTitleHeight > tagHeight
        ? sectionTitleHeight
        : tagHeight;

    const double fixedVerticalInsideCard =
        14 + // top padding
        8 + // gap title -> basic grid
        10 + // gap basic grid -> divider
        1 + // divider
        10 + // gap divider -> master row
        8 + // gap master row -> master grid
        14; // bottom padding

    final double cardHeight =
        fixedVerticalInsideCard +
        sectionTitleHeight +
        basicGridHeight +
        masterHeaderHeight +
        masterGridHeight;

    const double safetyBuffer = 8;
    return (cardHeight + sliverVerticalPadding + safetyBuffer).clamp(
      236,
      double.infinity,
    );
  }

  void _queueSelectionHeaderMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final BuildContext? context = _selectionCardKey.currentContext;
      if (context == null || !context.mounted) {
        return;
      }

      final Size? size = context.size;
      if (size == null || !size.height.isFinite || size.height <= 0) {
        return;
      }

      final double measuredExtent =
          size.height + _selectionHeaderVerticalPadding;
      final double previous = _measuredSelectionHeaderExtent ?? 0;
      if ((previous - measuredExtent).abs() < 0.5) {
        return;
      }

      setState(() {
        _measuredSelectionHeaderExtent = measuredExtent;
      });
    });
  }
}

class _SelectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SelectionHeaderDelegate({required this.child, required this.extent});

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
  bool shouldRebuild(covariant _SelectionHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.extent != extent;
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return AppMysticalCard(
      borderColor: AppColors.richGold.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.menu_book_rounded,
                size: 16,
                color: AppColors.richGold,
              ),
              8.width,
              Text(
                LocaleKey.numberLibraryIntroTitle.tr,
                style: AppStyles.h3(
                  fontWeight: FontWeight.w700,
                ).copyWith(fontSize: 16, height: 1.3),
              ),
            ],
          ),
          6.height,
          Text(
            LocaleKey.numberLibraryIntroBody.tr,
            style: AppStyles.caption(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ).copyWith(fontSize: 12, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _ExpandableInfoCard extends StatelessWidget {
  const _ExpandableInfoCard({
    required this.icon,
    required this.title,
    required this.isExpanded,
    required this.onTap,
    required this.description,
    required this.bullets,
    required this.isMasterCard,
  });

  final IconData icon;
  final String title;
  final bool isExpanded;
  final VoidCallback onTap;
  final String description;
  final List<String> bullets;
  final bool isMasterCard;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isMasterCard
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  AppColors.richGold.withValues(alpha: 0.15),
                  AppColors.richGold.withValues(alpha: 0.08),
                  AppColors.violetAccent.withValues(alpha: 0.12),
                ],
              )
            : null,
        color: isMasterCard ? null : AppColors.card.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isMasterCard
              ? AppColors.richGold.withValues(alpha: 0.4)
              : AppColors.richGold.withValues(alpha: 0.2),
        ),
        boxShadow: isMasterCard
            ? <BoxShadow>[
                BoxShadow(
                  color: AppColors.richGold.withValues(alpha: 0.14),
                  blurRadius: 16,
                ),
              ]
            : null,
      ),
      child: Column(
        children: <Widget>[
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: <Widget>[
                  Icon(icon, size: 16, color: AppColors.richGold),
                  8.width,
                  Expanded(
                    child: Text(
                      title,
                      style: AppStyles.h3(
                        fontWeight: FontWeight.w600,
                      ).copyWith(fontSize: 14, height: 1.3),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppColors.richGold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          description,
                          style: AppStyles.caption(
                            color: AppColors.textSecondary,
                          ).copyWith(fontSize: 12, height: 1.35),
                        ),
                        8.height,
                        for (final String bullet in bullets)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(top: 1.5),
                                  child: Icon(
                                    Icons.circle,
                                    size: 6,
                                    color: isMasterCard
                                        ? AppColors.goldBright
                                        : AppColors.richGold,
                                  ),
                                ),
                                8.width,
                                Expanded(
                                  child: Text(
                                    bullet,
                                    style: AppStyles.caption(
                                      color: AppColors.textSecondary,
                                    ).copyWith(fontSize: 12, height: 1.35),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({required this.state, required this.onNumberTap});

  final NumberLibraryState state;
  final ValueChanged<int> onNumberTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              LocaleKey.numberLibraryBasicSectionTitle.tr,
              style: AppStyles.h3(
                fontWeight: FontWeight.w600,
              ).copyWith(fontSize: 14, height: 1.3),
            ),
            8.height,
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.basicNumbers.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 9,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1,
              ),
              itemBuilder: (BuildContext context, int index) {
                final int number = state.basicNumbers[index];
                return _BasicNumberTile(
                  number: number,
                  isSelected: state.selectedNumber == number,
                  onTap: () => onNumberTap(number),
                );
              },
            ),
            10.height,
            Container(
              height: 1,
              color: AppColors.border.withValues(alpha: 0.5),
            ),
            10.height,
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    LocaleKey.numberLibraryMasterSectionTitle.tr,
                    style: AppStyles.h3(
                      fontWeight: FontWeight.w600,
                    ).copyWith(fontSize: 14, height: 1.3),
                  ),
                ),
                Text(
                  LocaleKey.numberLibraryMasterTagHighEnergy.tr,
                  style: AppStyles.caption(color: AppColors.textMuted),
                ),
              ],
            ),
            8.height,
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              clipBehavior: Clip.hardEdge,
              itemCount: state.masterNumbers.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (BuildContext context, int index) {
                final int number = state.masterNumbers[index];
                return Padding(
                  padding: const EdgeInsets.all(2),
                  child: _MasterNumberTile(
                    number: number,
                    isSelected: state.selectedNumber == number,
                    onTap: () => onNumberTap(number),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BasicNumberTile extends StatelessWidget {
  const _BasicNumberTile({
    required this.number,
    required this.isSelected,
    required this.onTap,
  });

  final int number;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: isSelected ? 1.05 : 1,
      curve: Curves.easeOutCubic,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.richGold.withValues(alpha: isSelected ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.richGold.withValues(
                alpha: isSelected ? 0.5 : 0.3,
              ),
              width: isSelected ? 2 : 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: AppStyles.numberSmall().copyWith(
              fontSize: 18,
              color: isSelected ? AppColors.goldBright : AppColors.richGold,
            ),
          ),
        ),
      ),
    );
  }
}

class _MasterNumberTile extends StatelessWidget {
  const _MasterNumberTile({
    required this.number,
    required this.isSelected,
    required this.onTap,
  });

  final int number;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? <Color>[
                    AppColors.richGold.withValues(alpha: 0.3),
                    AppColors.violetAccent.withValues(alpha: 0.3),
                  ]
                : <Color>[
                    AppColors.richGold.withValues(alpha: 0.2),
                    AppColors.violetAccent.withValues(alpha: 0.2),
                  ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.richGold.withValues(alpha: isSelected ? 0.6 : 0.4),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppColors.richGold.withValues(alpha: 0.2),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '$number',
          style: AppStyles.numberMedium().copyWith(fontSize: 24),
        ),
      ),
    );
  }
}

class _SelectedNumberSection extends StatelessWidget {
  const _SelectedNumberSection({
    required this.selectedNumber,
    required this.meaning,
    super.key,
  });

  final int selectedNumber;
  final NumerologyNumberLibraryContent meaning;

  @override
  Widget build(BuildContext context) {
    final (Color colorA, Color colorB) = _numberGradient(selectedNumber);

    return Column(
      children: <Widget>[
        AppMysticalCard(
          borderColor: AppColors.richGold.withValues(alpha: 0.4),
          child: Stack(
            children: <Widget>[
              Positioned(
                top: -40,
                right: -24,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.richGold.withValues(alpha: 0.16),
                  ),
                ),
              ),
              Column(
                children: <Widget>[
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          colorA.withValues(alpha: 0.3),
                          colorB.withValues(alpha: 0.22),
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.richGold.withValues(alpha: 0.5),
                        width: 4,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppColors.richGold.withValues(alpha: 0.2),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$selectedNumber',
                      style: AppStyles.numberLarge().copyWith(fontSize: 44),
                    ),
                  ),
                  12.height,
                  Text(
                    LocaleKey.numberLibraryDetailTitle.trParams(
                      <String, String>{
                        'number': '$selectedNumber',
                        'title': meaning.title,
                      },
                    ),
                    textAlign: TextAlign.center,
                    style: AppStyles.h3(
                      fontWeight: FontWeight.w700,
                    ).copyWith(fontSize: 20),
                  ),
                  10.height,
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: meaning.keywords.map((String keyword) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.richGold.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
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
            ],
          ),
        ),
        12.height,
        _SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: AppColors.richGold,
                  ),
                  8.width,
                  Text(
                    LocaleKey.numberLibraryMeaningEnergyTitle.tr,
                    style: AppStyles.h3(
                      fontWeight: FontWeight.w600,
                    ).copyWith(fontSize: 16),
                  ),
                ],
              ),
              10.height,
              Text(
                meaning.description,
                style: AppStyles.bodyMedium(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        12.height,
        if (meaning.symbolism.isNotEmpty) ...<Widget>[
          _SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.category_outlined,
                      size: 16,
                      color: AppColors.richGold,
                    ),
                    8.width,
                    Text(
                      LocaleKey.numberLibrarySymbolismTitle.tr,
                      style: AppStyles.h3(
                        fontWeight: FontWeight.w600,
                      ).copyWith(fontSize: 16),
                    ),
                  ],
                ),
                10.height,
                Text(
                  meaning.symbolism,
                  style: AppStyles.bodyMedium(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          12.height,
        ],
        _SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                LocaleKey.numberLibraryWhenAppearTitle.trParams(
                  <String, String>{'number': '$selectedNumber'},
                ),
                style: AppStyles.h3(
                  fontWeight: FontWeight.w600,
                ).copyWith(fontSize: 16),
              ),
              10.height,
              _BulletText(text: LocaleKey.numberLibraryAppearOne.tr),
              _BulletText(text: LocaleKey.numberLibraryAppearTwo.tr),
              _BulletText(text: LocaleKey.numberLibraryAppearThree.tr),
              _BulletText(
                text: LocaleKey.numberLibraryAppearFour.trParams(
                  <String, String>{'number': '$selectedNumber'},
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  (Color, Color) _numberGradient(int number) {
    final Map<int, (Color, Color)> colors = <int, (Color, Color)>{
      1: (AppColors.energyRed, AppColors.energyOrange),
      2: (AppColors.energyOrange, AppColors.energyAmber),
      3: (AppColors.energyYellow, AppColors.energyAmber),
      4: (AppColors.energyGreen, AppColors.energyEmerald),
      5: (AppColors.energyBlue, AppColors.energyCyan),
      6: (AppColors.energyPink, AppColors.energyRose),
      7: (AppColors.energyPurple, AppColors.energyViolet),
      8: (AppColors.energyAmber, AppColors.energyOrange),
      9: (AppColors.energyIndigo, AppColors.energyPurple),
      11: (AppColors.energyViolet, AppColors.energyPurple),
      22: (AppColors.energyCyan, AppColors.energyTeal),
      33: (AppColors.energyRose, AppColors.energyPink),
    };
    return colors[number] ?? colors[1]!;
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.circle, size: 7, color: AppColors.richGold),
          ),
          8.width,
          Expanded(
            child: Text(
              text,
              style: AppStyles.bodyMedium(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 34),
      child: Text(
        LocaleKey.numberLibrarySelectHint.tr,
        textAlign: TextAlign.center,
        style: AppStyles.bodyMedium(color: AppColors.textMuted),
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
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}
