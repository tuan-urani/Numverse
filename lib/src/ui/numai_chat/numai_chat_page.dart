import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/locale/locale_key.dart';
import 'package:test/src/ui/compatibility/components/compatibility_profile_input_dialog.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_state.dart';
import 'package:test/src/ui/numai_chat/components/numai_chat_header.dart';
import 'package:test/src/ui/numai_chat/components/numai_chat_input_bar.dart';
import 'package:test/src/ui/numai_chat/components/numai_chat_messages.dart';
import 'package:test/src/ui/numai_chat/interactor/numai_chat_bloc.dart';
import 'package:test/src/ui/numai_chat/interactor/numai_chat_state.dart';
import 'package:test/src/ui/widgets/app_mystical_scaffold.dart';
import 'package:test/src/ui/widgets/app_state_view.dart';
import 'package:test/src/ui/widgets/soul_points_insufficient_dialog.dart';
import 'package:test/src/utils/app_pages.dart';
import 'package:test/src/utils/tab_navigation_helper.dart';

class NumAiChatPage extends StatefulWidget {
  const NumAiChatPage({super.key});

  @override
  State<NumAiChatPage> createState() => _NumAiChatPageState();
}

class _NumAiChatPageState extends State<NumAiChatPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final Object? args =
          Get.arguments ?? ModalRoute.of(context)?.settings.arguments;
      if (args is! Map<String, dynamic>) {
        return;
      }
      final Object? value = args['initialMessage'];
      if (value is! String || value.trim().isEmpty) {
        return;
      }
      _controller.text = value;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MainSessionBloc sessionCubit = Get.find<MainSessionBloc>();
    final NumAiChatBloc bloc = Get.isRegistered<NumAiChatBloc>()
        ? Get.find<NumAiChatBloc>()
        : Get.put<NumAiChatBloc>(NumAiChatBloc());

    if (sessionCubit.state.viewState == AppViewStateStatus.loading) {
      sessionCubit.initialize();
    }

    return AppMysticalScaffold(
      child: SafeArea(
        bottom: false,
        child: BlocBuilder<MainSessionBloc, MainSessionState>(
          bloc: sessionCubit,
          builder: (BuildContext context, MainSessionState sessionState) {
            return AppStateView(
              status: sessionState.viewState,
              onRetry: sessionCubit.initialize,
              success: BlocBuilder<NumAiChatBloc, NumAiChatState>(
                bloc: bloc,
                builder: (BuildContext context, NumAiChatState state) {
                  return Column(
                    children: <Widget>[
                      NumAiChatHeader(
                        soulPoints: sessionState.soulPoints,
                        onBackTap: () => _onBackTap(context),
                      ),
                      Expanded(
                        child: NumAiChatMessages(
                          messages: state.messages,
                          isLoading: state.isLoading,
                          onActionTap: () => _onActionTap(
                            context,
                            bloc: bloc,
                            sessionCubit: sessionCubit,
                          ),
                          onQuickSuggestionTap: (String suggestion) {
                            bloc.applyQuickSuggestion(suggestion);
                            _controller.text = suggestion;
                            _controller.selection = TextSelection.fromPosition(
                              TextPosition(offset: _controller.text.length),
                            );
                            setState(() {});
                          },
                        ),
                      ),
                      NumAiChatInputBar(
                        controller: _controller,
                        isLoading: state.isLoading,
                        canAffordMessage:
                            sessionState.soulPoints >=
                            NumAiChatBloc.messageCost,
                        showInsufficientPointsWarning:
                            state.showInsufficientPointsWarning,
                        onTextChanged: (_) {
                          bloc.clearInsufficientWarning();
                          setState(() {});
                        },
                        onSendTap: () => _onSendTap(
                          bloc: bloc,
                          sessionCubit: sessionCubit,
                          sessionState: sessionState,
                        ),
                        onClearTap: () {
                          _controller.clear();
                          setState(() {});
                        },
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onSendTap({
    required NumAiChatBloc bloc,
    required MainSessionBloc sessionCubit,
    required MainSessionState sessionState,
  }) async {
    final String text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    if (sessionState.soulPoints < NumAiChatBloc.messageCost) {
      await _showSoulPointsInsufficientModal(
        requiredPoints: NumAiChatBloc.messageCost,
        sessionCubit: sessionCubit,
      );
      return;
    }

    final bool sent = await bloc.sendMessage(
      rawMessage: text,
      hasProfile: sessionState.currentProfile != null,
      deductSoulPoints: (int amount) => sessionCubit.deductSoulPoints(
        amount,
        sourceType: 'numai_message',
        metadata: const <String, dynamic>{'screen': 'numai_chat'},
      ),
    );
    if (!mounted || !sent) {
      return;
    }

    _controller.clear();
    setState(() {});
  }

  Future<void> _onActionTap(
    BuildContext context, {
    required NumAiChatBloc bloc,
    required MainSessionBloc sessionCubit,
  }) async {
    await CompatibilityProfileInputDialog.show(
      context,
      onSubmit: (String name, DateTime birthDate) async {
        await sessionCubit.addProfile(name: name, birthDate: birthDate);
      },
    );

    if (!mounted || sessionCubit.state.currentProfile == null) {
      return;
    }

    bloc.appendPendingQuestionAnswerAfterProfile();
  }

  void _onBackTap(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Get.offAllNamed(AppPages.numai);
  }

  Future<void> _showSoulPointsInsufficientModal({
    required int requiredPoints,
    required MainSessionBloc sessionCubit,
  }) async {
    await SoulPointsInsufficientDialog.show(
      context,
      sessionBloc: sessionCubit,
      requiredPoints: requiredPoints,
      onWatchAdTap: _onWatchAdTap,
      onBuyPointsTap: _onBuyPointsTap,
    );
  }

  Future<void> _onWatchAdTap() async {
    Get.snackbar(
      LocaleKey.commonComingSoon.tr,
      LocaleKey.commonComingSoon.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _onBuyPointsTap() async {
    await TabNavigationHelper.pushCommonRoute(AppPages.subscription);
  }
}
