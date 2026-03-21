import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:test/src/core/model/cloud_numai_thread_messages_result.dart';
import 'package:test/src/core/model/local_numai_guest_message.dart';
import 'package:test/src/core/repository/interface/i_app_session_repository.dart';
import 'package:test/src/core/repository/interface/i_cloud_account_repository.dart';
import 'package:test/src/ui/numai_chat/interactor/numai_chat_event.dart';
import 'package:test/src/ui/numai_chat/interactor/numai_chat_state.dart';

class NumAiChatBloc extends Bloc<NumAiChatEvent, NumAiChatState> {
  NumAiChatBloc({
    required ICloudAccountRepository cloudAccountRepository,
    required IAppSessionRepository appSessionRepository,
  }) : _cloudAccountRepository = cloudAccountRepository,
       _appSessionRepository = appSessionRepository,
       super(NumAiChatState.initial()) {
    on<NumAiChatHistoryRequested>(_onHistoryRequested);
    on<NumAiChatMessageSent>(_onMessageSent);
    on<NumAiChatInsufficientWarningCleared>(_onInsufficientWarningCleared);
    on<NumAiChatQuickSuggestionApplied>(_onQuickSuggestionApplied);
    on<NumAiChatPendingProfileQuestionCleared>(
      _onPendingProfileQuestionCleared,
    );
    on<NumAiChatPendingQuestionAnswerAppended>(
      _onPendingQuestionAnswerAppended,
    );
    on<NumAiChatConversationReset>(_onConversationReset);
  }

  static const int messageCost = 3;
  static const int _maxGuestLocalMessages = 80;
  final ICloudAccountRepository _cloudAccountRepository;
  final IAppSessionRepository _appSessionRepository;

  void loadCloudHistory({
    required bool hasCloudSession,
    required String? profileId,
    required String? cloudUserId,
    bool forceRefresh = false,
  }) {
    add(
      NumAiChatHistoryRequested(
        hasCloudSession: hasCloudSession,
        profileId: profileId,
        cloudUserId: cloudUserId,
        forceRefresh: forceRefresh,
      ),
    );
  }

  Future<bool> sendMessage({
    required String rawMessage,
    required bool hasProfile,
    required bool hasCloudSession,
    required String? profileId,
    required String? cloudUserId,
    required String? locale,
    required DeductSoulPoints deductSoulPoints,
    required SyncSoulPoints syncSoulPoints,
  }) async {
    final Completer<bool> completer = Completer<bool>();
    add(
      NumAiChatMessageSent(
        rawMessage: rawMessage,
        hasProfile: hasProfile,
        hasCloudSession: hasCloudSession,
        profileId: profileId,
        cloudUserId: cloudUserId,
        locale: locale,
        deductSoulPoints: deductSoulPoints,
        syncSoulPoints: syncSoulPoints,
        completer: completer,
      ),
    );
    return completer.future;
  }

  Future<void> _onHistoryRequested(
    NumAiChatHistoryRequested event,
    Emitter<NumAiChatState> emit,
  ) async {
    final String profileId = (event.profileId ?? '').trim();
    final String guestUserKey = _resolveGuestUserKey(event.cloudUserId);
    final bool sameProfileContext = state.activeProfileId == profileId;
    final bool shouldClearForContextChange = !sameProfileContext;
    final String? threadIdForProfile = sameProfileContext
        ? state.threadId
        : null;

    if (!event.forceRefresh &&
        sameProfileContext &&
        state.messages.isNotEmpty) {
      return;
    }

    emit(
      state.copyWith(
        isLoading: true,
        showInsufficientPointsWarning: false,
        clearTypingMessageId: true,
        messages: shouldClearForContextChange
            ? const <NumAiChatMessage>[]
            : state.messages,
        clearThreadId: shouldClearForContextChange,
        activeProfileId: profileId.isEmpty ? null : profileId,
        clearActiveProfileId: profileId.isEmpty,
      ),
    );

    if (profileId.isEmpty) {
      try {
        final guestMessages = await _appSessionRepository
            .loadNumAiGuestMessages(userKey: guestUserKey);
        emit(
          state.copyWith(
            messages: _sortMessagesByTimestamp(
              guestMessages.map(_toChatMessageFromGuest),
            ),
            isLoading: false,
            clearThreadId: true,
            clearActiveProfileId: true,
            clearTypingMessageId: true,
          ),
        );
      } catch (_) {
        emit(
          state.copyWith(
            isLoading: false,
            clearThreadId: true,
            clearActiveProfileId: true,
            clearTypingMessageId: true,
          ),
        );
      }
      return;
    }

    if (!event.hasCloudSession || !_cloudAccountRepository.isConfigured) {
      emit(
        state.copyWith(
          isLoading: false,
          activeProfileId: profileId,
          clearTypingMessageId: true,
        ),
      );
      return;
    }

    try {
      await _tryMigrateGuestHistoryToCloud(
        profileId: profileId,
        guestUserKey: guestUserKey,
      );
      final result = await _cloudAccountRepository.fetchNumAiThreadMessages(
        profileId: profileId,
        threadId: threadIdForProfile,
      );
      emit(
        state.copyWith(
          messages: _sortMessagesByTimestamp(
            result.messages.map(_toChatMessageFromCloud),
          ),
          isLoading: false,
          threadId: result.threadId.isEmpty ? null : result.threadId,
          activeProfileId: profileId,
          clearTypingMessageId: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          activeProfileId: profileId,
          clearTypingMessageId: true,
        ),
      );
    }
  }

  void clearInsufficientWarning() {
    add(const NumAiChatInsufficientWarningCleared());
  }

  Future<void> _onMessageSent(
    NumAiChatMessageSent event,
    Emitter<NumAiChatState> emit,
  ) async {
    final String message = event.rawMessage.trim();
    if (message.isEmpty || state.isLoading) {
      _completeBool(event.completer, false);
      return;
    }

    final String profileId = (event.profileId ?? '').trim();
    final String guestUserKey = _resolveGuestUserKey(event.cloudUserId);
    if (event.hasCloudSession && _cloudAccountRepository.isConfigured) {
      if (profileId.isNotEmpty) {
        await _tryMigrateGuestHistoryToCloud(
          profileId: profileId,
          guestUserKey: guestUserKey,
        );
        await _sendCloudMessage(
          event: event,
          emit: emit,
          message: message,
          profileId: profileId,
        );
        return;
      }

      await _sendGuestCloudMessage(
        event: event,
        emit: emit,
        message: message,
        guestUserKey: guestUserKey,
      );
      return;
    }

    _completeBool(event.completer, false);
  }

  Future<void> _sendGuestCloudMessage({
    required NumAiChatMessageSent event,
    required Emitter<NumAiChatState> emit,
    required String message,
    required String guestUserKey,
  }) async {
    final List<NumAiChatMessage> previousMessages = state.messages;
    final DateTime userSentAt = DateTime.now();
    final NumAiChatMessage userMessage = NumAiChatMessage(
      id: '${userSentAt.microsecondsSinceEpoch}-user',
      role: NumAiChatMessageRole.user,
      content: message,
      timestamp: userSentAt,
    );
    final List<NumAiChatMessage> nextMessages = <NumAiChatMessage>[
      ...previousMessages,
      userMessage,
    ];

    emit(
      state.copyWith(
        messages: nextMessages,
        isLoading: true,
        showInsufficientPointsWarning: false,
        clearThreadId: true,
        clearActiveProfileId: true,
        clearTypingMessageId: true,
      ),
    );

    try {
      final result = await _cloudAccountRepository.sendNumAiGuestMessage(
        messageText: message,
        locale: event.locale,
        recentMessages: nextMessages
            .map(
              (NumAiChatMessage item) => <String, String>{
                'role': item.role == NumAiChatMessageRole.user
                    ? 'user'
                    : 'assistant',
                'text': item.content.trim(),
              },
            )
            .where(
              (Map<String, String> item) => (item['text'] ?? '').isNotEmpty,
            )
            .toList(),
      );

      final DateTime assistantSentAt = DateTime.now();
      final NumAiChatMessage assistantMessage = NumAiChatMessage(
        id: '${assistantSentAt.microsecondsSinceEpoch}-assistant',
        role: NumAiChatMessageRole.assistant,
        content: result.assistantText,
        timestamp: assistantSentAt,
        hasActionButton: result.requiresProfileInfo,
        followUpSuggestions: result.suggestions,
        fallbackReason: result.fallbackReason,
        requiresProfileInfo: result.requiresProfileInfo,
      );
      final List<NumAiChatMessage> allMessages = <NumAiChatMessage>[
        ...nextMessages,
        assistantMessage,
      ];

      emit(
        state.copyWith(
          messages: allMessages,
          isLoading: false,
          clearPendingProfileQuestion: true,
          clearThreadId: true,
          clearActiveProfileId: true,
          typingMessageId: assistantMessage.id,
        ),
      );
      try {
        await _persistGuestMessages(
          guestUserKey: guestUserKey,
          messages: allMessages,
        );
      } catch (_) {}
      try {
        await event.syncSoulPoints(result.walletBalance);
      } catch (_) {}
      _completeBool(event.completer, true);
    } catch (error) {
      final String errorCode = _resolveErrorCode(error);
      if (errorCode == 'insufficient_soul_points') {
        emit(
          state.copyWith(
            messages: previousMessages,
            isLoading: false,
            showInsufficientPointsWarning: true,
            clearThreadId: true,
            clearActiveProfileId: true,
          ),
        );
        _completeBool(event.completer, false);
        return;
      }

      emit(
        state.copyWith(
          messages: previousMessages,
          isLoading: false,
          clearThreadId: true,
          clearActiveProfileId: true,
          clearTypingMessageId: true,
        ),
      );
      _completeBool(event.completer, false);
    }
  }

  Future<void> _sendCloudMessage({
    required NumAiChatMessageSent event,
    required Emitter<NumAiChatState> emit,
    required String message,
    required String profileId,
  }) async {
    final String? threadIdForProfile = state.activeProfileId == profileId
        ? state.threadId
        : null;
    final List<NumAiChatMessage> previousMessages = state.messages;
    final DateTime userSentAt = DateTime.now();
    final NumAiChatMessage userMessage = NumAiChatMessage(
      id: '${userSentAt.microsecondsSinceEpoch}-user',
      role: NumAiChatMessageRole.user,
      content: message,
      timestamp: userSentAt,
    );
    final List<NumAiChatMessage> nextMessages = <NumAiChatMessage>[
      ...previousMessages,
      userMessage,
    ];

    emit(
      state.copyWith(
        messages: nextMessages,
        isLoading: true,
        showInsufficientPointsWarning: false,
        activeProfileId: profileId,
        clearTypingMessageId: true,
      ),
    );

    try {
      final result = await _cloudAccountRepository.sendNumAiMessage(
        profileId: profileId,
        messageText: message,
        threadId: threadIdForProfile,
        locale: event.locale,
      );
      final DateTime assistantSentAt = DateTime.now();
      final NumAiChatMessage assistantMessage = NumAiChatMessage(
        id: '${assistantSentAt.microsecondsSinceEpoch}-assistant',
        role: NumAiChatMessageRole.assistant,
        content: result.assistantText,
        timestamp: assistantSentAt,
        hasActionButton: !event.hasProfile && result.requiresProfileInfo,
        followUpSuggestions: result.suggestions,
        fallbackReason: result.fallbackReason,
        requiresProfileInfo: result.requiresProfileInfo,
      );
      emit(
        state.copyWith(
          messages: <NumAiChatMessage>[...nextMessages, assistantMessage],
          isLoading: false,
          clearPendingProfileQuestion: true,
          threadId: result.threadId.isEmpty ? null : result.threadId,
          activeProfileId: profileId,
          typingMessageId: assistantMessage.id,
        ),
      );
      try {
        await event.syncSoulPoints(result.walletBalance);
      } catch (_) {}
      _completeBool(event.completer, true);
    } catch (error) {
      final String errorCode = _resolveErrorCode(error);
      if (errorCode == 'insufficient_soul_points') {
        emit(
          state.copyWith(
            messages: previousMessages,
            isLoading: false,
            showInsufficientPointsWarning: true,
            activeProfileId: profileId,
          ),
        );
        _completeBool(event.completer, false);
        return;
      }

      emit(
        state.copyWith(
          messages: previousMessages,
          isLoading: false,
          activeProfileId: profileId,
          clearTypingMessageId: true,
        ),
      );
      _completeBool(event.completer, false);
    }
  }

  String _resolveErrorCode(Object error) {
    if (error is StateError) {
      final Object message = error.message;
      if (message is String) {
        return message.trim();
      }
    }
    return '';
  }

  void _onInsufficientWarningCleared(
    NumAiChatInsufficientWarningCleared event,
    Emitter<NumAiChatState> emit,
  ) {
    if (!state.showInsufficientPointsWarning) {
      return;
    }
    emit(state.copyWith(showInsufficientPointsWarning: false));
  }

  void applyQuickSuggestion(String suggestion) {
    add(NumAiChatQuickSuggestionApplied(suggestion));
  }

  void _onQuickSuggestionApplied(
    NumAiChatQuickSuggestionApplied event,
    Emitter<NumAiChatState> emit,
  ) {
    if (state.showInsufficientPointsWarning) {
      emit(state.copyWith(showInsufficientPointsWarning: false));
    }
  }

  void clearPendingProfileQuestion() {
    add(const NumAiChatPendingProfileQuestionCleared());
  }

  void _onPendingProfileQuestionCleared(
    NumAiChatPendingProfileQuestionCleared event,
    Emitter<NumAiChatState> emit,
  ) {
    if (state.pendingProfileQuestion == null) {
      return;
    }
    emit(state.copyWith(clearPendingProfileQuestion: true));
  }

  void appendPendingQuestionAnswerAfterProfile() {
    add(const NumAiChatPendingQuestionAnswerAppended());
  }

  void resetConversation({required String? cloudUserId}) {
    add(NumAiChatConversationReset(cloudUserId: cloudUserId));
  }

  void _onPendingQuestionAnswerAppended(
    NumAiChatPendingQuestionAnswerAppended event,
    Emitter<NumAiChatState> emit,
  ) {
    if (state.pendingProfileQuestion == null) {
      return;
    }
    emit(state.copyWith(clearPendingProfileQuestion: true));
  }

  Future<void> _onConversationReset(
    NumAiChatConversationReset event,
    Emitter<NumAiChatState> emit,
  ) async {
    try {
      await _appSessionRepository.clearNumAiGuestMessages(
        userKey: _resolveGuestUserKey(event.cloudUserId),
      );
    } catch (_) {}
    emit(NumAiChatState.initial());
  }

  static void _completeBool(Completer<bool> completer, bool value) {
    if (!completer.isCompleted) {
      completer.complete(value);
    }
  }

  String _resolveGuestUserKey(String? cloudUserId) {
    final String clean = (cloudUserId ?? '').trim();
    if (clean.isEmpty) {
      return 'local';
    }
    return clean;
  }

  NumAiChatMessage _toChatMessageFromCloud(CloudNumAiThreadMessage item) {
    return NumAiChatMessage(
      id: item.id.isNotEmpty
          ? item.id
          : '${item.createdAt.microsecondsSinceEpoch}-${item.senderType}',
      role: item.senderType == 'user'
          ? NumAiChatMessageRole.user
          : NumAiChatMessageRole.assistant,
      content: item.messageText,
      timestamp: item.createdAt,
      hasActionButton: false,
      followUpSuggestions: item.followUpSuggestions,
      fallbackReason: item.fallbackReason,
      requiresProfileInfo: item.requiresProfileInfo,
    );
  }

  NumAiChatMessage _toChatMessageFromGuest(LocalNumAiGuestMessage item) {
    return NumAiChatMessage(
      id: item.id,
      role: item.senderType == 'user'
          ? NumAiChatMessageRole.user
          : NumAiChatMessageRole.assistant,
      content: item.messageText,
      timestamp: item.createdAt,
      hasActionButton:
          item.senderType == 'assistant' && item.requiresProfileInfo,
      followUpSuggestions: item.followUpSuggestions,
      requiresProfileInfo: item.requiresProfileInfo,
    );
  }

  List<NumAiChatMessage> _sortMessagesByTimestamp(
    Iterable<NumAiChatMessage> rawMessages,
  ) {
    final List<NumAiChatMessage> sorted = rawMessages.toList();
    sorted.sort((NumAiChatMessage left, NumAiChatMessage right) {
      final int byTime = left.timestamp.compareTo(right.timestamp);
      if (byTime != 0) {
        return byTime;
      }
      return left.id.compareTo(right.id);
    });
    return sorted;
  }

  Future<void> _persistGuestMessages({
    required String guestUserKey,
    required List<NumAiChatMessage> messages,
  }) async {
    final List<NumAiChatMessage> cappedMessages =
        messages.length > _maxGuestLocalMessages
        ? messages.sublist(messages.length - _maxGuestLocalMessages)
        : messages;
    final List<LocalNumAiGuestMessage> payload = cappedMessages
        .map(
          (NumAiChatMessage item) => LocalNumAiGuestMessage(
            id: item.id.trim(),
            senderType: item.role == NumAiChatMessageRole.user
                ? 'user'
                : 'assistant',
            messageText: item.content.trim(),
            createdAt: item.timestamp,
            followUpSuggestions: item.followUpSuggestions,
            requiresProfileInfo: item.requiresProfileInfo,
          ),
        )
        .where(
          (LocalNumAiGuestMessage item) =>
              item.id.isNotEmpty && item.messageText.isNotEmpty,
        )
        .toList();
    if (payload.isEmpty) {
      return;
    }
    await _appSessionRepository.saveNumAiGuestMessages(
      userKey: guestUserKey,
      messages: payload,
    );
  }

  Future<void> _tryMigrateGuestHistoryToCloud({
    required String profileId,
    required String guestUserKey,
  }) async {
    if (profileId.isEmpty) {
      return;
    }
    try {
      final List<LocalNumAiGuestMessage> guestMessages =
          await _appSessionRepository.loadNumAiGuestMessages(
            userKey: guestUserKey,
          );
      if (guestMessages.isEmpty) {
        return;
      }

      final String requestId = _buildGuestImportRequestId(
        guestUserKey: guestUserKey,
        profileId: profileId,
        messages: guestMessages,
      );
      await _cloudAccountRepository.importGuestNumAiHistory(
        profileId: profileId,
        messages: guestMessages,
        requestId: requestId,
      );
      await _appSessionRepository.clearNumAiGuestMessages(
        userKey: guestUserKey,
      );
    } catch (_) {}
  }

  String _buildGuestImportRequestId({
    required String guestUserKey,
    required String profileId,
    required List<LocalNumAiGuestMessage> messages,
  }) {
    final String firstId = messages.first.id.trim();
    final String lastId = messages.last.id.trim();
    return [
      'guest_import',
      guestUserKey,
      profileId,
      '${messages.length}',
      firstId,
      lastId,
    ].join(':');
  }
}
