import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/extensions/int_extensions.dart';
import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/admin/components/admin_content_list.dart';
import 'package:test/src/ui/admin/components/admin_editor_panel.dart';
import 'package:test/src/ui/admin/components/admin_login_panel.dart';
import 'package:test/src/ui/admin/components/admin_release_toolbar.dart';
import 'package:test/src/ui/admin/interactor/admin_bloc.dart';
import 'package:test/src/ui/admin/interactor/admin_state.dart';
import 'package:test/src/ui/widgets/app_mystical_scaffold.dart';
import 'package:test/src/utils/app_colors.dart';
import 'package:test/src/utils/app_styles.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  static const List<String> _defaultContentTypes = <String>[
    AdminBloc.allContentType,
    'universal_day',
    'lucky_number',
    'daily_message',
    'angel_number',
    'number_library',
    'todaypersonalnumber',
    'month_personal_number',
    'year_personal_number',
    'life_path_number',
    'expression_number',
    'soul_urge_number',
    'mission_number',
    'birthday_matrix',
    'name_matrix',
    'life_cycles',
    'compatibility_content',
  ];

  late final AdminBloc _bloc;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _contentTypeController = TextEditingController();
  final TextEditingController _numberKeyController = TextEditingController();
  final TextEditingController _payloadController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bloc = Get.find<AdminBloc>();
    _bloc.bootstrap();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _searchController.dispose();
    _contentTypeController.dispose();
    _numberKeyController.dispose();
    _payloadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppMysticalScaffold(
      child: SafeArea(
        child: BlocConsumer<AdminBloc, AdminState>(
          bloc: _bloc,
          listener: _onStateChanged,
          builder: (BuildContext context, AdminState state) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    LocaleKey.adminTitle.tr,
                    style: AppStyles.h3(fontWeight: FontWeight.w700),
                  ),
                  4.height,
                  Text(
                    LocaleKey.adminSubtitle.tr,
                    style: AppStyles.bodySmall(color: AppColors.textMuted),
                  ),
                  12.height,
                  Expanded(
                    child: !state.isAuthenticated
                        ? AdminLoginPanel(
                            emailController: _emailController,
                            passwordController: _passwordController,
                            isLoading:
                                state.authStatus ==
                                AdminAuthStatus.authenticating,
                            onLoginTap: _onLoginTap,
                          )
                        : _buildWorkspace(state),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWorkspace(AdminState state) {
    final List<String> contentTypeOptions = _buildContentTypeOptions(state);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Widget toolbar = AdminReleaseToolbar(
          locale: state.localeFilter,
          releases: state.releases,
          selectedReleaseId: state.selectedReleaseId,
          selectedContentType: state.contentTypeFilter,
          contentTypeOptions: contentTypeOptions,
          searchController: _searchController,
          isPublishing: state.isPublishing,
          isCreatingDraft: state.isCreatingDraft,
          onLocaleChanged: _bloc.onLocaleChanged,
          onReleaseChanged: _bloc.onSelectRelease,
          onContentTypeChanged: _bloc.onContentTypeChanged,
          onSearchSubmitted: _bloc.onSearchChanged,
          onRefreshTap: _bloc.onRefreshContents,
          onPublishTap: _bloc.onPublish,
          onCreateDraftTap: () => _showCreateDraftDialog(state),
          onLogoutTap: _bloc.onLogout,
        );

        final Widget listPanel = AdminContentList(
          contents: state.contents,
          selectedContentId: state.selectedContentId,
          onSelectContent: _bloc.onSelectContent,
        );

        final Widget editorPanel = AdminEditorPanel(
          contentTypeController: _contentTypeController,
          numberKeyController: _numberKeyController,
          payloadController: _payloadController,
          isDraftRelease: state.selectedRelease?.isDraft ?? false,
          isSaving: state.isSaving,
          canSave: state.canSave,
          onContentTypeChanged: _bloc.onEditorContentTypeChanged,
          onNumberKeyChanged: _bloc.onEditorNumberKeyChanged,
          onPayloadChanged: _bloc.onEditorPayloadChanged,
          onSaveTap: _bloc.onSave,
        );

        if (constraints.maxWidth < 1100) {
          return Column(
            children: <Widget>[
              toolbar,
              12.height,
              SizedBox(height: 270, child: listPanel),
              12.height,
              Expanded(child: editorPanel),
            ],
          );
        }

        return Column(
          children: <Widget>[
            toolbar,
            12.height,
            Expanded(
              child: Row(
                children: <Widget>[
                  SizedBox(width: 360, child: listPanel),
                  12.width,
                  Expanded(child: editorPanel),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _onStateChanged(BuildContext context, AdminState state) {
    _syncTextController(_searchController, state.searchKeyword);
    _syncTextController(_contentTypeController, state.editorContentType);
    _syncTextController(_numberKeyController, state.editorNumberKey);
    _syncTextController(_payloadController, state.editorPayloadJson);

    if (state.errorKey != null && state.errorKey!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorKey!.tr),
          backgroundColor: AppColors.error,
        ),
      );
      _bloc.clearMessage();
      return;
    }

    if (state.messageKey != null && state.messageKey!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.messageKey!.tr),
          backgroundColor: AppColors.success,
        ),
      );
      _bloc.clearMessage();
    }
  }

  void _onLoginTap() {
    _bloc.onLogin(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  Future<void> _showCreateDraftDialog(AdminState state) async {
    final TextEditingController versionController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    final bool? shouldCreate = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(
            LocaleKey.adminCreateDraftTitle.tr,
            style: AppStyles.h5(fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  LocaleKey.adminVersionLabel.tr,
                  style: AppStyles.caption(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                6.height,
                TextField(
                  controller: versionController,
                  decoration: InputDecoration(
                    hintText: LocaleKey.adminVersionHint.tr,
                  ),
                ),
                10.height,
                Text(
                  LocaleKey.adminNotesLabel.tr,
                  style: AppStyles.caption(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                6.height,
                TextField(
                  controller: notesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: LocaleKey.adminNotesHint.tr,
                  ),
                ),
                10.height,
                Text(
                  '${LocaleKey.adminLocaleLabel.tr}: ${state.localeFilter.toUpperCase()}',
                  style: AppStyles.bodySmall(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(LocaleKey.commonCancel.tr),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(LocaleKey.adminCreateAction.tr),
            ),
          ],
        );
      },
    );

    if (shouldCreate == true) {
      _bloc.onCreateDraft(
        version: versionController.text,
        notes: notesController.text,
      );
    }
    versionController.dispose();
    notesController.dispose();
  }

  List<String> _buildContentTypeOptions(AdminState state) {
    final Set<String> values = <String>{..._defaultContentTypes};
    for (final content in state.contents) {
      values.add(content.contentType);
    }
    final List<String> options = values.toList()
      ..sort((String a, String b) {
        if (a == AdminBloc.allContentType) {
          return -1;
        }
        if (b == AdminBloc.allContentType) {
          return 1;
        }
        return a.compareTo(b);
      });
    return options;
  }

  void _syncTextController(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }
    controller
      ..text = value
      ..selection = TextSelection.collapsed(offset: value.length);
  }
}
