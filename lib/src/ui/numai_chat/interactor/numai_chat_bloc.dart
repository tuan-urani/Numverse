import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:test/src/ui/numai_chat/interactor/numai_chat_event.dart';
import 'package:test/src/ui/numai_chat/interactor/numai_chat_state.dart';

class NumAiChatBloc extends Bloc<NumAiChatEvent, NumAiChatState> {
  NumAiChatBloc() : super(NumAiChatState.initial()) {
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

  bool questionNeedsProfile(String question) {
    final String lowerQuestion = question.toLowerCase();

    const List<String> personalKeywords = <String>[
      'tôi',
      'mình',
      'em',
      'của tôi',
      'của mình',
      'của em',
      'bản thân',
      'con người tôi',
      'tính cách tôi',
      'số chủ đạo tôi',
      'số linh hồn tôi',
      'bộ số của tôi',
      'biểu đồ ngày sinh tôi',
      'biểu đồ của tôi',
      'năm nay tôi',
      'tháng này tôi',
      'hôm nay tôi',
      'công việc của tôi',
      'tình cảm của tôi',
      'sự nghiệp tôi',
      'tương hợp của tôi',
      'hợp với ai',
    ];

    final bool hasPersonalKeyword = personalKeywords.any(
      lowerQuestion.contains,
    );

    final List<RegExp> universalPatterns = <RegExp>[
      RegExp('số vũ trụ', caseSensitive: false),
      RegExp('số thiên thần', caseSensitive: false),
      RegExp('ý nghĩa (của )?số \\d', caseSensitive: false),
      RegExp('con số \\d', caseSensitive: false),
      RegExp('số \\d+ (là gì|có nghĩa|nghĩa là)', caseSensitive: false),
      RegExp('thần số học là gì', caseSensitive: false),
      RegExp('giải thích|khái niệm|định nghĩa', caseSensitive: false),
      RegExp('tìm hiểu về số', caseSensitive: false),
      RegExp('số may mắn hôm nay', caseSensitive: false),
    ];

    final bool isUniversalQuestion = universalPatterns.any(
      (RegExp pattern) => pattern.hasMatch(question),
    );

    if (isUniversalQuestion && !hasPersonalKeyword) {
      return false;
    }

    return hasPersonalKeyword;
  }

  Future<bool> sendMessage({
    required String rawMessage,
    required bool hasProfile,
    required DeductSoulPoints deductSoulPoints,
  }) async {
    final Completer<bool> completer = Completer<bool>();
    add(
      NumAiChatMessageSent(
        rawMessage: rawMessage,
        hasProfile: hasProfile,
        deductSoulPoints: deductSoulPoints,
        completer: completer,
      ),
    );
    return completer.future;
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
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 1500));

    final bool needsProfile = questionNeedsProfile(message);
    final bool shouldShowActionButton = needsProfile && !event.hasProfile;
    final DateTime replyAt = DateTime.now();

    final NumAiChatMessage assistantMessage = NumAiChatMessage(
      id: '${replyAt.microsecondsSinceEpoch}-assistant',
      role: NumAiChatMessageRole.assistant,
      content: _generateMockResponse(message, event.hasProfile),
      timestamp: replyAt,
      hasActionButton: shouldShowActionButton,
    );

    emit(
      state.copyWith(
        messages: <NumAiChatMessage>[...nextMessages, assistantMessage],
        isLoading: false,
        pendingProfileQuestion: shouldShowActionButton ? message : null,
        clearPendingProfileQuestion: !shouldShowActionButton,
      ),
    );
    _completeBool(event.completer, true);
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

  void resetConversation() {
    add(const NumAiChatConversationReset());
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
      content: _generateMockResponse(pendingQuestion, true),
      timestamp: now,
    );

    emit(
      state.copyWith(
        messages: <NumAiChatMessage>[...state.messages, response],
        clearPendingProfileQuestion: true,
      ),
    );
  }

  void _onConversationReset(
    NumAiChatConversationReset event,
    Emitter<NumAiChatState> emit,
  ) {
    emit(NumAiChatState.initial());
  }

  static void _completeBool(Completer<bool> completer, bool value) {
    if (!completer.isCompleted) {
      completer.complete(value);
    }
  }

  String _generateMockResponse(String question, bool hasProfile) {
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

    if (!hasProfile) {
      return 'Để trả lời câu hỏi cá nhân này, tôi cần thêm thông tin của bạn.\n\n'
          'Hãy nhập họ tên và ngày sinh để tôi phân tích theo bộ số thần số học '
          'cá nhân hóa.';
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
        '${hasProfile ? 'Dựa trên hồ sơ hiện tại, câu hỏi này liên quan đến định hướng phát triển cá nhân và cách bạn cân bằng cảm xúc với hành động.' : 'Nếu bạn muốn phân tích cá nhân hóa, hãy nhập thông tin hồ sơ.'}\n\n'
        'Bạn có muốn mình đi sâu vào một khía cạnh cụ thể hơn không?';
  }
}
