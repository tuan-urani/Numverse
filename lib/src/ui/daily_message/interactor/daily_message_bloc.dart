import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/ui/daily_message/interactor/daily_message_event.dart';
import 'package:test/src/ui/daily_message/interactor/daily_message_state.dart';

class DailyMessageBloc extends Bloc<DailyMessageEvent, DailyMessageState> {
  DailyMessageBloc({
    required INumerologyContentRepository contentRepository,
    required String languageCode,
    required int Function() dayNumberProvider,
    DateTime Function()? nowProvider,
  }) : _contentRepository = contentRepository,
       _languageCode = languageCode,
       _dayNumberProvider = dayNumberProvider,
       _nowProvider = nowProvider ?? DateTime.now,
       super(
         _buildState(
           now: (nowProvider ?? DateTime.now)(),
           contentRepository: contentRepository,
           languageCode: languageCode,
           dayNumber: dayNumberProvider(),
         ),
       ) {
    on<DailyMessageRefreshed>(_onRefreshed);
  }

  final INumerologyContentRepository _contentRepository;
  final String _languageCode;
  final int Function() _dayNumberProvider;
  final DateTime Function() _nowProvider;

  void refresh() {
    add(const DailyMessageRefreshed());
  }

  void _onRefreshed(
    DailyMessageRefreshed event,
    Emitter<DailyMessageState> emit,
  ) {
    emit(
      _buildState(
        now: _nowProvider(),
        contentRepository: _contentRepository,
        languageCode: _languageCode,
        dayNumber: _dayNumberProvider(),
      ),
    );
  }

  static DailyMessageState _buildState({
    required DateTime now,
    required INumerologyContentRepository contentRepository,
    required String languageCode,
    required int dayNumber,
  }) {
    final int dayOfYear = _getDayOfYear(now);
    final template = contentRepository.getDailyMessageTemplate(
      number: dayNumber,
      dayOfYear: dayOfYear,
      languageCode: languageCode,
    );

    return DailyMessageState(
      formattedDate: _formatDate(now, languageCode),
      dayNumber: dayNumber,
      mainMessage: template.mainMessage,
      subMessage: template.subMessage,
      hintAction: template.hintAction,
      thinking: template.thinking,
      tips: template.tips,
    );
  }

  static int _getDayOfYear(DateTime date) {
    final DateTime startOfYear = DateTime(date.year, 1, 0);
    return date.difference(startOfYear).inDays;
  }

  static String _formatDate(DateTime date, String languageCode) {
    final String locale = switch (languageCode.toLowerCase()) {
      'vi' => 'vi_VN',
      'en' => 'en_US',
      'ja' => 'ja_JP',
      _ => 'en_US',
    };

    try {
      return DateFormat('EEEE, d MMMM, y', locale).format(date).toLowerCase();
    } catch (_) {
      return DateFormat('EEEE, d MMMM, y').format(date);
    }
  }
}
