import 'package:dio/dio.dart';

import 'package:test/src/core/service/supabase_offline_coordinator.dart';
import 'package:test/src/core/service/supabase_offline_error_classifier.dart';

const String kSupabaseOfflineRetriedRequestExtraKey =
    'supabase_offline_retried_once';

class SupabaseOfflineInterceptor extends Interceptor {
  SupabaseOfflineInterceptor({
    required Dio dio,
    required SupabaseOfflineCoordinator coordinator,
  }) : _dio = dio,
       _coordinator = coordinator;

  final Dio _dio;
  final SupabaseOfflineCoordinator _coordinator;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!isSupabaseOfflineError(err)) {
      handler.next(err);
      return;
    }

    if (_coordinator.isLaunchGuardActive) {
      _coordinator.markLaunchOfflineError();
      handler.next(err);
      return;
    }

    final bool alreadyRetried =
        err.requestOptions.extra[kSupabaseOfflineRetriedRequestExtraKey] ==
        true;
    if (alreadyRetried) {
      handler.next(err);
      return;
    }

    final SupabaseOfflinePopupAction action = await _coordinator
        .showInAppRetryPopup();
    if (action != SupabaseOfflinePopupAction.retry) {
      handler.next(err);
      return;
    }

    final Map<String, dynamic> nextExtra = Map<String, dynamic>.from(
      err.requestOptions.extra,
    )..[kSupabaseOfflineRetriedRequestExtraKey] = true;
    final RequestOptions retryOptions = err.requestOptions.copyWith(
      extra: nextExtra,
    );

    try {
      final Response<dynamic> retryResponse = await _dio.fetch<dynamic>(
        retryOptions,
      );
      handler.resolve(retryResponse);
    } on DioException catch (retryError) {
      handler.next(retryError);
    } catch (retryError, stackTrace) {
      handler.next(
        DioException(
          requestOptions: retryOptions,
          type: DioExceptionType.unknown,
          error: retryError,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
