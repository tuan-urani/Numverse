import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import 'package:test/src/core/model/numerology_content_models.dart';
import 'package:test/src/core/model/numerology_reading_models.dart';
import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/helper/numerology_reading_data.dart';
import 'package:test/src/utils/app_shared.dart';
import 'package:test/src/utils/app_supabase_config.dart';

class AssetNumerologyContentRepository implements INumerologyContentRepository {
  AssetNumerologyContentRepository({
    required AppShared appShared,
    AssetBundle? assetBundle,
    Dio? dio,
    AppSupabaseConfig? supabaseConfig,
  }) : _appShared = appShared,
       _assetBundle = assetBundle ?? rootBundle,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 3),
               receiveTimeout: const Duration(seconds: 3),
             ),
           ),
       _supabaseConfig = supabaseConfig ?? const AppSupabaseConfig();

  static const String _fallbackLanguageCode = 'vi';
  static const Set<String> _supportedLanguages = <String>{'vi', 'en'};
  static const String _typeUniversalDay = 'universal_day';
  static const String _typeLuckyNumber = 'lucky_number';
  static const String _typeDailyMessage = 'daily_message';
  static const String _typeAngelNumber = 'angel_number';
  static const String _typeNumberLibrary = 'number_library';
  static const String _typeTodayPersonalNumber = 'todaypersonalnumber';
  static const String _typePersonalMonth = 'month_personal_number';
  static const String _typePersonalYear = 'year_personal_number';
  static const String _typeLifePathNumber = 'life_path_number';
  static const String _typeExpressionNumber = 'expression_number';
  static const String _typeSoulUrgeNumber = 'soul_urge_number';
  static const String _typeMissionNumber = 'mission_number';
  static const String _typeBirthdayMatrix = 'birthday_matrix';
  static const String _typeNameMatrix = 'name_matrix';
  static const String _typeLifePinnacle = 'life_pinnacle';
  static const String _typeLifeChallenge = 'life_challenge';
  static const String _typeCompatibilityContent = 'compatibility_content';

  static const NumerologyUniversalDayContent
  _fallbackUniversalDayContent = NumerologyUniversalDayContent(
    title: 'Khởi đầu & Lãnh đạo',
    energyTheme:
        'Hôm nay mang năng lượng của sự tiên phong và khởi động chu kỳ mới.',
    keywords: <String>['Độc lập', 'Sáng tạo', 'Tự tin'],
    meaning:
        'Ngày của sự khởi đầu và năng lượng mới. Đây là thời điểm tuyệt vời để bắt tay vào dự án mới hoặc đưa ra quyết định quan trọng.',
    energyManifestation:
        'Bạn có thể cảm nhận xu hướng muốn bắt đầu việc mới, ra quyết định nhanh và chủ động dẫn dắt thay vì chờ đợi.',
  );

  static const NumerologyDailyMessageTemplate
  _fallbackDailyMessageTemplate = NumerologyDailyMessageTemplate(
    mainMessage: 'Hôm nay là ngày để bạn dẫn dắt',
    subMessage:
        'Năng lượng số 1 mang đến cho bạn sức mạnh tiên phong. Đừng chờ đợi - hãy hành động ngay!',
    hintAction:
        'Bắt đầu một dự án mới hoặc đưa ra quyết định quan trọng mà bạn đã trì hoãn',
    thinking:
        'Hãy dành vài phút để suy ngẫm về thông điệp này. Nó có ý nghĩa gì với tình huống hiện tại của bạn? Làm thế nào bạn có thể áp dụng lời khuyên này vào cuộc sống hôm nay?',
    tips: <String>[
      'Viết thông điệp này vào nhật ký để theo dõi sự phát triển',
      'Đặt thông điệp làm lời nhắc trong ngày để giữ tâm trí tập trung',
      'Chia sẻ với người thân nếu thông điệp này có ý nghĩa đặc biệt',
      'Quay lại vào cuối ngày để xem thông điệp đã giúp bạn như thế nào',
    ],
  );

  static const NumerologyLuckyNumberContent
  _fallbackLuckyNumberContent = NumerologyLuckyNumberContent(
    title: 'Khởi đầu & Lãnh đạo',
    message: 'Số may mắn hôm nay khuyến khích bạn hành động dứt khoát.',
    meaning:
        'Đây là thời điểm tốt để chủ động bắt đầu việc quan trọng và giữ tinh thần tiên phong.',
    howToUse: <String>[
      'Ưu tiên một quyết định then chốt trong ngày.',
      'Bắt đầu một bước nhỏ cho mục tiêu lớn.',
      'Nhận diện cơ hội và phản hồi nhanh với sự tự tin.',
    ],
    situations: <String>[
      'Chọn số trong bốc thăm hoặc trò chơi',
      'Chọn số phòng, số ghế hoặc mã số',
      'Chọn thời điểm để suy nghĩ và lập kế hoạch',
      'Đưa ra quyết định cần sự rõ ràng nội tâm',
    ],
  );

  static const NumerologyAngelNumberContent _fallbackAngelNumberContent =
      NumerologyAngelNumberContent(
        title: 'Biểu hiện & Khởi đầu mới',
        coreMeanings: <String>[
          'Khởi đầu chu kỳ mới với tư duy chủ động.',
          'Tăng cường sức mạnh ý định và khả năng thu hút.',
          'Nhấn mạnh vai trò dẫn dắt của bạn trong hiện tại.',
        ],
        universeMessages: <String>[
          'Vũ trụ đang phản hồi rất nhanh với điều bạn tập trung.',
          'Đây là thời điểm phù hợp để đặt lại mục tiêu rõ ràng.',
          'Hãy giữ tần số tích cực để mở rộng cơ hội.',
        ],
        guidance: <String>[
          'Tập trung vào điều bạn muốn, không phải điều bạn sợ hãi',
          'Đây là thời điểm tốt để bắt đầu dự án mới',
          'Hãy giữ suy nghĩ tích cực và lạc quan',
        ],
      );

  static const List<String> _fallbackAngelNumberPopularNumbers = <String>[
    '111',
    '222',
    '333',
  ];

  static const NumerologyNumberLibraryContent
  _fallbackNumberLibraryContent = NumerologyNumberLibraryContent(
    title: 'Khởi đầu & Lãnh đạo',
    description: 'Năng lượng hành động, quyết đoán và mở chu kỳ mới.',
    keywords: <String>['Độc lập', 'Sáng tạo', 'Tự tin'],
    symbolism:
        'Biểu tượng cho khởi đầu mới, tinh thần tiên phong và năng lượng hành động.',
  );
  static const List<int> _fallbackNumberLibraryBasicNumbers = <int>[
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
  ];
  static const List<int> _fallbackNumberLibraryMasterNumbers = <int>[
    11,
    22,
    33,
  ];
  static const NumerologyTodayPersonalNumberContent
  _fallbackTodayPersonalNumberContent = NumerologyTodayPersonalNumberContent(
    quote: 'Hôm nay thuận cho sự biểu đạt, sáng tạo và kết nối chân thành.',
    dailyRhythm: 'Mở rộng - Kết nối',
    detail: <String>[
      'Bạn dễ truyền đạt ý tưởng rõ ràng và tạo ấn tượng tích cực trong giao tiếp.',
      'Năng lượng trong ngày phù hợp để chia sẻ, sáng tạo và khơi mở cảm hứng mới.',
      'Giữ nhịp tập trung sẽ giúp bạn chuyển cảm hứng thành kết quả thực tế.',
    ],
    hintActions: <String>[
      'Ưu tiên việc cần giao tiếp, thuyết trình hoặc làm việc nhóm.',
      'Dành thời gian cho một hoạt động sáng tạo giúp bạn nạp lại năng lượng.',
      'Lập danh sách 3 việc quan trọng để tránh phân tán vào chi tiết nhỏ.',
      'Khép ngày bằng việc tổng kết điều đã học được để duy trì đà phát triển.',
    ],
    shouldDoActions: <String>[
      'Ưu tiên việc cần giao tiếp, thuyết trình hoặc làm việc nhóm.',
      'Dành thời gian cho một hoạt động sáng tạo giúp bạn nạp lại năng lượng.',
    ],
    shouldAvoidActions: <String>[
      'Tránh phân tán vào quá nhiều đầu việc nhỏ cùng lúc.',
      'Tránh quyết định vội khi chưa có đủ thông tin quan trọng.',
    ],
  );
  static const NumerologyPersonalMonthContent
  _fallbackPersonalMonthContent = NumerologyPersonalMonthContent(
    keyword: 'Thay đổi',
    heroTitle: 'Tháng cá nhân 5',
    focus: <String>[
      'Tháng này thiên về dịch chuyển, trải nghiệm mới và điều chỉnh kế hoạch linh hoạt.',
      'Bạn sẽ hiệu quả hơn khi giữ mục tiêu chính rõ ràng nhưng mở với các hướng triển khai khác nhau.',
    ],
    steps: <NumerologyPersonalMonthStep>[
      NumerologyPersonalMonthStep(
        title: 'Linh hoạt hơn trong kế hoạch',
        body: 'Không cố ép mọi thứ theo lịch cũ khi bối cảnh đã thay đổi.',
      ),
      NumerologyPersonalMonthStep(
        title: 'Mở ra trải nghiệm mới',
        body: 'Chủ động thử cách làm mới hoặc kết nối với môi trường mới.',
      ),
      NumerologyPersonalMonthStep(
        title: 'Không cố giữ mọi thứ cũ',
        body: 'Sẵn sàng buông điều không còn phù hợp để tiến về phía trước.',
      ),
    ],
    priorities: <String>[
      'Thử phương án mới trong công việc.',
      'Điều chỉnh kế hoạch nhanh khi cần.',
      'Mở rộng mạng lưới kết nối.',
      'Dành thời gian cho khám phá và học hỏi.',
    ],
    cautions: <String>[
      'Tránh thay đổi quá nhiều thứ cùng lúc.',
      'Cẩn thận với xu hướng phân tán.',
      'Không trì hoãn trách nhiệm quan trọng.',
    ],
  );
  static const NumerologyPersonalYearContent
  _fallbackPersonalYearContent = NumerologyPersonalYearContent(
    keyword: 'Thành tựu',
    heroTitle: 'Năm cá nhân 8',
    theme: <String>[
      'Đây là năm tập trung vào kết quả, năng lực quản trị và mục tiêu dài hạn.',
      'Bạn có cơ hội tạo bước tiến rõ rệt nếu duy trì kỷ luật và tư duy chiến lược.',
      'Giữ cân bằng giữa tham vọng, trách nhiệm và sức khỏe sẽ giúp bạn bền vững.',
    ],
    lessons: <NumerologyPersonalMonthStep>[
      NumerologyPersonalMonthStep(
        title: 'Kỷ luật',
        body: 'Thiết kế nhịp làm việc ổn định để duy trì tiến độ cả năm.',
      ),
      NumerologyPersonalMonthStep(
        title: 'Trách nhiệm',
        body: 'Ra quyết định rõ ràng và chịu trách nhiệm với kết quả của mình.',
      ),
      NumerologyPersonalMonthStep(
        title: 'Cân bằng tham vọng',
        body:
            'Theo đuổi mục tiêu lớn nhưng không đánh đổi các giá trị cốt lõi.',
      ),
    ],
    focusAreas: <NumerologyPersonalMonthStep>[
      NumerologyPersonalMonthStep(
        title: 'Sự nghiệp',
        body:
            'Tăng vị thế chuyên môn, nâng chất lượng đầu ra và vai trò dẫn dắt.',
      ),
      NumerologyPersonalMonthStep(
        title: 'Tài chính',
        body: 'Quản trị ngân sách và đầu tư theo kế hoạch có kiểm soát.',
      ),
      NumerologyPersonalMonthStep(
        title: 'Mục tiêu',
        body: 'Chia nhỏ mục tiêu năm thành các mốc quý để theo dõi tiến độ.',
      ),
      NumerologyPersonalMonthStep(
        title: 'Cân bằng',
        body: 'Giữ nhịp phục hồi để đảm bảo hiệu suất dài hạn.',
      ),
    ],
  );
  static final Map<int, CoreNumberContent> _fallbackLifePathNumberContent =
      NumerologyReadingData.lifePath;
  static final Map<int, CoreNumberContent> _fallbackExpressionNumberContent =
      NumerologyReadingData.personality;
  static final Map<int, CoreNumberContent> _fallbackSoulUrgeNumberContent =
      NumerologyReadingData.soulUrge;
  static final Map<int, CoreNumberContent> _fallbackMissionNumberContent =
      NumerologyReadingData.mission;
  static const BirthChartDataSet _fallbackBirthdayMatrixContent =
      NumerologyReadingData.birthChart;
  static const BirthChartDataSet _fallbackNameMatrixContent =
      NumerologyReadingData.birthChart;
  static final Map<int, LifeCycleContent> _fallbackLifePinnacleContent =
      NumerologyReadingData.pinnacles;
  static final Map<int, LifeCycleContent> _fallbackLifeChallengeContent =
      NumerologyReadingData.challenges;
  static const NumerologyCompatibilityContent
  _fallbackCompatibilityExcellent = NumerologyCompatibilityContent(
    strengths: <String>[
      'Hai bạn bổ trợ tự nhiên về nhịp sống và mục tiêu.',
      'Mức đồng điệu cao giúp giao tiếp dễ đi vào trọng tâm.',
      'Năng lượng cảm xúc hỗ trợ nhau khi cần nâng đỡ.',
      'Có tiềm năng đồng hành dài hạn nếu giữ nhịp tôn trọng.',
    ],
    challenges: <String>[
      'Kỳ vọng cao có thể gây áp lực ngược nếu thiếu chia sẻ rõ ràng.',
      'Dễ chủ quan khi mọi thứ đang thuận lợi.',
      'Cần tránh né xung đột nhỏ để không tích tụ.',
    ],
    advice: <String>[
      'Duy trì check-in cảm xúc định kỳ để giữ kết nối sâu.',
      'Thiết lập mục tiêu chung theo chu kỳ tháng/quý.',
      'Phân vai rõ trong các quyết định quan trọng.',
      'Giữ không gian riêng để mỗi người phục hồi năng lượng.',
    ],
    quote:
        'Sự hòa hợp bền vững đến từ thấu hiểu nhất quán, không chỉ cảm xúc nhất thời.',
  );
  static const NumerologyCompatibilityContent
  _fallbackCompatibilityGood = NumerologyCompatibilityContent(
    strengths: <String>[
      'Hai bạn có nền tảng tương hợp tốt để phát triển cùng nhau.',
      'Nhiều điểm chung trong cách nhìn và định hướng.',
      'Có khả năng nâng đỡ nhau khi gặp áp lực.',
      'Mối quan hệ có dư địa để đi xa nếu cùng chủ động.',
    ],
    challenges: <String>[
      'Khác biệt nhỏ trong giao tiếp có thể gây hiểu lầm123.',
      'Nhịp hành động đôi lúc lệch pha theo giai đoạn.',
      'Dễ trì hoãn đối thoại khi có va chạm nhẹ.',
    ],
    advice: <String>[
      'Thống nhất cách phản hồi khi có bất đồng.',
      'Làm rõ ưu tiên ngắn hạn của từng người.',
      'Giữ một hoạt động kết nối cố định mỗi tuần.',
      'Đánh giá lại kỳ vọng chung định kỳ.',
    ],
    quote:
        'Tương hợp tốt là điểm khởi đầu mạnh, nhưng bền vững cần nỗ lực đồng bộ.',
  );
  static const NumerologyCompatibilityContent
  _fallbackCompatibilityModerate = NumerologyCompatibilityContent(
    strengths: <String>[
      'Sự khác biệt giúp mối quan hệ có góc nhìn đa chiều.',
      'Có cơ hội học cách bổ sung thay vì cạnh tranh.',
      'Mỗi người có thể giúp bên kia mở rộng vùng an toàn.',
      'Tính thích nghi sẽ tăng nếu cả hai cùng cam kết.',
    ],
    challenges: <String>[
      'Nhịp tư duy và giao tiếp dễ lệch nếu thiếu kiên nhẫn.',
      'Xung đột giá trị nhỏ có thể lặp lại theo chu kỳ.',
      'Dễ phòng thủ khi cảm thấy không được thấu hiểu.',
    ],
    advice: <String>[
      'Ưu tiên lắng nghe trước khi phản biện.',
      'Thống nhất nguyên tắc xử lý mâu thuẫn từ sớm.',
      'Chia mục tiêu chung thành bước nhỏ khả thi.',
      'Ghi nhận tiến bộ thay vì chỉ tập trung điểm chưa ổn.',
    ],
    quote:
        'Khác biệt không phải trở ngại, nếu hai bạn cùng học cách điều chỉnh.',
  );
  static const NumerologyCompatibilityContent
  _fallbackCompatibilityEffort = NumerologyCompatibilityContent(
    strengths: <String>[
      'Mối quan hệ này mang tiềm năng học bài học trưởng thành sâu.',
      'Có cơ hội xây nền tảng mới từ sự trung thực.',
      'Nếu kiên định, hai bạn vẫn có thể tạo nhịp riêng phù hợp.',
      'Thử thách hiện tại có thể trở thành điểm bứt phá nội tâm.',
    ],
    challenges: <String>[
      'Khác biệt lớn ở cách nhìn và phản ứng cảm xúc.',
      'Giao tiếp dễ rơi vào phòng thủ hoặc phán xét.',
      'Mất kết nối nhanh nếu không có cơ chế đối thoại rõ.',
    ],
    advice: <String>[
      'Đặt quy tắc tranh luận an toàn ngay từ đầu.',
      'Làm rõ ranh giới và nhu cầu cốt lõi của mỗi người.',
      'Ưu tiên trị liệu/coach hoặc công cụ hỗ trợ giao tiếp khi cần.',
      'Đánh giá mối quan hệ bằng dữ kiện và hành động, không chỉ cảm xúc.',
    ],
    quote:
        'Tương hợp thấp không phải kết thúc, nhưng đòi hỏi cam kết thay đổi thực chất.',
  );
  static const Map<String, NumerologyCompatibilityContent>
  _fallbackCompatibilityByBand = <String, NumerologyCompatibilityContent>{
    'excellent': _fallbackCompatibilityExcellent,
    'good': _fallbackCompatibilityGood,
    'moderate': _fallbackCompatibilityModerate,
    'effort': _fallbackCompatibilityEffort,
  };

  final AssetBundle _assetBundle;
  final AppShared _appShared;
  final Dio _dio;
  final AppSupabaseConfig _supabaseConfig;
  final Map<String, Map<int, NumerologyUniversalDayContent>>
  _universalDayByLanguage = <String, Map<int, NumerologyUniversalDayContent>>{};
  final Map<String, Map<int, List<NumerologyDailyMessageTemplate>>>
  _dailyMessageByLanguage =
      <String, Map<int, List<NumerologyDailyMessageTemplate>>>{};
  final Map<String, Map<int, NumerologyLuckyNumberContent>>
  _luckyNumberByLanguage = <String, Map<int, NumerologyLuckyNumberContent>>{};
  final Map<String, Map<String, NumerologyAngelNumberContent>>
  _angelNumberByLanguage =
      <String, Map<String, NumerologyAngelNumberContent>>{};
  final Map<String, List<String>> _angelNumberPopularByLanguage =
      <String, List<String>>{};
  final Map<String, Map<int, NumerologyNumberLibraryContent>>
  _numberLibraryByLanguage =
      <String, Map<int, NumerologyNumberLibraryContent>>{};
  final Map<String, List<int>> _numberLibraryBasicByLanguage =
      <String, List<int>>{};
  final Map<String, List<int>> _numberLibraryMasterByLanguage =
      <String, List<int>>{};
  final Map<String, Map<int, NumerologyTodayPersonalNumberContent>>
  _todayPersonalNumberByLanguage =
      <String, Map<int, NumerologyTodayPersonalNumberContent>>{};
  final Map<String, Map<int, NumerologyPersonalMonthContent>>
  _personalMonthByLanguage =
      <String, Map<int, NumerologyPersonalMonthContent>>{};
  final Map<String, Map<int, NumerologyPersonalYearContent>>
  _personalYearByLanguage = <String, Map<int, NumerologyPersonalYearContent>>{};
  final Map<String, Map<int, CoreNumberContent>> _lifePathNumberByLanguage =
      <String, Map<int, CoreNumberContent>>{};
  final Map<String, Map<int, CoreNumberContent>> _expressionNumberByLanguage =
      <String, Map<int, CoreNumberContent>>{};
  final Map<String, Map<int, CoreNumberContent>> _soulUrgeNumberByLanguage =
      <String, Map<int, CoreNumberContent>>{};
  final Map<String, Map<int, CoreNumberContent>> _missionNumberByLanguage =
      <String, Map<int, CoreNumberContent>>{};
  final Map<String, BirthChartDataSet> _birthdayMatrixByLanguage =
      <String, BirthChartDataSet>{};
  final Map<String, BirthChartDataSet> _nameMatrixByLanguage =
      <String, BirthChartDataSet>{};
  final Map<String, Map<int, LifeCycleContent>> _lifePinnacleByLanguage =
      <String, Map<int, LifeCycleContent>>{};
  final Map<String, Map<int, LifeCycleContent>> _lifeChallengeByLanguage =
      <String, Map<int, LifeCycleContent>>{};
  final Map<String, Map<String, NumerologyCompatibilityContent>>
  _compatibilityByLanguage =
      <String, Map<String, NumerologyCompatibilityContent>>{};

  bool _isWarmedUp = false;
  int _lastResolvedVariantDayOfYear = -1;

  @override
  Future<void> warmUp() async {
    if (_isWarmedUp) {
      return;
    }

    await _loadSeedAssetsIfAvailable();
    _overlayCachedLedger();
    await _syncLedgerFromServer();

    _lastResolvedVariantDayOfYear = _currentDayOfYear();
    _isWarmedUp = true;
  }

  Future<void> _loadSeedAssetsIfAvailable() async {
    try {
      final String manifest = await _assetBundle.loadString(
        'AssetManifest.json',
      );
      if (!manifest.contains('assets/numerology/')) {
        return;
      }
    } catch (_) {
      return;
    }
    await _loadSeedAssets();
  }

  Future<void> _loadSeedAssets() async {
    for (final String languageCode in _supportedLanguages) {
      _universalDayByLanguage[languageCode] = await _loadUniversalDayMap(
        languageCode,
      );
      _dailyMessageByLanguage[languageCode] = await _loadDailyMessageMap(
        languageCode,
      );
      _luckyNumberByLanguage[languageCode] = await _loadLuckyNumberMap(
        languageCode,
      );
      final ({
        Map<String, NumerologyAngelNumberContent> map,
        List<String> popularNumbers,
      })
      angelPayload = await _loadAngelNumberPayload(languageCode);
      _angelNumberByLanguage[languageCode] = angelPayload.map;
      _angelNumberPopularByLanguage[languageCode] = angelPayload.popularNumbers;
      final ({
        Map<int, NumerologyNumberLibraryContent> map,
        List<int> basicNumbers,
        List<int> masterNumbers,
      })
      numberLibraryPayload = await _loadNumberLibraryPayload(languageCode);
      _numberLibraryByLanguage[languageCode] = numberLibraryPayload.map;
      _numberLibraryBasicByLanguage[languageCode] =
          numberLibraryPayload.basicNumbers;
      _numberLibraryMasterByLanguage[languageCode] =
          numberLibraryPayload.masterNumbers;
      _todayPersonalNumberByLanguage[languageCode] =
          await _loadTodayPersonalNumberMap(languageCode);
      _personalMonthByLanguage[languageCode] = await _loadPersonalMonthMap(
        languageCode,
      );
      _personalYearByLanguage[languageCode] = await _loadPersonalYearMap(
        languageCode,
      );
      _lifePathNumberByLanguage[languageCode] = await _loadLifePathNumberMap(
        languageCode,
      );
      _expressionNumberByLanguage[languageCode] =
          await _loadExpressionNumberMap(languageCode);
      _soulUrgeNumberByLanguage[languageCode] = await _loadSoulUrgeNumberMap(
        languageCode,
      );
      _missionNumberByLanguage[languageCode] = await _loadMissionNumberMap(
        languageCode,
      );
      _birthdayMatrixByLanguage[languageCode] = await _loadBirthdayMatrix(
        languageCode,
      );
      _nameMatrixByLanguage[languageCode] = await _loadNameMatrix(languageCode);
      _lifePinnacleByLanguage[languageCode] = await _loadLifePinnacleMap(
        languageCode,
      );
      _lifeChallengeByLanguage[languageCode] = await _loadLifeChallengeMap(
        languageCode,
      );
      _compatibilityByLanguage[languageCode] = await _loadCompatibilityMap(
        languageCode,
      );
    }
  }

  void _overlayCachedLedger() {
    for (final String languageCode in _supportedLanguages) {
      final String? raw = _appShared.getNumerologyLedgerActive(languageCode);
      if (raw == null || raw.isEmpty) {
        continue;
      }
      final ({String version, String checksum, Map<String, dynamic> ledger})?
      envelope = _decodeLedgerEnvelope(raw);
      if (envelope == null) {
        continue;
      }
      _applyLedgerPayload(languageCode: languageCode, ledger: envelope.ledger);
    }
  }

  Future<void> _syncLedgerFromServer() async {
    if (!_supabaseConfig.isConfigured) {
      return;
    }

    for (final String languageCode in _supportedLanguages) {
      final String? raw = _appShared.getNumerologyLedgerActive(languageCode);
      final ({String version, String checksum, Map<String, dynamic> ledger})?
      cachedEnvelope = raw == null ? null : _decodeLedgerEnvelope(raw);
      final Map<String, dynamic>? response = await _fetchLedgerFromServer(
        localeCode: languageCode,
        clientVersion: cachedEnvelope?.version,
      );
      if (response == null) {
        continue;
      }

      final bool isNotModified = response['not_modified'] == true;
      if (isNotModified) {
        if (cachedEnvelope != null) {
          _applyLedgerPayload(
            languageCode: languageCode,
            ledger: cachedEnvelope.ledger,
          );
        }
        continue;
      }

      final ({String version, String checksum, Map<String, dynamic> ledger})?
      remoteEnvelope = _parseRemoteEnvelope(response);
      if (remoteEnvelope == null) {
        continue;
      }

      final String encoded = jsonEncode(<String, dynamic>{
        'version': remoteEnvelope.version,
        'checksum': remoteEnvelope.checksum,
        'ledger': remoteEnvelope.ledger,
      });
      await _appShared.setNumerologyLedgerTemp(
        localeCode: languageCode,
        value: encoded,
      );
      await _appShared.activateNumerologyLedgerTemp(languageCode);

      _applyLedgerPayload(
        languageCode: languageCode,
        ledger: remoteEnvelope.ledger,
      );
    }
  }

  Future<Map<String, dynamic>?> _fetchLedgerFromServer({
    required String localeCode,
    String? clientVersion,
  }) async {
    try {
      final String anonKey = _supabaseConfig.resolvedAnonKey;
      final Map<String, dynamic> payload = <String, dynamic>{
        'p_locale': localeCode,
      };
      if (clientVersion != null && clientVersion.trim().isNotEmpty) {
        payload['p_client_version'] = clientVersion.trim();
      }

      final Response<dynamic> response = await _dio.postUri(
        _supabaseConfig.rpcUri('get_ledger'),
        data: payload,
        options: Options(
          headers: <String, String>{
            'apikey': anonKey,
            'Authorization': 'Bearer $anonKey',
            'Content-Type': 'application/json',
          },
        ),
      );
      final dynamic rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        return rawData;
      }
      if (rawData is String && rawData.trim().isNotEmpty) {
        final Object? decoded = jsonDecode(rawData);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  ({String version, String checksum, Map<String, dynamic> ledger})?
  _decodeLedgerEnvelope(String raw) {
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return _parseRemoteEnvelope(decoded);
    } catch (_) {
      return null;
    }
  }

  ({String version, String checksum, Map<String, dynamic> ledger})?
  _parseRemoteEnvelope(Map<String, dynamic> json) {
    final String version = (json['version'] as String? ?? '').trim();
    final String checksum = (json['checksum'] as String? ?? '').trim();
    final Object? rawLedger = json['ledger'];
    if (version.isEmpty || rawLedger is! Map<String, dynamic>) {
      return null;
    }
    return (version: version, checksum: checksum, ledger: rawLedger);
  }

  void _applyLedgerPayload({
    required String languageCode,
    required Map<String, dynamic> ledger,
  }) {
    final Map<String, dynamic>? universalDayRaw = _asJsonMap(
      ledger[_typeUniversalDay],
    );
    if (universalDayRaw != null && universalDayRaw.isNotEmpty) {
      final Map<int, NumerologyUniversalDayContent> map =
          _parseUniversalDayEntries(universalDayRaw);
      if (map.isNotEmpty) {
        _universalDayByLanguage[languageCode] = map;
      }
    }

    final Map<String, dynamic>? dailyMessageRaw = _asJsonMap(
      ledger[_typeDailyMessage],
    );
    if (dailyMessageRaw != null && dailyMessageRaw.isNotEmpty) {
      final Map<int, List<NumerologyDailyMessageTemplate>> map =
          _parseDailyMessageEntries(dailyMessageRaw);
      if (map.isNotEmpty) {
        _dailyMessageByLanguage[languageCode] = map;
      }
    }

    final Map<String, dynamic>? luckyNumberRaw = _asJsonMap(
      ledger[_typeLuckyNumber],
    );
    if (luckyNumberRaw != null && luckyNumberRaw.isNotEmpty) {
      final Map<int, NumerologyLuckyNumberContent> map =
          _parseLuckyNumberEntries(luckyNumberRaw);
      if (map.isNotEmpty) {
        _luckyNumberByLanguage[languageCode] = map;
      }
    }

    final Map<String, dynamic>? angelNumberRaw = _asJsonMap(
      ledger[_typeAngelNumber],
    );
    if (angelNumberRaw != null && angelNumberRaw.isNotEmpty) {
      final Map<String, NumerologyAngelNumberContent> map =
          _parseAngelNumberEntries(angelNumberRaw);
      if (map.isNotEmpty) {
        _angelNumberByLanguage[languageCode] = map;
        _angelNumberPopularByLanguage[languageCode] =
            _extractAngelPopularNumbersFromLedger(
              rawEntries: angelNumberRaw,
              parsedMap: map,
            );
      }
    }

    final Map<String, dynamic>? numberLibraryRaw = _asJsonMap(
      ledger[_typeNumberLibrary],
    );
    if (numberLibraryRaw != null && numberLibraryRaw.isNotEmpty) {
      final Map<int, NumerologyNumberLibraryContent> map =
          _parseNumberLibraryEntries(numberLibraryRaw);
      if (map.isNotEmpty) {
        _numberLibraryByLanguage[languageCode] = map;
        _numberLibraryBasicByLanguage[languageCode] = _resolveBasicNumbers(map);
        _numberLibraryMasterByLanguage[languageCode] = _resolveMasterNumbers(
          map,
        );
      }
    }

    final Map<String, dynamic>? todayPersonalRaw = _asJsonMap(
      ledger[_typeTodayPersonalNumber],
    );
    if (todayPersonalRaw != null && todayPersonalRaw.isNotEmpty) {
      final Map<int, NumerologyTodayPersonalNumberContent> map =
          _parseTodayPersonalEntries(todayPersonalRaw);
      if (map.isNotEmpty) {
        _todayPersonalNumberByLanguage[languageCode] = map;
      }
    }

    final Map<String, dynamic>? personalMonthRaw = _asJsonMap(
      ledger[_typePersonalMonth],
    );
    if (personalMonthRaw != null && personalMonthRaw.isNotEmpty) {
      final Map<int, NumerologyPersonalMonthContent> map =
          _parsePersonalMonthEntries(personalMonthRaw);
      if (map.isNotEmpty) {
        _personalMonthByLanguage[languageCode] = map;
      }
    }

    final Map<String, dynamic>? personalYearRaw = _asJsonMap(
      ledger[_typePersonalYear],
    );
    if (personalYearRaw != null && personalYearRaw.isNotEmpty) {
      final Map<int, NumerologyPersonalYearContent> map =
          _parsePersonalYearEntries(personalYearRaw);
      if (map.isNotEmpty) {
        _personalYearByLanguage[languageCode] = map;
      }
    }

    final Map<String, dynamic>? lifePathRaw =
        _asJsonMap(ledger[_typeLifePathNumber]) ??
        _asJsonMap(ledger['life_path']);
    if (lifePathRaw != null && lifePathRaw.isNotEmpty) {
      final Map<int, CoreNumberContent> map = _parseCoreNumberEntries(
        lifePathRaw,
      );
      if (map.isNotEmpty) {
        _lifePathNumberByLanguage[languageCode] = map;
      }
    }

    final Map<String, dynamic>? expressionRaw =
        _asJsonMap(ledger[_typeExpressionNumber]) ??
        _asJsonMap(ledger['personality_number']);
    if (expressionRaw != null && expressionRaw.isNotEmpty) {
      final Map<int, CoreNumberContent> map = _parseCoreNumberEntries(
        expressionRaw,
      );
      if (map.isNotEmpty) {
        _expressionNumberByLanguage[languageCode] = map;
      }
    }

    final Map<String, dynamic>? soulUrgeRaw = _asJsonMap(
      ledger[_typeSoulUrgeNumber],
    );
    if (soulUrgeRaw != null && soulUrgeRaw.isNotEmpty) {
      final Map<int, CoreNumberContent> map = _parseCoreNumberEntries(
        soulUrgeRaw,
      );
      if (map.isNotEmpty) {
        _soulUrgeNumberByLanguage[languageCode] = map;
      }
    }

    final Map<String, dynamic>? missionRaw = _asJsonMap(
      ledger[_typeMissionNumber],
    );
    if (missionRaw != null && missionRaw.isNotEmpty) {
      final Map<int, CoreNumberContent> map = _parseCoreNumberEntries(
        missionRaw,
      );
      if (map.isNotEmpty) {
        _missionNumberByLanguage[languageCode] = map;
      }
    }

    final Map<String, dynamic>? birthdayMatrixRaw =
        _asJsonMap(ledger[_typeBirthdayMatrix]) ??
        _asJsonMap(ledger['birday_matrix']);
    if (birthdayMatrixRaw != null && birthdayMatrixRaw.isNotEmpty) {
      final BirthChartDataSet? dataSet = _parseMatrixDataSet(birthdayMatrixRaw);
      if (dataSet != null) {
        _birthdayMatrixByLanguage[languageCode] = dataSet;
      }
    }

    final Map<String, dynamic>? nameMatrixRaw = _asJsonMap(
      ledger[_typeNameMatrix],
    );
    if (nameMatrixRaw != null && nameMatrixRaw.isNotEmpty) {
      final BirthChartDataSet? dataSet = _parseMatrixDataSet(nameMatrixRaw);
      if (dataSet != null) {
        _nameMatrixByLanguage[languageCode] = dataSet;
      }
    }

    final Map<String, dynamic>? lifePinnacleRaw =
        _asJsonMap(ledger[_typeLifePinnacle]) ??
        _asJsonMap(ledger['life_peaks']);
    if (lifePinnacleRaw != null && lifePinnacleRaw.isNotEmpty) {
      final Map<int, LifeCycleContent> map = _parseLifeCycleEntries(
        lifePinnacleRaw,
      );
      if (map.isNotEmpty) {
        _lifePinnacleByLanguage[languageCode] = map;
      }
    }

    final Map<String, dynamic>? lifeChallengeRaw =
        _asJsonMap(ledger[_typeLifeChallenge]) ??
        _asJsonMap(ledger['life_challenges']);
    if (lifeChallengeRaw != null && lifeChallengeRaw.isNotEmpty) {
      final Map<int, LifeCycleContent> map = _parseLifeCycleEntries(
        lifeChallengeRaw,
      );
      if (map.isNotEmpty) {
        _lifeChallengeByLanguage[languageCode] = map;
      }
    }

    final Map<String, dynamic>? compatibilityRaw = _asJsonMap(
      ledger[_typeCompatibilityContent],
    );
    if (compatibilityRaw != null && compatibilityRaw.isNotEmpty) {
      final Map<String, NumerologyCompatibilityContent> map =
          _parseCompatibilityEntries(compatibilityRaw);
      if (map.isNotEmpty) {
        _compatibilityByLanguage[languageCode] = map;
      }
    }
  }

  Map<String, dynamic>? _asJsonMap(Object? value) {
    return switch (value) {
      Map<String, dynamic>() => value,
      _ => null,
    };
  }

  @override
  NumerologyUniversalDayContent getUniversalDayContent({
    required int number,
    required String languageCode,
  }) {
    _refreshDynamicVariantsIfNeeded();
    final Map<int, NumerologyUniversalDayContent> map = _resolveUniversalDayMap(
      languageCode,
    );
    return map[number] ?? map[1] ?? _fallbackUniversalDayContent;
  }

  @override
  NumerologyDailyMessageTemplate getDailyMessageTemplate({
    required int number,
    required int dayOfYear,
    required String languageCode,
  }) {
    final Map<int, List<NumerologyDailyMessageTemplate>> map =
        _resolveDailyMessageMap(languageCode);
    final List<NumerologyDailyMessageTemplate> templates =
        map[number] ?? map[1] ?? <NumerologyDailyMessageTemplate>[];
    if (templates.isEmpty) {
      return _fallbackDailyMessageTemplate;
    }

    final int index = dayOfYear % templates.length;
    return templates[index];
  }

  @override
  NumerologyLuckyNumberContent getLuckyNumberContent({
    required int number,
    required String languageCode,
  }) {
    _refreshDynamicVariantsIfNeeded();
    final Map<int, NumerologyLuckyNumberContent> map = _resolveLuckyNumberMap(
      languageCode,
    );
    return map[number] ?? map[1] ?? _fallbackLuckyNumberContent;
  }

  @override
  NumerologyAngelNumberContent? findAngelNumberContent({
    required String number,
    required String languageCode,
  }) {
    final String normalized = number.trim();
    if (normalized.isEmpty) {
      return null;
    }
    final Map<String, NumerologyAngelNumberContent> map =
        _resolveAngelNumberMap(languageCode);
    return map[normalized];
  }

  @override
  List<String> getAngelNumberPopularNumbers({required String languageCode}) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    final List<String> list =
        _angelNumberPopularByLanguage[normalizedLanguageCode] ??
        _angelNumberPopularByLanguage[_fallbackLanguageCode] ??
        _fallbackAngelNumberPopularNumbers;
    return list.isEmpty ? _fallbackAngelNumberPopularNumbers : list;
  }

  @override
  NumerologyNumberLibraryContent getNumberLibraryContent({
    required int number,
    required String languageCode,
  }) {
    final Map<int, NumerologyNumberLibraryContent> map =
        _resolveNumberLibraryMap(languageCode);
    return map[number] ?? map[1] ?? _fallbackNumberLibraryContent;
  }

  @override
  NumerologyTodayPersonalNumberContent getTodayPersonalNumberContent({
    required int number,
    required String languageCode,
  }) {
    _refreshDynamicVariantsIfNeeded();
    final Map<int, NumerologyTodayPersonalNumberContent> map =
        _resolveTodayPersonalNumberMap(languageCode);
    return map[number] ?? map[1] ?? _fallbackTodayPersonalNumberContent;
  }

  @override
  NumerologyPersonalMonthContent getPersonalMonthContent({
    required int number,
    required String languageCode,
  }) {
    _refreshDynamicVariantsIfNeeded();
    final Map<int, NumerologyPersonalMonthContent> map =
        _resolvePersonalMonthMap(languageCode);
    return map[number] ?? map[1] ?? _fallbackPersonalMonthContent;
  }

  @override
  NumerologyPersonalYearContent getPersonalYearContent({
    required int number,
    required String languageCode,
  }) {
    _refreshDynamicVariantsIfNeeded();
    final Map<int, NumerologyPersonalYearContent> map = _resolvePersonalYearMap(
      languageCode,
    );
    return map[number] ?? map[1] ?? _fallbackPersonalYearContent;
  }

  @override
  List<int> getNumberLibraryBasicNumbers({required String languageCode}) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    final List<int> list =
        _numberLibraryBasicByLanguage[normalizedLanguageCode] ??
        _numberLibraryBasicByLanguage[_fallbackLanguageCode] ??
        _fallbackNumberLibraryBasicNumbers;
    return list.isEmpty ? _fallbackNumberLibraryBasicNumbers : list;
  }

  @override
  List<int> getNumberLibraryMasterNumbers({required String languageCode}) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    final List<int> list =
        _numberLibraryMasterByLanguage[normalizedLanguageCode] ??
        _numberLibraryMasterByLanguage[_fallbackLanguageCode] ??
        _fallbackNumberLibraryMasterNumbers;
    return list.isEmpty ? _fallbackNumberLibraryMasterNumbers : list;
  }

  @override
  CoreNumberContent getLifePathNumberContent({
    required int number,
    required String languageCode,
  }) {
    final Map<int, CoreNumberContent> map = _resolveLifePathNumberMap(
      languageCode,
    );
    return map[number] ??
        map[1] ??
        _fallbackLifePathNumberContent[1] ??
        const CoreNumberContent(
          title: '',
          description: '',
          interpretation: '',
          keywords: <String>[],
        );
  }

  @override
  CoreNumberContent getExpressionNumberContent({
    required int number,
    required String languageCode,
  }) {
    final Map<int, CoreNumberContent> map = _resolveExpressionNumberMap(
      languageCode,
    );
    return map[number] ??
        map[1] ??
        _fallbackExpressionNumberContent[1] ??
        const CoreNumberContent(
          title: '',
          description: '',
          interpretation: '',
          keywords: <String>[],
        );
  }

  @override
  CoreNumberContent getSoulUrgeNumberContent({
    required int number,
    required String languageCode,
  }) {
    final Map<int, CoreNumberContent> map = _resolveSoulUrgeNumberMap(
      languageCode,
    );
    return map[number] ??
        map[1] ??
        _fallbackSoulUrgeNumberContent[1] ??
        const CoreNumberContent(
          title: '',
          description: '',
          interpretation: '',
          keywords: <String>[],
        );
  }

  @override
  CoreNumberContent getMissionNumberContent({
    required int number,
    required String languageCode,
  }) {
    final Map<int, CoreNumberContent> map = _resolveMissionNumberMap(
      languageCode,
    );
    return map[number] ??
        map[1] ??
        _fallbackMissionNumberContent[1] ??
        const CoreNumberContent(
          title: '',
          description: '',
          interpretation: '',
          keywords: <String>[],
        );
  }

  @override
  BirthChartDataSet getBirthdayMatrixContent({required String languageCode}) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    return _birthdayMatrixByLanguage[normalizedLanguageCode] ??
        _birthdayMatrixByLanguage[_fallbackLanguageCode] ??
        _fallbackBirthdayMatrixContent;
  }

  @override
  BirthChartDataSet getNameMatrixContent({required String languageCode}) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    return _nameMatrixByLanguage[normalizedLanguageCode] ??
        _nameMatrixByLanguage[_fallbackLanguageCode] ??
        _fallbackNameMatrixContent;
  }

  @override
  LifeCycleContent getLifePinnacleContent({
    required int number,
    required String languageCode,
  }) {
    final Map<int, LifeCycleContent> map = _resolveLifePinnacleMap(
      languageCode,
    );
    return map[number] ??
        map[1] ??
        _fallbackLifePinnacleContent[1] ??
        const LifeCycleContent(
          theme: '',
          description: '',
          opportunities: '',
          advice: '',
        );
  }

  @override
  LifeCycleContent getLifeChallengeContent({
    required int number,
    required String languageCode,
  }) {
    final Map<int, LifeCycleContent> map = _resolveLifeChallengeMap(
      languageCode,
    );
    return map[number] ??
        map[1] ??
        _fallbackLifeChallengeContent[1] ??
        const LifeCycleContent(
          theme: '',
          description: '',
          opportunities: '',
          advice: '',
        );
  }

  @override
  NumerologyCompatibilityContent getCompatibilityContent({
    required int overallScore,
    required String languageCode,
  }) {
    final Map<String, NumerologyCompatibilityContent> map =
        _resolveCompatibilityMap(languageCode);
    final String band = _resolveCompatibilityBand(overallScore);
    return map[band] ??
        _fallbackCompatibilityByBand[band] ??
        _fallbackCompatibilityExcellent;
  }

  Map<int, NumerologyUniversalDayContent> _resolveUniversalDayMap(
    String languageCode,
  ) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    return _universalDayByLanguage[normalizedLanguageCode] ??
        _universalDayByLanguage[_fallbackLanguageCode] ??
        const <int, NumerologyUniversalDayContent>{};
  }

  Map<int, List<NumerologyDailyMessageTemplate>> _resolveDailyMessageMap(
    String languageCode,
  ) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    return _dailyMessageByLanguage[normalizedLanguageCode] ??
        _dailyMessageByLanguage[_fallbackLanguageCode] ??
        const <int, List<NumerologyDailyMessageTemplate>>{};
  }

  Map<int, NumerologyLuckyNumberContent> _resolveLuckyNumberMap(
    String languageCode,
  ) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    return _luckyNumberByLanguage[normalizedLanguageCode] ??
        _luckyNumberByLanguage[_fallbackLanguageCode] ??
        const <int, NumerologyLuckyNumberContent>{};
  }

  Map<String, NumerologyAngelNumberContent> _resolveAngelNumberMap(
    String languageCode,
  ) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    final Map<String, NumerologyAngelNumberContent> map =
        _angelNumberByLanguage[normalizedLanguageCode] ??
        _angelNumberByLanguage[_fallbackLanguageCode] ??
        const <String, NumerologyAngelNumberContent>{};
    return map.isNotEmpty
        ? map
        : <String, NumerologyAngelNumberContent>{
            _fallbackAngelNumberPopularNumbers.first:
                _fallbackAngelNumberContent,
          };
  }

  Map<int, NumerologyNumberLibraryContent> _resolveNumberLibraryMap(
    String languageCode,
  ) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    final Map<int, NumerologyNumberLibraryContent> map =
        _numberLibraryByLanguage[normalizedLanguageCode] ??
        _numberLibraryByLanguage[_fallbackLanguageCode] ??
        const <int, NumerologyNumberLibraryContent>{};
    return map.isNotEmpty
        ? map
        : <int, NumerologyNumberLibraryContent>{
            1: _fallbackNumberLibraryContent,
          };
  }

  Map<int, NumerologyTodayPersonalNumberContent> _resolveTodayPersonalNumberMap(
    String languageCode,
  ) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    final Map<int, NumerologyTodayPersonalNumberContent> map =
        _todayPersonalNumberByLanguage[normalizedLanguageCode] ??
        _todayPersonalNumberByLanguage[_fallbackLanguageCode] ??
        const <int, NumerologyTodayPersonalNumberContent>{};
    return map.isNotEmpty
        ? map
        : <int, NumerologyTodayPersonalNumberContent>{
            1: _fallbackTodayPersonalNumberContent,
          };
  }

  Map<int, NumerologyPersonalMonthContent> _resolvePersonalMonthMap(
    String languageCode,
  ) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    final Map<int, NumerologyPersonalMonthContent> map =
        _personalMonthByLanguage[normalizedLanguageCode] ??
        _personalMonthByLanguage[_fallbackLanguageCode] ??
        const <int, NumerologyPersonalMonthContent>{};
    return map.isNotEmpty
        ? map
        : <int, NumerologyPersonalMonthContent>{
            1: _fallbackPersonalMonthContent,
          };
  }

  Map<int, NumerologyPersonalYearContent> _resolvePersonalYearMap(
    String languageCode,
  ) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    final Map<int, NumerologyPersonalYearContent> map =
        _personalYearByLanguage[normalizedLanguageCode] ??
        _personalYearByLanguage[_fallbackLanguageCode] ??
        const <int, NumerologyPersonalYearContent>{};
    return map.isNotEmpty
        ? map
        : <int, NumerologyPersonalYearContent>{1: _fallbackPersonalYearContent};
  }

  Map<int, CoreNumberContent> _resolveLifePathNumberMap(String languageCode) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    final Map<int, CoreNumberContent> map =
        _lifePathNumberByLanguage[normalizedLanguageCode] ??
        _lifePathNumberByLanguage[_fallbackLanguageCode] ??
        const <int, CoreNumberContent>{};
    return map.isNotEmpty ? map : _fallbackLifePathNumberContent;
  }

  Map<int, CoreNumberContent> _resolveExpressionNumberMap(String languageCode) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    final Map<int, CoreNumberContent> map =
        _expressionNumberByLanguage[normalizedLanguageCode] ??
        _expressionNumberByLanguage[_fallbackLanguageCode] ??
        const <int, CoreNumberContent>{};
    return map.isNotEmpty ? map : _fallbackExpressionNumberContent;
  }

  Map<int, CoreNumberContent> _resolveSoulUrgeNumberMap(String languageCode) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    final Map<int, CoreNumberContent> map =
        _soulUrgeNumberByLanguage[normalizedLanguageCode] ??
        _soulUrgeNumberByLanguage[_fallbackLanguageCode] ??
        const <int, CoreNumberContent>{};
    return map.isNotEmpty ? map : _fallbackSoulUrgeNumberContent;
  }

  Map<int, CoreNumberContent> _resolveMissionNumberMap(String languageCode) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    final Map<int, CoreNumberContent> map =
        _missionNumberByLanguage[normalizedLanguageCode] ??
        _missionNumberByLanguage[_fallbackLanguageCode] ??
        const <int, CoreNumberContent>{};
    return map.isNotEmpty ? map : _fallbackMissionNumberContent;
  }

  Map<int, LifeCycleContent> _resolveLifePinnacleMap(String languageCode) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    final Map<int, LifeCycleContent> map =
        _lifePinnacleByLanguage[normalizedLanguageCode] ??
        _lifePinnacleByLanguage[_fallbackLanguageCode] ??
        const <int, LifeCycleContent>{};
    return map.isNotEmpty ? map : _fallbackLifePinnacleContent;
  }

  Map<int, LifeCycleContent> _resolveLifeChallengeMap(String languageCode) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    final Map<int, LifeCycleContent> map =
        _lifeChallengeByLanguage[normalizedLanguageCode] ??
        _lifeChallengeByLanguage[_fallbackLanguageCode] ??
        const <int, LifeCycleContent>{};
    return map.isNotEmpty ? map : _fallbackLifeChallengeContent;
  }

  Map<String, NumerologyCompatibilityContent> _resolveCompatibilityMap(
    String languageCode,
  ) {
    final String normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    final Map<String, NumerologyCompatibilityContent> map =
        _compatibilityByLanguage[normalizedLanguageCode] ??
        _compatibilityByLanguage[_fallbackLanguageCode] ??
        const <String, NumerologyCompatibilityContent>{};
    return map.isNotEmpty ? map : _fallbackCompatibilityByBand;
  }

  String _resolveCompatibilityBand(int overallScore) {
    if (overallScore >= 80) {
      return 'excellent';
    }
    if (overallScore >= 70) {
      return 'good';
    }
    if (overallScore >= 60) {
      return 'moderate';
    }
    return 'effort';
  }

  String _normalizeLanguageCode(String languageCode) {
    final String normalized = languageCode.toLowerCase();
    if (_supportedLanguages.contains(normalized)) {
      return normalized;
    }
    return _fallbackLanguageCode;
  }

  Future<Map<int, NumerologyUniversalDayContent>> _loadUniversalDayMap(
    String languageCode,
  ) async {
    final String path = 'assets/numerology/$languageCode/universal_day.json';
    final Map<String, dynamic> json = await _readJson(path);
    final Object? rawNumbers = json['numbers'];
    final Map<String, dynamic> numbers = switch (rawNumbers) {
      Map<String, dynamic>() => rawNumbers,
      _ => json,
    };
    return _parseUniversalDayEntries(numbers);
  }

  Future<Map<int, List<NumerologyDailyMessageTemplate>>> _loadDailyMessageMap(
    String languageCode,
  ) async {
    final String path = 'assets/numerology/$languageCode/daily_message.json';
    final Map<String, dynamic> json = await _readJson(path);
    final Object? numbers = json['numbers'];
    if (numbers is! Map<String, dynamic>) {
      return const <int, List<NumerologyDailyMessageTemplate>>{};
    }

    return _parseDailyMessageEntries(numbers);
  }

  Future<Map<int, NumerologyLuckyNumberContent>> _loadLuckyNumberMap(
    String languageCode,
  ) async {
    final String path = 'assets/numerology/$languageCode/lucky_number.json';
    final Map<String, dynamic> json = await _readJson(path);
    final Object? rawNumbers = json['numbers'];
    final Map<String, dynamic> numbers = switch (rawNumbers) {
      Map<String, dynamic>() => rawNumbers,
      _ => json,
    };
    return _parseLuckyNumberEntries(numbers);
  }

  Future<
    ({
      Map<String, NumerologyAngelNumberContent> map,
      List<String> popularNumbers,
    })
  >
  _loadAngelNumberPayload(String languageCode) async {
    final String path = 'assets/numerology/$languageCode/angel_number.json';
    final Map<String, dynamic> json = await _readJson(path);
    final Object? numbers = json['numbers'];
    if (numbers is! Map<String, dynamic>) {
      return (
        map: const <String, NumerologyAngelNumberContent>{},
        popularNumbers: const <String>[],
      );
    }

    final Map<String, NumerologyAngelNumberContent> map =
        _parseAngelNumberEntries(numbers);

    final Object? rawPopularNumbers = json['popular_numbers'];
    final List<String> popularNumbers = switch (rawPopularNumbers) {
      List<dynamic>() =>
        rawPopularNumbers
            .whereType<String>()
            .map((String value) => value.trim())
            .where((String value) => value.isNotEmpty && map.containsKey(value))
            .toList(growable: false),
      _ => _resolveAngelPopularNumbers(map),
    };

    return (map: map, popularNumbers: popularNumbers);
  }

  Future<
    ({
      Map<int, NumerologyNumberLibraryContent> map,
      List<int> basicNumbers,
      List<int> masterNumbers,
    })
  >
  _loadNumberLibraryPayload(String languageCode) async {
    final String path = 'assets/numerology/$languageCode/number_library.json';
    final Map<String, dynamic> json = await _readJson(path);
    final Object? numbers = json['numbers'];
    if (numbers is! Map<String, dynamic>) {
      return (
        map: const <int, NumerologyNumberLibraryContent>{},
        basicNumbers: const <int>[],
        masterNumbers: const <int>[],
      );
    }

    final Map<int, NumerologyNumberLibraryContent> map =
        _parseNumberLibraryEntries(numbers);

    int? parseNumber(Object? value) {
      return switch (value) {
        int() => value,
        String() => int.tryParse(value.trim()),
        _ => null,
      };
    }

    List<int> parseNumberList(Object? value) {
      return switch (value) {
        List<dynamic>() =>
          value
              .map(parseNumber)
              .whereType<int>()
              .where((int item) => map.containsKey(item))
              .toList(growable: false),
        _ => const <int>[],
      };
    }

    final List<int> basicNumbers = parseNumberList(json['basic_numbers']);
    final List<int> masterNumbers = parseNumberList(json['master_numbers']);

    final List<int> fallbackBasic = _resolveBasicNumbers(map);
    final List<int> fallbackMaster = _resolveMasterNumbers(map);

    return (
      map: map,
      basicNumbers: basicNumbers.isEmpty ? fallbackBasic : basicNumbers,
      masterNumbers: masterNumbers.isEmpty ? fallbackMaster : masterNumbers,
    );
  }

  Future<Map<int, NumerologyTodayPersonalNumberContent>>
  _loadTodayPersonalNumberMap(String languageCode) async {
    final String path =
        'assets/numerology/$languageCode/todaypersonalnumber.json';
    final Map<String, dynamic> json = await _readJson(path);
    final Object? rawNumbers = json['numbers'];
    final Map<String, dynamic> numbers = switch (rawNumbers) {
      Map<String, dynamic>() => rawNumbers,
      _ => json,
    };
    return _parseTodayPersonalEntries(numbers);
  }

  Future<Map<int, NumerologyPersonalMonthContent>> _loadPersonalMonthMap(
    String languageCode,
  ) async {
    final String path =
        'assets/numerology/$languageCode/month_personal_number.json';
    final Map<String, dynamic> json = await _readJson(path);
    final Object? rawNumbers = json['numbers'];
    final Map<String, dynamic> numbers = switch (rawNumbers) {
      Map<String, dynamic>() => rawNumbers,
      _ => json,
    };
    return _parsePersonalMonthEntries(numbers);
  }

  Future<Map<int, NumerologyPersonalYearContent>> _loadPersonalYearMap(
    String languageCode,
  ) async {
    final String path =
        'assets/numerology/$languageCode/year_personal_number.json';
    final Map<String, dynamic> json = await _readJson(path);
    final Object? rawNumbers = json['numbers'];
    final Map<String, dynamic> numbers = switch (rawNumbers) {
      Map<String, dynamic>() => rawNumbers,
      _ => json,
    };
    return _parsePersonalYearEntries(numbers);
  }

  Future<Map<int, CoreNumberContent>> _loadLifePathNumberMap(
    String languageCode,
  ) async {
    return _loadCoreNumberMap(
      languageCode: languageCode,
      fileName: 'life_path_number.json',
      legacyFileName: 'life_path.json',
    );
  }

  Future<Map<int, CoreNumberContent>> _loadExpressionNumberMap(
    String languageCode,
  ) async {
    return _loadCoreNumberMap(
      languageCode: languageCode,
      fileName: 'expression_number.json',
      legacyFileName: 'personality_number.json',
    );
  }

  Future<Map<int, CoreNumberContent>> _loadSoulUrgeNumberMap(
    String languageCode,
  ) async {
    return _loadCoreNumberMap(
      languageCode: languageCode,
      fileName: 'soul_urge_number.json',
    );
  }

  Future<Map<int, CoreNumberContent>> _loadMissionNumberMap(
    String languageCode,
  ) async {
    return _loadCoreNumberMap(
      languageCode: languageCode,
      fileName: 'mission_number.json',
    );
  }

  Future<Map<int, CoreNumberContent>> _loadCoreNumberMap({
    required String languageCode,
    required String fileName,
    String? legacyFileName,
  }) async {
    final String path = 'assets/numerology/$languageCode/$fileName';
    final Map<String, dynamic> json = await _readJson(path);
    final Map<int, CoreNumberContent> parsed = _parseCoreNumberEntries(
      _resolveRootNumbersMap(json),
    );
    if (parsed.isNotEmpty) {
      return parsed;
    }

    if (legacyFileName == null) {
      return const <int, CoreNumberContent>{};
    }
    final String legacyPath = 'assets/numerology/$languageCode/$legacyFileName';
    final Map<String, dynamic> legacyJson = await _readJson(legacyPath);
    return _parseCoreNumberEntries(_resolveRootNumbersMap(legacyJson));
  }

  Future<BirthChartDataSet> _loadBirthdayMatrix(String languageCode) async {
    final BirthChartDataSet? data = await _loadMatrixDataSet(
      languageCode: languageCode,
      fileName: 'birthday_matrix.json',
      legacyFileName: 'birday_matrix.json',
    );
    return data ?? _fallbackBirthdayMatrixContent;
  }

  Future<BirthChartDataSet> _loadNameMatrix(String languageCode) async {
    final BirthChartDataSet? data = await _loadMatrixDataSet(
      languageCode: languageCode,
      fileName: 'name_matrix.json',
    );
    return data ?? _fallbackNameMatrixContent;
  }

  Future<BirthChartDataSet?> _loadMatrixDataSet({
    required String languageCode,
    required String fileName,
    String? legacyFileName,
  }) async {
    final String path = 'assets/numerology/$languageCode/$fileName';
    final Map<String, dynamic> json = await _readJson(path);
    final BirthChartDataSet? parsed = _parseMatrixDataSet(json);
    if (parsed != null) {
      return parsed;
    }
    if (legacyFileName == null) {
      return null;
    }
    final String legacyPath = 'assets/numerology/$languageCode/$legacyFileName';
    return _parseMatrixDataSet(await _readJson(legacyPath));
  }

  Future<Map<int, LifeCycleContent>> _loadLifePinnacleMap(
    String languageCode,
  ) async {
    return _loadLifeCycleMap(
      languageCode: languageCode,
      fileName: 'life_pinnacle.json',
      legacyFileName: 'pinnacle.json',
    );
  }

  Future<Map<int, LifeCycleContent>> _loadLifeChallengeMap(
    String languageCode,
  ) async {
    return _loadLifeCycleMap(
      languageCode: languageCode,
      fileName: 'life_challenge.json',
      legacyFileName: 'challenge.json',
    );
  }

  Future<Map<String, NumerologyCompatibilityContent>> _loadCompatibilityMap(
    String languageCode,
  ) async {
    final String path =
        'assets/numerology/$languageCode/compatibility_content.json';
    final Map<String, dynamic> json = await _readJson(path);
    return _parseCompatibilityEntries(json);
  }

  Future<Map<int, LifeCycleContent>> _loadLifeCycleMap({
    required String languageCode,
    required String fileName,
    String? legacyFileName,
  }) async {
    final String path = 'assets/numerology/$languageCode/$fileName';
    final Map<String, dynamic> json = await _readJson(path);
    final Map<int, LifeCycleContent> parsed = _parseLifeCycleEntries(
      _resolveRootNumbersMap(json),
    );
    if (parsed.isNotEmpty) {
      return parsed;
    }
    if (legacyFileName == null) {
      return const <int, LifeCycleContent>{};
    }
    final String legacyPath = 'assets/numerology/$languageCode/$legacyFileName';
    final Map<String, dynamic> legacyJson = await _readJson(legacyPath);
    return _parseLifeCycleEntries(_resolveRootNumbersMap(legacyJson));
  }

  Map<String, dynamic> _resolveRootNumbersMap(Map<String, dynamic> json) {
    final Map<String, dynamic> root = switch (_asJsonMap(
      _resolveVariantPayload(json),
    )) {
      final Map<String, dynamic> map => map,
      _ => json,
    };
    final Object? rawNumbers = root['numbers'];
    return switch (rawNumbers) {
      Map<String, dynamic>() => rawNumbers,
      _ => root,
    };
  }

  Map<int, NumerologyUniversalDayContent> _parseUniversalDayEntries(
    Map<String, dynamic> numbers,
  ) {
    final Map<int, NumerologyUniversalDayContent> map =
        <int, NumerologyUniversalDayContent>{};
    for (final MapEntry<String, dynamic> entry in numbers.entries) {
      final int? number = int.tryParse(entry.key.trim());
      final Map<String, dynamic>? payload = _asJsonMap(
        _resolveVariantPayload(entry.value),
      );
      if (number == null || payload == null) {
        continue;
      }

      try {
        map[number] = NumerologyUniversalDayContent.fromJson(payload);
      } catch (_) {
        continue;
      }
    }
    return map;
  }

  Map<int, List<NumerologyDailyMessageTemplate>> _parseDailyMessageEntries(
    Map<String, dynamic> numbers,
  ) {
    final Map<int, List<NumerologyDailyMessageTemplate>> map =
        <int, List<NumerologyDailyMessageTemplate>>{};
    for (final MapEntry<String, dynamic> entry in numbers.entries) {
      final int? number = int.tryParse(entry.key.trim());
      final List<dynamic>? templateItems = _resolveDailyMessageTemplateItems(
        entry.value,
      );
      if (number == null || templateItems == null || templateItems.isEmpty) {
        continue;
      }

      final List<NumerologyDailyMessageTemplate> templates =
          <NumerologyDailyMessageTemplate>[];
      for (final dynamic item in templateItems) {
        final Map<String, dynamic>? templatePayload = _asJsonMap(
          _resolveVariantPayload(item),
        );
        if (templatePayload == null) {
          continue;
        }
        try {
          templates.add(
            NumerologyDailyMessageTemplate.fromJson(templatePayload),
          );
        } catch (_) {
          continue;
        }
      }

      if (templates.isNotEmpty) {
        map[number] = templates;
      }
    }

    return map;
  }

  List<dynamic>? _resolveDailyMessageTemplateItems(Object? raw) {
    if (raw is List<dynamic>) {
      return raw;
    }

    final Map<String, dynamic>? payload = _asJsonMap(raw);
    if (payload == null) {
      final Object? resolved = _resolveVariantPayload(raw);
      return resolved is List<dynamic> ? resolved : null;
    }

    final Object? variantsRaw =
        payload['variants'] ?? payload['messages'] ?? payload['templates'];
    if (variantsRaw is List<dynamic>) {
      return variantsRaw;
    }

    if (payload.containsKey('payload')) {
      final Object? nested = payload['payload'];
      if (nested is List<dynamic>) {
        return nested;
      }
      if (nested is Map<String, dynamic>) {
        final Object? nestedVariants =
            nested['variants'] ?? nested['messages'] ?? nested['templates'];
        if (nestedVariants is List<dynamic>) {
          return nestedVariants;
        }
      }
    }

    final Object? resolved = _resolveVariantPayload(payload);
    if (resolved is List<dynamic>) {
      return resolved;
    }
    if (resolved is Map<String, dynamic>) {
      return <dynamic>[resolved];
    }
    return null;
  }

  Map<int, NumerologyLuckyNumberContent> _parseLuckyNumberEntries(
    Map<String, dynamic> numbers,
  ) {
    final Map<int, NumerologyLuckyNumberContent> map =
        <int, NumerologyLuckyNumberContent>{};
    for (final MapEntry<String, dynamic> entry in numbers.entries) {
      final int? number = int.tryParse(entry.key.trim());
      final Map<String, dynamic>? payload = _asJsonMap(
        _resolveVariantPayload(entry.value),
      );
      if (number == null || payload == null) {
        continue;
      }

      try {
        map[number] = NumerologyLuckyNumberContent.fromJson(payload);
      } catch (_) {
        continue;
      }
    }

    return map;
  }

  Map<String, NumerologyAngelNumberContent> _parseAngelNumberEntries(
    Map<String, dynamic> numbers,
  ) {
    final Map<String, NumerologyAngelNumberContent> map =
        <String, NumerologyAngelNumberContent>{};
    for (final MapEntry<String, dynamic> entry in numbers.entries) {
      final String number = entry.key.trim();
      final Map<String, dynamic>? payload = _asJsonMap(
        _resolveVariantPayload(entry.value),
      );
      if (number.isEmpty || payload == null) {
        continue;
      }

      try {
        map[number] = NumerologyAngelNumberContent.fromJson(payload);
      } catch (_) {
        continue;
      }
    }
    return map;
  }

  List<String> _resolveAngelPopularNumbers(
    Map<String, NumerologyAngelNumberContent> map,
  ) {
    final List<String> allNumbers = map.keys.toList(growable: false)
      ..sort((String a, String b) => a.compareTo(b));
    if (allNumbers.isEmpty) {
      return const <String>[];
    }

    final List<String> preferred = <String>[
      '111',
      '222',
      '333',
    ].where(map.containsKey).toList(growable: false);
    if (preferred.length == 3) {
      return preferred;
    }

    return allNumbers.take(3).toList(growable: false);
  }

  List<String> _extractAngelPopularNumbersFromLedger({
    required Map<String, dynamic> rawEntries,
    required Map<String, NumerologyAngelNumberContent> parsedMap,
  }) {
    final Object? rawPopularPayload =
        rawEntries['__popular_numbers__'] ?? rawEntries['popular_numbers'];
    if (rawPopularPayload == null) {
      return _resolveAngelPopularNumbers(parsedMap);
    }

    final Map<String, dynamic>? popularPayload = _asJsonMap(
      _resolveVariantPayload(rawPopularPayload),
    );
    final Object? rawItems = popularPayload?['items'] ?? rawPopularPayload;
    if (rawItems is! List<dynamic>) {
      return _resolveAngelPopularNumbers(parsedMap);
    }

    final List<String> items = rawItems
        .map((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty && parsedMap.containsKey(item))
        .toList(growable: false);
    if (items.isNotEmpty) {
      return items;
    }
    return _resolveAngelPopularNumbers(parsedMap);
  }

  Map<int, NumerologyNumberLibraryContent> _parseNumberLibraryEntries(
    Map<String, dynamic> numbers,
  ) {
    final Map<int, NumerologyNumberLibraryContent> map =
        <int, NumerologyNumberLibraryContent>{};
    for (final MapEntry<String, dynamic> entry in numbers.entries) {
      final int? number = int.tryParse(entry.key.trim());
      final Map<String, dynamic>? payload = _asJsonMap(
        _resolveVariantPayload(entry.value),
      );
      if (number == null || payload == null) {
        continue;
      }

      try {
        map[number] = NumerologyNumberLibraryContent.fromJson(payload);
      } catch (_) {
        continue;
      }
    }

    return map;
  }

  List<int> _resolveBasicNumbers(Map<int, NumerologyNumberLibraryContent> map) {
    final List<int> numbers = _fallbackNumberLibraryBasicNumbers
        .where(map.containsKey)
        .toList(growable: false);
    return numbers;
  }

  List<int> _resolveMasterNumbers(
    Map<int, NumerologyNumberLibraryContent> map,
  ) {
    final List<int> numbers = _fallbackNumberLibraryMasterNumbers
        .where(map.containsKey)
        .toList(growable: false);
    return numbers;
  }

  Map<int, NumerologyTodayPersonalNumberContent> _parseTodayPersonalEntries(
    Map<String, dynamic> numbers,
  ) {
    final Map<int, NumerologyTodayPersonalNumberContent> map =
        <int, NumerologyTodayPersonalNumberContent>{};
    for (final MapEntry<String, dynamic> entry in numbers.entries) {
      final int? number = int.tryParse(entry.key.trim());
      final Map<String, dynamic>? payload = _asJsonMap(
        _resolveVariantPayload(entry.value),
      );
      if (number == null || payload == null) {
        continue;
      }
      try {
        map[number] = NumerologyTodayPersonalNumberContent.fromJson(payload);
      } catch (_) {
        continue;
      }
    }
    return map;
  }

  Map<int, NumerologyPersonalMonthContent> _parsePersonalMonthEntries(
    Map<String, dynamic> numbers,
  ) {
    final Map<int, NumerologyPersonalMonthContent> map =
        <int, NumerologyPersonalMonthContent>{};
    for (final MapEntry<String, dynamic> entry in numbers.entries) {
      final int? number = int.tryParse(entry.key.trim());
      final Map<String, dynamic>? payload = _asJsonMap(
        _resolveVariantPayload(entry.value),
      );
      if (number == null || payload == null) {
        continue;
      }
      try {
        map[number] = NumerologyPersonalMonthContent.fromJson(payload);
      } catch (_) {
        continue;
      }
    }
    return map;
  }

  Map<int, NumerologyPersonalYearContent> _parsePersonalYearEntries(
    Map<String, dynamic> numbers,
  ) {
    final Map<int, NumerologyPersonalYearContent> map =
        <int, NumerologyPersonalYearContent>{};
    for (final MapEntry<String, dynamic> entry in numbers.entries) {
      final int? number = int.tryParse(entry.key.trim());
      final Map<String, dynamic>? payload = _asJsonMap(
        _resolveVariantPayload(entry.value),
      );
      if (number == null || payload == null) {
        continue;
      }
      try {
        map[number] = NumerologyPersonalYearContent.fromJson(payload);
      } catch (_) {
        continue;
      }
    }
    return map;
  }

  Map<int, CoreNumberContent> _parseCoreNumberEntries(
    Map<String, dynamic> numbers,
  ) {
    final Map<int, CoreNumberContent> map = <int, CoreNumberContent>{};
    for (final MapEntry<String, dynamic> entry in numbers.entries) {
      final int? number = int.tryParse(entry.key.trim());
      final Map<String, dynamic>? payload = _asJsonMap(
        _resolveVariantPayload(entry.value),
      );
      if (number == null || payload == null) {
        continue;
      }
      try {
        map[number] = CoreNumberContent.fromJson(payload);
      } catch (_) {
        continue;
      }
    }
    return map;
  }

  BirthChartDataSet? _parseMatrixDataSet(Map<String, dynamic> raw) {
    Map<String, dynamic>? payload = _asJsonMap(_resolveVariantPayload(raw));
    if (payload == null || payload.isEmpty) {
      return null;
    }
    if (!payload.containsKey('numbers')) {
      final Map<String, dynamic>? defaultPayload = _asJsonMap(
        _resolveVariantPayload(payload['default'] ?? payload['1']),
      );
      if (defaultPayload != null && defaultPayload.containsKey('numbers')) {
        payload = defaultPayload;
      } else {
        Object? firstValue;
        final Iterator<Object?> iterator = payload.values.iterator;
        if (iterator.moveNext()) {
          firstValue = iterator.current;
        }
        final Map<String, dynamic>? firstPayload = _asJsonMap(
          _resolveVariantPayload(firstValue),
        );
        if (firstPayload != null && firstPayload.containsKey('numbers')) {
          payload = firstPayload;
        }
      }
    }
    try {
      return BirthChartDataSet.fromJson(payload);
    } catch (_) {
      return null;
    }
  }

  Map<int, LifeCycleContent> _parseLifeCycleEntries(Map<String, dynamic> map) {
    final Map<int, LifeCycleContent> result = <int, LifeCycleContent>{};
    for (final MapEntry<String, dynamic> entry in map.entries) {
      final int? number = int.tryParse(entry.key.trim());
      final Map<String, dynamic>? payload = _asJsonMap(
        _resolveVariantPayload(entry.value),
      );
      if (number == null || payload == null) {
        continue;
      }
      try {
        result[number] = LifeCycleContent.fromJson(payload);
      } catch (_) {
        continue;
      }
    }
    return result;
  }

  Map<String, NumerologyCompatibilityContent> _parseCompatibilityEntries(
    Map<String, dynamic> map,
  ) {
    final Map<String, NumerologyCompatibilityContent> result =
        <String, NumerologyCompatibilityContent>{};
    for (final MapEntry<String, dynamic> entry in map.entries) {
      final String key = entry.key.trim().toLowerCase();
      final Map<String, dynamic>? payload = _asJsonMap(
        _resolveVariantPayload(entry.value),
      );
      if (key.isEmpty || payload == null) {
        continue;
      }
      try {
        result[key] = NumerologyCompatibilityContent.fromJson(payload);
      } catch (_) {
        continue;
      }
    }
    return result;
  }

  Object? _resolveVariantPayload(Object? raw) {
    final Map<String, dynamic>? payload = _asJsonMap(raw);
    if (payload == null) {
      return raw;
    }

    final Object? variantsRaw = payload['variants'];
    if (variantsRaw is List<dynamic> && variantsRaw.isNotEmpty) {
      final int index = _resolveVariantIndex(
        length: variantsRaw.length,
        strategy:
            payload['variant_strategy'] as String? ??
            payload['variantStrategy'] as String?,
      );
      return variantsRaw[index];
    }
    if (variantsRaw is Map<String, dynamic> && variantsRaw.isNotEmpty) {
      final List<String> keys = variantsRaw.keys.toList(growable: false)
        ..sort();
      final int index = _resolveVariantIndex(
        length: keys.length,
        strategy:
            payload['variant_strategy'] as String? ??
            payload['variantStrategy'] as String?,
      );
      return variantsRaw[keys[index]];
    }

    if (payload.containsKey('payload')) {
      return payload['payload'];
    }
    if (payload.containsKey('default')) {
      return payload['default'];
    }
    return payload;
  }

  int _resolveVariantIndex({required int length, String? strategy}) {
    if (length <= 1) {
      return 0;
    }
    final String normalizedStrategy = (strategy ?? 'day_of_year_mod')
        .trim()
        .toLowerCase();
    return switch (normalizedStrategy) {
      'static' => 0,
      _ => (_currentDayOfYear() - 1) % length,
    };
  }

  int _currentDayOfYear([DateTime? date]) {
    final DateTime now = date ?? DateTime.now();
    return now.difference(DateTime(now.year, 1, 1)).inDays + 1;
  }

  void _refreshDynamicVariantsIfNeeded() {
    if (!_isWarmedUp) {
      return;
    }
    final int currentDay = _currentDayOfYear();
    if (currentDay == _lastResolvedVariantDayOfYear) {
      return;
    }
    _lastResolvedVariantDayOfYear = currentDay;
    _overlayCachedLedger();
  }

  Future<Map<String, dynamic>> _readJson(String path) async {
    try {
      final String raw = await _assetBundle.loadString(path);
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return const <String, dynamic>{};
    }

    return const <String, dynamic>{};
  }
}
