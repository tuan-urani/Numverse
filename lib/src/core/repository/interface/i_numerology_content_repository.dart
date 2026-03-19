import 'package:test/src/core/model/compatibility_aspect.dart';
import 'package:test/src/core/model/numerology_content_models.dart';
import 'package:test/src/core/model/numerology_reading_models.dart';

abstract class INumerologyContentRepository {
  Future<void> warmUp();

  NumerologyUniversalDayContent getUniversalDayContent({
    required int number,
    required String languageCode,
  });

  NumerologyDailyMessageTemplate getDailyMessageTemplate({
    required int number,
    required int dayOfYear,
    required String languageCode,
  });

  NumerologyLuckyNumberContent getLuckyNumberContent({
    required int number,
    required String languageCode,
  });

  NumerologyAngelNumberContent? findAngelNumberContent({
    required String number,
    required String languageCode,
  });

  List<String> getAngelNumberPopularNumbers({required String languageCode});

  NumerologyNumberLibraryContent getNumberLibraryContent({
    required int number,
    required String languageCode,
  });

  NumerologyTodayPersonalNumberContent getTodayPersonalNumberContent({
    required int number,
    required String languageCode,
  });

  NumerologyPersonalMonthContent getPersonalMonthContent({
    required int number,
    required String languageCode,
  });

  NumerologyPersonalYearContent getPersonalYearContent({
    required int number,
    required String languageCode,
  });

  List<int> getNumberLibraryBasicNumbers({required String languageCode});

  List<int> getNumberLibraryMasterNumbers({required String languageCode});

  CoreNumberContent getLifePathNumberContent({
    required int number,
    required String languageCode,
  });

  CoreNumberContent getExpressionNumberContent({
    required int number,
    required String languageCode,
  });

  CoreNumberContent getSoulUrgeNumberContent({
    required int number,
    required String languageCode,
  });

  CoreNumberContent getMissionNumberContent({
    required int number,
    required String languageCode,
  });

  BirthChartDataSet getBirthdayMatrixContent({required String languageCode});

  BirthChartDataSet getNameMatrixContent({required String languageCode});

  LifeCycleContent getLifePinnacleContent({
    required int number,
    required String languageCode,
  });

  LifeCycleContent getLifeChallengeContent({
    required int number,
    required String languageCode,
  });

  NumerologyCompatibilityContent getCompatibilityContent({
    required int overallScore,
    required String languageCode,
  });

  NumerologyCompatibilityContent getCompatibilityAspectContent({
    required CompatibilityAspect aspect,
    required int score,
    required String languageCode,
  });
}
