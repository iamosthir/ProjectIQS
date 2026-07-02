import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iqs_flutter/core/network/network_providers.dart';
import 'package:iqs_flutter/features/payments/data/payments_repository.dart';

final paymentsRepositoryProvider = Provider<PaymentsRepository>(
  (ref) => PaymentsRepository(ref.watch(apiClientProvider)),
);
