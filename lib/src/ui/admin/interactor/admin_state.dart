import 'package:equatable/equatable.dart';

import 'package:test/src/core/model/admin_ledger_content.dart';
import 'package:test/src/core/model/admin_ledger_release.dart';

enum AdminAuthStatus { unauthenticated, authenticating, authenticated }

enum AdminLoadStatus { initial, loading, success, failure }

class AdminState extends Equatable {
  const AdminState({
    required this.authStatus,
    required this.loadStatus,
    required this.localeFilter,
    required this.contentTypeFilter,
    required this.searchKeyword,
    required this.releases,
    required this.selectedReleaseId,
    required this.contents,
    required this.selectedContentId,
    required this.editorContentType,
    required this.editorNumberKey,
    required this.editorPayloadJson,
    required this.isSaving,
    required this.isPublishing,
    required this.isCreatingDraft,
    required this.messageKey,
    required this.errorKey,
  });

  factory AdminState.initial() {
    return const AdminState(
      authStatus: AdminAuthStatus.unauthenticated,
      loadStatus: AdminLoadStatus.initial,
      localeFilter: 'vi',
      contentTypeFilter: 'all',
      searchKeyword: '',
      releases: <AdminLedgerRelease>[],
      selectedReleaseId: null,
      contents: <AdminLedgerContent>[],
      selectedContentId: null,
      editorContentType: '',
      editorNumberKey: '',
      editorPayloadJson: '{}',
      isSaving: false,
      isPublishing: false,
      isCreatingDraft: false,
      messageKey: null,
      errorKey: null,
    );
  }

  final AdminAuthStatus authStatus;
  final AdminLoadStatus loadStatus;
  final String localeFilter;
  final String contentTypeFilter;
  final String searchKeyword;
  final List<AdminLedgerRelease> releases;
  final String? selectedReleaseId;
  final List<AdminLedgerContent> contents;
  final String? selectedContentId;
  final String editorContentType;
  final String editorNumberKey;
  final String editorPayloadJson;
  final bool isSaving;
  final bool isPublishing;
  final bool isCreatingDraft;
  final String? messageKey;
  final String? errorKey;

  bool get isAuthenticated => authStatus == AdminAuthStatus.authenticated;

  AdminLedgerRelease? get selectedRelease {
    final String? selectedId = selectedReleaseId;
    if (selectedId == null) {
      return null;
    }
    for (final AdminLedgerRelease release in releases) {
      if (release.id == selectedId) {
        return release;
      }
    }
    return null;
  }

  AdminLedgerContent? get selectedContent {
    final String? selectedId = selectedContentId;
    if (selectedId == null) {
      return null;
    }
    for (final AdminLedgerContent content in contents) {
      if (content.id == selectedId) {
        return content;
      }
    }
    return null;
  }

  bool get canSave {
    return (selectedRelease?.isDraft ?? false) &&
        editorContentType.trim().isNotEmpty &&
        editorNumberKey.trim().isNotEmpty;
  }

  AdminState copyWith({
    AdminAuthStatus? authStatus,
    AdminLoadStatus? loadStatus,
    String? localeFilter,
    String? contentTypeFilter,
    String? searchKeyword,
    List<AdminLedgerRelease>? releases,
    String? selectedReleaseId,
    bool clearSelectedReleaseId = false,
    List<AdminLedgerContent>? contents,
    String? selectedContentId,
    bool clearSelectedContentId = false,
    String? editorContentType,
    String? editorNumberKey,
    String? editorPayloadJson,
    bool? isSaving,
    bool? isPublishing,
    bool? isCreatingDraft,
    String? messageKey,
    bool clearMessageKey = false,
    String? errorKey,
    bool clearErrorKey = false,
  }) {
    return AdminState(
      authStatus: authStatus ?? this.authStatus,
      loadStatus: loadStatus ?? this.loadStatus,
      localeFilter: localeFilter ?? this.localeFilter,
      contentTypeFilter: contentTypeFilter ?? this.contentTypeFilter,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      releases: releases ?? this.releases,
      selectedReleaseId: clearSelectedReleaseId
          ? null
          : selectedReleaseId ?? this.selectedReleaseId,
      contents: contents ?? this.contents,
      selectedContentId: clearSelectedContentId
          ? null
          : selectedContentId ?? this.selectedContentId,
      editorContentType: editorContentType ?? this.editorContentType,
      editorNumberKey: editorNumberKey ?? this.editorNumberKey,
      editorPayloadJson: editorPayloadJson ?? this.editorPayloadJson,
      isSaving: isSaving ?? this.isSaving,
      isPublishing: isPublishing ?? this.isPublishing,
      isCreatingDraft: isCreatingDraft ?? this.isCreatingDraft,
      messageKey: clearMessageKey ? null : messageKey ?? this.messageKey,
      errorKey: clearErrorKey ? null : errorKey ?? this.errorKey,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    authStatus,
    loadStatus,
    localeFilter,
    contentTypeFilter,
    searchKeyword,
    releases,
    selectedReleaseId,
    contents,
    selectedContentId,
    editorContentType,
    editorNumberKey,
    editorPayloadJson,
    isSaving,
    isPublishing,
    isCreatingDraft,
    messageKey,
    errorKey,
  ];
}
