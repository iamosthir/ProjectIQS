import 'package:dio/dio.dart';

import '../api/api_models.dart';
import 'api_exception.dart';

/// The single gateway to the API. Every repository goes through this — widgets
/// never touch Dio directly.
///
/// Responsibilities:
/// - unwrap the success envelope (`{success, message, data, meta}`) → `data`;
/// - lift `meta.pagination` into a [Paginated];
/// - throw a typed [ApiException] on `success:false` / non-2xx;
/// - fire [_onUnauthorized] on 401 (token already invalid → clear + bounce).
class ApiClient {
  ApiClient(this._dio, {void Function()? onUnauthorized})
      : _onUnauthorized = onUnauthorized;

  final Dio _dio;
  final void Function()? _onUnauthorized;

  Dio get raw => _dio;

  // ---- typed single-object calls ----

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    required T Function(dynamic data) parse,
  }) =>
      _send(() => _dio.get(path, queryParameters: query), parse);

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    required T Function(dynamic data) parse,
  }) =>
      _send(() => _dio.post(path, data: data, queryParameters: query), parse);

  Future<T> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    required T Function(dynamic data) parse,
  }) =>
      _send(() => _dio.put(path, data: data, queryParameters: query), parse);

  Future<T> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    required T Function(dynamic data) parse,
  }) =>
      _send(() => _dio.delete(path, data: data, queryParameters: query), parse);

  /// Multipart POST (file uploads). Same envelope handling as [post].
  Future<T> postMultipart<T>(
    String path, {
    required FormData data,
    required T Function(dynamic data) parse,
  }) =>
      _send(() => _dio.post(path, data: data), parse);

  // ---- paginated list calls ----

  Future<Paginated<T>> getPaged<T>(
    String path, {
    Map<String, dynamic>? query,
    required T Function(Map<String, dynamic> json) parseItem,
  }) async {
    final res = await _call(() => _dio.get(path, queryParameters: query));
    final body = res.data;
    if (body is Map && body['success'] == true) {
      final list = (body['data'] as List?) ?? const [];
      final items = list
          .map((e) => parseItem((e as Map).cast<String, dynamic>()))
          .toList();
      final meta = _readPageMeta(body['meta'], items.length);
      return Paginated(items: items, meta: meta);
    }
    throw _failure(res);
  }

  // ---- internals ----

  Future<T> _send<T>(
    Future<Response> Function() call,
    T Function(dynamic data) parse,
  ) async {
    final res = await _call(call);
    final body = res.data;
    if (body is Map && body['success'] == true) {
      return parse(body['data']);
    }
    throw _failure(res);
  }

  /// Executes a Dio call, normalizing transport errors to [ApiException].
  Future<Response> _call(Future<Response> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw (e.error is ApiException)
          ? e.error as ApiException
          : ApiException.fromDioException(e);
    }
  }

  ApiException _failure(Response res) {
    final err = ApiException.fromResponse(res);
    if (err.isUnauthorized) _onUnauthorized?.call();
    return err;
  }

  PageMeta _readPageMeta(dynamic meta, int fallbackCount) {
    if (meta is Map && meta['pagination'] is Map) {
      return PageMeta.fromJson((meta['pagination'] as Map).cast<String, dynamic>());
    }
    return PageMeta.single(fallbackCount);
  }
}
