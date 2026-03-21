import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:test/src/core/repository/interface/i_app_session_repository.dart';
import 'package:test/src/core/repository/interface/i_cloud_account_repository.dart';
import 'package:test/src/core/service/admob_rewarded_ad_service.dart';
import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/compatibility/components/compatibility_profile_input_dialog.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_state.dart';
import 'package:test/src/ui/numai_chat/interactor/numai_chat_bloc.dart';
import 'package:test/src/ui/numai_chat/interactor/numai_chat_state.dart';
import 'package:test/src/ui/numai_chat/components/numai_chat_auto_scroll_policy.dart';
import 'package:test/src/ui/numai_chat/components/numai_typewriter_text.dart';
import 'package:test/src/ui/profile/components/profile_soul_points_actions_dialog.dart';
import 'package:test/src/ui/widgets/ad_reward_claim_flow.dart';
import 'package:test/src/ui/widgets/app_state_view.dart';
import 'package:test/src/ui/widgets/custom_circular_progress.dart';
import 'package:test/src/utils/app_assets.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_pages.dart';
import 'package:test/src/utils/app_styles.dart';
import 'package:test/src/utils/tab_navigation_helper.dart';

class NumAiPage extends StatefulWidget {
  const NumAiPage({super.key});

  @override
  State<NumAiPage> createState() => _NumAiPageState();
}

class _NumAiPageState extends State<NumAiPage> {
  static const int _adRewardPointsPerWatch = 5;
  static const double _nearBottomThreshold = 120;
  static const double _bottomOffset = 42;

  late final MainSessionBloc _sessionBloc;
  late final AdMobRewardedAdService _adMobRewardedAdService;
  late final NumAiChatBloc _chatBloc;
  late final TextEditingController _controller;
  late final ScrollController _scrollController;
  late List<_NumAiDomain> _visibleDomainSuggestions;

  String? _activeDomainId;
  String? _lastHydratedContextKey;
  NumAiChatState? _lastChatStateForScroll;
  bool _scrollScheduled = false;
  NumAiChatAutoScrollMode _pendingScrollMode = NumAiChatAutoScrollMode.none;

  @override
  void initState() {
    super.initState();
    _sessionBloc = Get.find<MainSessionBloc>();
    _adMobRewardedAdService = Get.find<AdMobRewardedAdService>();
    _chatBloc = Get.isRegistered<NumAiChatBloc>()
        ? Get.find<NumAiChatBloc>()
        : Get.put<NumAiChatBloc>(
            NumAiChatBloc(
              cloudAccountRepository: Get.find<ICloudAccountRepository>(),
              appSessionRepository: Get.find<IAppSessionRepository>(),
            ),
          );
    _controller = TextEditingController();
    _scrollController = ScrollController();
    _visibleDomainSuggestions = _domains.take(3).toList();
    _lastChatStateForScroll = _chatBloc.state;

    if (_sessionBloc.state.viewState == AppViewStateStatus.loading) {
      _sessionBloc.initialize();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: BlocBuilder<MainSessionBloc, MainSessionState>(
        bloc: _sessionBloc,
        builder: (BuildContext context, MainSessionState sessionState) {
          return AppStateView(
            status: sessionState.viewState,
            onRetry: _sessionBloc.initialize,
            success: BlocListener<NumAiChatBloc, NumAiChatState>(
              bloc: _chatBloc,
              listenWhen: (NumAiChatState previous, NumAiChatState current) {
                return previous.messages.length != current.messages.length ||
                    previous.isLoading != current.isLoading;
              },
              listener: (BuildContext _, NumAiChatState current) {
                final NumAiChatState previous =
                    _lastChatStateForScroll ?? NumAiChatState.initial();
                _lastChatStateForScroll = current;
                _onChatStateChanged(previous, current);
              },
              child: BlocBuilder<NumAiChatBloc, NumAiChatState>(
                bloc: _chatBloc,
                builder: (BuildContext context, NumAiChatState chatState) {
                  _maybeHydrateHistory(sessionState);
                  final bool isChatBlank =
                      chatState.messages.isEmpty && !chatState.isLoading;
                  final _NumAiDomain? activeDomain = _domainById(
                    _activeDomainId,
                  );
                  final bool canAffordMessage =
                      sessionState.soulPoints >= NumAiChatBloc.messageCost;
                  final bool canSend =
                      _controller.text.trim().isNotEmpty &&
                      !chatState.isLoading &&
                      canAffordMessage;
                  final String emptyHint = activeDomain == null
                      ? LocaleKey.numaiChatSelectDomainHint.tr
                      : LocaleKey.numaiChatActiveDomainHint.trParams(
                          <String, String>{'domain': activeDomain.labelKey.tr},
                        );
                  final String inputHint =
                      activeDomain?.placeholderKey.tr ??
                      LocaleKey.numaiChatInputPlaceholder.tr;

                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          AppColors.background.withValues(alpha: 0.08),
                          AppColors.deepViolet.withValues(alpha: 0.16),
                          AppColors.violetAccent.withValues(alpha: 0.2),
                        ],
                      ),
                    ),
                    child: Column(
                      children: <Widget>[
                        _NumAiHeaderBar(
                          activeDomainLabel: activeDomain?.labelKey.tr,
                          soulPoints: sessionState.soulPoints,
                          onNewChatTap: _resetConversation,
                        ),
                        Expanded(
                          child: _NumAiMessagesPanel(
                            messages: chatState.messages,
                            isLoading: chatState.isLoading,
                            typingMessageId: chatState.typingMessageId,
                            emptyHint: emptyHint,
                            scrollController: _scrollController,
                            onAssistantTypingCompleted:
                                _chatBloc.completeTypingMessage,
                            onActionTap: _onProfileActionTap,
                            onSuggestionTap: (String suggestion) {
                              _sendMessage(messageText: suggestion);
                            },
                            showFollowupSuggestions: false,
                            followupDomains: _visibleDomainSuggestions,
                            onFollowupTap: (_NumAiDomain domain) {
                              _sendMessage(
                                messageText: domain.featuredPromptKey.tr,
                                domain: domain,
                              );
                            },
                          ),
                        ),
                        _NumAiComposer(
                          domains: _visibleDomainSuggestions,
                          activeDomainId: _activeDomainId,
                          canAffordMessage: canAffordMessage,
                          missingPoints:
                              (NumAiChatBloc.messageCost -
                                      sessionState.soulPoints)
                                  .clamp(0, NumAiChatBloc.messageCost),
                          canSend: canSend,
                          isLoading: chatState.isLoading,
                          controller: _controller,
                          inputHint: inputHint,
                          onChanged: (_) => setState(() {}),
                          onSendTap: () => _sendMessage(),
                          showSuggestions: isChatBlank,
                          onNoPointsTap: _showSoulPointsActionDialog,
                          onDomainTap: (_NumAiDomain domain) {
                            _sendMessage(
                              messageText: domain.featuredPromptKey.tr,
                              domain: domain,
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _maybeHydrateHistory(MainSessionState sessionState) {
    final String profileId = (sessionState.currentProfile?.id ?? '').trim();
    final String guestKey = (sessionState.cloudUserId ?? '').trim();
    final String contextKey = profileId.isNotEmpty
        ? 'profile:$profileId'
        : 'guest:${guestKey.isEmpty ? 'local' : guestKey}';
    if (_lastHydratedContextKey == contextKey) {
      return;
    }

    _lastHydratedContextKey = contextKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _chatBloc.loadCloudHistory(
        hasCloudSession: sessionState.hasCloudSession,
        isAnonymousUser: sessionState.isAnonymousUser,
        profileId: profileId.isEmpty ? null : profileId,
        cloudUserId: sessionState.cloudUserId,
        forceRefresh: true,
      );
    });
  }

  Future<void> _sendMessage({String? messageText, _NumAiDomain? domain}) async {
    final bool shouldClearInput = messageText == null;
    final String resolvedMessage = (messageText ?? _controller.text).trim();
    if (resolvedMessage.isEmpty) {
      return;
    }

    final _NumAiDomain? selectedDomain = domain ?? _domainById(_activeDomainId);
    if (domain != null && selectedDomain != null) {
      _rotateSuggestionsAfterSelection(selectedDomain.id);
    }

    if (_sessionBloc.state.soulPoints < NumAiChatBloc.messageCost) {
      await _showSoulPointsInsufficientModal();
      return;
    }

    if (selectedDomain != null) {
      setState(() {
        _activeDomainId = selectedDomain.id;
      });
    }

    if (shouldClearInput) {
      _controller.clear();
      setState(() {});
    }

    final bool hasProfile = _sessionBloc.state.currentProfile != null;

    final bool sent = await _chatBloc.sendMessage(
      rawMessage: resolvedMessage,
      hasProfile: hasProfile,
      hasCloudSession: _sessionBloc.state.hasCloudSession,
      isAnonymousUser: _sessionBloc.state.isAnonymousUser,
      profileId: _sessionBloc.state.currentProfile?.id,
      cloudUserId: _sessionBloc.state.cloudUserId,
      locale: null,
      deductSoulPoints: (int amount) => _sessionBloc.deductSoulPoints(
        amount,
        sourceType: 'numai_message',
        metadata: const <String, dynamic>{'screen': 'numai'},
      ),
      syncSoulPoints: _sessionBloc.syncSoulPointsFromCloud,
    );
    if (!mounted || !sent) {
      return;
    }

    setState(() {});
  }

  void _rotateSuggestionsAfterSelection(String selectedDomainId) {
    final List<_NumAiDomain> candidates = <_NumAiDomain>[];

    for (final _NumAiDomain domain in _domains) {
      if (domain.id != selectedDomainId) {
        candidates.add(domain);
      }
    }

    final List<_NumAiDomain> next = <_NumAiDomain>[];
    for (final _NumAiDomain domain in candidates) {
      if (_visibleDomainSuggestions.any((item) => item.id == domain.id)) {
        continue;
      }
      next.add(domain);
      if (next.length == 3) {
        break;
      }
    }

    for (final _NumAiDomain domain in candidates) {
      if (next.any((item) => item.id == domain.id)) {
        continue;
      }
      next.add(domain);
      if (next.length == 3) {
        break;
      }
    }

    setState(() {
      _visibleDomainSuggestions = next.take(3).toList();
    });
  }

  Future<void> _onProfileActionTap() async {
    await CompatibilityProfileInputDialog.show(
      context,
      onSubmit: (String name, DateTime birthDate) async {
        await _sessionBloc.addProfile(name: name, birthDate: birthDate);
      },
    );
    if (!mounted || _sessionBloc.state.currentProfile == null) {
      return;
    }
    final MainSessionState refreshedState = _sessionBloc.state;
    final String refreshedProfileId = (refreshedState.currentProfile?.id ?? '')
        .trim();
    if (refreshedProfileId.isEmpty) {
      return;
    }
    _lastHydratedContextKey = 'profile:$refreshedProfileId';
    _chatBloc.loadCloudHistory(
      hasCloudSession: refreshedState.hasCloudSession,
      isAnonymousUser: refreshedState.isAnonymousUser,
      profileId: refreshedProfileId,
      cloudUserId: refreshedState.cloudUserId,
      forceRefresh: true,
    );
  }

  Future<void> _showSoulPointsInsufficientModal() async {
    await _showSoulPointsActionDialog();
  }

  Future<void> _showSoulPointsActionDialog() async {
    await ProfileSoulPointsActionsDialog.show(
      context,
      sessionBloc: _sessionBloc,
      onWatchAdTap: () async {
        await AdRewardClaimFlow.watchAdThenClaim(
          sessionBloc: _sessionBloc,
          adMobRewardedAdService: _adMobRewardedAdService,
          amount: _adRewardPointsPerWatch,
          placementCode: 'numai_soul_points_dialog',
        );
      },
      onBuyPointsTap: _onBuyPointsTap,
    );
  }

  Future<void> _onBuyPointsTap() async {
    await TabNavigationHelper.pushCommonRoute(AppPages.subscription);
  }

  void _resetConversation() {
    _chatBloc.resetConversation(cloudUserId: _sessionBloc.state.cloudUserId);
    _controller.clear();
    setState(() {
      _activeDomainId = null;
      _visibleDomainSuggestions = _domains.take(3).toList();
    });
  }

  void _onChatStateChanged(NumAiChatState previous, NumAiChatState current) {
    final bool nearBottom = _isNearBottom();
    final NumAiChatAutoScrollSnapshot previousSnapshot =
        buildNumAiChatScrollSnapshot(
          messages: previous.messages,
          isLoading: previous.isLoading,
          isNearBottom: nearBottom,
          forceOnUserSend: true,
        );
    final NumAiChatAutoScrollSnapshot currentSnapshot =
        buildNumAiChatScrollSnapshot(
          messages: current.messages,
          isLoading: current.isLoading,
          isNearBottom: nearBottom,
          forceOnUserSend: true,
        );
    final NumAiChatAutoScrollMode mode = decideNumAiChatAutoScroll(
      previous: previousSnapshot,
      current: currentSnapshot,
    );
    _queueScroll(mode);
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) {
      return true;
    }
    final double distanceToBottom =
        _scrollController.position.maxScrollExtent - _scrollController.offset;
    return distanceToBottom <= _nearBottomThreshold;
  }

  void _queueScroll(NumAiChatAutoScrollMode mode) {
    if (mode == NumAiChatAutoScrollMode.none) {
      return;
    }
    _pendingScrollMode = mode;
    if (_scrollScheduled) {
      return;
    }
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      final NumAiChatAutoScrollMode pendingMode = _pendingScrollMode;
      _pendingScrollMode = NumAiChatAutoScrollMode.none;
      _applyScroll(pendingMode);
    });
  }

  void _applyScroll(NumAiChatAutoScrollMode mode) {
    if (!mounted || !_scrollController.hasClients) {
      return;
    }
    final double target =
        _scrollController.position.maxScrollExtent + _bottomOffset;
    if (mode == NumAiChatAutoScrollMode.jump) {
      _scrollController.jumpTo(target);
      return;
    }
    if (mode == NumAiChatAutoScrollMode.animate) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      return;
    }
  }

  _NumAiDomain? _domainById(String? id) {
    if (id == null) {
      return null;
    }
    for (final _NumAiDomain domain in _domains) {
      if (domain.id == id) {
        return domain;
      }
    }
    return null;
  }
}

class _NumAiHeaderBar extends StatelessWidget {
  const _NumAiHeaderBar({
    required this.activeDomainLabel,
    required this.soulPoints,
    required this.onNewChatTap,
  });

  final String? activeDomainLabel;
  final int soulPoints;
  final VoidCallback onNewChatTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 23,
                  color: AppColors.richGold,
                ),
                6.width,
                Text(
                  LocaleKey.numaiTitle.tr,
                  style: AppStyles.titleLarge(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (activeDomainLabel != null) ...<Widget>[
                  8.width,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.richGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.richGold.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      activeDomainLabel!,
                      style: AppStyles.caption(
                        color: AppColors.richGold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // TextButton(
          //   onPressed: onNewChatTap,
          //   style: TextButton.styleFrom(
          //     foregroundColor: AppColors.textMuted,
          //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          //     minimumSize: Size.zero,
          //     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          //   ),
          //   child: Text(LocaleKey.numaiChatNew.tr),
          // ),
          6.width,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.richGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.richGold.withValues(alpha: 0.3),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.richGold.withValues(alpha: 0.18),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                SvgPicture.asset(
                  AppAssets.iconCoinPng,
                  width: 14,
                  height: 14,
                  colorFilter: const ColorFilter.mode(
                    AppColors.richGold,
                    BlendMode.srcIn,
                  ),
                ),
                4.width,
                Text(
                  '$soulPoints SP',
                  style: AppStyles.numberSmall(
                    color: AppColors.richGold,
                    fontWeight: FontWeight.w700,
                  ).copyWith(fontSize: 12, height: 1.0, letterSpacing: 0.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NumAiMessagesPanel extends StatelessWidget {
  const _NumAiMessagesPanel({
    required this.messages,
    required this.isLoading,
    required this.typingMessageId,
    required this.emptyHint,
    required this.scrollController,
    required this.onAssistantTypingCompleted,
    required this.onActionTap,
    required this.onSuggestionTap,
    required this.showFollowupSuggestions,
    required this.followupDomains,
    required this.onFollowupTap,
  });

  final List<NumAiChatMessage> messages;
  final bool isLoading;
  final String? typingMessageId;
  final String emptyHint;
  final ScrollController scrollController;
  final ValueChanged<String> onAssistantTypingCompleted;
  final Future<void> Function() onActionTap;
  final ValueChanged<String> onSuggestionTap;
  final bool showFollowupSuggestions;
  final List<_NumAiDomain> followupDomains;
  final ValueChanged<_NumAiDomain> onFollowupTap;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      if (isLoading) {
        return const _NumAiHistoryLoadingState();
      }
      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        physics: const BouncingScrollPhysics(),
        children: <Widget>[
          22.height,
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                emptyHint,
                textAlign: TextAlign.center,
                style: AppStyles.bodySmall(color: AppColors.textMuted),
              ),
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double bubbleMaxWidth = constraints.maxWidth * 0.85;
        final bool hasBottomSuggestions =
            showFollowupSuggestions && !isLoading && followupDomains.isNotEmpty;
        final int itemCount =
            messages.length +
            (isLoading ? 1 : 0) +
            (hasBottomSuggestions ? 1 : 0);

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          itemCount: itemCount,
          itemBuilder: (BuildContext context, int index) {
            if (index < messages.length) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _NumAiMessageBubble(
                  message: messages[index],
                  maxWidth: bubbleMaxWidth,
                  shouldAnimate:
                      messages[index].role == NumAiChatMessageRole.assistant &&
                      messages[index].id == typingMessageId,
                  onAssistantTypingCompleted: onAssistantTypingCompleted,
                  onActionTap: onActionTap,
                  onSuggestionTap: onSuggestionTap,
                ),
              );
            }

            final int loadingIndex = messages.length;
            if (isLoading && index == loadingIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.card.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.richGold.withValues(alpha: 0.95),
                          ),
                        ),
                        8.width,
                        Text(
                          LocaleKey.numaiChatAnalyzing.tr,
                          style: AppStyles.bodySmall(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (hasBottomSuggestions) {
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _NumAiFollowupSuggestions(
                  domains: followupDomains,
                  onTap: onFollowupTap,
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}

class _NumAiHistoryLoadingState extends StatelessWidget {
  const _NumAiHistoryLoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(
              width: 16,
              height: 16,
              child: CustomCircularProgress(color: AppColors.richGold),
            ),
            8.width,
            Text(
              LocaleKey.numaiChatAnalyzing.tr,
              style: AppStyles.bodySmall(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumAiMessageBubble extends StatefulWidget {
  const _NumAiMessageBubble({
    required this.message,
    required this.maxWidth,
    required this.shouldAnimate,
    required this.onAssistantTypingCompleted,
    required this.onActionTap,
    required this.onSuggestionTap,
  });

  final NumAiChatMessage message;
  final double maxWidth;
  final bool shouldAnimate;
  final ValueChanged<String> onAssistantTypingCompleted;
  final Future<void> Function() onActionTap;
  final ValueChanged<String> onSuggestionTap;

  @override
  State<_NumAiMessageBubble> createState() => _NumAiMessageBubbleState();
}

class _NumAiMessageBubbleState extends State<_NumAiMessageBubble> {
  late bool _typingCompleted;

  @override
  void initState() {
    super.initState();
    _typingCompleted = !widget.shouldAnimate;
  }

  @override
  void didUpdateWidget(covariant _NumAiMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.id != widget.message.id) {
      _typingCompleted = !widget.shouldAnimate;
      return;
    }
    if (!widget.shouldAnimate) {
      _typingCompleted = true;
    }
  }

  void _onTypewriterCompleted() {
    if (_typingCompleted || !mounted) {
      return;
    }
    widget.onAssistantTypingCompleted(widget.message.id);
    setState(() {
      _typingCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final NumAiChatMessage message = widget.message;
    final bool isUser = message.role == NumAiChatMessageRole.user;
    final bool isAnimating = widget.shouldAnimate && !_typingCompleted;
    final TextStyle baseStyle = AppStyles.bodySmall(
      color: isUser ? AppColors.midnight : AppColors.textPrimary,
    ).copyWith(height: 1.45);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        decoration: BoxDecoration(
          gradient: isUser
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    AppColors.richGold.withValues(alpha: 0.92),
                    AppColors.goldSoft.withValues(alpha: 0.82),
                  ],
                )
              : null,
          color: isUser ? null : AppColors.card.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUser
                ? AppColors.richGold.withValues(alpha: 0.2)
                : AppColors.border.withValues(alpha: 0.55),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (!isUser) ...<Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: AppColors.richGold,
                  ),
                  4.width,
                  Text(
                    LocaleKey.numaiTitle.tr,
                    style: AppStyles.caption(
                      color: AppColors.richGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              6.height,
            ],
            NumAiTypewriterText(
              key: ValueKey<String>('message-${message.id}'),
              text: message.content,
              baseStyle: baseStyle,
              animate: isAnimating,
              spansBuilder: _buildBoldSpans,
              onCompleted: _onTypewriterCompleted,
            ),
            if (!isUser &&
                message.followUpSuggestions.isNotEmpty &&
                !isAnimating) ...<Widget>[
              10.height,
              ...message.followUpSuggestions.map(
                (String suggestion) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: () => widget.onSuggestionTap(suggestion),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.deepViolet.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Text(
                        suggestion,
                        style: AppStyles.caption(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (message.hasActionButton) ...<Widget>[
              10.height,
              InkWell(
                onTap: widget.onActionTap,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient(),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.richGold.withValues(alpha: 0.24),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 14,
                        color: AppColors.midnight,
                      ),
                      6.width,
                      Text(
                        LocaleKey.numaiChatActionTapHere.tr,
                        style: AppStyles.buttonSmall(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            6.height,
            Text(
              _formatTime(message.timestamp),
              style: AppStyles.caption(
                color: isUser
                    ? AppColors.midnight.withValues(alpha: 0.62)
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<InlineSpan> _buildBoldSpans(String content, TextStyle baseStyle) {
    final RegExp pattern = RegExp(r'\*\*(.*?)\*\*');
    final List<InlineSpan> spans = <InlineSpan>[];
    int currentIndex = 0;

    for (final RegExpMatch match in pattern.allMatches(content)) {
      if (match.start > currentIndex) {
        spans.add(
          TextSpan(
            text: content.substring(currentIndex, match.start),
            style: baseStyle,
          ),
        );
      }

      final String? boldText = match.group(1);
      if (boldText != null) {
        spans.add(
          TextSpan(
            text: boldText,
            style: baseStyle.copyWith(fontWeight: FontWeight.w700),
          ),
        );
      }
      currentIndex = match.end;
    }

    if (currentIndex < content.length) {
      spans.add(
        TextSpan(text: content.substring(currentIndex), style: baseStyle),
      );
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: content, style: baseStyle));
    }
    return spans;
  }

  String _formatTime(DateTime timestamp) {
    final String hour = timestamp.hour.toString().padLeft(2, '0');
    final String minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _NumAiComposer extends StatelessWidget {
  const _NumAiComposer({
    required this.domains,
    required this.activeDomainId,
    required this.canAffordMessage,
    required this.missingPoints,
    required this.canSend,
    required this.isLoading,
    required this.controller,
    required this.inputHint,
    required this.onChanged,
    required this.onSendTap,
    required this.onNoPointsTap,
    required this.showSuggestions,
    required this.onDomainTap,
  });

  final List<_NumAiDomain> domains;
  final String? activeDomainId;
  final bool canAffordMessage;
  final int missingPoints;
  final bool canSend;
  final bool isLoading;
  final TextEditingController controller;
  final String inputHint;
  final ValueChanged<String> onChanged;
  final VoidCallback onSendTap;
  final Future<void> Function() onNoPointsTap;
  final bool showSuggestions;
  final ValueChanged<_NumAiDomain> onDomainTap;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final double resolvedBottomInset = keyboardInset > 0
        ? keyboardInset
        : bottomInset;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + resolvedBottomInset),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.84),
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.45)),
        ),
      ),
      child: Column(
        children: <Widget>[
          if (showSuggestions) ...<Widget>[
            for (int index = 0; index < domains.length; index++) ...<Widget>[
              _DomainPromptButton(
                domain: domains[index],
                isActive: domains[index].id == activeDomainId,
                onTap: () => onDomainTap(domains[index]),
              ),
              if (index != domains.length - 1) 6.height,
            ],
            10.height,
          ],
          if (!canAffordMessage) ...<Widget>[
            _NumAiNeedMorePointsCta(
              missingPoints: missingPoints,
              onTap: onNoPointsTap,
            ),
          ] else ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.send,
                    onChanged: onChanged,
                    onSubmitted: (_) {
                      if (canSend) {
                        onSendTap();
                      }
                    },
                    style: AppStyles.bodyMedium(),
                    decoration: InputDecoration(
                      hintText: inputHint,
                      hintStyle: AppStyles.bodyMedium(
                        color: AppColors.textMuted,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: AppColors.deepViolet.withValues(alpha: 0.48),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.7),
                          width: 1.1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.7),
                          width: 1.1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.richGold,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
                8.width,
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: canSend ? 1 : 0.45,
                  child: InkWell(
                    onTap: canSend ? onSendTap : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient(),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.midnight,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              size: 20,
                              color: AppColors.midnight,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          6.height,
          Text(
            LocaleKey.numaiChatCostFootnote.tr,
            style: AppStyles.caption(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _NumAiNeedMorePointsCta extends StatefulWidget {
  const _NumAiNeedMorePointsCta({
    required this.missingPoints,
    required this.onTap,
  });

  final int missingPoints;
  final Future<void> Function() onTap;

  @override
  State<_NumAiNeedMorePointsCta> createState() =>
      _NumAiNeedMorePointsCtaState();
}

class _NumAiNeedMorePointsCtaState extends State<_NumAiNeedMorePointsCta>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int safeMissingPoints = widget.missingPoints <= 0
        ? 1
        : widget.missingPoints;
    final String label = LocaleKey.numaiStartNeedMorePointsCta.trParams(
      <String, String>{'points': '$safeMissingPoints'},
    );

    return AnimatedBuilder(
      animation: _glowController,
      builder: (BuildContext context, Widget? child) {
        final double glowValue = _glowController.value;
        return InkWell(
          onTap: () {
            widget.onTap();
          },
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  AppColors.energyOrange.withValues(alpha: 0.96),
                  AppColors.energyRose.withValues(alpha: 0.92),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.energyOrange.withValues(
                    alpha: 0.28 + (glowValue * 0.32),
                  ),
                  blurRadius: 18 + (glowValue * 18),
                  spreadRadius: 1 + (glowValue * 2),
                ),
                BoxShadow(
                  color: AppColors.energyRose.withValues(
                    alpha: 0.2 + (glowValue * 0.2),
                  ),
                  blurRadius: 24 + (glowValue * 12),
                ),
              ],
            ),
            child: Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: AppStyles.buttonMedium(
                color: AppColors.white,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }
}

class _NumAiFollowupSuggestions extends StatelessWidget {
  const _NumAiFollowupSuggestions({required this.domains, required this.onTap});

  final List<_NumAiDomain> domains;
  final ValueChanged<_NumAiDomain> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int index = 0; index < domains.length; index++) ...<Widget>[
          _DomainPromptButton(
            domain: domains[index],
            isActive: false,
            onTap: () => onTap(domains[index]),
          ),
          if (index != domains.length - 1) 6.height,
        ],
      ],
    );
  }
}

class _DomainPromptButton extends StatelessWidget {
  const _DomainPromptButton({
    required this.domain,
    required this.isActive,
    required this.onTap,
  });

  final _NumAiDomain domain;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color glowColor = AppColors.richGold.withValues(
      alpha: isActive ? 0.3 : 0.16,
    );
    final Color borderColor = AppColors.richGold.withValues(
      alpha: isActive ? 0.5 : 0.24,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              AppColors.midnightSoft.withValues(alpha: 0.96),
              AppColors.deepViolet.withValues(alpha: isActive ? 0.92 : 0.84),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: isActive ? 1.2 : 1),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: glowColor,
              blurRadius: isActive ? 24 : 16,
              spreadRadius: isActive ? 0.8 : 0.2,
            ),
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Icon(
              domain.icon,
              size: 16,
              color: AppColors.richGold.withValues(
                alpha: isActive ? 0.95 : 0.8,
              ),
            ),
            8.width,
            Expanded(
              child: Text(
                domain.featuredPromptKey.tr,
                style: AppStyles.bodySmall(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumAiDomain {
  const _NumAiDomain({
    required this.id,
    required this.labelKey,
    required this.featuredPromptKey,
    required this.placeholderKey,
    required this.icon,
  });

  final String id;
  final String labelKey;
  final String featuredPromptKey;
  final String placeholderKey;
  final IconData icon;
}

const List<_NumAiDomain> _domains = <_NumAiDomain>[
  _NumAiDomain(
    id: 'personality',
    labelKey: LocaleKey.numaiDomainPersonalityLabel,
    featuredPromptKey: LocaleKey.numaiDomainPersonalityFeatured,
    placeholderKey: LocaleKey.numaiDomainPersonalityPlaceholder,
    icon: Icons.account_circle_outlined,
  ),
  _NumAiDomain(
    id: 'career',
    labelKey: LocaleKey.numaiDomainCareerLabel,
    featuredPromptKey: LocaleKey.numaiDomainCareerFeatured,
    placeholderKey: LocaleKey.numaiDomainCareerPlaceholder,
    icon: Icons.work_outline_rounded,
  ),
  _NumAiDomain(
    id: 'love',
    labelKey: LocaleKey.numaiDomainLoveLabel,
    featuredPromptKey: LocaleKey.numaiDomainLoveFeatured,
    placeholderKey: LocaleKey.numaiDomainLovePlaceholder,
    icon: Icons.favorite_border_rounded,
  ),
  _NumAiDomain(
    id: 'cycles',
    labelKey: LocaleKey.numaiDomainCyclesLabel,
    featuredPromptKey: LocaleKey.numaiDomainCyclesFeatured,
    placeholderKey: LocaleKey.numaiDomainCyclesPlaceholder,
    icon: Icons.refresh_rounded,
  ),
];
