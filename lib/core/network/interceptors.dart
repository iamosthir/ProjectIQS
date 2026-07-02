import 'package:dio/dio.dart';

import '../storage/secure_token_store.dart';
import 'api_exception.dart';

/// Injects `Authorization: Bearer <token>` from the synchronous token cache.
/// 401 handling lives in [ApiClient] (4xx responses don't throw here — see the
/// Dio `validateStatus` config).
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStore);

  final SecureTokenStore _tokenStore;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokenStore.cachedToken;
    if (token != null && !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Injects `Accept-Language: ar|en` on every request from the current locale.
class LocaleInterceptor extends Interceptor {
  LocaleInterceptor(this._languageCode);

  final String Function() _languageCode;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] = _languageCode();
    handler.next(options);
  }
}

/// Converts transport-level failures (5xx, timeouts, connection errors) into a
/// typed [ApiException] carried on `DioException.error`, so [ApiClient] can
/// rethrow it uniformly. 4xx are handled in [ApiClient] from the response body.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: ApiException.fromDioException(err),
      ),
    );
  }
}
