import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iqs_flutter/core/network/api_exception.dart';

Response<dynamic> _resp(int code, dynamic data,
        {Map<String, List<String>>? headers}) =>
    Response<dynamic>(
      requestOptions: RequestOptions(path: '/'),
      statusCode: code,
      data: data,
      headers: headers == null ? null : Headers.fromMap(headers),
    );

void main() {
  group('ApiException.fromResponse', () {
    test('422 maps the errors object to field → messages', () {
      final e = ApiException.fromResponse(_resp(422, {
        'success': false,
        'message': 'The given data was invalid.',
        'errors': {
          'otp': ['The otp is invalid.'],
          'phone': ['required'],
        },
      }));
      expect(e.statusCode, 422);
      expect(e.isValidation, isTrue);
      expect(e.fieldError('otp'), 'The otp is invalid.');
      expect(e.fieldError('phone'), 'required');
      expect(e.fieldError('missing'), isNull);
    });

    test('status-code helpers', () {
      expect(ApiException.fromResponse(_resp(401, {})).isUnauthorized, isTrue);
      expect(ApiException.fromResponse(_resp(403, {})).isForbidden, isTrue);
      expect(ApiException.fromResponse(_resp(404, {})).isNotFound, isTrue);
      // 422 without an errors map is NOT a "validation" error for field mapping.
      expect(ApiException.fromResponse(_resp(422, {'message': 'x'})).isValidation,
          isFalse);
    });

    test('reads Retry-After on 429', () {
      final e = ApiException.fromResponse(_resp(
        429,
        {'message': 'Too many requests'},
        headers: {'retry-after': ['30']},
      ));
      expect(e.isThrottled, isTrue);
      expect(e.retryAfter, 30);
    });

    test('falls back to a generic message when none supplied', () {
      final e = ApiException.fromResponse(_resp(500, {}));
      expect(e.message, isNotEmpty);
    });
  });

  group('ApiException.fromDioException', () {
    test('connection error → network kind', () {
      final e = ApiException.fromDioException(DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionError,
      ));
      expect(e.isNetwork, isTrue);
    });

    test('timeout → network kind', () {
      final e = ApiException.fromDioException(DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.receiveTimeout,
      ));
      expect(e.isNetwork, isTrue);
    });
  });
}
