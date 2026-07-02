import 'package:iqs_flutter/core/api/api_models.dart';
import 'package:iqs_flutter/core/network/api_client.dart';

import 'payment.dart';

/// Payments (Phase 7). The app never calls the gateway `/callback` — the
/// outcome is learned only by polling `status`.
class PaymentsRepository {
  PaymentsRepository(this._api);

  final ApiClient _api;

  /// `POST /payments/initiate`. `gateway` ∈ zaincash|fib (never manual).
  /// 404 unknown payable · 403 not owner · 502 gateway init failed.
  /// The returned [Payment] carries transient `redirectUrl`/`qr`.
  Future<Payment> initiate({
    required String payableType,
    required int payableId,
    required String gateway,
  }) =>
      _api.post(
        '/payments/initiate',
        data: {
          'payable_type': payableType,
          'payable_id': payableId,
          'gateway': gateway,
        },
        parse: (d) => Payment.fromJson((d as Map).cast<String, dynamic>()),
      );

  /// `GET /payments/:number/status`. 404 for an unknown **or** non-owned number
  /// (user-scoped `firstOrFail`, NOT 403). `redirectUrl`/`qr` are null here.
  Future<Payment> status(String number) => _api.get(
        '/payments/$number/status',
        parse: (d) => Payment.fromJson((d as Map).cast<String, dynamic>()),
      );

  Future<Paginated<Payment>> history({int page = 1}) => _api.getPaged(
        '/payments',
        query: {'page': page, 'per_page': 20},
        parseItem: Payment.fromJson,
      );
}
