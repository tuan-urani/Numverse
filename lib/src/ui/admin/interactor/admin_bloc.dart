import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:test/src/core/model/admin_ledger_content.dart';
import 'package:test/src/core/model/admin_ledger_release.dart';
import 'package:test/src/core/repository/interface/i_admin_ledger_repository.dart';
import 'package:test/src/ui/admin/interactor/admin_event.dart';
import 'package:test/src/ui/admin/interactor/admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  AdminBloc(this._repository) : super(AdminState.initial()) {
    on<AdminBootstrapRequested>(_onBootstrapRequested);
    on<AdminLoginSubmitted>(_onLoginSubmitted);
    on<AdminLogoutRequested>(_onLogoutRequested);
    on<AdminLocaleFilterChanged>(_onLocaleFilterChanged);
    on<AdminContentTypeFilterChanged>(_onContentTypeFilterChanged);
    on<AdminSearchKeywordChanged>(_onSearchKeywordChanged);
    on<AdminReleaseSelected>(_onReleaseSelected);
    on<AdminContentsRequested>(_onContentsRequested);
    on<AdminContentSelected>(_onContentSelected);
    on<AdminEditorContentTypeChanged>(_onEditorContentTypeChanged);
    on<AdminEditorNumberKeyChanged>(_onEditorNumberKeyChanged);
    on<AdminEditorPayloadChanged>(_onEditorPayloadChanged);
    on<AdminSaveRequested>(_onSaveRequested);
    on<AdminPublishRequested>(_onPublishRequested);
    on<AdminCreateDraftRequested>(_onCreateDraftRequested);
    on<AdminMessageCleared>(_onMessageCleared);
  }

  final IAdminLedgerRepository _repository;

  static const String allContentType = 'all';

  Future<void> bootstrap() async {
    add(const AdminBootstrapRequested());
  }

  void onLogin({required String email, required String password}) {
    add(AdminLoginSubmitted(email: email, password: password));
  }

  void onLogout() {
    add(const AdminLogoutRequested());
  }

  void onLocaleChanged(String locale) {
    add(AdminLocaleFilterChanged(locale));
  }

  void onContentTypeChanged(String contentType) {
    add(AdminContentTypeFilterChanged(contentType));
  }

  void onSearchChanged(String keyword) {
    add(AdminSearchKeywordChanged(keyword));
  }

  void onSelectRelease(String releaseId) {
    add(AdminReleaseSelected(releaseId));
  }

  void onRefreshContents() {
    add(const AdminContentsRequested());
  }

  void onSelectContent(String contentId) {
    add(AdminContentSelected(contentId));
  }

  void onEditorContentTypeChanged(String value) {
    add(AdminEditorContentTypeChanged(value));
  }

  void onEditorNumberKeyChanged(String value) {
    add(AdminEditorNumberKeyChanged(value));
  }

  void onEditorPayloadChanged(String value) {
    add(AdminEditorPayloadChanged(value));
  }

  void onSave() {
    add(const AdminSaveRequested());
  }

  void onPublish() {
    add(const AdminPublishRequested());
  }

  void onCreateDraft({required String version, required String notes}) {
    add(AdminCreateDraftRequested(version: version, notes: notes));
  }

  void clearMessage() {
    add(const AdminMessageCleared());
  }

  Future<void> _onBootstrapRequested(
    AdminBootstrapRequested event,
    Emitter<AdminState> emit,
  ) async {
    if (!_repository.isConfigured) {
      emit(
        state.copyWith(
          loadStatus: AdminLoadStatus.failure,
          errorKey: 'admin_error_not_configured',
        ),
      );
      return;
    }
    if (!_repository.hasActiveSession) {
      emit(
        state.copyWith(
          authStatus: AdminAuthStatus.unauthenticated,
          loadStatus: AdminLoadStatus.initial,
          clearErrorKey: true,
        ),
      );
      return;
    }
    await _loadReleases(emit, forceLoading: true);
  }

  Future<void> _onLoginSubmitted(
    AdminLoginSubmitted event,
    Emitter<AdminState> emit,
  ) async {
    emit(
      state.copyWith(
        authStatus: AdminAuthStatus.authenticating,
        loadStatus: AdminLoadStatus.loading,
        clearErrorKey: true,
        clearMessageKey: true,
      ),
    );
    try {
      await _repository.login(email: event.email, password: event.password);
      await _loadReleases(emit, forceLoading: false);
    } catch (error) {
      emit(
        state.copyWith(
          authStatus: AdminAuthStatus.unauthenticated,
          loadStatus: AdminLoadStatus.failure,
          errorKey: _resolveErrorKey(error),
        ),
      );
    }
  }

  Future<void> _onLogoutRequested(
    AdminLogoutRequested event,
    Emitter<AdminState> emit,
  ) async {
    await _repository.logout();
    emit(AdminState.initial());
  }

  Future<void> _onLocaleFilterChanged(
    AdminLocaleFilterChanged event,
    Emitter<AdminState> emit,
  ) async {
    emit(
      state.copyWith(
        localeFilter: event.locale.trim().toLowerCase(),
        clearMessageKey: true,
        clearErrorKey: true,
      ),
    );
    await _loadReleases(emit, forceLoading: false);
  }

  Future<void> _onContentTypeFilterChanged(
    AdminContentTypeFilterChanged event,
    Emitter<AdminState> emit,
  ) async {
    emit(
      state.copyWith(
        contentTypeFilter: event.contentType.trim().toLowerCase(),
        clearMessageKey: true,
        clearErrorKey: true,
      ),
    );
    await _loadContents(emit);
  }

  Future<void> _onSearchKeywordChanged(
    AdminSearchKeywordChanged event,
    Emitter<AdminState> emit,
  ) async {
    emit(
      state.copyWith(
        searchKeyword: event.keyword,
        clearMessageKey: true,
        clearErrorKey: true,
      ),
    );
    await _loadContents(emit);
  }

  Future<void> _onReleaseSelected(
    AdminReleaseSelected event,
    Emitter<AdminState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedReleaseId: event.releaseId,
        clearSelectedContentId: true,
        clearMessageKey: true,
        clearErrorKey: true,
      ),
    );
    await _loadContents(emit);
  }

  Future<void> _onContentsRequested(
    AdminContentsRequested event,
    Emitter<AdminState> emit,
  ) async {
    await _loadContents(emit);
  }

  void _onContentSelected(
    AdminContentSelected event,
    Emitter<AdminState> emit,
  ) {
    final AdminLedgerContent? selected = _findContentById(
      state.contents,
      event.contentId,
    );

    if (selected == null) {
      return;
    }

    emit(
      state.copyWith(
        selectedContentId: selected.id,
        editorContentType: selected.contentType,
        editorNumberKey: selected.numberKey,
        editorPayloadJson: _prettyJson(selected.payloadJsonb),
        clearMessageKey: true,
        clearErrorKey: true,
      ),
    );
  }

  void _onEditorContentTypeChanged(
    AdminEditorContentTypeChanged event,
    Emitter<AdminState> emit,
  ) {
    emit(
      state.copyWith(
        editorContentType: event.value.trim().toLowerCase(),
        clearMessageKey: true,
        clearErrorKey: true,
      ),
    );
  }

  void _onEditorNumberKeyChanged(
    AdminEditorNumberKeyChanged event,
    Emitter<AdminState> emit,
  ) {
    emit(
      state.copyWith(
        editorNumberKey: event.value.trim(),
        clearMessageKey: true,
        clearErrorKey: true,
      ),
    );
  }

  void _onEditorPayloadChanged(
    AdminEditorPayloadChanged event,
    Emitter<AdminState> emit,
  ) {
    emit(
      state.copyWith(
        editorPayloadJson: event.value,
        clearMessageKey: true,
        clearErrorKey: true,
      ),
    );
  }

  Future<void> _onSaveRequested(
    AdminSaveRequested event,
    Emitter<AdminState> emit,
  ) async {
    final AdminLedgerRelease? release = state.selectedRelease;
    if (release == null) {
      emit(state.copyWith(errorKey: 'admin_error_select_release'));
      return;
    }
    if (!release.isDraft) {
      emit(state.copyWith(errorKey: 'admin_error_release_not_draft'));
      return;
    }
    if (!state.canSave) {
      emit(state.copyWith(errorKey: 'admin_error_missing_fields'));
      return;
    }

    final Object? decodedPayload;
    try {
      decodedPayload = jsonDecode(state.editorPayloadJson);
    } catch (_) {
      emit(state.copyWith(errorKey: 'admin_error_invalid_json'));
      return;
    }
    if (decodedPayload is! Map<String, dynamic>) {
      emit(state.copyWith(errorKey: 'admin_error_invalid_json'));
      return;
    }

    emit(
      state.copyWith(
        isSaving: true,
        clearErrorKey: true,
        clearMessageKey: true,
      ),
    );

    try {
      final String contentId = await _repository.upsertContent(
        releaseId: release.id,
        contentType: state.editorContentType,
        numberKey: state.editorNumberKey,
        payloadJsonb: decodedPayload,
      );
      await _loadContents(
        emit,
        selectContentId: contentId.isNotEmpty ? contentId : null,
      );
      emit(
        state.copyWith(
          isSaving: false,
          messageKey: 'admin_message_save_success',
        ),
      );
    } catch (error) {
      emit(state.copyWith(isSaving: false, errorKey: _resolveErrorKey(error)));
    }
  }

  Future<void> _onPublishRequested(
    AdminPublishRequested event,
    Emitter<AdminState> emit,
  ) async {
    final AdminLedgerRelease? release = state.selectedRelease;
    if (release == null) {
      emit(state.copyWith(errorKey: 'admin_error_select_release'));
      return;
    }
    if (!release.isDraft) {
      emit(state.copyWith(errorKey: 'admin_error_release_not_draft'));
      return;
    }

    emit(
      state.copyWith(
        isPublishing: true,
        clearErrorKey: true,
        clearMessageKey: true,
      ),
    );
    try {
      await _repository.publishRelease(releaseId: release.id);
      await _loadReleases(emit, forceLoading: false, keepReleaseId: release.id);
      emit(
        state.copyWith(
          isPublishing: false,
          messageKey: 'admin_message_publish_success',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(isPublishing: false, errorKey: _resolveErrorKey(error)),
      );
    }
  }

  Future<void> _onCreateDraftRequested(
    AdminCreateDraftRequested event,
    Emitter<AdminState> emit,
  ) async {
    final AdminLedgerRelease? selectedRelease = state.selectedRelease;
    final String version = event.version.trim();
    if (version.isEmpty) {
      emit(state.copyWith(errorKey: 'admin_error_missing_version'));
      return;
    }

    emit(
      state.copyWith(
        isCreatingDraft: true,
        clearErrorKey: true,
        clearMessageKey: true,
      ),
    );
    try {
      final String newReleaseId = await _repository.createDraft(
        locale: state.localeFilter,
        version: version,
        notes: event.notes,
        cloneFromReleaseId: selectedRelease?.id,
      );
      await _loadReleases(
        emit,
        forceLoading: false,
        keepReleaseId: newReleaseId,
      );
      emit(
        state.copyWith(
          isCreatingDraft: false,
          messageKey: 'admin_message_draft_success',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isCreatingDraft: false,
          errorKey: _resolveErrorKey(error),
        ),
      );
    }
  }

  void _onMessageCleared(AdminMessageCleared event, Emitter<AdminState> emit) {
    emit(state.copyWith(clearErrorKey: true, clearMessageKey: true));
  }

  Future<void> _loadReleases(
    Emitter<AdminState> emit, {
    required bool forceLoading,
    String? keepReleaseId,
  }) async {
    emit(
      state.copyWith(
        authStatus: AdminAuthStatus.authenticated,
        loadStatus: forceLoading ? AdminLoadStatus.loading : state.loadStatus,
        clearErrorKey: true,
      ),
    );

    try {
      final List<AdminLedgerRelease> releases = await _repository.getReleases(
        locale: state.localeFilter,
      );
      final String? nextSelectedReleaseId = _resolveSelectedReleaseId(
        releases,
        preferredId: keepReleaseId ?? state.selectedReleaseId,
      );
      emit(
        state.copyWith(
          authStatus: AdminAuthStatus.authenticated,
          loadStatus: AdminLoadStatus.success,
          releases: releases,
          selectedReleaseId: nextSelectedReleaseId,
          contents: const <AdminLedgerContent>[],
          clearSelectedContentId: true,
        ),
      );
      await _loadContents(emit);
    } catch (error) {
      emit(
        state.copyWith(
          authStatus: AdminAuthStatus.unauthenticated,
          loadStatus: AdminLoadStatus.failure,
          errorKey: _resolveErrorKey(error),
        ),
      );
    }
  }

  Future<void> _loadContents(
    Emitter<AdminState> emit, {
    String? selectContentId,
  }) async {
    final AdminLedgerRelease? release = state.selectedRelease;
    if (release == null) {
      emit(
        state.copyWith(
          contents: const <AdminLedgerContent>[],
          clearSelectedContentId: true,
        ),
      );
      return;
    }

    try {
      final List<AdminLedgerContent> contents = await _repository.getContents(
        releaseId: release.id,
        contentType: state.contentTypeFilter == allContentType
            ? null
            : state.contentTypeFilter,
        search: state.searchKeyword,
      );
      final String? selectedContentId = _resolveSelectedContentId(
        contents,
        preferredId: selectContentId ?? state.selectedContentId,
      );
      final AdminLedgerContent? selectedContent = _findContentById(
        contents,
        selectedContentId,
      );

      emit(
        state.copyWith(
          loadStatus: AdminLoadStatus.success,
          contents: contents,
          selectedContentId: selectedContentId,
          editorContentType:
              selectedContent?.contentType ?? state.editorContentType,
          editorNumberKey: selectedContent?.numberKey ?? state.editorNumberKey,
          editorPayloadJson: selectedContent != null
              ? _prettyJson(selectedContent.payloadJsonb)
              : state.editorPayloadJson,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          loadStatus: AdminLoadStatus.failure,
          errorKey: _resolveErrorKey(error),
        ),
      );
    }
  }

  String? _resolveSelectedReleaseId(
    List<AdminLedgerRelease> releases, {
    String? preferredId,
  }) {
    if (releases.isEmpty) {
      return null;
    }
    if (preferredId != null &&
        releases.any(
          (AdminLedgerRelease release) => release.id == preferredId,
        )) {
      return preferredId;
    }
    final AdminLedgerRelease? active = _findActiveRelease(releases);
    return active?.id ?? releases.first.id;
  }

  String? _resolveSelectedContentId(
    List<AdminLedgerContent> contents, {
    String? preferredId,
  }) {
    if (contents.isEmpty) {
      return null;
    }
    if (preferredId != null &&
        contents.any(
          (AdminLedgerContent content) => content.id == preferredId,
        )) {
      return preferredId;
    }
    return contents.first.id;
  }

  String _prettyJson(Map<String, dynamic> value) {
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(value);
  }

  String _resolveErrorKey(Object error) {
    final String message = error.toString().toLowerCase();
    if (message.contains('forbidden')) {
      return 'admin_error_forbidden';
    }
    if (message.contains('unauthorized')) {
      return 'admin_error_unauthorized';
    }
    if (message.contains('supabase_not_configured')) {
      return 'admin_error_not_configured';
    }
    if (message.contains('release_not_draft')) {
      return 'admin_error_release_not_draft';
    }
    if (message.contains('invalid_payload_jsonb') ||
        message.contains('ledger_release_invalid_payload')) {
      return 'admin_error_invalid_payload';
    }
    if (message.contains('duplicate_release_version')) {
      return 'admin_error_duplicate_version';
    }
    return 'admin_error_generic';
  }

  AdminLedgerContent? _findContentById(
    List<AdminLedgerContent> contents,
    String? contentId,
  ) {
    if (contentId == null) {
      return null;
    }
    for (final AdminLedgerContent content in contents) {
      if (content.id == contentId) {
        return content;
      }
    }
    return null;
  }

  AdminLedgerRelease? _findActiveRelease(List<AdminLedgerRelease> releases) {
    for (final AdminLedgerRelease release in releases) {
      if (release.isActive) {
        return release;
      }
    }
    return null;
  }
}
