import 'package:dio/dio.dart';

enum ApiErrorKind { server, network, cancelled }

/// The single typed error surfaced by the data layer. Repositories throw this;
/// the application layer turns it into an `AsyncError` so screens render
/// `ErrorState`. Built from either a non-2xx response envelope or a transport
/// [DioException].
class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
    this.retryAfter,
    this.kind = ApiErrorKind.server,
  });

  /// Localized, user-facing message. For server failures this is the envelope's
  /// `message` (the backend pre-localizes via `Accept-Language`); for transport
  /// failures it is an Arabic fallback.
  final String message;
  final int? statusCode;

  /// 422 validation map: field → messages.
  final Map<String, List<String>>? errors;

  /// 429 `Retry-After` seconds, when present.
  final int? retryAfter;
  final ApiErrorKind kind;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidation => statusCode == 422 && (errors?.isNotEmpty ?? false);
  bool get isThrottled => statusCode == 429;
  bool get isNetwork => kind == ApiErrorKind.network;

  /// First validation message for [field], if any.
  String? fieldError(String field) {
    final list = errors?[field];
    return (list != null && list.isNotEmpty) ? list.first : null;
  }

  factory ApiException.fromResponse(Response response) {
    final data = response.data;
    String message = 'حدث خطأ غير متوقع';
    Map<String, List<String>>? errors;
    int? bodyRetryAfter;
    if (data is Map) {
      final m = data['message'];
      if (m is String && m.isNotEmpty) message = m;
      final raw = data['errors'];
      if (raw is Map) {
        errors = raw.map(
          (k, v) => MapEntry(
            k.toString(),
            v is List
                ? v.map((e) => e.toString()).toList()
                : <String>[v.toString()],
          ),
        );
      }
      // Backend surfaces the cooldown as a top-level `retry_after` (seconds).
      final ra = data['retry_after'];
      if (ra is num) {
        bodyRetryAfter = ra.toInt();
      } else if (ra is String) {
        bodyRetryAfter = int.tryParse(ra);
      }
    }
    // Prefer the body field; fall back to the standard `Retry-After` header.
    final retryAfter = bodyRetryAfter ??
        int.tryParse(response.headers.value('retry-after') ?? '');
    return ApiException(
      message: message,
      statusCode: response.statusCode,
      errors: errors,
      retryAfter: retryAfter,
      kind: ApiErrorKind.server,
    );
  }

  factory ApiException.fromDioException(DioException e) {
    if (e.response != null) return ApiException.fromResponse(e.response!);
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'انتهت مهلة الاتصال بالخادم',
          kind: ApiErrorKind.network,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          message: 'تعذّر الاتصال بالخادم. تحقّق من اتصالك بالإنترنت',
          kind: ApiErrorKind.network,
        );
      case DioExceptionType.cancel:
        return ApiException(
          message: 'تم إلغاء الطلب',
          kind: ApiErrorKind.cancelled,
        );
      default:
        return ApiException(
          message: 'تعذّر إكمال الطلب',
          kind: ApiErrorKind.network,
        );
    }
  }

  @override
  String toString() => 'ApiException(status: $statusCode, message: $message)';
}
