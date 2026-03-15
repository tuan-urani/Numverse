import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/numai_chat/interactor/numai_chat_state.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class NumAiChatMessages extends StatefulWidget {
  const NumAiChatMessages({
    required this.messages,
    required this.isLoading,
    required this.onActionTap,
    required this.onQuickSuggestionTap,
    super.key,
  });

  final List<NumAiChatMessage> messages;
  final bool isLoading;
  final VoidCallback onActionTap;
  final ValueChanged<String> onQuickSuggestionTap;

  @override
  State<NumAiChatMessages> createState() => _NumAiChatMessagesState();
}

class _NumAiChatMessagesState extends State<NumAiChatMessages> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(covariant NumAiChatMessages oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messages.length != widget.messages.length ||
        oldWidget.isLoading != widget.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty && !widget.isLoading) {
      return _EmptyState(onQuickSuggestionTap: widget.onQuickSuggestionTap);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: widget.messages.length + (widget.isLoading ? 1 : 0),
      itemBuilder: (BuildContext context, int index) {
        if (index >= widget.messages.length) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _LoadingBubble(),
          );
        }
        final NumAiChatMessage message = widget.messages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _MessageBubble(
            message: message,
            onActionTap: widget.onActionTap,
          ),
        );
      },
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 48,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onQuickSuggestionTap});

  final ValueChanged<String> onQuickSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final List<String> suggestions = <String>[
      LocaleKey.numaiChatQuickOne.tr,
      LocaleKey.numaiChatQuickTwo.tr,
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    AppColors.richGold.withValues(alpha: 0.32),
                    AppColors.deepViolet.withValues(alpha: 0.45),
                  ],
                ),
                border: Border.all(
                  color: AppColors.richGold.withValues(alpha: 0.4),
                ),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 40,
                color: AppColors.richGold,
              ),
            ),
            16.height,
            Text(
              LocaleKey.numaiChatEmptyTitle.tr,
              textAlign: TextAlign.center,
              style: AppStyles.h4(fontWeight: FontWeight.w700),
            ),
            8.height,
            Text(
              LocaleKey.numaiChatEmptyBody.tr,
              textAlign: TextAlign.center,
              style: AppStyles.bodySmall(color: AppColors.textMuted),
            ),
            18.height,
            Text(
              LocaleKey.numaiChatQuickSuggestions.tr,
              style: AppStyles.caption(color: AppColors.textMuted),
            ),
            10.height,
            ...suggestions.map(
              (String suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => onQuickSuggestionTap(suggestion),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.card.withValues(alpha: 0.52),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Text(
                      suggestion,
                      style: AppStyles.bodySmall(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.onActionTap});

  final NumAiChatMessage message;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.role == NumAiChatMessageRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 316),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        decoration: BoxDecoration(
          gradient: isUser ? AppColors.primaryGradient() : null,
          color: isUser ? null : AppColors.card.withValues(alpha: 0.56),
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
            Text(
              message.content,
              style: AppStyles.bodySmall(
                color: isUser ? AppColors.midnight : AppColors.textPrimary,
              ),
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

  String _formatTime(DateTime timestamp) {
    final String hour = timestamp.hour.toString().padLeft(2, '0');
    final String minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _LoadingBubble extends StatelessWidget {
  const _LoadingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 290),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.56),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.richGold.withValues(alpha: 0.9),
              ),
            ),
            8.width,
            Text(
              LocaleKey.numaiChatThinking.tr,
              style: AppStyles.bodySmall(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
