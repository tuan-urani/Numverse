import 'package:test/src/core/model/numerology_reading_models.dart';
import 'package:test/src/helper/numerology_reading_data.dart';

class NumerologyHelper {
  NumerologyHelper._();

  static const List<int> _masterNumbers = <int>[11, 22, 33];

  static int calculateUniversalDayNumber([DateTime? date]) {
    final DateTime now = date ?? DateTime.now();
    final int sum = now.day + now.month + now.year;
    return reduceToSingleDigit(sum);
  }

  static int calculateUniversalYearNumber([DateTime? date]) {
    final DateTime now = date ?? DateTime.now();
    return reduceToSingleDigit(now.year);
  }

  static int calculateUniversalMonthNumber([DateTime? date]) {
    final DateTime now = date ?? DateTime.now();
    final int universalYear = calculateUniversalYearNumber(now);
    return reduceToSingleDigit(universalYear + now.month);
  }

  static int luckyNumber([DateTime? date]) {
    final DateTime now = date ?? DateTime.now();
    final int seed = now.day + now.month + now.year;
    return (seed % 9) + 1;
  }

  static int reduceToSingleDigit(int value, {bool preserveMaster = false}) {
    int result = value.abs();
    while (result > 9) {
      if (preserveMaster && _masterNumbers.contains(result)) {
        return result;
      }
      result = _sumDigits(result);
    }
    return result;
  }

  static String dailyMessage(int number) {
    final Map<int, List<String>> messages = <int, List<String>>{
      1: <String>[
        'Hôm nay, hãy dám mở một cánh cửa mới cho chính mình.',
        'Chủ động và tự tin sẽ mang lại đột phá.',
      ],
      2: <String>[
        'Lắng nghe sâu hơn để hiểu đúng hơn.',
        'Hợp tác đúng người sẽ tạo ra lực đẩy lớn.',
      ],
      3: <String>[
        'Biểu đạt chân thật là món quà của hôm nay.',
        'Niềm vui và sáng tạo sẽ mở lối.',
      ],
      4: <String>[
        'Kỷ luật nhỏ tạo nên kết quả lớn.',
        'Hoàn tất việc dang dở trước khi mở việc mới.',
      ],
      5: <String>[
        'Thay đổi là lời mời nâng cấp bản thân.',
        'Giữ linh hoạt và đón cơ hội mới.',
      ],
      6: <String>[
        'Sự chăm sóc chân thành sẽ quay lại gấp bội.',
        'Nuôi dưỡng các mối quan hệ quan trọng.',
      ],
      7: <String>[
        'Khoảng lặng sẽ cho bạn câu trả lời rõ nhất.',
        'Ưu tiên học sâu thay vì làm nhanh.',
      ],
      8: <String>[
        'Mục tiêu lớn cần hành động dứt khoát hôm nay.',
        'Tập trung vào kết quả đo được.',
      ],
      9: <String>[
        'Buông điều cũ để đón chương mới.',
        'Lòng từ bi giúp bạn thấy bức tranh rộng hơn.',
      ],
      11: <String>[
        'Trực giác hôm nay rất rõ, hãy tin vào nó.',
        'Bạn đang được dẫn dắt đến bước tiến đúng.',
      ],
      22: <String>[
        'Nghĩ lớn và hành động có kế hoạch.',
        'Hôm nay phù hợp để xây nền cho mục tiêu dài hạn.',
      ],
      33: <String>[
        'Tình yêu vô điều kiện là sức mạnh chủ đạo hôm nay.',
        'Chữa lành bắt đầu từ sự hiện diện chân thành.',
      ],
    };

    final List<String> set = messages[number] ?? messages[1]!;
    final int index = DateTime.now().day % set.length;
    return set[index];
  }

  static int getLifePathNumber(DateTime birthDate) {
    final int day = reduceToSingleDigit(birthDate.day);
    final int month = reduceToSingleDigit(birthDate.month);
    final int year = reduceToSingleDigit(birthDate.year);

    final int total = day + month + year;
    return reduceToSingleDigit(total, preserveMaster: true);
  }

  static int getExpressionNumber(String fullName) {
    final String normalizedName = _normalizeName(fullName);

    int sum = 0;
    for (final String char in normalizedName.split('')) {
      final int? value = _letterValue(char);
      if (value != null) {
        sum += value;
      }
    }

    return reduceToSingleDigit(sum);
  }

  static int getSoulUrgeNumber(String fullName) {
    final Set<String> vowels = <String>{'A', 'E', 'I', 'O', 'U'};
    final String normalizedName = _normalizeName(fullName);

    int sum = 0;
    for (final String char in normalizedName.split('')) {
      if (!vowels.contains(char)) {
        continue;
      }
      final int? value = _letterValue(char);
      if (value != null) {
        sum += value;
      }
    }

    return reduceToSingleDigit(sum);
  }

  static int getPersonalityNumber(String fullName) {
    final Set<String> vowels = <String>{'A', 'E', 'I', 'O', 'U'};
    final String normalizedName = _normalizeName(fullName);

    int sum = 0;
    for (final String char in normalizedName.split('')) {
      if (vowels.contains(char)) {
        continue;
      }
      final int? value = _letterValue(char);
      if (value != null) {
        sum += value;
      }
    }

    return reduceToSingleDigit(sum);
  }

  static int getMissionNumber(DateTime birthDate, String fullName) {
    final int lifePathNumber = getLifePathNumber(birthDate);
    final int expressionNumber = getExpressionNumber(fullName);

    return reduceToSingleDigit(lifePathNumber + expressionNumber);
  }

  static int calculatePersonalYearNumber({
    required DateTime birthDate,
    DateTime? date,
  }) {
    final DateTime targetDate = date ?? DateTime.now();
    final int birthDay = reduceToSingleDigit(birthDate.day);
    final int birthMonth = reduceToSingleDigit(birthDate.month);
    final int currentYear = reduceToSingleDigit(targetDate.year);
    return reduceToSingleDigit(birthDay + birthMonth + currentYear);
  }

  static int calculatePersonalMonthNumber({
    required DateTime birthDate,
    DateTime? date,
  }) {
    final DateTime targetDate = date ?? DateTime.now();
    final int personalYear = calculatePersonalYearNumber(
      birthDate: birthDate,
      date: targetDate,
    );
    return reduceToSingleDigit(personalYear + targetDate.month);
  }

  static int calculatePersonalDayNumber({
    required DateTime birthDate,
    DateTime? date,
  }) {
    final DateTime targetDate = date ?? DateTime.now();
    final int personalMonth = calculatePersonalMonthNumber(
      birthDate: birthDate,
      date: targetDate,
    );
    return reduceToSingleDigit(personalMonth + targetDate.day);
  }

  static CoreNumberContent getLifePathContent(int number) {
    return _contentByNumber(number, NumerologyReadingData.lifePath);
  }

  static CoreNumberContent getSoulUrgeContent(int number) {
    return _contentByNumber(number, NumerologyReadingData.soulUrge);
  }

  static CoreNumberContent getPersonalityContent(int number) {
    return _contentByNumber(number, NumerologyReadingData.personality);
  }

  static CoreNumberContent getMissionContent(int number) {
    return _contentByNumber(number, NumerologyReadingData.mission);
  }

  static BirthChartDataSet get birthChartData =>
      NumerologyReadingData.birthChart;

  static BirthChartGrid calculateBirthChart(DateTime birthDate) {
    final String dateString =
        '${birthDate.day}${birthDate.month}${birthDate.year}';

    final Map<int, int> numbers = <int, int>{for (int i = 1; i <= 9; i++) i: 0};

    for (final String char in dateString.split('')) {
      final int? digit = int.tryParse(char);
      if (digit == null || digit < 1 || digit > 9) {
        continue;
      }
      numbers[digit] = (numbers[digit] ?? 0) + 1;
    }

    return _buildChartGrid(numbers);
  }

  static BirthChartGrid calculateNameChart(String fullName) {
    final String normalizedName = _normalizeName(fullName);

    final Map<int, int> numbers = <int, int>{for (int i = 1; i <= 9; i++) i: 0};

    for (final String char in normalizedName.split('')) {
      final int? value = _letterValue(char);
      if (value == null) {
        continue;
      }
      numbers[value] = (numbers[value] ?? 0) + 1;
    }

    return _buildChartGrid(numbers);
  }

  static BirthChartAxes analyzeBirthChartAxes(BirthChartGrid chart) {
    ChartAxisScore score(List<int> axisNumbers) {
      final int count = axisNumbers
          .where((int value) => (chart.numbers[value] ?? 0) > 0)
          .length;
      return ChartAxisScore(
        present: count == 3,
        numbers: axisNumbers,
        count: count,
      );
    }

    return BirthChartAxes(
      physical: score(const <int>[1, 4, 7]),
      mental: score(const <int>[3, 6, 9]),
      emotional: score(const <int>[2, 5, 8]),
    );
  }

  static BirthChartArrows analyzeBirthChartArrows(BirthChartGrid chart) {
    bool hasPattern(List<int> pattern) {
      return pattern.every((int number) => (chart.numbers[number] ?? 0) > 0);
    }

    return BirthChartArrows(
      determination: ChartArrowPattern(
        present: hasPattern(const <int>[3, 5, 7]),
        numbers: const <int>[3, 5, 7],
      ),
      planning: ChartArrowPattern(
        present: hasPattern(const <int>[1, 2, 3]),
        numbers: const <int>[1, 2, 3],
      ),
      willpower: ChartArrowPattern(
        present: hasPattern(const <int>[4, 5, 6]),
        numbers: const <int>[4, 5, 6],
      ),
      activity: ChartArrowPattern(
        present: hasPattern(const <int>[1, 5, 9]),
        numbers: const <int>[1, 5, 9],
      ),
      sensitivity: ChartArrowPattern(
        present: hasPattern(const <int>[3, 6, 9]),
        numbers: const <int>[3, 6, 9],
      ),
      frustration: ChartArrowPattern(
        present: !hasPattern(const <int>[4, 5, 6]),
        numbers: const <int>[4, 5, 6],
      ),
      success: ChartArrowPattern(
        present: hasPattern(const <int>[7, 8, 9]),
        numbers: const <int>[7, 8, 9],
      ),
      spirituality: ChartArrowPattern(
        present: hasPattern(const <int>[1, 5, 9]),
        numbers: const <int>[1, 5, 9],
      ),
    );
  }

  static List<DominantNumber> getDominantNumbers(BirthChartGrid chart) {
    final int maxCount = chart.numbers.values.fold<int>(
      0,
      (int previous, int current) => current > previous ? current : previous,
    );

    if (maxCount <= 1) {
      return const <DominantNumber>[];
    }

    return chart.numbers.entries
        .where((MapEntry<int, int> entry) => entry.value == maxCount)
        .map(
          (MapEntry<int, int> entry) =>
              DominantNumber(number: entry.key, count: entry.value),
        )
        .toList();
  }

  static int calculateAge(DateTime birthDate, [DateTime? now]) {
    final DateTime currentDate = now ?? DateTime.now();
    int age = currentDate.year - birthDate.year;

    final bool notReachedBirthday =
        currentDate.month < birthDate.month ||
        (currentDate.month == birthDate.month &&
            currentDate.day < birthDate.day);
    if (notReachedBirthday) {
      age -= 1;
    }

    return age;
  }

  static List<PinnacleCycle> calculatePinnacles(
    DateTime birthDate,
    int currentAge,
  ) {
    final int day = birthDate.day;
    final int month = birthDate.month;
    final int year = birthDate.year;

    final int lifePathNumber = getLifePathNumber(birthDate);

    final int pinnacle1 = reduceToSingleDigit(
      month + day,
      preserveMaster: true,
    );
    final int pinnacle2 = reduceToSingleDigit(day + year, preserveMaster: true);
    final int pinnacle3 = reduceToSingleDigit(
      pinnacle1 + pinnacle2,
      preserveMaster: true,
    );
    final int pinnacle4 = reduceToSingleDigit(
      month + year,
      preserveMaster: true,
    );

    final int pinnacle1End = 36 - lifePathNumber;
    final int pinnacle2End = pinnacle1End + 9;
    final int pinnacle3End = pinnacle2End + 9;

    return <PinnacleCycle>[
      PinnacleCycle(
        number: pinnacle1,
        startAge: 0,
        endAge: pinnacle1End,
        period: '0-$pinnacle1End tuổi',
        status: _resolveStatus(currentAge, 0, pinnacle1End),
      ),
      PinnacleCycle(
        number: pinnacle2,
        startAge: pinnacle1End + 1,
        endAge: pinnacle2End,
        period: '${pinnacle1End + 1}-$pinnacle2End tuổi',
        status: _resolveStatus(currentAge, pinnacle1End + 1, pinnacle2End),
      ),
      PinnacleCycle(
        number: pinnacle3,
        startAge: pinnacle2End + 1,
        endAge: pinnacle3End,
        period: '${pinnacle2End + 1}-$pinnacle3End tuổi',
        status: _resolveStatus(currentAge, pinnacle2End + 1, pinnacle3End),
      ),
      PinnacleCycle(
        number: pinnacle4,
        startAge: pinnacle3End + 1,
        endAge: 999,
        period: '${pinnacle3End + 1}+ tuổi',
        status: _resolveStatus(currentAge, pinnacle3End + 1, null),
      ),
    ];
  }

  static List<ChallengeCycle> calculateChallenges(
    DateTime birthDate,
    int currentAge,
  ) {
    final int day = reduceToSingleDigit(birthDate.day);
    final int month = reduceToSingleDigit(birthDate.month);
    final int yearReduced = reduceToSingleDigit(birthDate.year);

    final int lifePathNumber = getLifePathNumber(birthDate);

    final int challenge1 = (month - day).abs();
    final int challenge2 = (day - yearReduced).abs();
    final int challenge3 = (challenge1 - challenge2).abs();
    final int challenge4 = (month - yearReduced).abs();

    final int challenge1End = 36 - lifePathNumber;
    final int challenge2End = challenge1End + 9;
    final int challenge3End = challenge2End + 9;

    return <ChallengeCycle>[
      ChallengeCycle(
        number: challenge1,
        startAge: 0,
        endAge: challenge1End,
        period: '0-$challenge1End tuổi',
        status: _resolveStatus(currentAge, 0, challenge1End),
      ),
      ChallengeCycle(
        number: challenge2,
        startAge: challenge1End + 1,
        endAge: challenge2End,
        period: '${challenge1End + 1}-$challenge2End tuổi',
        status: _resolveStatus(currentAge, challenge1End + 1, challenge2End),
      ),
      ChallengeCycle(
        number: challenge3,
        startAge: challenge2End + 1,
        endAge: challenge3End,
        period: '${challenge2End + 1}-$challenge3End tuổi',
        status: _resolveStatus(currentAge, challenge2End + 1, challenge3End),
      ),
      ChallengeCycle(
        number: challenge4,
        startAge: challenge3End + 1,
        endAge: 999,
        period: '${challenge3End + 1}+ tuổi',
        status: _resolveStatus(currentAge, challenge3End + 1, null),
      ),
    ];
  }

  static LifeCycleContent pinnacleContent(int number) {
    return NumerologyReadingData.pinnacles[number] ??
        NumerologyReadingData.pinnacles[1]!;
  }

  static LifeCycleContent challengeContent(int number) {
    return NumerologyReadingData.challenges[number] ??
        NumerologyReadingData.challenges[1]!;
  }

  static int _sumDigits(int value) {
    return value
        .toString()
        .split('')
        .map(int.parse)
        .reduce((int a, int b) => a + b);
  }

  static String _normalizeName(String value) {
    final String upper = value.toUpperCase();
    return upper
        .replaceAll('Á', 'A')
        .replaceAll('À', 'A')
        .replaceAll('Ả', 'A')
        .replaceAll('Ã', 'A')
        .replaceAll('Ạ', 'A')
        .replaceAll('Ă', 'A')
        .replaceAll('Ắ', 'A')
        .replaceAll('Ằ', 'A')
        .replaceAll('Ẳ', 'A')
        .replaceAll('Ẵ', 'A')
        .replaceAll('Ặ', 'A')
        .replaceAll('Â', 'A')
        .replaceAll('Ấ', 'A')
        .replaceAll('Ầ', 'A')
        .replaceAll('Ẩ', 'A')
        .replaceAll('Ẫ', 'A')
        .replaceAll('Ậ', 'A')
        .replaceAll('É', 'E')
        .replaceAll('È', 'E')
        .replaceAll('Ẻ', 'E')
        .replaceAll('Ẽ', 'E')
        .replaceAll('Ẹ', 'E')
        .replaceAll('Ê', 'E')
        .replaceAll('Ế', 'E')
        .replaceAll('Ề', 'E')
        .replaceAll('Ể', 'E')
        .replaceAll('Ễ', 'E')
        .replaceAll('Ệ', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ì', 'I')
        .replaceAll('Ỉ', 'I')
        .replaceAll('Ĩ', 'I')
        .replaceAll('Ị', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ò', 'O')
        .replaceAll('Ỏ', 'O')
        .replaceAll('Õ', 'O')
        .replaceAll('Ọ', 'O')
        .replaceAll('Ô', 'O')
        .replaceAll('Ố', 'O')
        .replaceAll('Ồ', 'O')
        .replaceAll('Ổ', 'O')
        .replaceAll('Ỗ', 'O')
        .replaceAll('Ộ', 'O')
        .replaceAll('Ơ', 'O')
        .replaceAll('Ớ', 'O')
        .replaceAll('Ờ', 'O')
        .replaceAll('Ở', 'O')
        .replaceAll('Ỡ', 'O')
        .replaceAll('Ợ', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('Ù', 'U')
        .replaceAll('Ủ', 'U')
        .replaceAll('Ũ', 'U')
        .replaceAll('Ụ', 'U')
        .replaceAll('Ư', 'U')
        .replaceAll('Ứ', 'U')
        .replaceAll('Ừ', 'U')
        .replaceAll('Ử', 'U')
        .replaceAll('Ữ', 'U')
        .replaceAll('Ự', 'U')
        .replaceAll('Ý', 'Y')
        .replaceAll('Ỳ', 'Y')
        .replaceAll('Ỷ', 'Y')
        .replaceAll('Ỹ', 'Y')
        .replaceAll('Ỵ', 'Y')
        .replaceAll('Đ', 'D');
  }

  static int? _letterValue(String char) {
    switch (char) {
      case 'A':
      case 'J':
      case 'S':
        return 1;
      case 'B':
      case 'K':
      case 'T':
        return 2;
      case 'C':
      case 'L':
      case 'U':
        return 3;
      case 'D':
      case 'M':
      case 'V':
        return 4;
      case 'E':
      case 'N':
      case 'W':
        return 5;
      case 'F':
      case 'O':
      case 'X':
        return 6;
      case 'G':
      case 'P':
      case 'Y':
        return 7;
      case 'H':
      case 'Q':
      case 'Z':
        return 8;
      case 'I':
      case 'R':
        return 9;
      default:
        return null;
    }
  }

  static CoreNumberContent _contentByNumber(
    int number,
    Map<int, CoreNumberContent> source,
  ) {
    final int reduced = reduceToSingleDigit(number);
    return source[number] ?? source[reduced] ?? source[1]!;
  }

  static BirthChartGrid _buildChartGrid(Map<int, int> numbers) {
    final List<List<int?>> grid = <List<int?>>[
      <int?>[
        numbers[3]! > 0 ? 3 : null,
        numbers[6]! > 0 ? 6 : null,
        numbers[9]! > 0 ? 9 : null,
      ],
      <int?>[
        numbers[2]! > 0 ? 2 : null,
        numbers[5]! > 0 ? 5 : null,
        numbers[8]! > 0 ? 8 : null,
      ],
      <int?>[
        numbers[1]! > 0 ? 1 : null,
        numbers[4]! > 0 ? 4 : null,
        numbers[7]! > 0 ? 7 : null,
      ],
    ];

    final List<int> presentNumbers = <int>[];
    final List<int> missingNumbers = <int>[];

    for (int i = 1; i <= 9; i++) {
      if ((numbers[i] ?? 0) > 0) {
        presentNumbers.add(i);
      } else {
        missingNumbers.add(i);
      }
    }

    return BirthChartGrid(
      grid: grid,
      numbers: numbers,
      presentNumbers: presentNumbers,
      missingNumbers: missingNumbers,
    );
  }

  static LifeCycleStatus _resolveStatus(
    int currentAge,
    int startAge,
    int? endAge,
  ) {
    if (endAge == null) {
      return currentAge >= startAge
          ? LifeCycleStatus.active
          : LifeCycleStatus.future;
    }

    if (currentAge < startAge) {
      return LifeCycleStatus.future;
    }

    if (currentAge <= endAge) {
      return LifeCycleStatus.active;
    }

    return LifeCycleStatus.passed;
  }
}
