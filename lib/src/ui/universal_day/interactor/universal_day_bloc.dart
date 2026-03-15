import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/helper/numerology_helper.dart';
import 'package:test/src/ui/universal_day/interactor/universal_day_event.dart';
import 'package:test/src/ui/universal_day/interactor/universal_day_state.dart';

class UniversalDayBloc extends Bloc<UniversalDayEvent, UniversalDayState> {
  UniversalDayBloc({
    required INumerologyContentRepository contentRepository,
    required String languageCode,
    DateTime Function()? nowProvider,
  }) : _contentRepository = contentRepository,
       _languageCode = languageCode,
       _nowProvider = nowProvider ?? DateTime.now,
       super(
         _buildState(
           now: (nowProvider ?? DateTime.now)(),
           contentRepository: contentRepository,
           languageCode: languageCode,
         ),
       ) {
    on<UniversalDayRefreshed>(_onRefreshed);
  }

  final INumerologyContentRepository _contentRepository;
  final String _languageCode;
  final DateTime Function() _nowProvider;

  void refresh() {
    add(const UniversalDayRefreshed());
  }

  void _onRefreshed(
    UniversalDayRefreshed event,
    Emitter<UniversalDayState> emit,
  ) {
    emit(
      _buildState(
        now: _nowProvider(),
        contentRepository: _contentRepository,
        languageCode: _languageCode,
      ),
    );
  }

  static UniversalDayState _buildState({
    required DateTime now,
    required INumerologyContentRepository contentRepository,
    required String languageCode,
  }) {
    final int dayNumber = NumerologyHelper.calculateUniversalDayNumber(now);
    final content = contentRepository.getUniversalDayContent(
      number: dayNumber,
      languageCode: languageCode,
    );

    return UniversalDayState(
      formattedDate: _formatDate(now, languageCode),
      dayNumber: dayNumber,
      numberTitle: content.title,
      energyTheme: content.energyTheme,
      keywords: content.keywords,
      meaning: content.meaning,
      energyManifestation: content.energyManifestation,
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
      return DateFormat('EEEE, d MMMM, y', locale).format(date).toLowerCase();
    } catch (_) {
      return DateFormat('EEEE, d MMMM, y').format(date);
    }
  }
}
