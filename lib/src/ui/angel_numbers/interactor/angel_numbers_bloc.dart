import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:test/src/core/model/numerology_content_models.dart';
import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/ui/angel_numbers/interactor/angel_numbers_event.dart';
import 'package:test/src/ui/angel_numbers/interactor/angel_numbers_state.dart';

class AngelNumbersBloc extends Bloc<AngelNumbersEvent, AngelNumbersState> {
  AngelNumbersBloc({
    required INumerologyContentRepository contentRepository,
    required String languageCode,
  }) : _contentRepository = contentRepository,
       _languageCode = languageCode,
       super(
         AngelNumbersState.initial(
           popularNumbers: contentRepository.getAngelNumberPopularNumbers(
             languageCode: languageCode,
           ),
         ),
       ) {
    on<AngelNumbersSearchTextChanged>(_onSearchTextChanged);
    on<AngelNumbersSearchRequested>(_onSearchRequested);
    on<AngelNumbersQuickSearchRequested>(_onQuickSearchRequested);
  }

  static final RegExp _digitsOnly = RegExp(r'^\d+$');
  final INumerologyContentRepository _contentRepository;
  final String _languageCode;

  void onSearchTextChanged(String value) {
    add(AngelNumbersSearchTextChanged(value));
  }

  void onSearch() {
    add(const AngelNumbersSearchRequested());
  }

  void onQuickSearch(String number) {
    add(AngelNumbersQuickSearchRequested(number));
  }

  void _onSearchTextChanged(
    AngelNumbersSearchTextChanged event,
    Emitter<AngelNumbersState> emit,
  ) {
    emit(state.copyWith(searchText: event.value, showInputError: false));
  }

  void _onSearchRequested(
    AngelNumbersSearchRequested event,
    Emitter<AngelNumbersState> emit,
  ) {
    _search(state.searchText, clearInput: true, emit: emit);
  }

  void _onQuickSearchRequested(
    AngelNumbersQuickSearchRequested event,
    Emitter<AngelNumbersState> emit,
  ) {
    final String number = event.number;
    emit(state.copyWith(searchText: number, showInputError: false));
    _search(number, clearInput: false, emit: emit);
  }

  void _search(
    String rawNumber, {
    required bool clearInput,
    required Emitter<AngelNumbersState> emit,
  }) {
    final String number = rawNumber.trim();
    if (!_isValidSearchNumber(number)) {
      emit(state.copyWith(showInputError: true));
      return;
    }

    final AngelNumberMeaning result = _getAngelNumberMeaning(number);
    emit(
      state.copyWith(
        displayNumber: number,
        result: result,
        hasSearched: true,
        searchText: clearInput ? '' : number,
        showInputError: false,
      ),
    );
  }

  bool _isValidSearchNumber(String number) {
    if (number.isEmpty) {
      return false;
    }
    if (!_digitsOnly.hasMatch(number)) {
      return false;
    }
    return number.length >= 2 && number.length <= 4;
  }

  AngelNumberMeaning _getAngelNumberMeaning(String number) {
    final NumerologyAngelNumberContent? knownContent = _contentRepository
        .findAngelNumberContent(number: number, languageCode: _languageCode);
    if (knownContent != null) {
      return AngelNumberMeaning(
        title: knownContent.title,
        coreMeanings: knownContent.coreMeanings,
        universeMessages: knownContent.universeMessages,
        guidance: knownContent.guidance,
      );
    }

    return _generateMeaning(number);
  }

  static const Map<String, _BasicDigitMeaning> _basicMeanings =
      <String, _BasicDigitMeaning>{
        '1': _BasicDigitMeaning(
          keyword: 'khởi đầu và lãnh đạo',
          energy: 'độc lập, sáng tạo, hành động',
        ),
        '2': _BasicDigitMeaning(
          keyword: 'hợp tác và cân bằng',
          energy: 'đối tác, hòa hợp, nhạy cảm',
        ),
        '3': _BasicDigitMeaning(
          keyword: 'sáng tạo và giao tiếp',
          energy: 'biểu đạt, vui vẻ, nghệ thuật',
        ),
        '4': _BasicDigitMeaning(
          keyword: 'nền tảng và kỷ luật',
          energy: 'tổ chức, ổn định, thực tế',
        ),
        '5': _BasicDigitMeaning(
          keyword: 'tự do và thay đổi',
          energy: 'phiêu lưu, linh hoạt, khám phá',
        ),
        '6': _BasicDigitMeaning(
          keyword: 'trách nhiệm và chăm sóc',
          energy: 'gia đình, yêu thương, phục vụ',
        ),
        '7': _BasicDigitMeaning(
          keyword: 'trí tuệ và tâm linh',
          energy: 'suy ngẫm, học hỏi, nội tâm',
        ),
        '8': _BasicDigitMeaning(
          keyword: 'quyền lực và thành công',
          energy: 'thành tựu, tài chính, vật chất',
        ),
        '9': _BasicDigitMeaning(
          keyword: 'hoàn thành và từ bi',
          energy: 'kết thúc, nhân văn, tha thứ',
        ),
      };
  static const _BasicDigitMeaning _fallbackBasicMeaning = _BasicDigitMeaning(
    keyword: 'khởi đầu và lãnh đạo',
    energy: 'độc lập, sáng tạo, hành động',
  );

  AngelNumberMeaning _generateMeaning(String number) {
    final int digitRoot = _calculateDigitRoot(number);
    final bool isRepeating = _isRepeatingDigit(number);
    final List<String> uniqueDigits = _getUniqueDigits(number);
    final _BasicDigitMeaning rootMeaning = _digitMeaning('$digitRoot');

    if (isRepeating) {
      final _BasicDigitMeaning repeatedMeaning = _digitMeaning(number[0]);
      final String intensity = switch (number.length) {
        >= 4 => 'cực kỳ mạnh mẽ',
        3 => 'mạnh mẽ',
        _ => 'đáng kể',
      };

      return AngelNumberMeaning(
        title: 'Năng lượng ${repeatedMeaning.keyword} $intensity',
        coreMeanings: <String>[
          'Chuỗi lặp $number khuếch đại năng lượng ${repeatedMeaning.keyword}.',
          'Từ khóa trọng tâm: ${repeatedMeaning.energy}.',
          'Mức cường độ hiện tại: $intensity.',
        ],
        universeMessages: <String>[
          'Hãy đồng bộ suy nghĩ, cảm xúc và hành động trước khi quyết định.',
          'Điều bạn tập trung lúc này có xu hướng thành hiện thực nhanh hơn.',
          'Vũ trụ đang nhắc bạn tin vào năng lượng ${repeatedMeaning.keyword}.',
        ],
        guidance: <String>[
          'Hãy tập trung vào các khía cạnh liên quan đến ${repeatedMeaning.keyword}',
          'Năng lượng này đang ${intensity.toLowerCase()} trong cuộc sống bạn - hãy tận dụng nó',
          'Tin tưởng vào sự dẫn dắt của vũ trụ về ${repeatedMeaning.energy}',
          'Hãy tin tưởng rằng bạn đang nhận được sự dẫn dắt từ vũ trụ',
        ],
      );
    }

    final _BasicDigitMeaning firstMeaning = _digitMeaning(number[0]);
    final _BasicDigitMeaning lastMeaning = _digitMeaning(
      number[number.length - 1],
    );

    return AngelNumberMeaning(
      title: 'Hành trình từ ${firstMeaning.keyword} đến ${lastMeaning.keyword}',
      coreMeanings: <String>[
        'Sự kết hợp của các số ${uniqueDigits.join(', ')} tạo nên trường năng lượng đa chiều.',
        'Hành trình phát triển đi từ ${firstMeaning.keyword} đến ${lastMeaning.keyword}.',
        'Gốc rút gọn $digitRoot đại diện cho ${rootMeaning.keyword}.',
      ],
      universeMessages: <String>[
        'Vũ trụ khuyến khích bạn tích hợp các phẩm chất khác nhau thành một hướng đi rõ ràng.',
        'Khi duy trì cân bằng, bạn sẽ mở thêm cơ hội phù hợp với bản thân.',
        'Tin vào trực giác khi cần lựa chọn giữa nhiều hướng.',
      ],
      guidance: <String>[
        'Hãy cân bằng giữa ${firstMeaning.keyword} và ${lastMeaning.keyword}',
        'Tập trung vào năng lượng cốt lõi: ${rootMeaning.energy}',
        'Đây là thời điểm để tích hợp nhiều mặt khác nhau của bản thân',
        'Hãy tin tưởng rằng bạn đang nhận được sự dẫn dắt từ vũ trụ',
      ],
    );
  }

  int _calculateDigitRoot(String value) {
    int sum = value.split('').map(int.parse).reduce((int a, int b) => a + b);
    while (sum > 9) {
      sum = sum.toString().split('').map(int.parse).reduce((int a, int b) {
        return a + b;
      });
    }
    return sum;
  }

  bool _isRepeatingDigit(String value) {
    return value.split('').every((String digit) => digit == value[0]);
  }

  List<String> _getUniqueDigits(String value) {
    final Set<String> seen = <String>{};
    final List<String> result = <String>[];
    for (final String digit in value.split('')) {
      if (seen.add(digit)) {
        result.add(digit);
      }
    }
    return result;
  }

  _BasicDigitMeaning _digitMeaning(String digit) {
    return _basicMeanings[digit] ?? _fallbackBasicMeaning;
  }
}

class _BasicDigitMeaning {
  const _BasicDigitMeaning({required this.keyword, required this.energy});

  final String keyword;
  final String energy;
}
