import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:test/src/core/model/app_session_snapshot.dart';
import 'package:test/src/core/model/cloud_login_result.dart';
import 'package:test/src/core/model/comparison_profile.dart';
import 'package:test/src/core/model/profile_life_based_snapshot.dart';
import 'package:test/src/core/model/profile_time_life_snapshot.dart';
import 'package:test/src/core/model/user_profile.dart';
import 'package:test/src/core/repository/interface/i_app_session_repository.dart';
import 'package:test/src/core/repository/interface/i_cloud_account_repository.dart';
import 'package:test/src/helper/numerology_helper.dart';
import 'package:test/src/ui/main/interactor/main_session_event.dart';
import 'package:test/src/ui/main/interactor/main_session_state.dart';
import 'package:test/src/ui/widgets/app_state_view.dart';

class MainSessionBloc extends Bloc<MainSessionEvent, MainSessionState> {
  MainSessionBloc(this._sessionRepository, this._cloudAccountRepository)
    : super(MainSessionState.initial()) {
    on<MainSessionInitializeRequested>(_onInitializeRequested);
    on<MainSessionLoginRequested>(_onLoginRequested);
    on<MainSessionLogoutRequested>(_onLogoutRequested);
    on<MainSessionProfileAdded>(_onProfileAdded);
    on<MainSessionProfileSwitched>(_onProfileSwitched);
    on<MainSessionProfileUpdated>(_onProfileUpdated);
    on<MainSessionProfileRemoved>(_onProfileRemoved);
    on<MainSessionCompareProfileAdded>(_onCompareProfileAdded);
    on<MainSessionCompareProfileSelected>(_onCompareProfileSelected);
    on<MainSessionSoulPointsAdded>(_onSoulPointsAdded);
    on<MainSessionSoulPointsDeducted>(_onSoulPointsDeducted);
    on<MainSessionCheckedIn>(_onCheckedIn);
    on<MainSessionInteractionTracked>(_onInteractionTracked);
    on<MainSessionPageInteractionReset>(_onPageInteractionReset);
    on<MainSessionTimeLifeRefreshRequested>(_onTimeLifeRefreshRequested);
  }

  static const int _interactionThreshold = 5;
  static const String guestProfileId = ProfileTimeLifeSnapshot.guestProfileId;

  final IAppSessionRepository _sessionRepository;
  final ICloudAccountRepository _cloudAccountRepository;

  Future<void> initialize() async {
    final Completer<void> completer = Completer<void>();
    add(MainSessionInitializeRequested(completer: completer));
    await completer.future;
  }

  Future<void> _onInitializeRequested(
    MainSessionInitializeRequested event,
    Emitter<MainSessionState> emit,
  ) async {
    try {
      emit(state.copyWith(viewState: AppViewStateStatus.loading));
      final AppSessionSnapshot snapshot = await _sessionRepository
          .loadSnapshot();
      final UserProfile? currentProfile = _resolveCurrentProfile(
        snapshot.profiles,
        snapshot.currentProfileId,
      );
      emit(
        state.copyWith(
          viewState: AppViewStateStatus.success,
          isAuthenticated: snapshot.isAuthenticated,
          userEmail: snapshot.userEmail,
          userName: snapshot.userName,
          profiles: snapshot.profiles,
          lifeBasedByProfileId: snapshot.lifeBasedByProfileId,
          timeLifeByProfileId: snapshot.timeLifeByProfileId,
          currentProfile: currentProfile,
          soulPoints: snapshot.soulPoints,
          currentStreak: snapshot.currentStreak,
          dailyEarnings: snapshot.dailyEarnings,
          lastCheckInAt: snapshot.lastCheckInAt,
          compareProfiles: snapshot.compareProfiles,
          selectedCompareProfileId: snapshot.selectedCompareProfileId,
          clearErrorMessage: true,
        ),
      );
      await _ensureLifeBasedForCurrentProfile(emit);
      await _refreshTimeLifeForCurrentProfile(emit);
    } catch (_) {
      emit(
        state.copyWith(
          viewState: AppViewStateStatus.error,
          errorMessage: 'session_load_failed',
        ),
      );
    } finally {
      _completeVoid(event.completer);
    }
  }

  Future<void> login({
    required String email,
    required String password,
    required String name,
  }) async {
    final Completer<void> completer = Completer<void>();
    add(
      MainSessionLoginRequested(
        email: email,
        password: password,
        name: name,
        completer: completer,
      ),
    );
    await completer.future;
  }

  Future<void> _onLoginRequested(
    MainSessionLoginRequested event,
    Emitter<MainSessionState> emit,
  ) async {
    try {
      final String normalizedEmail = event.email.trim().toLowerCase();
      final String normalizedName = event.name.trim();
      final AppSessionSnapshot localSnapshotBeforeAuth = AppSessionSnapshot(
        isAuthenticated: true,
        userEmail: normalizedEmail,
        userName: normalizedName,
        profiles: state.profiles,
        lifeBasedByProfileId: state.lifeBasedByProfileId,
        timeLifeByProfileId: state.timeLifeByProfileId,
        currentProfileId: state.currentProfile?.id,
        soulPoints: state.soulPoints,
        currentStreak: state.currentStreak,
        dailyEarnings: state.dailyEarnings,
        lastCheckInAt: state.lastCheckInAt,
        compareProfiles: state.compareProfiles,
        selectedCompareProfileId: state.selectedCompareProfileId,
      );

      if (_cloudAccountRepository.isConfigured) {
        final CloudLoginResult loginResult = await _cloudAccountRepository
            .loginAndSyncFirstTime(
              email: normalizedEmail,
              password: event.password,
              displayName: normalizedName,
              localSnapshot: localSnapshotBeforeAuth,
            );

        // first sync => local snapshot just got uploaded (local wins bootstrap).
        if (loginResult.firstSyncPerformed) {
          await _applySnapshotToState(
            localSnapshotBeforeAuth,
            emit,
            recomputeMetrics: false,
          );
          _completeVoid(event.completer);
          return;
        }

        // existing cloud account => cloud wins local state for v1.
        final AppSessionSnapshot cloudSnapshot = await _cloudAccountRepository
            .fetchCloudSessionSnapshot(
              fallbackEmail: normalizedEmail,
              fallbackDisplayName: normalizedName,
            );
        await _applySnapshotToState(
          cloudSnapshot,
          emit,
          recomputeMetrics: true,
          forceRecomputeMetrics: true,
        );
      } else {
        await _applySnapshotToState(
          localSnapshotBeforeAuth,
          emit,
          recomputeMetrics: false,
        );
      }
      _completeVoid(event.completer);
    } catch (error, stackTrace) {
      _completeError(event.completer, error, stackTrace);
    }
  }

  Future<void> logout() async {
    final Completer<void> completer = Completer<void>();
    add(MainSessionLogoutRequested(completer: completer));
    await completer.future;
  }

  Future<void> _onLogoutRequested(
    MainSessionLogoutRequested event,
    Emitter<MainSessionState> emit,
  ) async {
    try {
      await _cloudAccountRepository.clearSession();
      emit(
        state.copyWith(
          isAuthenticated: false,
          clearUserEmail: true,
          clearUserName: true,
        ),
      );
      await _persistSnapshot();
      _completeVoid(event.completer);
    } catch (error, stackTrace) {
      _completeError(event.completer, error, stackTrace);
    }
  }

  Future<void> addProfile({
    required String name,
    required DateTime birthDate,
  }) async {
    final Completer<void> completer = Completer<void>();
    add(
      MainSessionProfileAdded(
        name: name,
        birthDate: birthDate,
        completer: completer,
      ),
    );
    await completer.future;
  }

  Future<void> _onProfileAdded(
    MainSessionProfileAdded event,
    Emitter<MainSessionState> emit,
  ) async {
    try {
      final UserProfile profile = UserProfile(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: event.name,
        birthDate: event.birthDate,
        createdAt: DateTime.now(),
      );
      final List<UserProfile> profiles = <UserProfile>[
        ...state.profiles,
        profile,
      ];
      emit(state.copyWith(profiles: profiles, currentProfile: profile));
      await _persistSnapshot();
      await _ensureLifeBasedForCurrentProfile(emit, force: true);
      await _refreshTimeLifeForCurrentProfile(emit);
      _completeVoid(event.completer);
    } catch (error, stackTrace) {
      _completeError(event.completer, error, stackTrace);
    }
  }

  Future<void> switchProfile(String profileId) async {
    final Completer<void> completer = Completer<void>();
    add(MainSessionProfileSwitched(profileId: profileId, completer: completer));
    await completer.future;
  }

  Future<void> _onProfileSwitched(
    MainSessionProfileSwitched event,
    Emitter<MainSessionState> emit,
  ) async {
    try {
      final UserProfile? profile = _findProfileById(
        state.profiles,
        event.profileId,
      );
      if (profile == null) {
        _completeVoid(event.completer);
        return;
      }
      emit(state.copyWith(currentProfile: profile));
      await _persistSnapshot();
      await _ensureLifeBasedForCurrentProfile(emit);
      await _refreshTimeLifeForCurrentProfile(emit);
      _completeVoid(event.completer);
    } catch (error, stackTrace) {
      _completeError(event.completer, error, stackTrace);
    }
  }

  Future<void> updateProfile({
    required String profileId,
    required String name,
    required DateTime birthDate,
  }) async {
    final Completer<void> completer = Completer<void>();
    add(
      MainSessionProfileUpdated(
        profileId: profileId,
        name: name,
        birthDate: birthDate,
        completer: completer,
      ),
    );
    await completer.future;
  }

  Future<void> _onProfileUpdated(
    MainSessionProfileUpdated event,
    Emitter<MainSessionState> emit,
  ) async {
    try {
      final List<UserProfile> profiles = state.profiles
          .map(
            (UserProfile profile) => profile.id == event.profileId
                ? profile.copyWith(name: event.name, birthDate: event.birthDate)
                : profile,
          )
          .toList();
      final UserProfile? currentProfile = _resolveCurrentProfile(
        profiles,
        state.currentProfile?.id,
      );
      final Map<String, ProfileLifeBasedSnapshot> nextLifeBasedByProfileId =
          Map<String, ProfileLifeBasedSnapshot>.from(state.lifeBasedByProfileId)
            ..remove(event.profileId);
      final Map<String, ProfileTimeLifeSnapshot> nextTimeLifeByProfileId =
          Map<String, ProfileTimeLifeSnapshot>.from(state.timeLifeByProfileId)
            ..remove(event.profileId);
      emit(
        state.copyWith(
          profiles: profiles,
          currentProfile: currentProfile,
          lifeBasedByProfileId: nextLifeBasedByProfileId,
          timeLifeByProfileId: nextTimeLifeByProfileId,
        ),
      );
      await _persistSnapshot();

      if (currentProfile?.id == event.profileId) {
        await _ensureLifeBasedForCurrentProfile(emit, force: true);
        await _refreshTimeLifeForCurrentProfile(emit, force: true);
      }
      _completeVoid(event.completer);
    } catch (error, stackTrace) {
      _completeError(event.completer, error, stackTrace);
    }
  }

  Future<void> removeProfile(String profileId) async {
    final Completer<void> completer = Completer<void>();
    add(MainSessionProfileRemoved(profileId: profileId, completer: completer));
    await completer.future;
  }

  Future<void> _onProfileRemoved(
    MainSessionProfileRemoved event,
    Emitter<MainSessionState> emit,
  ) async {
    try {
      final List<UserProfile> profiles = state.profiles
          .where((UserProfile profile) => profile.id != event.profileId)
          .toList();
      final Map<String, ProfileLifeBasedSnapshot> lifeBasedByProfileId =
          Map<String, ProfileLifeBasedSnapshot>.from(state.lifeBasedByProfileId)
            ..remove(event.profileId);
      final Map<String, ProfileTimeLifeSnapshot> timeLifeByProfileId =
          Map<String, ProfileTimeLifeSnapshot>.from(state.timeLifeByProfileId)
            ..remove(event.profileId);
      final UserProfile? currentProfile = _resolveCurrentProfile(
        profiles,
        state.currentProfile?.id == event.profileId
            ? (profiles.isNotEmpty ? profiles.first.id : null)
            : state.currentProfile?.id,
      );
      emit(
        state.copyWith(
          profiles: profiles,
          lifeBasedByProfileId: lifeBasedByProfileId,
          timeLifeByProfileId: timeLifeByProfileId,
          currentProfile: currentProfile,
        ),
      );
      await _persistSnapshot();
      await _ensureLifeBasedForCurrentProfile(emit);
      await _refreshTimeLifeForCurrentProfile(emit);
      _completeVoid(event.completer);
    } catch (error, stackTrace) {
      _completeError(event.completer, error, stackTrace);
    }
  }

  Future<void> addCompareProfile({
    required String name,
    required String relation,
    required DateTime birthDate,
  }) async {
    final Completer<void> completer = Completer<void>();
    add(
      MainSessionCompareProfileAdded(
        name: name,
        relation: relation,
        birthDate: birthDate,
        completer: completer,
      ),
    );
    await completer.future;
  }

  Future<void> _onCompareProfileAdded(
    MainSessionCompareProfileAdded event,
    Emitter<MainSessionState> emit,
  ) async {
    try {
      final ComparisonProfile profile = ComparisonProfile(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: event.name.trim(),
        relation: event.relation.trim(),
        birthDate: event.birthDate,
        lifePathNumber: NumerologyHelper.getLifePathNumber(event.birthDate),
      );
      emit(
        state.copyWith(
          compareProfiles: <ComparisonProfile>[
            ...state.compareProfiles,
            profile,
          ],
          selectedCompareProfileId: profile.id,
        ),
      );
      await _persistSnapshot();
      _completeVoid(event.completer);
    } catch (error, stackTrace) {
      _completeError(event.completer, error, stackTrace);
    }
  }

  Future<void> selectCompareProfile(String profileId) async {
    final Completer<void> completer = Completer<void>();
    add(
      MainSessionCompareProfileSelected(
        profileId: profileId,
        completer: completer,
      ),
    );
    await completer.future;
  }

  Future<void> _onCompareProfileSelected(
    MainSessionCompareProfileSelected event,
    Emitter<MainSessionState> emit,
  ) async {
    try {
      if (!state.compareProfiles.any(
        (ComparisonProfile profile) => profile.id == event.profileId,
      )) {
        _completeVoid(event.completer);
        return;
      }
      emit(state.copyWith(selectedCompareProfileId: event.profileId));
      await _persistSnapshot();
      _completeVoid(event.completer);
    } catch (error, stackTrace) {
      _completeError(event.completer, error, stackTrace);
    }
  }

  Future<void> addSoulPoints(int amount) async {
    final Completer<void> completer = Completer<void>();
    add(MainSessionSoulPointsAdded(amount: amount, completer: completer));
    await completer.future;
  }

  Future<void> _onSoulPointsAdded(
    MainSessionSoulPointsAdded event,
    Emitter<MainSessionState> emit,
  ) async {
    try {
      emit(state.copyWith(soulPoints: state.soulPoints + event.amount));
      await _persistSnapshot();
      _completeVoid(event.completer);
    } catch (error, stackTrace) {
      _completeError(event.completer, error, stackTrace);
    }
  }

  Future<bool> deductSoulPoints(int amount) async {
    final Completer<bool> completer = Completer<bool>();
    add(MainSessionSoulPointsDeducted(amount: amount, completer: completer));
    return completer.future;
  }

  Future<void> _onSoulPointsDeducted(
    MainSessionSoulPointsDeducted event,
    Emitter<MainSessionState> emit,
  ) async {
    try {
      if (state.soulPoints < event.amount) {
        _completeBool(event.completer, false);
        return;
      }
      emit(state.copyWith(soulPoints: state.soulPoints - event.amount));
      await _persistSnapshot();
      _completeBool(event.completer, true);
    } catch (error, stackTrace) {
      _completeError(event.completer, error, stackTrace);
    }
  }

  Future<void> checkIn() async {
    final Completer<void> completer = Completer<void>();
    add(MainSessionCheckedIn(completer: completer));
    await completer.future;
  }

  Future<void> _onCheckedIn(
    MainSessionCheckedIn event,
    Emitter<MainSessionState> emit,
  ) async {
    try {
      if (state.hasCheckedInToday || state.dailyEarnings >= state.dailyLimit) {
        _completeVoid(event.completer);
        return;
      }

      final int reward = _rewardByStreak(state.currentStreak);
      final int nextEarning = (state.dailyEarnings + reward).clamp(
        0,
        state.dailyLimit,
      );

      emit(
        state.copyWith(
          dailyEarnings: nextEarning,
          currentStreak: state.currentStreak + 1,
          soulPoints: state.soulPoints + reward,
          lastCheckInAt: DateTime.now(),
        ),
      );
      await _persistSnapshot();
      _completeVoid(event.completer);
    } catch (error, stackTrace) {
      _completeError(event.completer, error, stackTrace);
    }
  }

  void trackInteraction(String page) {
    add(MainSessionInteractionTracked(page));
  }

  void _onInteractionTracked(
    MainSessionInteractionTracked event,
    Emitter<MainSessionState> emit,
  ) {
    if (state.currentPageInteraction != event.page) {
      emit(
        state.copyWith(currentPageInteraction: event.page, interactionCount: 1),
      );
      return;
    }
    emit(state.copyWith(interactionCount: state.interactionCount + 1));
  }

  void resetPageInteraction(String page) {
    add(MainSessionPageInteractionReset(page));
  }

  void _onPageInteractionReset(
    MainSessionPageInteractionReset event,
    Emitter<MainSessionState> emit,
  ) {
    emit(
      state.copyWith(currentPageInteraction: event.page, interactionCount: 0),
    );
  }

  bool shouldShowProfilePrompt(String page) {
    return state.currentPageInteraction == page &&
        state.interactionCount >= _interactionThreshold &&
        !state.hasAnyProfile;
  }

  Future<void> refreshTimeLifeForCurrentProfile({
    DateTime? now,
    bool force = false,
  }) async {
    final Completer<void> completer = Completer<void>();
    add(
      MainSessionTimeLifeRefreshRequested(
        now: now,
        force: force,
        completer: completer,
      ),
    );
    await completer.future;
  }

  Future<void> _onTimeLifeRefreshRequested(
    MainSessionTimeLifeRefreshRequested event,
    Emitter<MainSessionState> emit,
  ) async {
    try {
      await _refreshTimeLifeForCurrentProfile(
        emit,
        now: event.now,
        force: event.force,
      );
      _completeVoid(event.completer);
    } catch (error, stackTrace) {
      _completeError(event.completer, error, stackTrace);
    }
  }

  Future<void> _refreshTimeLifeForCurrentProfile(
    Emitter<MainSessionState> emit, {
    DateTime? now,
    bool force = false,
  }) async {
    final DateTime currentTime = now ?? DateTime.now();
    final UserProfile? profile = state.currentProfile;
    final String profileId = _activeTimeLifeProfileId(profile);
    final ProfileTimeLifeSnapshot existing =
        state.timeLifeByProfileId[profileId] ??
        ProfileTimeLifeSnapshot.initial();

    final bool shouldRefreshUniversalDay =
        force ||
        existing.needsRefresh(
          ProfileTimeLifeSnapshot.universalDayMetric,
          currentTime,
        );
    final bool shouldRefreshLuckyNumber =
        force ||
        existing.needsRefresh(
          ProfileTimeLifeSnapshot.luckyNumberMetric,
          currentTime,
        );
    final bool shouldRefreshDailyMessage =
        force ||
        existing.needsRefresh(
          ProfileTimeLifeSnapshot.dailyMessageNumberMetric,
          currentTime,
        );
    final bool shouldRefreshDaily =
        shouldRefreshUniversalDay ||
        shouldRefreshLuckyNumber ||
        shouldRefreshDailyMessage;

    final bool shouldRefreshPersonalYear =
        profile != null &&
        (force ||
            existing.needsRefresh(
              ProfileTimeLifeSnapshot.personalYearMetric,
              currentTime,
            ));
    final bool shouldRefreshPersonalMonth =
        profile != null &&
        (force ||
            existing.needsRefresh(
              ProfileTimeLifeSnapshot.personalMonthMetric,
              currentTime,
            ));
    final bool shouldRefreshPersonalDay =
        profile != null &&
        (force ||
            existing.needsRefresh(
              ProfileTimeLifeSnapshot.personalDayMetric,
              currentTime,
            ));

    if (!shouldRefreshDaily &&
        !shouldRefreshPersonalYear &&
        !shouldRefreshPersonalMonth &&
        !shouldRefreshPersonalDay) {
      return;
    }

    ProfileTimeLifeSnapshot snapshot = existing;

    if (shouldRefreshDaily) {
      final int universalDay = NumerologyHelper.calculateUniversalDayNumber(
        currentTime,
      );
      final int luckyNumber = NumerologyHelper.luckyNumber(currentTime);
      final DateTime dailyRefreshAt = _nextDailyRefreshAt(currentTime);

      if (shouldRefreshUniversalDay) {
        snapshot = snapshot.upsertMetric(
          key: ProfileTimeLifeSnapshot.universalDayMetric,
          snapshot: TimeLifeMetricSnapshot(
            value: universalDay,
            computedAt: currentTime,
            refreshAt: dailyRefreshAt,
          ),
        );
      }
      if (shouldRefreshLuckyNumber) {
        snapshot = snapshot.upsertMetric(
          key: ProfileTimeLifeSnapshot.luckyNumberMetric,
          snapshot: TimeLifeMetricSnapshot(
            value: luckyNumber,
            computedAt: currentTime,
            refreshAt: dailyRefreshAt,
          ),
        );
      }
      if (shouldRefreshDailyMessage) {
        snapshot = snapshot.upsertMetric(
          key: ProfileTimeLifeSnapshot.dailyMessageNumberMetric,
          snapshot: TimeLifeMetricSnapshot(
            value: universalDay,
            computedAt: currentTime,
            refreshAt: dailyRefreshAt,
          ),
        );
      }
    }

    if (profile != null) {
      if (shouldRefreshPersonalYear) {
        snapshot = snapshot.upsertMetric(
          key: ProfileTimeLifeSnapshot.personalYearMetric,
          snapshot: TimeLifeMetricSnapshot(
            value: NumerologyHelper.calculatePersonalYearNumber(
              birthDate: profile.birthDate,
              date: currentTime,
            ),
            computedAt: currentTime,
            refreshAt: _nextYearlyRefreshAt(currentTime),
          ),
        );
      }
      if (shouldRefreshPersonalMonth) {
        snapshot = snapshot.upsertMetric(
          key: ProfileTimeLifeSnapshot.personalMonthMetric,
          snapshot: TimeLifeMetricSnapshot(
            value: NumerologyHelper.calculatePersonalMonthNumber(
              birthDate: profile.birthDate,
              date: currentTime,
            ),
            computedAt: currentTime,
            refreshAt: _nextMonthlyRefreshAt(currentTime),
          ),
        );
      }
      if (shouldRefreshPersonalDay) {
        snapshot = snapshot.upsertMetric(
          key: ProfileTimeLifeSnapshot.personalDayMetric,
          snapshot: TimeLifeMetricSnapshot(
            value: NumerologyHelper.calculatePersonalDayNumber(
              birthDate: profile.birthDate,
              date: currentTime,
            ),
            computedAt: currentTime,
            refreshAt: _nextDailyRefreshAt(currentTime),
          ),
        );
      }
    }

    final Map<String, ProfileTimeLifeSnapshot> nextTimeLifeByProfileId =
        Map<String, ProfileTimeLifeSnapshot>.from(state.timeLifeByProfileId)
          ..[profileId] = snapshot;
    emit(state.copyWith(timeLifeByProfileId: nextTimeLifeByProfileId));
    await _persistSnapshot();
  }

  // đảm bảo profile hiện tại đã có lifebased, nếu chưa thì tính toán lại
  Future<void> _ensureLifeBasedForCurrentProfile(
    Emitter<MainSessionState> emit, {
    DateTime? now,
    bool force = false,
  }) async {
    final UserProfile? profile = state.currentProfile;
    if (profile == null) {
      return;
    }

    final ProfileLifeBasedSnapshot? existing =
        state.lifeBasedByProfileId[profile.id];
    if (!force && existing != null && existing.metrics.isNotEmpty) {
      return;
    }

    final DateTime currentTime = now ?? DateTime.now();
    final ProfileLifeBasedSnapshot snapshot = ProfileLifeBasedSnapshot(
      computedAt: currentTime,
      metrics: <String, int>{
        ProfileLifeBasedSnapshot.lifePathMetric:
            NumerologyHelper.getLifePathNumber(profile.birthDate),
        ProfileLifeBasedSnapshot.expressionMetric:
            NumerologyHelper.getExpressionNumber(profile.name),
        ProfileLifeBasedSnapshot.soulUrgeMetric:
            NumerologyHelper.getSoulUrgeNumber(profile.name),
        ProfileLifeBasedSnapshot.personalityMetric:
            NumerologyHelper.getPersonalityNumber(profile.name),
        ProfileLifeBasedSnapshot.missionMetric:
            NumerologyHelper.getMissionNumber(profile.birthDate, profile.name),
      },
    );

    final Map<String, ProfileLifeBasedSnapshot> nextLifeBasedByProfileId =
        Map<String, ProfileLifeBasedSnapshot>.from(state.lifeBasedByProfileId)
          ..[profile.id] = snapshot;
    emit(state.copyWith(lifeBasedByProfileId: nextLifeBasedByProfileId));
    await _persistSnapshot();
  }

  Future<void> _persistSnapshot() async {
    final AppSessionSnapshot snapshot = AppSessionSnapshot(
      isAuthenticated: state.isAuthenticated,
      userEmail: state.userEmail,
      userName: state.userName,
      profiles: state.profiles,
      lifeBasedByProfileId: state.lifeBasedByProfileId,
      timeLifeByProfileId: state.timeLifeByProfileId,
      currentProfileId: state.currentProfile?.id,
      soulPoints: state.soulPoints,
      currentStreak: state.currentStreak,
      dailyEarnings: state.dailyEarnings,
      lastCheckInAt: state.lastCheckInAt,
      compareProfiles: state.compareProfiles,
      selectedCompareProfileId: state.selectedCompareProfileId,
    );
    await _sessionRepository.saveSnapshot(snapshot);
  }

  Future<void> _applySnapshotToState(
    AppSessionSnapshot snapshot,
    Emitter<MainSessionState> emit, {
    required bool recomputeMetrics,
    bool forceRecomputeMetrics = false,
  }) async {
    final UserProfile? currentProfile = _resolveCurrentProfile(
      snapshot.profiles,
      snapshot.currentProfileId,
    );

    emit(
      state.copyWith(
        isAuthenticated: snapshot.isAuthenticated,
        userEmail: snapshot.userEmail,
        userName: snapshot.userName,
        profiles: snapshot.profiles,
        lifeBasedByProfileId: snapshot.lifeBasedByProfileId,
        timeLifeByProfileId: snapshot.timeLifeByProfileId,
        currentProfile: currentProfile,
        soulPoints: snapshot.soulPoints,
        currentStreak: snapshot.currentStreak,
        dailyEarnings: snapshot.dailyEarnings,
        lastCheckInAt: snapshot.lastCheckInAt,
        compareProfiles: snapshot.compareProfiles,
        selectedCompareProfileId: snapshot.selectedCompareProfileId,
        clearErrorMessage: true,
      ),
    );
    await _persistSnapshot();
    if (!recomputeMetrics) {
      return;
    }
    await _ensureLifeBasedForCurrentProfile(emit, force: forceRecomputeMetrics);
    await _refreshTimeLifeForCurrentProfile(emit, force: forceRecomputeMetrics);
  }

  static int _rewardByStreak(int streak) {
    if (streak >= 30) {
      return 30;
    }
    if (streak >= 14) {
      return 20;
    }
    if (streak >= 7) {
      return 15;
    }
    return 10;
  }

  static UserProfile? _resolveCurrentProfile(
    List<UserProfile> profiles,
    String? profileId,
  ) {
    if (profiles.isEmpty) {
      return null;
    }
    if (profileId == null) {
      return profiles.first;
    }
    return _findProfileById(profiles, profileId) ?? profiles.first;
  }

  static UserProfile? _findProfileById(
    List<UserProfile> profiles,
    String profileId,
  ) {
    for (final UserProfile profile in profiles) {
      if (profile.id == profileId) {
        return profile;
      }
    }
    return null;
  }

  static String _activeTimeLifeProfileId(UserProfile? profile) {
    return profile?.id ?? guestProfileId;
  }

  static DateTime _nextDailyRefreshAt(DateTime now) {
    return DateTime(now.year, now.month, now.day + 1);
  }

  static DateTime _nextMonthlyRefreshAt(DateTime now) {
    return DateTime(now.year, now.month + 1, 1);
  }

  static DateTime _nextYearlyRefreshAt(DateTime now) {
    return DateTime(now.year + 1, 1, 1);
  }

  static void _completeVoid(Completer<void> completer) {
    if (!completer.isCompleted) {
      completer.complete();
    }
  }

  static void _completeBool(Completer<bool> completer, bool value) {
    if (!completer.isCompleted) {
      completer.complete(value);
    }
  }

  static void _completeError<T>(
    Completer<T> completer,
    Object error,
    StackTrace stackTrace,
  ) {
    if (!completer.isCompleted) {
      completer.completeError(error, stackTrace);
    }
  }
}
