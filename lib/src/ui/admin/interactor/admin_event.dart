import 'package:equatable/equatable.dart';

sealed class AdminEvent extends Equatable {
  const AdminEvent();
}

final class AdminBootstrapRequested extends AdminEvent {
  const AdminBootstrapRequested();

  @override
  List<Object?> get props => <Object?>[];
}

final class AdminLoginSubmitted extends AdminEvent {
  const AdminLoginSubmitted({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => <Object?>[email, password];
}

final class AdminLogoutRequested extends AdminEvent {
  const AdminLogoutRequested();

  @override
  List<Object?> get props => <Object?>[];
}

final class AdminLocaleFilterChanged extends AdminEvent {
  const AdminLocaleFilterChanged(this.locale);

  final String locale;

  @override
  List<Object?> get props => <Object?>[locale];
}

final class AdminContentTypeFilterChanged extends AdminEvent {
  const AdminContentTypeFilterChanged(this.contentType);

  final String contentType;

  @override
  List<Object?> get props => <Object?>[contentType];
}

final class AdminSearchKeywordChanged extends AdminEvent {
  const AdminSearchKeywordChanged(this.keyword);

  final String keyword;

  @override
  List<Object?> get props => <Object?>[keyword];
}

final class AdminReleaseSelected extends AdminEvent {
  const AdminReleaseSelected(this.releaseId);

  final String releaseId;

  @override
  List<Object?> get props => <Object?>[releaseId];
}

final class AdminContentsRequested extends AdminEvent {
  const AdminContentsRequested();

  @override
  List<Object?> get props => <Object?>[];
}

final class AdminContentSelected extends AdminEvent {
  const AdminContentSelected(this.contentId);

  final String contentId;

  @override
  List<Object?> get props => <Object?>[contentId];
}

final class AdminEditorContentTypeChanged extends AdminEvent {
  const AdminEditorContentTypeChanged(this.value);

  final String value;

  @override
  List<Object?> get props => <Object?>[value];
}

final class AdminEditorNumberKeyChanged extends AdminEvent {
  const AdminEditorNumberKeyChanged(this.value);

  final String value;

  @override
  List<Object?> get props => <Object?>[value];
}

final class AdminEditorPayloadChanged extends AdminEvent {
  const AdminEditorPayloadChanged(this.value);

  final String value;

  @override
  List<Object?> get props => <Object?>[value];
}

final class AdminSaveRequested extends AdminEvent {
  const AdminSaveRequested();

  @override
  List<Object?> get props => <Object?>[];
}

final class AdminPublishRequested extends AdminEvent {
  const AdminPublishRequested();

  @override
  List<Object?> get props => <Object?>[];
}

final class AdminCreateDraftRequested extends AdminEvent {
  const AdminCreateDraftRequested({required this.version, required this.notes});

  final String version;
  final String notes;

  @override
  List<Object?> get props => <Object?>[version, notes];
}

final class AdminMessageCleared extends AdminEvent {
  const AdminMessageCleared();

  @override
  List<Object?> get props => <Object?>[];
}
