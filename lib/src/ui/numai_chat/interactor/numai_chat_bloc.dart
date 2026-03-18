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
          ),
        );
      } catch (_) {
        emit(
          state.copyWith(
            isLoading: false,
            clearThreadId: true,
            clearActiveProfileId: true,
          ),
        );
      }
      return;
    }

    if (!event.hasCloudSession || !_cloudAccountRepository.isConfigured) {
      emit(state.copyWith(isLoading: false, activeProfileId: profileId));
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
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoading: false, activeProfileId: profileId));
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

    final bool canDeduct = await event.deductSoulPoints(messageCost);
    if (!canDeduct) {
      emit(state.copyWith(showInsufficientPointsWarning: true));
      _completeBool(event.completer, false);
      return;
    }

    final DateTime now = DateTime.now();
    final NumAiChatMessage userMessage = NumAiChatMessage(
      id: '${now.microsecondsSinceEpoch}-user',
      role: NumAiChatMessageRole.user,
      content: message,
      timestamp: now,
    );

    final List<NumAiChatMessage> nextMessages = <NumAiChatMessage>[
      ...state.messages,
      userMessage,
    ];

    emit(
      state.copyWith(
        messages: nextMessages,
        isLoading: true,
        showInsufficientPointsWarning: false,
        activeProfileId: profileId.isEmpty ? null : profileId,
        clearThreadId: profileId.isEmpty,
        clearActiveProfileId: profileId.isEmpty,
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 1500));

    final DateTime replyAt = DateTime.now();

    final NumAiChatMessage assistantMessage = NumAiChatMessage(
      id: '${replyAt.microsecondsSinceEpoch}-assistant',
      role: NumAiChatMessageRole.assistant,
      content: _generateMockResponse(message),
      timestamp: replyAt,
    );

    emit(
      state.copyWith(
        messages: <NumAiChatMessage>[...nextMessages, assistantMessage],
        isLoading: false,
        clearPendingProfileQuestion: true,
        activeProfileId: profileId.isEmpty ? null : profileId,
        clearThreadId: profileId.isEmpty,
        clearActiveProfileId: profileId.isEmpty,
      ),
    );
    if (profileId.isEmpty) {
      await _persistGuestMessages(
        guestUserKey: guestUserKey,
        messages: <NumAiChatMessage>[...nextMessages, assistantMessage],
      );
    }
    _completeBool(event.completer, true);
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
        followUpSuggestions: result.suggestions,
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

      final DateTime now = DateTime.now();
      final NumAiChatMessage assistantFallback = NumAiChatMessage(
        id: '${now.microsecondsSinceEpoch}-assistant-fallback',
        role: NumAiChatMessageRole.assistant,
        content: _generateMockResponse(message),
        timestamp: now,
      );
      final List<NumAiChatMessage> fallbackMessages = <NumAiChatMessage>[
        ...nextMessages,
        assistantFallback,
      ];
      emit(
        state.copyWith(
          messages: fallbackMessages,
          isLoading: false,
          clearPendingProfileQuestion: true,
          clearThreadId: true,
          clearActiveProfileId: true,
        ),
      );
      try {
        await _persistGuestMessages(
          guestUserKey: guestUserKey,
          messages: fallbackMessages,
        );
      } catch (_) {}
      _completeBool(event.completer, true);
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
        followUpSuggestions: result.suggestions,
      );
      emit(
        state.copyWith(
          messages: <NumAiChatMessage>[...nextMessages, assistantMessage],
          isLoading: false,
          clearPendingProfileQuestion: true,
          threadId: result.threadId.isEmpty ? null : result.threadId,
          activeProfileId: profileId,
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

      if (errorCode == 'profile_not_found' ||
          errorCode == 'primary_profile_not_found') {
        final DateTime now = DateTime.now();
        final NumAiChatMessage assistantMessage = NumAiChatMessage(
          id: '${now.microsecondsSinceEpoch}-assistant-fallback',
          role: NumAiChatMessageRole.assistant,
          content: _generateMockResponse(message),
          timestamp: now,
        );
        emit(
          state.copyWith(
            messages: <NumAiChatMessage>[
              ...previousMessages,
              userMessage,
              assistantMessage,
            ],
            isLoading: false,
            clearPendingProfileQuestion: true,
            activeProfileId: profileId,
          ),
        );
        _completeBool(event.completer, true);
        return;
      }

      try {
        final history = await _cloudAccountRepository.fetchNumAiThreadMessages(
          profileId: profileId,
          threadId: threadIdForProfile,
        );
        emit(
          state.copyWith(
            messages: _sortMessagesByTimestamp(
              history.messages.map(_toChatMessageFromCloud),
            ),
            isLoading: false,
            threadId: history.threadId.isEmpty ? null : history.threadId,
            activeProfileId: profileId,
          ),
        );
      } catch (_) {
        emit(
          state.copyWith(
            messages: previousMessages,
            isLoading: false,
            activeProfileId: profileId,
          ),
        );
      }
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
    final String? pendingQuestion = state.pendingProfileQuestion;
    if (pendingQuestion == null) {
      return;
    }

    final DateTime now = DateTime.now();
    final NumAiChatMessage response = NumAiChatMessage(
      id: '${now.microsecondsSinceEpoch}-assistant-profile',
      role: NumAiChatMessageRole.assistant,
      content: _generateMockResponse(pendingQuestion),
      timestamp: now,
    );

    emit(
      state.copyWith(
        messages: <NumAiChatMessage>[...state.messages, response],
        clearPendingProfileQuestion: true,
      ),
    );
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
      followUpSuggestions: item.followUpSuggestions,
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
      followUpSuggestions: item.followUpSuggestions,
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

  String _generateMockResponse(String question) {
    final String lowerQuestion = question.toLowerCase();

    if (lowerQuestion.contains('số vũ trụ')) {
      return 'Số vũ trụ hôm nay là 7.\n\n'
          'Ý nghĩa:\n'
          'Ngày hôm nay mang năng lượng của sự tĩnh lặng, nội tâm và trí tuệ. '
          'Đây là thời điểm tốt để suy ngẫm, học hỏi và dành thời gian một mình '
          'để nạp năng lượng.\n\n'
          'Hãy tránh quyết định quá vội và tin vào trực giác của bạn.';
    }

    if (lowerQuestion.contains('số thiên thần')) {
      return 'Số thiên thần là những chuỗi số lặp lại xuất hiện như thông điệp.\n\n'
          'Ví dụ phổ biến:\n'
          '111: Cơ hội mới\n'
          '222: Cân bằng\n'
          '333: Được hỗ trợ\n'
          '444: Nền tảng ổn định\n'
          '555: Biến đổi mạnh\n\n'
          'Bạn có thể xem thêm trong tab Hôm nay.';
    }

    if (RegExp(
      'ý nghĩa (của )?số \\d',
      caseSensitive: false,
    ).hasMatch(lowerQuestion)) {
      final RegExpMatch? match = RegExp('\\d+').firstMatch(lowerQuestion);
      final String number = match?.group(0) ?? '1';
      return 'Số $number mang một tần số năng lượng riêng trong thần số học.\n\n'
          'Bạn có thể tra cứu sâu hơn trong Thư viện con số để xem điểm mạnh, '
          'thử thách và cách ứng dụng vào đời sống thực tế.';
    }

    if (lowerQuestion.contains('tóm tắt') ||
        lowerQuestion.contains('người thế nào')) {
      return 'Từ hồ sơ của bạn, tôi thấy bạn có nội tâm sâu, trực giác tốt và '
          'xu hướng tìm ý nghĩa trong mọi trải nghiệm.\n\n'
          'Bạn mạnh ở khả năng quan sát, tư duy chiến lược và kết nối cảm xúc '
          'khi làm việc hoặc trong mối quan hệ gần gũi.';
    }

    if (lowerQuestion.contains('hôm nay') &&
        (lowerQuestion.contains('tôi') || lowerQuestion.contains('mình'))) {
      return 'Hôm nay bạn nên ưu tiên sự linh hoạt và chủ động.\n\n'
          'Nên làm:\n'
          '• Mở rộng kết nối\n'
          '• Thử một cách tiếp cận mới\n'
          '• Dành thời gian rà soát cảm xúc trước khi quyết định lớn\n\n'
          'Nên tránh:\n'
          '• Cố kiểm soát mọi thứ theo khuôn cũ\n'
          '• Trì hoãn các cơ hội nhỏ nhưng có tiềm năng.';
    }

    if (lowerQuestion.contains('tương hợp') ||
        lowerQuestion.contains('hợp ở đâu')) {
      return 'Để phân tích tương hợp chính xác, tôi cần thông tin của người bạn '
          'muốn so sánh (tên + ngày sinh).\n\n'
          'Sau đó tôi có thể trả về: mức độ hòa hợp cốt lõi, giao tiếp, cảm xúc '
          'và gợi ý hành động cho hai bên.';
    }

    return 'Đây là một câu hỏi thú vị trong thần số học.\n\n'
        'Dựa trên ngữ cảnh hiện tại, câu hỏi này liên quan đến định hướng '
        'phát triển cá nhân và cách bạn cân bằng cảm xúc với hành động.\n\n'
        'Bạn có muốn mình đi sâu vào một khía cạnh cụ thể hơn không?';
  }
}
