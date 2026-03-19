import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:test/src/core/model/comparison_profile.dart';
import 'package:test/src/core/model/compatibility_aspect.dart';
import 'package:test/src/core/model/compatibility_history_item.dart';
import 'package:test/src/core/model/numerology_content_models.dart';
import 'package:test/src/core/model/user_profile.dart';
import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/helper/compatibility_scoring.dart';
import 'package:test/src/helper/numerology_helper.dart';
import 'package:test/src/ui/comparison_result/interactor/comparison_result_event.dart';
import 'package:test/src/ui/comparison_result/interactor/comparison_result_state.dart';

class ComparisonResultBloc
    extends Bloc<ComparisonResultEvent, ComparisonResultState> {
  ComparisonResultBloc({
    required INumerologyContentRepository contentRepository,
  }) : _contentRepository = contentRepository,
       super(ComparisonResultState.initial()) {
    on<ComparisonResultLoaded>(_onLoaded);
    on<ComparisonResultLoadedFromHistory>(_onLoadedFromHistory);
  }

  final INumerologyContentRepository _contentRepository;

  void load({
    required UserProfile selfProfile,
    required ComparisonProfile targetProfile,
    required String languageCode,
  }) {
    add(
      ComparisonResultLoaded(
        selfProfile: selfProfile,
        targetProfile: targetProfile,
        languageCode: languageCode,
      ),
    );
  }

  void loadFromHistory({
    required CompatibilityHistoryItem item,
    required String languageCode,
  }) {
    add(
      ComparisonResultLoadedFromHistory(item: item, languageCode: languageCode),
    );
  }

  void _onLoaded(
    ComparisonResultLoaded event,
    Emitter<ComparisonResultState> emit,
  ) {
    final UserProfile selfProfile = event.selfProfile;
    final ComparisonProfile targetProfile = event.targetProfile;
    final String languageCode = event.languageCode.trim().toLowerCase();
    final String selfId = selfProfile.id;
    final String targetId = targetProfile.id;

    if (state.selfProfileId == selfId &&
        state.targetProfileId == targetId &&
        state.languageCode == languageCode) {
      return;
    }

    final _ProfileMetrics selfMetrics = _buildSelfMetrics(selfProfile);
    final _TargetMetrics targetMetrics = _buildTargetMetrics(targetProfile);

    final CompatibilityScoreBreakdown scores = CompatibilityScoring.calculate(
      selfLifePath: selfMetrics.lifePath,
      selfExpression: selfMetrics.expression,
      selfPersonality: selfMetrics.personality,
      selfSoul: selfMetrics.soul,
      targetLifePath: targetMetrics.lifePath,
      targetExpression: targetMetrics.expression,
      targetPersonality: targetMetrics.personality,
      targetSoul: targetMetrics.soul,
    );
    final NumerologyCompatibilityContent compatibilityContent =
        _contentRepository.getCompatibilityContent(
          overallScore: scores.overall,
          languageCode: languageCode,
        );
    final int expressionScore = CompatibilityScoring.pairScore(
      selfMetrics.expression,
      targetMetrics.expression,
    );
    final ComparisonAspectInsight lifePathInsight =
        ComparisonAspectInsight.fromContent(
          _contentRepository.getCompatibilityAspectContent(
            aspect: CompatibilityAspect.lifePath,
            score: scores.core,
            languageCode: languageCode,
          ),
        );
    final ComparisonAspectInsight expressionInsight =
        ComparisonAspectInsight.fromContent(
          _contentRepository.getCompatibilityAspectContent(
            aspect: CompatibilityAspect.expression,
            score: expressionScore,
            languageCode: languageCode,
          ),
        );
    final ComparisonAspectInsight soulInsight =
        ComparisonAspectInsight.fromContent(
          _contentRepository.getCompatibilityAspectContent(
            aspect: CompatibilityAspect.soul,
            score: scores.soul,
            languageCode: languageCode,
          ),
        );
    final ComparisonAspectInsight personalityInsight =
        ComparisonAspectInsight.fromContent(
          _contentRepository.getCompatibilityAspectContent(
            aspect: CompatibilityAspect.personality,
            score: scores.personality,
            languageCode: languageCode,
          ),
        );

    emit(
      state.copyWith(
        languageCode: languageCode,
        selfProfileId: selfId,
        targetProfileId: targetId,
        selfName: selfMetrics.name,
        selfDate: selfMetrics.formattedDate,
        selfLifePath: selfMetrics.lifePath,
        selfSoul: selfMetrics.soul,
        selfPersonality: selfMetrics.personality,
        selfExpression: selfMetrics.expression,
        targetName: targetMetrics.name,
        targetRelation: targetMetrics.relation,
        targetDate: targetMetrics.formattedDate,
        targetLifePath: targetMetrics.lifePath,
        targetSoul: targetMetrics.soul,
        targetPersonality: targetMetrics.personality,
        targetExpression: targetMetrics.expression,
        overallScore: scores.overall,
        coreScore: scores.core,
        communicationScore: scores.communication,
        expressionScore: expressionScore,
        soulScore: scores.soul,
        personalityScore: scores.personality,
        strengths: compatibilityContent.strengths,
        challenges: compatibilityContent.challenges,
        advice: compatibilityContent.advice,
        quote: compatibilityContent.quote,
        lifePathInsight: lifePathInsight,
        expressionInsight: expressionInsight,
        soulInsight: soulInsight,
        personalityInsight: personalityInsight,
      ),
    );
  }

  void _onLoadedFromHistory(
    ComparisonResultLoadedFromHistory event,
    Emitter<ComparisonResultState> emit,
  ) {
    final CompatibilityHistoryItem item = event.item;
    final String languageCode = event.languageCode.trim().toLowerCase();

    if (state.selfProfileId == item.primaryProfileId &&
        state.targetProfileId == item.targetProfileId &&
        state.languageCode == languageCode &&
        state.overallScore == item.overallScore &&
        state.coreScore == item.coreScore &&
        state.communicationScore == item.communicationScore &&
        state.soulScore == item.soulScore &&
        state.personalityScore == item.personalityScore) {
      return;
    }

    final NumerologyCompatibilityContent compatibilityContent =
        _contentRepository.getCompatibilityContent(
          overallScore: item.overallScore,
          languageCode: languageCode,
        );
    final int expressionScore = CompatibilityScoring.pairScore(
      item.primaryExpression,
      item.targetExpression,
    );
    final ComparisonAspectInsight lifePathInsight =
        ComparisonAspectInsight.fromContent(
          _contentRepository.getCompatibilityAspectContent(
            aspect: CompatibilityAspect.lifePath,
            score: item.coreScore,
            languageCode: languageCode,
          ),
        );
    final ComparisonAspectInsight expressionInsight =
        ComparisonAspectInsight.fromContent(
          _contentRepository.getCompatibilityAspectContent(
            aspect: CompatibilityAspect.expression,
            score: expressionScore,
            languageCode: languageCode,
          ),
        );
    final ComparisonAspectInsight soulInsight =
        ComparisonAspectInsight.fromContent(
          _contentRepository.getCompatibilityAspectContent(
            aspect: CompatibilityAspect.soul,
            score: item.soulScore,
            languageCode: languageCode,
          ),
        );
    final ComparisonAspectInsight personalityInsight =
        ComparisonAspectInsight.fromContent(
          _contentRepository.getCompatibilityAspectContent(
            aspect: CompatibilityAspect.personality,
            score: item.personalityScore,
            languageCode: languageCode,
          ),
        );

    emit(
      state.copyWith(
        languageCode: languageCode,
        selfProfileId: item.primaryProfileId,
        targetProfileId: item.targetProfileId,
        selfName: item.primaryName,
        selfDate: _formatDate(item.primaryBirthDate),
        selfLifePath: item.primaryLifePath,
        selfSoul: item.primarySoul,
        selfPersonality: item.primaryPersonality,
        selfExpression: item.primaryExpression,
        targetName: item.targetName,
        targetRelation: item.targetRelation,
        targetDate: _formatDate(item.targetBirthDate),
        targetLifePath: item.targetLifePath,
        targetSoul: item.targetSoul,
        targetPersonality: item.targetPersonality,
        targetExpression: item.targetExpression,
        overallScore: item.overallScore,
        coreScore: item.coreScore,
        communicationScore: item.communicationScore,
        expressionScore: expressionScore,
        soulScore: item.soulScore,
        personalityScore: item.personalityScore,
        strengths: compatibilityContent.strengths,
        challenges: compatibilityContent.challenges,
        advice: compatibilityContent.advice,
        quote: compatibilityContent.quote,
        lifePathInsight: lifePathInsight,
        expressionInsight: expressionInsight,
        soulInsight: soulInsight,
        personalityInsight: personalityInsight,
      ),
    );
  }

  _ProfileMetrics _buildSelfMetrics(UserProfile profile) {
    return _ProfileMetrics(
      name: profile.name,
      formattedDate: _formatDate(profile.birthDate),
      lifePath: NumerologyHelper.getLifePathNumber(profile.birthDate),
      soul: NumerologyHelper.getSoulUrgeNumber(profile.name),
      personality: NumerologyHelper.getPersonalityNumber(profile.name),
      expression: NumerologyHelper.getExpressionNumber(profile.name),
    );
  }

  _TargetMetrics _buildTargetMetrics(ComparisonProfile profile) {
    return _TargetMetrics(
      name: profile.name,
      relation: profile.relation,
      formattedDate: _formatDate(profile.birthDate),
      lifePath: profile.lifePathNumber,
      soul: NumerologyHelper.getSoulUrgeNumber(profile.name),
      personality: NumerologyHelper.getPersonalityNumber(profile.name),
      expression: NumerologyHelper.getExpressionNumber(profile.name),
    );
  }

  static String _formatDate(DateTime value) {
    return DateFormat('dd/MM/yyyy').format(value);
  }
}

class _ProfileMetrics {
  const _ProfileMetrics({
    required this.name,
    required this.formattedDate,
    required this.lifePath,
    required this.soul,
    required this.personality,
    required this.expression,
  });

  final String name;
  final String formattedDate;
  final int lifePath;
  final int soul;
  final int personality;
  final int expression;
}

class _TargetMetrics {
  const _TargetMetrics({
    required this.name,
    required this.relation,
    required this.formattedDate,
    required this.lifePath,
    required this.soul,
    required this.personality,
    required this.expression,
  });

  final String name;
  final String relation;
  final String formattedDate;
  final int lifePath;
  final int soul;
  final int personality;
  final int expression;
}
