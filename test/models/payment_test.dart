import 'package:flutter_test/flutter_test.dart';

import 'package:iqs_flutter/features/payments/data/payment.dart';

void main() {
  group('Payment.fromJson', () {
    Map<String, dynamic> base() => {
          'id': 7,
          'payment_number': 'IQS-PAY-20260705-AB12CD',
          'gateway': 'zaincash',
          'amount': 10000,
          'currency': 'IQD',
          'status': 'pending',
          'payable': {'type': 'Listing', 'id': 42},
          'redirect_url': 'https://gw/pay/1',
          'qr': 'QRDATA',
          'expires_at': '2026-07-05T10:30:00+00:00',
          'created_at': '2026-07-05T10:00:00+00:00',
        };

    test('maps core fields + transient redirect/qr', () {
      final p = Payment.fromJson(base());
      expect(p.id, 7);
      expect(p.paymentNumber, 'IQS-PAY-20260705-AB12CD');
      expect(p.gateway, PaymentGateway.zaincash);
      expect(p.amount, 10000);
      expect(p.currency, 'IQD');
      expect(p.status, PaymentStatus.pending);
      expect(p.payableType, 'Listing');
      expect(p.payableId, 42);
      expect(p.redirectUrl, 'https://gw/pay/1');
      expect(p.qr, 'QRDATA');
      expect(p.expiresAt, isNotNull);
    });

    test('parses amount whether a JSON number or a decimal STRING', () {
      // The resource forces (float), but a Laravel decimal cast can serialize
      // as a string elsewhere — must not throw.
      expect(Payment.fromJson(base()..['amount'] = 10000).amount, 10000.0);
      expect(Payment.fromJson(base()..['amount'] = '15000.50').amount, 15000.5);
      expect(Payment.fromJson(base()..['amount'] = null).amount, 0);
    });

    test('redirect_url/qr are null on a status read (absent keys)', () {
      final read = base()
        ..remove('redirect_url')
        ..remove('qr');
      final p = Payment.fromJson(read);
      expect(p.redirectUrl, isNull);
      expect(p.qr, isNull);
    });

    test('status final/success helpers', () {
      for (final s in ['paid', 'failed', 'cancelled', 'refunded']) {
        expect(paymentStatusFrom(s).isFinal, isTrue, reason: s);
      }
      expect(paymentStatusFrom('pending').isFinal, isFalse);
      expect(paymentStatusFrom('processing').isFinal, isFalse);
      expect(paymentStatusFrom('paid').isSuccess, isTrue);
      expect(paymentStatusFrom('failed').isSuccess, isFalse);
      expect(paymentStatusFrom('bogus'), PaymentStatus.unknown);
    });

    test('gateway value round-trips (never sends manual from picker)', () {
      expect(PaymentGateway.zaincash.value, 'zaincash');
      expect(PaymentGateway.fib.value, 'fib');
      expect(paymentGatewayFrom('manual'), PaymentGateway.manual);
      expect(paymentGatewayFrom('xx'), PaymentGateway.unknown);
    });
  });
}
