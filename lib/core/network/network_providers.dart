import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../core_providers.dart';
import '../i18n/locale_provider.dart';
import 'api_client.dart';
import 'interceptors.dart';

/// Configured Dio instance. `Accept: application/json` is mandatory — without
/// it the backend returns HTTP 500 "Route [login] not defined." instead of 401.
final dioProvider = Provider<Dio>((ref) {
  final tokenStore = ref.watch(secureTokenStoreProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiV1,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: const {'Accept': 'application/json'},
      contentType: Headers.jsonContentType,
      // 4xx come back as normal responses (ApiClient turns them into typed
      // errors); only 5xx / transport failures throw → ErrorInterceptor.
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(AuthInterceptor(tokenStore));
  dio.interceptors
      .add(LocaleInterceptor(() => ref.read(localeProvider).languageCode));
  if (Env.isDebug) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
        logPrint: (obj) => debugPrint(obj.toString()),
      ),
    );
  }
  dio.interceptors.add(ErrorInterceptor());

  return dio;
});

/// The app-wide [ApiClient]. On 401 it clears the (now-invalid) token and bumps
/// [unauthorizedSignalProvider] so the auth layer re-evaluates the session.
final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(
    dio,
    onUnauthorized: () {
      unawaited(ref.read(secureTokenStoreProvider).clear());
      ref.read(unauthorizedSignalProvider.notifier).state++;
    },
  );
});
