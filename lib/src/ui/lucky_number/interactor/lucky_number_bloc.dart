import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/ui/lucky_number/interactor/lucky_number_event.dart';
import 'package:test/src/ui/lucky_number/interactor/lucky_number_state.dart';

class LuckyNumberBloc extends Bloc<LuckyNumberEvent, LuckyNumberState> {
  LuckyNumberBloc({
    required INumerologyContentRepository contentRepository,
    required String languageCode,
    required int Function() luckyNumberProvider,
    DateTime Function()? nowProvider,
  }) : _contentRepository = contentRepository,
       _languageCode = languageCode,
       _luckyNumberProvider = luckyNumberProvider,
       _nowProvider = nowProvider ?? DateTime.now,
       super(
         _buildState(
           now: (nowProvider ?? DateTime.now)(),
           contentRepository: contentRepository,
            languageCode: languageCode,
            luckyNumber: luckyNumberProvider(),
          ),
        ) {
    on<LuckyNumberRefreshed>(_onRefreshed);
  }

  final INumerologyContentRepository _contentRepository;
  final String _languageCode;
  final int Function() _luckyNumberProvider;
  final DateTime Function() _nowProvider;

  void refresh() {
    add(const LuckyNumberRefreshed());
  }

  void _onRefreshed(
    LuckyNumberRefreshed event,
    Emitter<LuckyNumberState> emit,
  ) {
    emit(
      _buildState(
        now: _nowProvider(),
        contentRepository: _contentRepository,
        languageCode: _languageCode,
        luckyNumber: _luckyNumberProvider(),
      ),
    );
  }

  static LuckyNumberState _buildState({
    required DateTime now,
    required INumerologyContentRepository contentRepository,
    required String languageCode,
    required int luckyNumber,
  }) {
    final content = contentRepository.getLuckyNumberContent(
      number: luckyNumber,
      languageCode: languageCode,
    );

    return LuckyNumberState(
      formattedDate: _formatDate(now, languageCode),
      luckyNumber: luckyNumber,
      title: content.title,
      message: content.message,
      meaning: content.meaning,
      howToUse: content.howToUse,
      situations: content.situations,
    );
  }

  static String _formatDate(DateTime date, String languageCode) {
    final String locale = switch (languageCode.toLowerCase()) {
      'vi' => 'vi_VN',
      'en' => 'en_US',
      'ja' => 'ja_JP',
      _ => 'en_US',
    };

    try {
      return DateFormat('EEEE, d MMMM', locale).format(date).toLowerCase();
    } catch (_) {
      return DateFormat('EEEE, d MMMM').format(date);
    }
  }
}
