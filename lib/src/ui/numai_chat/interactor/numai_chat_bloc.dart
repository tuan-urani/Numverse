import 'dart:async';

import 'package:dio/dio.dart';
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
    on<NumAiChatTypingMessageCompleted>(_onTypingMessageCompleted);
    on<NumAiChatConversationReset>(_onConversationReset);
  }

  static const int messageCost = 3;
  static const int _maxGuestLocalMessages = 80;
  static const String _canonicalGuestUserKey = 'local';
  static const int _maxHistoryFetchAttempts = 3;
  final ICloudAccountRepository _cloudAccountRepository;
  final IAppSessionRepository _appSessionRepository;

  void loadCloudHistory({
    required bool hasCloudSession,
    required bool isAnonymousUser,
    required String? profileId,
    required String? cloudUserId,
    bool forceRefresh = false,
  }) {
    add(
      NumAiChatHistoryRequested(
        hasCloudSession: hasCloudSession,
        isAnonymousUser: isAnonymousUser,
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
    required bool isAnonymousUser,
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
        isAnonymousUser: isAnonymousUser,
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
    final String previousProfileId = (state.activeProfileId ?? '').trim();
    final List<NumAiChatMessage> previousMessages = state.messages;
    final String guestUserKey = _resolveGuestUserKey(event.cloudUserId);
    final bool sameProfileContext = state.activeProfileId == profileId;
    final bool shouldClearForContextChange = !sameProfileContext;
    final bool isGuestToProfileTransition =
        shouldClearForContextChange &&
        previousProfileId.isEmpty &&
        profileId.isNotEmpty;
    final bool isProfileToProfileTransition =
        shouldClearForContextChange &&
        previousProfileId.isNotEmpty &&
        profileId.isNotEmpty;
    final String? threadIdForProfile = sameProfileContext
        ? state.threadId
        : null;

    if (!event.forceRefresh &&
        sameProfileContext &&
        state.messages.isNotEmpty) {
      return;
    }

    final List<String> guestCandidateKeys = await _resolveGuestCandidateKeys(
      guestUserKey: guestUserKey,
    );
    final List<LocalNumAiGuestMessage> mergedGuestMessages =
        await _loadMergedGuestMessages(candidateKeys: guestCandidateKeys);
    final List<NumAiChatMessage> guestFallbackMessages =
        _sortMessagesByTimestamp(
          mergedGuestMessages.map(_toChatMessageFromGuest),
        );
    final bool shouldShowGuestFallback =
        isGuestToProfileTransition && guestFallbackMessages.isNotEmpty;
    final List<NumAiChatMessage> contextChangeBaseMessages =
        shouldShowGuestFallback
        ? guestFallbackMessages
        : const <NumAiChatMessage>[];

    emit(
      state.copyWith(
        isLoading: true,
        showInsufficientPointsWarning: false,
        clearTypingMessageId: true,
        messages: shouldClearForContextChange
            ? contextChangeBaseMessages
            : previousMessages,
        clearThreadId: shouldClearForContextChange,
        activeProfileId: profileId.isEmpty ? null : profileId,
        clearActiveProfileId: profileId.isEmpty,
      ),
    );

    if (profileId.isEmpty) {
      emit(
        state.copyWith(
          messages: guestFallbackMessages,
          isLoading: false,
          clearThreadId: true,
          clearActiveProfileId: true,
          clearTypingMessageId: true,
        ),
      );
      return;
    }

    if (!event.hasCloudSession || !_cloudAccountRepository.isConfigured) {
      final List<NumAiChatMessage> fallbackMessages;
      if (sameProfileContext) {
        fallbackMessages = previousMessages;
      } else if (isGuestToProfileTransition &&
          guestFallbackMessages.isNotEmpty) {
        fallbackMessages = guestFallbackMessages;
      } else if (isProfileToProfileTransition) {
        fallbackMessages = const <NumAiChatMessage>[];
      } else {
        fallbackMessages = contextChangeBaseMessages;
      }
      emit(
        state.copyWith(
          messages: fallbackMessages,
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
        guestCandidateKeys: guestCandidateKeys,
        isAnonymousUser: event.isAnonymousUser,
      );
      final result = await _fetchCloudHistoryWithRetry(
        profileId: profileId,
        threadId: threadIdForProfile,
        isAnonymousUser: event.isAnonymousUser,
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
      final List<NumAiChatMessage> fallbackMessages;
      if (sameProfileContext) {
        fallbackMessages = previousMessages;
      } else if (isGuestToProfileTransition &&
          guestFallbackMessages.isNotEmpty) {
        fallbackMessages = guestFallbackMessages;
      } else if (isProfileToProfileTransition) {
        fallbackMessages = const <NumAiChatMessage>[];
      } else {
        fallbackMessages = contextChangeBaseMessages;
      }
      emit(
        state.copyWith(
          messages: fallbackMessages,
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
    final List<String> guestCandidateKeys = await _resolveGuestCandidateKeys(
      guestUserKey: guestUserKey,
    );
    if (event.hasCloudSession && _cloudAccountRepository.isConfigured) {
      if (profileId.isNotEmpty) {
        await _tryMigrateGuestHistoryToCloud(
          profileId: profileId,
          guestCandidateKeys: guestCandidateKeys,
          isAnonymousUser: event.isAnonymousUser,
        );
        await _sendCloudMessage(
          event: event,
          emit: emit,
          message: message,
          profileId: profileId,
          isAnonymousUser: event.isAnonymousUser,
        );
        return;
      }

      await _sendGuestCloudMessage(
        event: event,
        emit: emit,
        message: message,
        guestUserKey: guestUserKey,
        guestCandidateKeys: guestCandidateKeys,
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
    required List<String> guestCandidateKeys,
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
          guestCandidateKeys: guestCandidateKeys,
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
    required bool isAnonymousUser,
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
      final result = await _runWithAnonymousAuthRecovery(
        isAnonymousUser: isAnonymousUser,
        action: () {
          return _cloudAccountRepository.sendNumAiMessage(
            profileId: profileId,
            messageText: message,
            threadId: threadIdForProfile,
            locale: event.locale,
          );
        },
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

  void completeTypingMessage(String messageId) {
    final String cleanMessageId = messageId.trim();
    if (cleanMessageId.isEmpty) {
      return;
    }
    add(NumAiChatTypingMessageCompleted(messageId: cleanMessageId));
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

  void _onTypingMessageCompleted(
    NumAiChatTypingMessageCompleted event,
    Emitter<NumAiChatState> emit,
  ) {
    final String activeTypingId = (state.typingMessageId ?? '').trim();
    if (activeTypingId.isEmpty || activeTypingId != event.messageId) {
      return;
    }
    emit(state.copyWith(clearTypingMessageId: true));
  }

  Future<void> _onConversationReset(
    NumAiChatConversationReset event,
    Emitter<NumAiChatState> emit,
  ) async {
    try {
      final String guestUserKey = _resolveGuestUserKey(event.cloudUserId);
      final List<String> candidateKeys = await _resolveGuestCandidateKeys(
        guestUserKey: guestUserKey,
      );
      await _clearGuestMessagesByKeys(candidateKeys);
      await _appSessionRepository.clearLastNumAiGuestUserKey();
    } catch (_) {}
    emit(NumAiChatState.initial());
  }

  static void _completeBool(Completer<bool> completer, bool value) {
    if (!completer.isCompleted) {
      completer.complete(value);
    }
  }

  String _resolveGuestUserKey(String? cloudUserId) {
    final String clean = _normalizeGuestKey(cloudUserId);
    if (clean.isEmpty) {
      return _canonicalGuestUserKey;
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
    required List<String> guestCandidateKeys,
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
    final Set<String> saveKeys = <String>{
      ...guestCandidateKeys.map(_normalizeGuestKey),
      _canonicalGuestUserKey,
      _normalizeGuestKey(guestUserKey),
    }..removeWhere((String key) => key.isEmpty);
    for (final String key in saveKeys) {
      await _appSessionRepository.saveNumAiGuestMessages(
        userKey: key,
        messages: payload,
      );
    }

    final String normalizedGuestKey = _normalizeGuestKey(guestUserKey);
    if (normalizedGuestKey.isNotEmpty &&
        normalizedGuestKey != _canonicalGuestUserKey) {
      await _appSessionRepository.saveLastNumAiGuestUserKey(
        userKey: normalizedGuestKey,
      );
    }
  }

  Future<void> _tryMigrateGuestHistoryToCloud({
    required String profileId,
    required List<String> guestCandidateKeys,
    required bool isAnonymousUser,
  }) async {
    if (profileId.isEmpty) {
      return;
    }
    try {
      final List<LocalNumAiGuestMessage> guestMessages =
          await _loadMergedGuestMessages(candidateKeys: guestCandidateKeys);
      if (guestMessages.isEmpty) {
        return;
      }

      final String requestSourceKey = guestCandidateKeys.isEmpty
          ? _canonicalGuestUserKey
          : guestCandidateKeys.join('|');
      final String requestId = _buildGuestImportRequestId(
        guestUserKey: requestSourceKey,
        profileId: profileId,
        messages: guestMessages,
      );
      await _runWithAnonymousAuthRecovery(
        isAnonymousUser: isAnonymousUser,
        action: () {
          return _cloudAccountRepository.importGuestNumAiHistory(
            profileId: profileId,
            messages: guestMessages,
            requestId: requestId,
          );
        },
      );
      await _clearGuestMessagesByKeys(guestCandidateKeys);
      await _appSessionRepository.clearLastNumAiGuestUserKey();
    } catch (_) {}
  }

  Future<CloudNumAiThreadMessagesResult> _fetchCloudHistoryWithRetry({
    required String profileId,
    required String? threadId,
    required bool isAnonymousUser,
  }) async {
    Object? lastError;
    for (int attempt = 0; attempt < _maxHistoryFetchAttempts; attempt += 1) {
      try {
        return await _runWithAnonymousAuthRecovery(
          isAnonymousUser: isAnonymousUser,
          action: () {
            return _cloudAccountRepository.fetchNumAiThreadMessages(
              profileId: profileId,
              threadId: threadId,
            );
          },
        );
      } catch (error) {
        lastError = error;
        if (attempt >= _maxHistoryFetchAttempts - 1) {
          break;
        }
        await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
      }
    }
    throw lastError ?? StateError('numai_history_fetch_failed');
  }

  Future<T> _runWithAnonymousAuthRecovery<T>({
    required bool isAnonymousUser,
    required Future<T> Function() action,
  }) async {
    try {
      return await action();
    } catch (error) {
      if (!isAnonymousUser || !_isUnauthorizedError(error)) {
        rethrow;
      }
      await _cloudAccountRepository.ensureAnonymousSession();
      return action();
    }
  }

  bool _isUnauthorizedError(Object error) {
    if (error is DioException && error.response?.statusCode == 401) {
      return true;
    }
    final String errorCode = _resolveErrorCode(error).toLowerCase();
    if (errorCode.contains('unauthorized') ||
        errorCode.contains('missing_authorization_header') ||
        errorCode.contains('invalid_authorization_header') ||
        errorCode.contains('supabase_missing_access_token') ||
        errorCode == '401') {
      return true;
    }
    final String message = error.toString().toLowerCase();
    return message.contains(' 401') ||
        message.contains('statuscode 401') ||
        message.contains('unauthorized');
  }

  Future<List<String>> _resolveGuestCandidateKeys({
    required String guestUserKey,
  }) async {
    final Set<String> keys = <String>{
      _canonicalGuestUserKey,
      _normalizeGuestKey(guestUserKey),
    }..removeWhere((String key) => key.isEmpty);
    try {
      final String? lastKey = await _appSessionRepository
          .loadLastNumAiGuestUserKey();
      final String normalizedLast = _normalizeGuestKey(lastKey);
      if (normalizedLast.isNotEmpty) {
        keys.add(normalizedLast);
      }
    } catch (_) {}
    return keys.toList();
  }

  Future<List<LocalNumAiGuestMessage>> _loadMergedGuestMessages({
    required List<String> candidateKeys,
  }) async {
    final Set<String> normalizedKeys = candidateKeys
        .map(_normalizeGuestKey)
        .where((String key) => key.isNotEmpty)
        .toSet();
    if (normalizedKeys.isEmpty) {
      normalizedKeys.add(_canonicalGuestUserKey);
    }

    final List<LocalNumAiGuestMessage> merged = <LocalNumAiGuestMessage>[];
    for (final String key in normalizedKeys) {
      try {
        final List<LocalNumAiGuestMessage> part = await _appSessionRepository
            .loadNumAiGuestMessages(userKey: key);
        merged.addAll(part);
      } catch (_) {}
    }
    return _dedupeGuestMessages(merged);
  }

  List<LocalNumAiGuestMessage> _dedupeGuestMessages(
    List<LocalNumAiGuestMessage> messages,
  ) {
    if (messages.isEmpty) {
      return const <LocalNumAiGuestMessage>[];
    }

    final List<LocalNumAiGuestMessage> sorted =
        List<LocalNumAiGuestMessage>.from(messages)
          ..sort((LocalNumAiGuestMessage left, LocalNumAiGuestMessage right) {
            final int byTime = left.createdAt.compareTo(right.createdAt);
            if (byTime != 0) {
              return byTime;
            }
            return left.id.compareTo(right.id);
          });

    final Set<String> seenIds = <String>{};
    final Set<String> seenFallbacks = <String>{};
    final List<LocalNumAiGuestMessage> unique = <LocalNumAiGuestMessage>[];
    for (final LocalNumAiGuestMessage item in sorted) {
      final String id = item.id.trim();
      if (id.isNotEmpty) {
        if (seenIds.contains(id)) {
          continue;
        }
        seenIds.add(id);
        unique.add(item);
        continue;
      }
      final String fallbackKey = _guestFallbackKey(item);
      if (seenFallbacks.contains(fallbackKey)) {
        continue;
      }
      seenFallbacks.add(fallbackKey);
      unique.add(item);
    }
    return unique;
  }

  String _guestFallbackKey(LocalNumAiGuestMessage item) {
    final String sender = item.senderType.trim().toLowerCase();
    final String text = item.messageText.trim().toLowerCase();
    final int roundedEpochMs =
        (item.createdAt.millisecondsSinceEpoch ~/ 1000) * 1000;
    return '$sender|$text|$roundedEpochMs';
  }

  Future<void> _clearGuestMessagesByKeys(List<String> keys) async {
    final Set<String> uniqueKeys =
        keys
            .map(_normalizeGuestKey)
            .where((String key) => key.isNotEmpty)
            .toSet()
          ..add(_canonicalGuestUserKey);
    for (final String key in uniqueKeys) {
      await _appSessionRepository.clearNumAiGuestMessages(userKey: key);
    }
  }

  String _normalizeGuestKey(String? raw) {
    return (raw ?? '').trim().toLowerCase();
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
