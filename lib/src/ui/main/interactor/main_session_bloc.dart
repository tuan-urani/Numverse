import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:test/src/core/model/app_session_snapshot.dart';
import 'package:test/src/core/model/cloud_ad_reward_grant_result.dart';
import 'package:test/src/core/model/cloud_ad_reward_status_result.dart';
import 'package:test/src/core/model/cloud_login_result.dart';
import 'package:test/src/core/model/cloud_error_codes.dart';
import 'package:test/src/core/model/comparison_profile.dart';
import 'package:test/src/core/model/compatibility_history_item.dart';
import 'package:test/src/core/model/cloud_daily_checkin_result.dart';
import 'package:test/src/core/model/profile_life_based_snapshot.dart';
import 'package:test/src/core/model/profile_time_life_snapshot.dart';
import 'package:test/src/core/model/session_auth_mode.dart';
import 'package:test/src/core/model/user_profile.dart';
import 'package:test/src/core/repository/interface/i_app_session_repository.dart';
import 'package:test/src/core/repository/interface/i_cloud_account_repository.dart';
import 'package:test/src/ui/main/interactor/main_session_event.dart';
import 'package:test/src/ui/main/interactor/main_session_state.dart';
import 'package:test/src/ui/main/interactor/services/session_auth_service.dart';
import 'package:test/src/ui/main/interactor/services/session_compare_service.dart';
import 'package:test/src/ui/main/interactor/services/session_metrics_service.dart';
import 'package:test/src/ui/main/interactor/services/session_profile_service.dart';
import 'package:test/src/ui/main/interactor/services/session_prompt_service.dart';
import 'package:test/src/ui/main/interactor/services/session_reward_service.dart';
import 'package:test/src/ui/widgets/app_state_view.dart';

class MainSessionBloc extends Bloc<MainSessionEvent, MainSessionState> {
  static const int _compatibilityHistoryMaxItems = 100;

  /// Khởi tạo bloc session trung tâm và đăng ký toàn bộ event handler.
  MainSessionBloc(
    this._sessionRepository,
    this._cloudAccountRepository, {
    SessionAuthService? authService,
    SessionProfileService? profileService,
    SessionMetricsService? metricsService,
    SessionRewardService? rewardService,
    SessionCompareService? compareService,
    SessionPromptService? promptService,
  }) : _authService = authService ?? const SessionAuthService(),
       _profileService = profileService ?? const SessionProfileService(),
       _metricsService = metricsService ?? const SessionMetricsService(),
       _rewardService = rewardService ?? const SessionRewardService(),
       _compareService = compareService ?? const SessionCompareService(),
       _promptService = promptService ?? const SessionPromptService(),
       super(MainSessionState.initial()) {
    on<MainSessionInitializeRequested>(_onInitializeRequested);
    on<MainSessionLoginRequested>(_onLoginRequested);
    on<MainSessionRegisterRequested>(_onRegisterRequested);
    on<MainSessionLogoutRequested>(_onLogoutRequested);
    on<MainSessionProfileAdded>(_onProfileAdded);
    on<MainSessionProfileSwitched>(_onProfileSwitched);
    on<MainSessionProfileUpdated>(_onProfileUpdated);
    on<MainSessionProfileRemoved>(_onProfileRemoved);
    on<MainSessionCompareProfileAdded>(_onCompareProfileAdded);
    on<MainSessionCompareProfileSelected>(_onCompareProfileSelected);
    on<MainSessionCompatibilityHistorySaved>(_onCompatibilityHistorySaved);
    on<MainSessionSoulPointsAdded>(_onSoulPointsAdded);
    on<MainSessionAdRewardClaimed>(_onAdRewardClaimed);
    on<MainSessionAdRewardStatusRefreshRequested>(
      _onAdRewardStatusRefreshRequested,
    );
    on<MainSessionSoulPointsDeducted>(_onSoulPointsDeducted);
    on<MainSessionSoulPointsSynced>(_onSoulPointsSynced);
    on<MainSessionCheckedIn>(_onCheckedIn);
    on<MainSessionStartupAutoCheckInRequested>(_onStartupAutoCheckInRequested);
    on<MainSessionCheckInCelebrationConsumed>(_onCheckInCelebrationConsumed);
    on<MainSessionInteractionTracked>(_onInteractionTracked);
    on<MainSessionPageInteractionReset>(_onPageInteractionReset);
    on<MainSessionTimeLifeRefreshRequested>(_onTimeLifeRefreshRequested);
  }

  static const String guestProfileId = ProfileTimeLifeSnapshot.guestProfileId;

  final IAppSessionRepository _sessionRepository;
  final ICloudAccountRepository _cloudAccountRepository;
  final SessionAuthService _authService;
  final SessionProfileService _profileService;
  final SessionMetricsService _metricsService;
  final SessionRewardService _rewardService;
  final SessionCompareService _compareService;
  final SessionPromptService _promptService;

  /// API public để khởi tạo session: dispatch event và chờ hoàn tất.
  Future<void> initialize() async {
    final Completer<void> completer = Completer<void>();
    add(MainSessionInitializeRequested(completer: completer));
    await completer.future;
  }

  /// Xử lý khởi tạo: bootstrap cloud session (bắt buộc online) và hydrate state.
  Future<void> _onInitializeRequested(
    MainSessionInitializeRequested event,
    Emitter<MainSessionState> emit,
  ) async {
    // Startup path ưu tiên cloud snapshot để tránh phụ thuộc local backup khi boot.
    try {
      emit(state.copyWith(viewState: AppViewStateStatus.loading));
      AppSessionSnapshot effectiveSnapshot;
      if (_cloudAccountRepository.isConfigured) {
        await _cloudAccountRepository.ensureAnonymousSession();
        final AppSessionSnapshot cloudSnapshot = await _cloudAccountRepository
            .fetchCloudSessionSnapshot(
              fallbackEmail: '',
              fallbackDisplayName: '',
            );
        final String resolvedCloudUserId =
            (_cloudAccountRepository.currentUserId ?? cloudSnapshot.cloudUserId)
                ?.trim() ??
            '';
        effectiveSnapshot = cloudSnapshot.copyWith(
          isAuthenticated: true,
          pendingAnonymousBootstrap: false,
          cloudUserId: resolvedCloudUserId.isEmpty ? null : resolvedCloudUserId,
          clearCloudUserId: resolvedCloudUserId.isEmpty,
        );
      } else {
        // Dev fallback khi Supabase chưa cấu hình.
        effectiveSnapshot = await _sessionRepository.loadSnapshot();
      }

      final UserProfile? currentProfile = _profileService.resolveCurrentProfile(
        effectiveSnapshot.profiles,
        effectiveSnapshot.currentProfileId,
      );
      emit(
        state.copyWith(
          viewState: AppViewStateStatus.success,
          isAuthenticated: effectiveSnapshot.isAuthenticated,
          authMode: effectiveSnapshot.authMode,
          pendingAnonymousBootstrap:
              effectiveSnapshot.pendingAnonymousBootstrap,
          cloudUserId: effectiveSnapshot.cloudUserId,
          userEmail: effectiveSnapshot.userEmail,
          clearUserEmail: effectiveSnapshot.userEmail == null,
          userName: effectiveSnapshot.userName,
          clearUserName: effectiveSnapshot.userName == null,
          profiles: effectiveSnapshot.profiles,
          lifeBasedByProfileId: effectiveSnapshot.lifeBasedByProfileId,
          timeLifeByProfileId: effectiveSnapshot.timeLifeByProfileId,
          currentProfile: currentProfile,
          clearCurrentProfile: currentProfile == null,
          soulPoints: effectiveSnapshot.soulPoints,
          currentStreak: effectiveSnapshot.currentStreak,
          dailyEarnings: effectiveSnapshot.dailyEarnings,
          dailyAdEarnings: effectiveSnapshot.dailyAdEarnings,
          dailyAdLimit: effectiveSnapshot.dailyAdLimit,
          dailyAngelNumber: effectiveSnapshot.dailyAngelNumber,
          dailyAngelRefreshAt: effectiveSnapshot.dailyAngelRefreshAt,
          lastCheckInAt: effectiveSnapshot.lastCheckInAt,
          lastAdRewardAt: effectiveSnapshot.lastAdRewardAt,
          compareProfiles: effectiveSnapshot.compareProfiles,
          selectedCompareProfileId: effectiveSnapshot.selectedCompareProfileId,
          compatibilityHistory: effectiveSnapshot.compatibilityHistory,
          clearErrorMessage: true,
        ),
      );
      await _persistSnapshot();
      await _normalizeGuestRewardStateIfNeeded(emit);
      await _normalizeAdRewardStateIfNeeded(emit);
      await _ensureLifeBasedForCurrentProfile(emit);
      await _refreshTimeLifeForCurrentProfile(emit);
      _triggerStartupAutoCheckInIfEligible();
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

  /// API public đăng nhập: dispatch event rồi chờ flow login/sync xong.
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

  /// API public đăng ký: nếu user chưa tồn tại thì tạo account rồi đăng nhập.
  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final Completer<void> completer = Completer<void>();
    add(
      MainSessionRegisterRequested(
        email: email,
        password: password,
        name: name,
        completer: completer,
      ),
    );
    await completer.future;
  }

  /// Xử lý đăng nhập và đồng bộ dữ liệu giữa local/cloud theo policy hiện tại.
  Future<void> _onLoginRequested(
    MainSessionLoginRequested event,
    Emitter<MainSessionState> emit,
  ) async {
    // Chuẩn hóa thông tin đăng nhập và xử lý chiến lược sync cloud/local.
    // - first sync: local wins bootstrap
    // - account đã có dữ liệu cloud: cloud wins (v1)
    try {
      final NormalizedIdentity identity = _authService.normalizeIdentity(
        email: event.email,
        name: event.name,
      );

      if (_cloudAccountRepository.isConfigured &&
          state.authMode == SessionAuthMode.anonymous &&
          state.hasCloudSession) {
        await _cloudAccountRepository.signInExistingAccount(
          email: identity.email,
          password: event.password,
        );
        final AppSessionSnapshot cloudSnapshot = await _cloudAccountRepository
            .fetchCloudSessionSnapshot(
              fallbackEmail: identity.email,
              fallbackDisplayName: identity.name,
            );
        await _applySnapshotToState(
          cloudSnapshot.copyWith(
            authMode: SessionAuthMode.registered,
            pendingAnonymousBootstrap: false,
            cloudUserId: _cloudAccountRepository.currentUserId,
          ),
          emit,
          recomputeMetrics: true,
          forceRecomputeMetrics: true,
        );
        _completeVoid(event.completer);
        return;
      }

      final AppSessionSnapshot localSnapshotBeforeAuth = _authService
          .buildLocalSnapshotBeforeAuth(state: state, identity: identity);

      if (_cloudAccountRepository.isConfigured) {
        final CloudLoginResult loginResult = await _cloudAccountRepository
            .loginAndSyncFirstTime(
              email: identity.email,
              password: event.password,
              displayName: identity.name,
              localSnapshot: localSnapshotBeforeAuth,
            );

        if (loginResult.firstSyncPerformed) {
          await _applySnapshotToState(
            localSnapshotBeforeAuth,
            emit,
            recomputeMetrics: false,
          );
          _completeVoid(event.completer);
          return;
        }

        final AppSessionSnapshot cloudSnapshot = await _cloudAccountRepository
            .fetchCloudSessionSnapshot(
              fallbackEmail: identity.email,
              fallbackDisplayName: identity.name,
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

  /// Xử lý đăng ký account và đồng bộ dữ liệu sau khi đăng ký thành công.
  Future<void> _onRegisterRequested(
    MainSessionRegisterRequested event,
    Emitter<MainSessionState> emit,
  ) async {
    try {
      final NormalizedIdentity identity = _authService.normalizeIdentity(
        email: event.email,
        name: event.name,
      );
      final AppSessionSnapshot localSnapshotBeforeAuth = _authService
          .buildLocalSnapshotBeforeAuth(state: state, identity: identity);

      if (_cloudAccountRepository.isConfigured &&
          state.authMode == SessionAuthMode.anonymous &&
          state.hasCloudSession) {
        await _cloudAccountRepository.upgradeAnonymousToEmail(
          email: identity.email,
          password: event.password,
          displayName: identity.name,
        );
        await _applySnapshotToState(
          localSnapshotBeforeAuth.copyWith(
            authMode: SessionAuthMode.registered,
            pendingAnonymousBootstrap: false,
            cloudUserId: _cloudAccountRepository.currentUserId,
          ),
          emit,
          recomputeMetrics: false,
        );
        await _persistSnapshot(syncCloud: true);
        _completeVoid(event.completer);
        return;
      }

      if (_cloudAccountRepository.isConfigured) {
        final CloudLoginResult loginResult = await _cloudAccountRepository
            .registerAndSyncFirstTime(
              email: identity.email,
              password: event.password,
              displayName: identity.name,
              localSnapshot: localSnapshotBeforeAuth,
            );
        if (loginResult.firstSyncPerformed) {
          await _applySnapshotToState(
            localSnapshotBeforeAuth,
            emit,
            recomputeMetrics: false,
          );
          _completeVoid(event.completer);
          return;
        }

        final AppSessionSnapshot cloudSnapshot = await _cloudAccountRepository
            .fetchCloudSessionSnapshot(
              fallbackEmail: identity.email,
              fallbackDisplayName: identity.name,
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

  /// API public đăng xuất: clear cloud session, xóa local storage, reset state.
  Future<void> logout() async {
    final Completer<void> completer = Completer<void>();
    add(MainSessionLogoutRequested(completer: completer));
    await completer.future;
  }

  /// Xử lý đăng xuất: clear session cloud và cập nhật trạng thái local.
  Future<void> _onLogoutRequested(
    MainSessionLogoutRequested event,
    Emitter<MainSessionState> emit,
  ) async {
    // Đăng xuất khỏi cloud, xoá local storage, sau đó bootstrap lại anonymous cloud session.
    try {
      await _cloudAccountRepository.clearSession();
      await _sessionRepository.clear();
      emit(
        MainSessionState.initial().copyWith(
          viewState: AppViewStateStatus.success,
        ),
      );
      if (!_cloudAccountRepository.isConfigured) {
        _completeVoid(event.completer);
        return;
      }

      await _cloudAccountRepository.ensureAnonymousSession();
      final AppSessionSnapshot cloudSnapshot = await _cloudAccountRepository
          .fetchCloudSessionSnapshot(
            fallbackEmail: '',
            fallbackDisplayName: '',
          );
      final String resolvedCloudUserId =
          (_cloudAccountRepository.currentUserId ?? cloudSnapshot.cloudUserId)
              ?.trim() ??
          '';
      await _applySnapshotToState(
        cloudSnapshot.copyWith(
          isAuthenticated: true,
          authMode: SessionAuthMode.anonymous,
          pendingAnonymousBootstrap: false,
          cloudUserId: resolvedCloudUserId.isEmpty ? null : resolvedCloudUserId,
          clearCloudUserId: resolvedCloudUserId.isEmpty,
          clearUserEmail: true,
        ),
        emit,
        recomputeMetrics: true,
        forceRecomputeMetrics: true,
      );
      _completeVoid(event.completer);
    } catch (error, stackTrace) {
      _completeError(event.completer, error, stackTrace);
    }
  }

  /// API public thêm profile mới vào session hiện tại.
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

  /// Xử lý thêm profile mới và tính lại các metrics liên quan.
  Future<void> _onProfileAdded(
    MainSessionProfileAdded event,
    Emitter<MainSessionState> emit,
  ) async {
    // Tạo profile mới, set làm current profile, persist, rồi tính lại metrics.
    final MainSessionState previousState = state;
    try {
      final UserProfile profile = _profileService.createProfile(
        name: event.name,
        birthDate: event.birthDate,
      );
      final List<UserProfile> profiles = <UserProfile>[
        ...state.profiles,
        profile,
      ];
      emit(state.copyWith(profiles: profiles, currentProfile: profile));
      await _persistSnapshot(
        syncCloud: true,
        rethrowCloudErrorCodes: const <String>{kCloudErrorProfileLimitReached},
      );
      await _ensureLifeBasedForCurrentProfile(emit, force: true);
      await _refreshTimeLifeForCurrentProfile(emit);
      _completeVoid(event.completer);
    } catch (error, stackTrace) {
      if (isCloudErrorCode(error, kCloudErrorProfileLimitReached)) {
        emit(previousState);
      }
      _completeError(event.completer, error, stackTrace);
    }
  }

  /// API public chuyển current profile theo id.
  Future<void> switchProfile(String profileId) async {
    final Completer<void> completer = Completer<void>();
    add(MainSessionProfileSwitched(profileId: profileId, completer: completer));
    await completer.future;
  }

  /// Xử lý chuyển profile đang active và refresh dữ liệu theo profile mới.
  Future<void> _onProfileSwitched(
    MainSessionProfileSwitched event,
    Emitter<MainSessionState> emit,
  ) async {
    // Chuyển profile active, persist và refresh nhóm số liên quan profile đó.
    try {
      final UserProfile? profile = _profileService.findProfileById(
        state.profiles,
        event.profileId,
      );
      if (profile == null) {
        _completeVoid(event.completer);
        return;
      }
      emit(state.copyWith(currentProfile: profile));
      await _persistSnapshot(syncCloud: true);
      await _ensureLifeBasedForCurrentProfile(emit);
      await _refreshTimeLifeForCurrentProfile(emit);
      _completeVoid(event.completer);
    } catch (error, stackTrace) {
      _completeError(event.completer, error, stackTrace);
    }
  }

  /// API public cập nhật thông tin profile (tên/ngày sinh).
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

  /// Xử lý cập nhật profile theo chiến lược tạo mới và bỏ profile cũ.
  Future<void> _onProfileUpdated(
    MainSessionProfileUpdated event,
    Emitter<MainSessionState> emit,
  ) async {
    // Tạo profile mới với id mới, thay profile cũ trong session rồi sync cloud.
    try {
      final UserProfile? existingProfile = _profileService.findProfileById(
        state.profiles,
        event.profileId,
      );
      if (existingProfile == null) {
        _completeVoid(event.completer);
        return;
      }

      final UserProfile newProfile = _profileService.createProfile(
        name: event.name,
        birthDate: event.birthDate,
      );
      final List<UserProfile> profiles = _profileService.replaceProfile(
        state.profiles,
        oldProfileId: event.profileId,
        newProfile: newProfile,
      );
      final String? nextCurrentProfileId =
          state.currentProfile?.id == event.profileId
          ? newProfile.id
          : state.currentProfile?.id;
      final UserProfile? currentProfile = _profileService.resolveCurrentProfile(
        profiles,
        nextCurrentProfileId,
      );
      final Map<String, ProfileLifeBasedSnapshot> nextLifeBasedByProfileId =
          Map<String, ProfileLifeBasedSnapshot>.from(state.lifeBasedByProfileId)
            ..remove(event.profileId)
            ..remove(newProfile.id);
      final Map<String, ProfileTimeLifeSnapshot> nextTimeLifeByProfileId =
          Map<String, ProfileTimeLifeSnapshot>.from(state.timeLifeByProfileId)
            ..remove(event.profileId)
            ..remove(newProfile.id);
      emit(
        state.copyWith(
          profiles: profiles,
          currentProfile: currentProfile,
          clearCurrentProfile: currentProfile == null,
          lifeBasedByProfileId: nextLifeBasedByProfileId,
          timeLifeByProfileId: nextTimeLifeByProfileId,
        ),
      );
      await _persistSnapshot(syncCloud: true);

      if (currentProfile?.id == newProfile.id) {
        await _ensureLifeBasedForCurrentProfile(emit, force: true);
        await _refreshTimeLifeForCurrentProfile(emit, force: true);
      }
      _completeVoid(event.completer);
    } catch (error, stackTrace) {
      _completeError(event.completer, error, stackTrace);
    }
  }

  /// API public xóa profile khỏi session.
  Future<void> removeProfile(String profileId) async {
    final Completer<void> completer = Completer<void>();
    add(MainSessionProfileRemoved(profileId: profileId, completer: completer));
    await completer.future;
  }

  /// Xử lý xóa profile và dọn dẹp toàn bộ snapshot tương ứng.
  Future<void> _onProfileRemoved(
    MainSessionProfileRemoved event,
    Emitter<MainSessionState> emit,
  ) async {
    // Xóa profile và toàn bộ snapshot liên quan, chọn lại current profile phù hợp.
    try {
      final List<UserProfile> profiles = _profileService.removeProfile(
        state.profiles,
        profileId: event.profileId,
      );
      final Map<String, ProfileLifeBasedSnapshot> lifeBasedByProfileId =
          Map<String, ProfileLifeBasedSnapshot>.from(state.lifeBasedByProfileId)
            ..remove(event.profileId);
      final Map<String, ProfileTimeLifeSnapshot> timeLifeByProfileId =
          Map<String, ProfileTimeLifeSnapshot>.from(state.timeLifeByProfileId)
            ..remove(event.profileId);
      final String? nextCurrentProfileId =
          state.currentProfile?.id == event.profileId
          ? (profiles.isNotEmpty ? profiles.first.id : null)
          : state.currentProfile?.id;
      final UserProfile? currentProfile = _profileService.resolveCurrentProfile(
        profiles,
        nextCurrentProfileId,
      );
      emit(
        state.copyWith(
          profiles: profiles,
          lifeBasedByProfileId: lifeBasedByProfileId,
          timeLifeByProfileId: timeLifeByProfileId,
          currentProfile: currentProfile,
          clearCurrentProfile: currentProfile == null,
        ),
      );
      await _persistSnapshot(syncCloud: true);
      await _ensureLifeBasedForCurrentProfile(emit);
      await _refreshTimeLifeForCurrentProfile(emit);
      _completeVoid(event.completer);
    } catch (error, stackTrace) {
      _completeError(event.completer, error, stackTrace);
    }
  }

  /// API public thêm hồ sơ đối chiếu cho tính năng compatibility.
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

  /// Xử lý thêm hồ sơ đối chiếu và tự chọn hồ sơ vừa thêm.
  Future<void> _onCompareProfileAdded(
    MainSessionCompareProfileAdded event,
    Emitter<MainSessionState> emit,
  ) async {
    // Tạo compare profile, chọn luôn profile vừa thêm và persist.
    try {
      final profile = _compareService.createProfile(
        name: event.name,
        relation: event.relation,
        birthDate: event.birthDate,
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

  /// API public chọn hồ sơ đối chiếu đang dùng.
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

  /// API public lưu một bản ghi lịch sử tương hợp.
  Future<void> saveCompatibilityHistory(CompatibilityHistoryItem item) async {
    final Completer<void> completer = Completer<void>();
    add(MainSessionCompatibilityHistorySaved(item: item, completer: completer));
    await completer.future;
  }

  /// Xử lý lưu lịch sử: luôn persist local, cloud sync best-effort.
  Future<void> _onCompatibilityHistorySaved(
    MainSessionCompatibilityHistorySaved event,
    Emitter<MainSessionState> emit,
  ) async {
    try {
      final List<CompatibilityHistoryItem> localHistory =
          _upsertCompatibilityHistory(state.compatibilityHistory, event.item);
      emit(state.copyWith(compatibilityHistory: localHistory));
      await _persistSnapshot();

      if (state.hasCloudSession && _cloudAccountRepository.isConfigured) {
        try {
          final CompatibilityHistoryItem cloudItem =
              await _cloudAccountRepository.saveCompatibilityHistory(
                item: event.item,
              );
          final List<CompatibilityHistoryItem> mergedHistory =
              _upsertCompatibilityHistory(
                state.compatibilityHistory,
                cloudItem,
              );
          emit(state.copyWith(compatibilityHistory: mergedHistory));
          await _persistSnapshot();
        } catch (error, stackTrace) {
          developer.log(
            'Failed to sync compatibility history item to cloud.',
            name: 'MainSessionBloc',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }

      _completeVoid(event.completer);
    } catch (error, stackTrace) {
      _completeError(event.completer, error, stackTrace);
    }
  }

  /// Xử lý chọn hồ sơ đối chiếu nếu profile id hợp lệ.
  Future<void> _onCompareProfileSelected(
    MainSessionCompareProfileSelected event,
    Emitter<MainSessionState> emit,
  ) async {
    // Validate profile tồn tại trước khi set selected id.
    try {
      final bool profileExists = _compareService.containsProfile(
        state.compareProfiles,
        event.profileId,
      );
      if (!profileExists) {
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

  /// API public cộng soul points cho người dùng hiện tại.
  Future<void> addSoulPoints(int amount) async {
    final Completer<void> completer = Completer<void>();
    add(MainSessionSoulPointsAdded(amount: amount, completer: completer));
    await completer.future;
  }

  /// API public nhận thưởng point từ quảng cáo.
  Future<bool> claimAdReward({
    required int amount,
    String placementCode = 'default_rewarded',
    String? requestId,
  }) async {
    final Completer<bool> completer = Completer<bool>();
    final String cleanPlacementCode = placementCode.trim().isNotEmpty
        ? placementCode.trim()
        : 'default_rewarded';
    final String trimmedRequestId = (requestId ?? '').trim();
    final String? cleanRequestId = trimmedRequestId.isNotEmpty
        ? trimmedRequestId
        : null;
    add(
      MainSessionAdRewardClaimed(
        amount: amount,
        placementCode: cleanPlacementCode,
        requestId: cleanRequestId,
        completer: completer,
      ),
    );
    return completer.future;
  }

  /// API public đồng bộ trạng thái thưởng quảng cáo từ cloud/local.
  Future<void> refreshAdRewardStatus({
    String placementCode = 'default_rewarded',
  }) async {
    final Completer<void> completer = Completer<void>();
    final String cleanPlacementCode = placementCode.trim().isNotEmpty
        ? placementCode.trim()
        : 'default_rewarded';
    add(
      MainSessionAdRewardStatusRefreshRequested(
        placementCode: cleanPlacementCode,
        completer: completer,
      ),
    );
    await completer.future;
  }

  /// Xử lý cộng điểm soul points và persist snapshot.
  Future<void> _onSoulPointsAdded(
    MainSessionSoulPointsAdded event,
    Emitter<MainSessionState> emit,
  ) async {
    // Cộng điểm, lưu snapshot mới.
    try {
      final int nextSoulPoints = _rewardService.addSoulPoints(
        currentSoulPoints: state.soulPoints,
        amount: event.amount,
      );
      emit(state.copyWith(soulPoints: nextSoulPoints));
      await _persistSnapshot();
      _completeVoid(event.completer);
    } catch (error, stackTrace) {
      _completeError(event.completer, error, stackTrace);
    }
  }

  /// Xử lý nhận thưởng quảng cáo với giới hạn point mỗi ngày.
  Future<void> _onAdRewardClaimed(
    MainSessionAdRewardClaimed event,
    Emitter<MainSessionState> emit,
  ) async {
    try {
      if (event.amount <= 0) {
        _completeBool(event.completer, false);
        return;
      }

      if (!_cloudAccountRepository.isConfigured) {
        _completeBool(event.completer, false);
        return;
      }

      await _ensureAnonymousSessionIfNeeded(emit);
      if (!state.hasCloudSession) {
        _completeBool(event.completer, false);
        return;
      }

      final CloudAdRewardStatusResult status = await _cloudAccountRepository
          .getAdRewardStatus(placementCode: event.placementCode);

      if (!status.canWatch || status.remaining <= 0) {
        emit(
          state.copyWith(
            soulPoints: status.soulPoints,
            dailyAdEarnings: status.todayEarned,
            dailyAdLimit: status.dailyLimit,
            lastAdRewardAt: status.lastRewardAt,
            clearLastAdRewardAt: status.lastRewardAt == null,
          ),
        );
        await _persistSnapshot();
        _completeBool(event.completer, false);
        return;
      }

      final String trimmedRequestId = (event.requestId ?? '').trim();
      final String requestId = trimmedRequestId.isNotEmpty
          ? trimmedRequestId
          : _buildAdRewardRequestId(placementCode: event.placementCode);
      final CloudAdRewardGrantResult grantResult = await _cloudAccountRepository
          .grantAdReward(
            requestId: requestId,
            placementCode: event.placementCode,
            requestedAmount: event.amount,
            adNetwork: 'admob',
            metadata: <String, dynamic>{'placementCode': event.placementCode},
          );

      emit(
        state.copyWith(
          soulPoints: grantResult.soulPoints,
          dailyAdEarnings: grantResult.todayEarned,
          dailyAdLimit: grantResult.dailyLimit,
          lastAdRewardAt: grantResult.granted
              ? DateTime.now()
              : status.lastRewardAt,
          clearLastAdRewardAt:
              !grantResult.granted && status.lastRewardAt == null,
        ),
      );
      await _persistSnapshot();
      _completeBool(
        event.completer,
        grantResult.granted || grantResult.idempotent,
      );
    } catch (error, stackTrace) {
      _completeError(event.completer, error, stackTrace);
    }
  }

  Future<void> _onAdRewardStatusRefreshRequested(
    MainSessionAdRewardStatusRefreshRequested event,
    Emitter<MainSessionState> emit,
  ) async {
    try {
      await _normalizeAdRewardStateIfNeeded(emit);
      await _tryRefreshAdRewardStatusFromCloud(
        emit,
        placementCode: event.placementCode,
      );
      _completeVoid(event.completer);
    } catch (error, stackTrace) {
      _completeError(event.completer, error, stackTrace);
    }
  }

  String _buildAdRewardRequestId({required String placementCode}) {
    final String cleanPlacementCode = placementCode.trim().isNotEmpty
        ? placementCode.trim()
        : 'default_rewarded';
    return 'ad_reward:${DateTime.now().microsecondsSinceEpoch}:$cleanPlacementCode';
  }

  /// API public trừ soul points, trả về false nếu không đủ điểm.
  Future<bool> deductSoulPoints(
    int amount, {
    String sourceType = 'manual_adjustment',
    Map<String, dynamic> metadata = const <String, dynamic>{},
    String? requestId,
  }) async {
    final Completer<bool> completer = Completer<bool>();
    add(
      MainSessionSoulPointsDeducted(
        amount: amount,
        sourceType: sourceType,
        metadata: Map<String, dynamic>.from(metadata),
        requestId: requestId?.trim().isNotEmpty == true
            ? requestId!.trim()
            : 'spend:${DateTime.now().microsecondsSinceEpoch}:$sourceType:$amount',
        completer: completer,
      ),
    );
    return completer.future;
  }

  /// API public đồng bộ số dư soul points authoritative từ backend.
  Future<void> syncSoulPointsFromCloud(int soulPoints) async {
    final Completer<void> completer = Completer<void>();
    add(
      MainSessionSoulPointsSynced(soulPoints: soulPoints, completer: completer),
    );
    await completer.future;
  }

  /// Xử lý trừ điểm soul points với kiểm tra đủ điểm trước khi trừ.
  Future<void> _onSoulPointsDeducted(
    MainSessionSoulPointsDeducted event,
    Emitter<MainSessionState> emit,
  ) async {
    // Trừ điểm an toàn: account đăng nhập ưu tiên cloud-authoritative.
    try {
      if (state.hasCloudSession && _cloudAccountRepository.isConfigured) {
        final result = await _cloudAccountRepository.spendSoulPoints(
          amount: event.amount,
          sourceType: event.sourceType,
          requestId: event.requestId,
          metadata: event.metadata,
        );
        emit(state.copyWith(soulPoints: result.soulPoints));
        await _persistSnapshot();
        _completeBool(event.completer, result.applied || result.idempotent);
        return;
      }

      final int? nextSoulPoints = _rewardService.deductSoulPoints(
        currentSoulPoints: state.soulPoints,
        amount: event.amount,
      );
      if (nextSoulPoints == null) {
        _completeBool(event.completer, false);
        return;
      }
      emit(state.copyWith(soulPoints: nextSoulPoints));
      await _persistSnapshot();
      _completeBool(event.completer, true);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to deduct soul points.',
        name: 'MainSessionBloc',
        error: error,
        stackTrace: stackTrace,
      );
      _completeBool(event.completer, false);
    }
  }

  Future<void> _onSoulPointsSynced(
    MainSessionSoulPointsSynced event,
    Emitter<MainSessionState> emit,
  ) async {
    try {
      final int nextSoulPoints = event.soulPoints < 0 ? 0 : event.soulPoints;
      emit(state.copyWith(soulPoints: nextSoulPoints));
      await _persistSnapshot();
      _completeVoid(event.completer);
    } catch (error, stackTrace) {
      _completeError(event.completer, error, stackTrace);
    }
  }

  /// API public check-in hằng ngày để nhận thưởng streak.
  Future<void> checkIn() async {
    final Completer<void> completer = Completer<void>();
    add(MainSessionCheckedIn(completer: completer));
    await completer.future;
  }

  void consumeCheckInCelebration({required int eventId}) {
    add(MainSessionCheckInCelebrationConsumed(eventId: eventId));
  }

  /// Xử lý check-in hàng ngày và cập nhật streak/reward.
  Future<void> _onCheckedIn(
    MainSessionCheckedIn event,
    Emitter<MainSessionState> emit,
  ) async {
    // Cloud-authoritative: check-in luôn gọi cloud, không fallback local.
    try {
      if (!_cloudAccountRepository.isConfigured) {
        _completeVoid(event.completer);
        return;
      }

      await _ensureAnonymousSessionIfNeeded(emit);
      if (!state.hasCloudSession) {
        emit(state.copyWith(errorMessage: 'checkin_cloud_failed'));
        _completeVoid(event.completer);
        return;
      }

      await _checkInCloud(emit);
      _completeVoid(event.completer);
    } catch (_) {
      emit(state.copyWith(errorMessage: 'checkin_cloud_failed'));
      _completeVoid(event.completer);
    }
  }

  void _onCheckInCelebrationConsumed(
    MainSessionCheckInCelebrationConsumed event,
    Emitter<MainSessionState> emit,
  ) {
    if (event.eventId != state.lastCheckInEventId) {
      return;
    }
    if (state.lastCheckInRewardAwarded == 0) {
      return;
    }
    emit(state.copyWith(lastCheckInRewardAwarded: 0));
  }

  /// Check-in cloud cho account đã đăng nhập và đồng bộ lại reward state local.
  Future<void> _checkInCloud(Emitter<MainSessionState> emit) async {
    final String requestId = 'checkin:${DateTime.now().microsecondsSinceEpoch}';
    final CloudDailyCheckInResult result = await _cloudAccountRepository
        .claimDailyCheckIn(requestId: requestId);
    final int rewardAwarded = _normalizeRewardAwarded(result.rewardAwarded);
    emit(
      state.copyWith(
        dailyEarnings: result.dailyEarnings,
        currentStreak: result.currentStreak,
        soulPoints: result.soulPoints,
        lastCheckInAt: result.lastCheckInAt,
        lastCheckInRewardAwarded: rewardAwarded,
        lastCheckInEventId: state.lastCheckInEventId + 1,
      ),
    );
    await _persistSnapshot();
  }

  Future<void> _tryAutoClaimDailyCheckInFromCloud(
    Emitter<MainSessionState> emit,
  ) async {
    if (!state.hasCloudSession || !_cloudAccountRepository.isConfigured) {
      return;
    }
    try {
      await _checkInCloud(emit);
    } catch (error, stackTrace) {
      developer.log(
        'Auto check-in skipped due to cloud error.',
        name: 'MainSessionBloc',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _triggerStartupAutoCheckInIfEligible() {
    if (!_cloudAccountRepository.isConfigured ||
        !state.hasCloudSession ||
        state.authMode != SessionAuthMode.anonymous) {
      return;
    }

    unawaited(_enqueueStartupAutoCheckIn());
  }

  Future<void> _enqueueStartupAutoCheckIn() async {
    try {
      add(const MainSessionStartupAutoCheckInRequested());
    } catch (error, stackTrace) {
      developer.log(
        'Failed to enqueue startup auto check-in event.',
        name: 'MainSessionBloc',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _onStartupAutoCheckInRequested(
    MainSessionStartupAutoCheckInRequested event,
    Emitter<MainSessionState> emit,
  ) async {
    if (!_cloudAccountRepository.isConfigured ||
        !state.hasCloudSession ||
        state.authMode != SessionAuthMode.anonymous) {
      return;
    }

    await _tryAutoClaimDailyCheckInFromCloud(emit);
  }

  /// Chuẩn hoá reward local cho guest theo ngày:
  /// - Qua ngày mới: reset dailyEarnings về 0
  /// - Đứt streak (quá 1 ngày): reset currentStreak về 0
  Future<void> _normalizeGuestRewardStateIfNeeded(
    Emitter<MainSessionState> emit,
  ) async {
    if (state.hasCloudSession) {
      return;
    }
    final DateTime? lastCheckInAt = state.lastCheckInAt;
    if (lastCheckInAt == null) {
      if (state.dailyEarnings == 0 && state.currentStreak == 0) {
        return;
      }
      emit(state.copyWith(dailyEarnings: 0, currentStreak: 0));
      await _persistSnapshot();
      return;
    }

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime lastDay = DateTime(
      lastCheckInAt.year,
      lastCheckInAt.month,
      lastCheckInAt.day,
    );
    final int dayDiff = today.difference(lastDay).inDays;
    if (dayDiff == 0) {
      return;
    }

    final int nextDailyEarnings = 0;
    final int nextCurrentStreak = dayDiff == 1 ? state.currentStreak : 0;
    final bool hasChanged =
        state.dailyEarnings != nextDailyEarnings ||
        state.currentStreak != nextCurrentStreak;
    if (!hasChanged) {
      return;
    }

    emit(
      state.copyWith(
        dailyEarnings: nextDailyEarnings,
        currentStreak: nextCurrentStreak,
      ),
    );
    await _persistSnapshot();
  }

  /// Chuẩn hóa điểm nhận từ quảng cáo theo ngày.
  Future<void> _normalizeAdRewardStateIfNeeded(
    Emitter<MainSessionState> emit,
  ) async {
    final DateTime? lastAdRewardAt = state.lastAdRewardAt;
    if (lastAdRewardAt == null) {
      if (state.dailyAdEarnings == 0) {
        return;
      }
      emit(state.copyWith(dailyAdEarnings: 0));
      await _persistSnapshot();
      return;
    }

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime adRewardDay = DateTime(
      lastAdRewardAt.year,
      lastAdRewardAt.month,
      lastAdRewardAt.day,
    );
    final int dayDiff = today.difference(adRewardDay).inDays;
    if (dayDiff <= 0) {
      return;
    }
    emit(state.copyWith(dailyAdEarnings: 0, clearLastAdRewardAt: true));
    await _persistSnapshot();
  }

  void trackInteraction(String page) {
    /// Ghi nhận tương tác theo page để phục vụ gợi ý nhập profile.
    add(MainSessionInteractionTracked(page));
  }

  /// Xử lý event theo dõi tương tác trên page hiện tại.
  void _onInteractionTracked(
    MainSessionInteractionTracked event,
    Emitter<MainSessionState> emit,
  ) {
    // Tăng bộ đếm tương tác của trang hiện tại (hoặc reset khi sang trang khác).
    final SessionInteractionUpdate update = _promptService.trackInteraction(
      currentPage: state.currentPageInteraction,
      interactionCount: state.interactionCount,
      nextPage: event.page,
    );
    emit(
      state.copyWith(
        currentPageInteraction: update.page,
        interactionCount: update.count,
      ),
    );
  }

  void resetPageInteraction(String page) {
    /// Reset bộ đếm tương tác cho một trang cụ thể.
    add(MainSessionPageInteractionReset(page));
  }

  /// Xử lý event reset bộ đếm tương tác cho một page.
  void _onPageInteractionReset(
    MainSessionPageInteractionReset event,
    Emitter<MainSessionState> emit,
  ) {
    // Đưa interaction count của page về 0.
    final SessionInteractionUpdate update = _promptService.resetInteraction(
      event.page,
    );
    emit(
      state.copyWith(
        currentPageInteraction: update.page,
        interactionCount: update.count,
      ),
    );
  }

  bool shouldShowProfilePrompt(String page) {
    /// Quyết định có hiển thị prompt nhập profile trên trang hiện tại hay không.
    return _promptService.shouldShowProfilePrompt(
      page: page,
      currentPageInteraction: state.currentPageInteraction,
      interactionCount: state.interactionCount,
      hasAnyProfile: state.hasAnyProfile,
    );
  }

  /// API public refresh nhóm time-based number cho profile hiện tại/guest.
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

  /// Xử lý event refresh time-based metrics (daily/monthly/yearly).
  Future<void> _onTimeLifeRefreshRequested(
    MainSessionTimeLifeRefreshRequested event,
    Emitter<MainSessionState> emit,
  ) async {
    // Event handler refresh time-based theo mốc refreshAt hoặc force refresh.
    try {
      await _ensureAnonymousSessionIfNeeded(emit);
      await _normalizeGuestRewardStateIfNeeded(emit);
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

  /// Tính và cập nhật snapshot time-based cho current profile hoặc guest.
  Future<void> _refreshTimeLifeForCurrentProfile(
    Emitter<MainSessionState> emit, {
    DateTime? now,
    bool force = false,
  }) async {
    // Tính toán time-based metrics, cập nhật map snapshot và persist nếu có thay đổi.
    bool didMutateState = _refreshDailyAngelCacheIfNeeded(
      emit,
      now: now,
      force: force,
    );

    final TimeLifeRefreshResult? refreshResult = _metricsService
        .refreshTimeLifeForCurrentProfile(
          profile: state.currentProfile,
          timeLifeByProfileId: state.timeLifeByProfileId,
          guestProfileId: guestProfileId,
          now: now,
          force: force,
        );
    if (refreshResult != null) {
      final Map<String, ProfileTimeLifeSnapshot> nextTimeLifeByProfileId =
          Map<String, ProfileTimeLifeSnapshot>.from(state.timeLifeByProfileId)
            ..[refreshResult.profileId] = refreshResult.snapshot;
      emit(state.copyWith(timeLifeByProfileId: nextTimeLifeByProfileId));
      didMutateState = true;
    }

    if (!didMutateState) {
      return;
    }

    await _persistSnapshot();
  }

  bool _refreshDailyAngelCacheIfNeeded(
    Emitter<MainSessionState> emit, {
    DateTime? now,
    bool force = false,
  }) {
    final DateTime currentTime = now ?? DateTime.now();
    final DateTime? refreshAt = state.dailyAngelRefreshAt;
    final bool shouldRefresh =
        force ||
        state.dailyAngelNumber == null ||
        refreshAt == null ||
        !currentTime.isBefore(refreshAt);

    if (!shouldRefresh) {
      return false;
    }

    emit(
      state.copyWith(
        dailyAngelNumber: _angelNumberFromTime(currentTime),
        dailyAngelRefreshAt: DateTime(
          currentTime.year,
          currentTime.month,
          currentTime.day + 1,
        ),
      ),
    );
    return true;
  }

  int _angelNumberFromTime(DateTime now) {
    return (now.hour * 100) + now.minute;
  }

  /// Đảm bảo current profile có đầy đủ snapshot life-based.
  Future<void> _ensureLifeBasedForCurrentProfile(
    Emitter<MainSessionState> emit, {
    DateTime? now,
    bool force = false,
  }) async {
    // Đảm bảo profile hiện tại có đủ metrics life-based; thiếu thì tính và lưu lại.
    final LifeBasedRefreshResult? refreshResult = _metricsService
        .ensureLifeBasedForCurrentProfile(
          profile: state.currentProfile,
          lifeBasedByProfileId: state.lifeBasedByProfileId,
          now: now,
          force: force,
        );
    if (refreshResult == null) {
      return;
    }

    final Map<String, ProfileLifeBasedSnapshot> nextLifeBasedByProfileId =
        Map<String, ProfileLifeBasedSnapshot>.from(state.lifeBasedByProfileId)
          ..[refreshResult.profileId] = refreshResult.snapshot;
    emit(state.copyWith(lifeBasedByProfileId: nextLifeBasedByProfileId));
    await _persistSnapshot();
  }

  /// Lưu snapshot session hiện tại xuống storage local.
  Future<void> _persistSnapshot({
    bool syncCloud = false,
    Set<String> rethrowCloudErrorCodes = const <String>{},
  }) async {
    // Đồng bộ toàn bộ MainSessionState hiện tại xuống storage local.
    final AppSessionSnapshot snapshot = AppSessionSnapshot(
      isAuthenticated: state.isAuthenticated,
      authMode: state.authMode,
      pendingAnonymousBootstrap: state.pendingAnonymousBootstrap,
      cloudUserId: state.cloudUserId,
      userEmail: state.userEmail,
      userName: state.userName,
      profiles: state.profiles,
      lifeBasedByProfileId: state.lifeBasedByProfileId,
      timeLifeByProfileId: state.timeLifeByProfileId,
      currentProfileId: state.currentProfile?.id,
      soulPoints: state.soulPoints,
      currentStreak: state.currentStreak,
      dailyEarnings: state.dailyEarnings,
      dailyAdEarnings: state.dailyAdEarnings,
      dailyAdLimit: state.dailyAdLimit,
      dailyAngelNumber: state.dailyAngelNumber,
      dailyAngelRefreshAt: state.dailyAngelRefreshAt,
      lastCheckInAt: state.lastCheckInAt,
      lastAdRewardAt: state.lastAdRewardAt,
      compareProfiles: state.compareProfiles,
      selectedCompareProfileId: state.selectedCompareProfileId,
      compatibilityHistory: state.compatibilityHistory,
    );
    await _sessionRepository.saveSnapshot(snapshot);
    if (!syncCloud ||
        !state.hasCloudSession ||
        !_cloudAccountRepository.isConfigured) {
      return;
    }
    try {
      await _cloudAccountRepository.syncSessionSnapshot(snapshot: snapshot);
    } catch (error, stackTrace) {
      final String? cloudErrorCode = extractCloudErrorCode(error);
      if (cloudErrorCode != null &&
          rethrowCloudErrorCodes.contains(cloudErrorCode)) {
        throw StateError(cloudErrorCode);
      }

      // Không fail UI flow khi cloud sync lỗi, vì local snapshot đã lưu thành công.
      developer.log(
        'Failed to sync session snapshot to cloud.',
        name: 'MainSessionBloc',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Áp snapshot vào state runtime và tùy chọn recompute metrics sau khi apply.
  Future<void> _applySnapshotToState(
    AppSessionSnapshot snapshot,
    Emitter<MainSessionState> emit, {
    required bool recomputeMetrics,
    bool forceRecomputeMetrics = false,
  }) async {
    // Apply snapshot vào state runtime, rồi tùy chọn recompute metrics để đồng bộ dữ liệu.
    final UserProfile? currentProfile = _profileService.resolveCurrentProfile(
      snapshot.profiles,
      snapshot.currentProfileId,
    );

    emit(
      state.copyWith(
        isAuthenticated: snapshot.isAuthenticated,
        authMode: snapshot.authMode,
        pendingAnonymousBootstrap: snapshot.pendingAnonymousBootstrap,
        cloudUserId: snapshot.cloudUserId,
        userEmail: snapshot.userEmail,
        clearUserEmail: snapshot.userEmail == null,
        userName: snapshot.userName,
        clearUserName: snapshot.userName == null,
        profiles: snapshot.profiles,
        lifeBasedByProfileId: snapshot.lifeBasedByProfileId,
        timeLifeByProfileId: snapshot.timeLifeByProfileId,
        currentProfile: currentProfile,
        clearCurrentProfile: currentProfile == null,
        soulPoints: snapshot.soulPoints,
        currentStreak: snapshot.currentStreak,
        dailyEarnings: snapshot.dailyEarnings,
        dailyAdEarnings: snapshot.dailyAdEarnings,
        dailyAdLimit: snapshot.dailyAdLimit,
        dailyAngelNumber: snapshot.dailyAngelNumber,
        dailyAngelRefreshAt: snapshot.dailyAngelRefreshAt,
        lastCheckInAt: snapshot.lastCheckInAt,
        lastAdRewardAt: snapshot.lastAdRewardAt,
        compareProfiles: snapshot.compareProfiles,
        selectedCompareProfileId: snapshot.selectedCompareProfileId,
        compatibilityHistory: snapshot.compatibilityHistory,
        clearErrorMessage: true,
      ),
    );
    _refreshDailyAngelCacheIfNeeded(emit);
    await _persistSnapshot();
    if (recomputeMetrics) {
      await _ensureLifeBasedForCurrentProfile(
        emit,
        force: forceRecomputeMetrics,
      );
      await _refreshTimeLifeForCurrentProfile(
        emit,
        force: forceRecomputeMetrics,
      );
    }
    await _tryRefreshCompatibilityHistoryFromCloud(emit);
    await _tryAutoClaimDailyCheckInFromCloud(emit);
    await _tryRefreshAdRewardStatusFromCloud(emit);
  }

  int _normalizeRewardAwarded(int rawReward) {
    if (rawReward <= 0) {
      return 0;
    }
    return rawReward;
  }

  Future<void> _tryRefreshCompatibilityHistoryFromCloud(
    Emitter<MainSessionState> emit,
  ) async {
    if (!state.hasCloudSession || !_cloudAccountRepository.isConfigured) {
      return;
    }
    try {
      final List<CompatibilityHistoryItem> cloudHistory =
          await _cloudAccountRepository.fetchCompatibilityHistory(
            limit: _compatibilityHistoryMaxItems,
          );
      final List<CompatibilityHistoryItem> mergedHistory =
          _mergeCompatibilityHistory(state.compatibilityHistory, cloudHistory);
      emit(state.copyWith(compatibilityHistory: mergedHistory));
      await _persistSnapshot();
    } catch (error, stackTrace) {
      developer.log(
        'Failed to fetch compatibility history from cloud.',
        name: 'MainSessionBloc',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _tryRefreshAdRewardStatusFromCloud(
    Emitter<MainSessionState> emit, {
    String placementCode = 'default_rewarded',
  }) async {
    if (!state.hasCloudSession || !_cloudAccountRepository.isConfigured) {
      return;
    }
    try {
      final CloudAdRewardStatusResult status = await _cloudAccountRepository
          .getAdRewardStatus(placementCode: placementCode);
      final DateTime? nextLastRewardAt = status.lastRewardAt;
      final int currentLastRewardAtEpoch =
          state.lastAdRewardAt?.millisecondsSinceEpoch ?? 0;
      final int nextLastRewardAtEpoch =
          nextLastRewardAt?.millisecondsSinceEpoch ?? 0;
      final bool hasChanged =
          state.soulPoints != status.soulPoints ||
          state.dailyAdEarnings != status.todayEarned ||
          state.dailyAdLimit != status.dailyLimit ||
          currentLastRewardAtEpoch != nextLastRewardAtEpoch;
      if (!hasChanged) {
        return;
      }
      emit(
        state.copyWith(
          soulPoints: status.soulPoints,
          dailyAdEarnings: status.todayEarned,
          dailyAdLimit: status.dailyLimit,
          lastAdRewardAt: nextLastRewardAt,
          clearLastAdRewardAt: nextLastRewardAt == null,
        ),
      );
      await _persistSnapshot();
    } catch (error, stackTrace) {
      developer.log(
        'Failed to refresh ad reward status from cloud.',
        name: 'MainSessionBloc',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  List<CompatibilityHistoryItem> _upsertCompatibilityHistory(
    List<CompatibilityHistoryItem> source,
    CompatibilityHistoryItem item,
  ) {
    final String requestId = item.requestId.trim();
    final List<CompatibilityHistoryItem> next = source.where((
      CompatibilityHistoryItem existing,
    ) {
      if (requestId.isNotEmpty && existing.requestId.trim() == requestId) {
        return false;
      }
      return existing.id != item.id;
    }).toList();
    next.insert(0, item);
    next.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (next.length > _compatibilityHistoryMaxItems) {
      return next.take(_compatibilityHistoryMaxItems).toList();
    }
    return next;
  }

  List<CompatibilityHistoryItem> _mergeCompatibilityHistory(
    List<CompatibilityHistoryItem> current,
    List<CompatibilityHistoryItem> incoming,
  ) {
    List<CompatibilityHistoryItem> merged = List<CompatibilityHistoryItem>.from(
      current,
    );
    for (final CompatibilityHistoryItem item in incoming) {
      merged = _upsertCompatibilityHistory(merged, item);
    }
    return merged;
  }

  Future<void> _ensureAnonymousSessionIfNeeded(
    Emitter<MainSessionState> emit,
  ) async {
    if (!_cloudAccountRepository.isConfigured) {
      return;
    }
    if (state.authMode != SessionAuthMode.anonymous) {
      return;
    }
    if (state.hasCloudSession && !state.pendingAnonymousBootstrap) {
      return;
    }

    try {
      await _cloudAccountRepository.ensureAnonymousSession();
      emit(
        state.copyWith(
          isAuthenticated: true,
          authMode: SessionAuthMode.anonymous,
          pendingAnonymousBootstrap: false,
          cloudUserId: _cloudAccountRepository.currentUserId,
          clearUserEmail: true,
          clearErrorMessage: true,
        ),
      );
      await _persistSnapshot(syncCloud: true);
    } catch (error, stackTrace) {
      developer.log(
        'Anonymous bootstrap retry failed.',
        name: 'MainSessionBloc',
        error: error,
        stackTrace: stackTrace,
      );
      emit(
        state.copyWith(
          isAuthenticated: false,
          authMode: SessionAuthMode.anonymous,
          pendingAnonymousBootstrap: true,
          clearCloudUserId: true,
          clearUserEmail: true,
        ),
      );
      await _persistSnapshot();
    }
  }

  /// Complete `Completer<void>` an toàn, tránh complete nhiều lần.
  static void _completeVoid(Completer<void> completer) {
    // Hoàn tất completer void an toàn (tránh complete nhiều lần).
    if (!completer.isCompleted) {
      completer.complete();
    }
  }

  /// Complete `Completer<bool>` an toàn.
  static void _completeBool(Completer<bool> completer, bool value) {
    // Hoàn tất completer bool an toàn.
    if (!completer.isCompleted) {
      completer.complete(value);
    }
  }

  /// Complete lỗi cho completer an toàn.
  static void _completeError<T>(
    Completer<T> completer,
    Object error,
    StackTrace stackTrace,
  ) {
    // Trả lỗi qua completer an toàn nếu chưa complete.
    if (!completer.isCompleted) {
      completer.completeError(error, stackTrace);
    }
  }
}
