import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:test/src/core/repository/interface/i_numerology_content_repository.dart';
import 'package:test/src/ui/chart_matrix/components/chart_matrix_content.dart';
import 'package:test/src/ui/chart_matrix/components/chart_matrix_header.dart';
import 'package:test/src/ui/chart_matrix/interactor/chart_matrix_bloc.dart';
import 'package:test/src/ui/chart_matrix/interactor/chart_matrix_state.dart';
import 'package:test/src/ui/main/interactor/main_session_bloc.dart';
import 'package:test/src/ui/main/interactor/main_session_state.dart';
import 'package:test/src/ui/widgets/app_mystical_scaffold.dart';
import 'package:test/src/ui/widgets/app_state_view.dart';
import 'package:test/src/utils/app_pages.dart';

class ChartMatrixPage extends StatefulWidget {
  const ChartMatrixPage({super.key});

  @override
  State<ChartMatrixPage> createState() => _ChartMatrixPageState();
}

class _ChartMatrixPageState extends State<ChartMatrixPage> {
  final GlobalKey _birthSectionKey = GlobalKey();
  final GlobalKey _nameSectionKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final MainSessionBloc sessionCubit = Get.find<MainSessionBloc>();
    final ChartMatrixBloc bloc = Get.isRegistered<ChartMatrixBloc>()
        ? Get.find<ChartMatrixBloc>()
        : Get.put<ChartMatrixBloc>(
            ChartMatrixBloc(
              contentRepository: Get.find<INumerologyContentRepository>(),
            ),
          );

    if (sessionCubit.state.viewState == AppViewStateStatus.loading) {
      sessionCubit.initialize();
    }

    return AppMysticalScaffold(
      child: SafeArea(
        bottom: false,
        child: BlocBuilder<MainSessionBloc, MainSessionState>(
          bloc: sessionCubit,
          builder: (BuildContext context, MainSessionState sessionState) {
            final String languageCode = Get.locale?.languageCode ?? 'vi';
            bloc.syncProfile(
              sessionState.currentProfile,
              languageCode: languageCode,
            );
            return AppStateView(
              status: sessionState.viewState,
              onRetry: sessionCubit.initialize,
              success: BlocBuilder<ChartMatrixBloc, ChartMatrixState>(
                bloc: bloc,
                builder: (BuildContext context, ChartMatrixState state) {
                  return Column(
                    children: <Widget>[
                      ChartMatrixHeader(onBackTap: () => _onBack(context)),
                      Expanded(
                        child: SingleChildScrollView(
                          child: ChartMatrixContent(
                            state: state,
                            onToggleBirthChart: () =>
                                _onToggleBirthChart(bloc, state),
                            onToggleNameChart: () =>
                                _onToggleNameChart(bloc, state),
                            birthSectionKey: _birthSectionKey,
                            nameSectionKey: _nameSectionKey,
                          ),
                        ),
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

  void _onToggleBirthChart(ChartMatrixBloc bloc, ChartMatrixState state) {
    final bool willExpand = !state.expandedBirthChart;
    bloc.toggleBirthChart();
    if (willExpand) {
      _scrollToSection(_birthSectionKey);
    }
  }

  void _onToggleNameChart(ChartMatrixBloc bloc, ChartMatrixState state) {
    final bool willExpand = !state.expandedNameChart;
    bloc.toggleNameChart();
    if (willExpand) {
      _scrollToSection(_nameSectionKey);
    }
  }

  void _scrollToSection(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? sectionContext = key.currentContext;
      if (sectionContext == null || !mounted) {
        return;
      }
      Scrollable.ensureVisible(
        sectionContext,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: 0.04,
      );
      Future<void>.delayed(const Duration(milliseconds: 220), () {
        final BuildContext? delayedContext = key.currentContext;
        if (delayedContext == null || !mounted) {
          return;
        }
        Scrollable.ensureVisible(
          delayedContext,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: 0.04,
        );
      });
    });
  }

  void _onBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Get.offAllNamed(AppPages.main);
  }
}
