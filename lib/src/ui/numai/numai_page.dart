import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/compatibility/components/compatibility_profile_input_dialog.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_state.dart';
import 'package:test/src/ui/numai_chat/interactor/numai_chat_bloc.dart';
import 'package:test/src/ui/numai_chat/interactor/numai_chat_state.dart';
import 'package:test/src/ui/widgets/app_state_view.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class NumAiPage extends StatefulWidget {
  const NumAiPage({super.key});

  @override
  State<NumAiPage> createState() => _NumAiPageState();
}

class _NumAiPageState extends State<NumAiPage> {
  late final MainSessionBloc _sessionBloc;
  late final NumAiChatBloc _chatBloc;
  late final TextEditingController _controller;
  late final ScrollController _scrollController;

  String? _activeDomainId;

  @override
  void initState() {
    super.initState();
    _sessionBloc = Get.find<MainSessionBloc>();
    _chatBloc = Get.isRegistered<NumAiChatBloc>()
        ? Get.find<NumAiChatBloc>()
        : Get.put<NumAiChatBloc>(NumAiChatBloc());
    _controller = TextEditingController();
    _scrollController = ScrollController();

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
              listener: _onChatStateChanged,
              child: BlocBuilder<NumAiChatBloc, NumAiChatState>(
                bloc: _chatBloc,
                builder: (BuildContext context, NumAiChatState chatState) {
                  final _NumAiDomain? activeDomain = _domainById(
                    _activeDomainId,
                  );
                  final bool canAffordMessage =
                      sessionState.soulPoints >= NumAiChatBloc.messageCost;
                  final bool canSend =
                      _controller.text.trim().isNotEmpty &&
                      !chatState.isLoading &&
                      canAffordMessage &&
                      activeDomain != null;
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
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
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
                                emptyHint: emptyHint,
                                scrollController: _scrollController,
                                onActionTap: _onProfileActionTap,
                              ),
                            ),
                            _NumAiComposer(
                              domains: _domains,
                              activeDomainId: _activeDomainId,
                              canAffordMessage: canAffordMessage,
                              canSend: canSend,
                              isLoading: chatState.isLoading,
                              controller: _controller,
                              inputHint: inputHint,
                              noPointsMessage:
                                  LocaleKey.numaiChatNoPointsHint.tr,
                              onChanged: (_) => setState(() {}),
                              onSendTap: () => _sendMessage(),
                              onDomainTap: (_NumAiDomain domain) {
                                _sendMessage(
                                  messageText: domain.featuredPromptKey.tr,
                                  domain: domain,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
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

  Future<void> _sendMessage({String? messageText, _NumAiDomain? domain}) async {
    final String resolvedMessage = (messageText ?? _controller.text).trim();
    if (resolvedMessage.isEmpty) {
      return;
    }

    final _NumAiDomain? selectedDomain = domain ?? _domainById(_activeDomainId);
    if (selectedDomain == null) {
      return;
    }

    setState(() {
      _activeDomainId = selectedDomain.id;
    });

    final bool hasProfile = _sessionBloc.state.currentProfile != null;
    if (selectedDomain.needsProfile && !hasProfile) {
      await _promptProfileInputDialog();
      return;
    }

    final bool sent = await _chatBloc.sendMessage(
      rawMessage: resolvedMessage,
      hasProfile: hasProfile,
      deductSoulPoints: _sessionBloc.deductSoulPoints,
    );
    if (!mounted || !sent) {
      return;
    }

    if (messageText == null) {
      _controller.clear();
    }
    setState(() {});
  }

  Future<void> _promptProfileInputDialog() async {
    await CompatibilityProfileInputDialog.show(
      context,
      onSubmit: (String name, DateTime birthDate) async {
        await _sessionBloc.addProfile(name: name, birthDate: birthDate);
      },
    );
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
    _chatBloc.appendPendingQuestionAnswerAfterProfile();
  }

  void _resetConversation() {
    _chatBloc.resetConversation();
    _controller.clear();
    setState(() {
      _activeDomainId = null;
    });
  }

  void _scheduleScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 42,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _onChatStateChanged(BuildContext context, NumAiChatState state) {
    _scheduleScrollToBottom();
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
                  style: AppStyles.numberSmall(
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
                const Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: AppColors.richGold,
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
    required this.emptyHint,
    required this.scrollController,
    required this.onActionTap,
  });

  final List<NumAiChatMessage> messages;
  final bool isLoading;
  final String emptyHint;
  final ScrollController scrollController;
  final Future<void> Function() onActionTap;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty && !isLoading) {
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
        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          itemCount: messages.length + (isLoading ? 1 : 0),
          itemBuilder: (BuildContext context, int index) {
            if (index >= messages.length) {
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

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _NumAiMessageBubble(
                message: messages[index],
                maxWidth: bubbleMaxWidth,
                onActionTap: onActionTap,
              ),
            );
          },
        );
      },
    );
  }
}

class _NumAiMessageBubble extends StatelessWidget {
  const _NumAiMessageBubble({
    required this.message,
    required this.maxWidth,
    required this.onActionTap,
  });

  final NumAiChatMessage message;
  final double maxWidth;
  final Future<void> Function() onActionTap;

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.role == NumAiChatMessageRole.user;
    final TextStyle baseStyle = AppStyles.bodySmall(
      color: isUser ? AppColors.midnight : AppColors.textPrimary,
    ).copyWith(height: 1.45);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
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
            Text.rich(
              TextSpan(children: _buildBoldSpans(message.content, baseStyle)),
            ),
            if (message.hasActionButton) ...<Widget>[
              10.height,
              InkWell(
                onTap: onActionTap,
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
    required this.canSend,
    required this.isLoading,
    required this.controller,
    required this.inputHint,
    required this.noPointsMessage,
    required this.onChanged,
    required this.onSendTap,
    required this.onDomainTap,
  });

  final List<_NumAiDomain> domains;
  final String? activeDomainId;
  final bool canAffordMessage;
  final bool canSend;
  final bool isLoading;
  final TextEditingController controller;
  final String inputHint;
  final String noPointsMessage;
  final ValueChanged<String> onChanged;
  final VoidCallback onSendTap;
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
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.84),
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.45)),
        ),
      ),
      child: Column(
        children: <Widget>[
          for (int index = 0; index < domains.length; index++) ...<Widget>[
            _DomainPromptButton(
              domain: domains[index],
              isActive: domains[index].id == activeDomainId,
              onTap: () => onDomainTap(domains[index]),
            ),
            if (index != domains.length - 1) 6.height,
          ],
          10.height,
          if (!canAffordMessage) ...<Widget>[
            Text(
              noPointsMessage,
              textAlign: TextAlign.center,
              style: AppStyles.bodySmall(color: AppColors.error),
            ),
          ] else ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.card.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.65),
                      ),
                    ),
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
                        hintStyle: AppStyles.bodySmall(
                          color: AppColors.textMuted,
                        ),
                        border: InputBorder.none,
                        isDense: true,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.richGold.withValues(alpha: 0.15)
              : AppColors.card.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppColors.richGold.withValues(alpha: 0.45)
                : AppColors.border.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              domain.icon,
              size: 16,
              color: isActive ? AppColors.richGold : AppColors.textMuted,
            ),
            8.width,
            Expanded(
              child: Text(
                domain.featuredPromptKey.tr,
                style: AppStyles.bodySmall(
                  color: isActive ? AppColors.richGold : AppColors.textPrimary,
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
    required this.needsProfile,
  });

  final String id;
  final String labelKey;
  final String featuredPromptKey;
  final String placeholderKey;
  final IconData icon;
  final bool needsProfile;
}

const List<_NumAiDomain> _domains = <_NumAiDomain>[
  _NumAiDomain(
    id: 'personality',
    labelKey: LocaleKey.numaiDomainPersonalityLabel,
    featuredPromptKey: LocaleKey.numaiDomainPersonalityFeatured,
    placeholderKey: LocaleKey.numaiDomainPersonalityPlaceholder,
    icon: Icons.account_circle_outlined,
    needsProfile: true,
  ),
  _NumAiDomain(
    id: 'career',
    labelKey: LocaleKey.numaiDomainCareerLabel,
    featuredPromptKey: LocaleKey.numaiDomainCareerFeatured,
    placeholderKey: LocaleKey.numaiDomainCareerPlaceholder,
    icon: Icons.work_outline_rounded,
    needsProfile: true,
  ),
  _NumAiDomain(
    id: 'love',
    labelKey: LocaleKey.numaiDomainLoveLabel,
    featuredPromptKey: LocaleKey.numaiDomainLoveFeatured,
    placeholderKey: LocaleKey.numaiDomainLovePlaceholder,
    icon: Icons.favorite_border_rounded,
    needsProfile: true,
  ),
  _NumAiDomain(
    id: 'cycles',
    labelKey: LocaleKey.numaiDomainCyclesLabel,
    featuredPromptKey: LocaleKey.numaiDomainCyclesFeatured,
    placeholderKey: LocaleKey.numaiDomainCyclesPlaceholder,
    icon: Icons.refresh_rounded,
    needsProfile: true,
  ),
];
