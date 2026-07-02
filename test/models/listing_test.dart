import 'package:flutter_test/flutter_test.dart';

import 'package:iqs_flutter/features/marketplace/data/listing.dart';

void main() {
  group('Listing.fromJson', () {
    test('parses attributes as an associative MAP (canonical shape)', () {
      // Regression (Phase 4A): the backend serves attributes as a map keyed by
      // the field key, not a list.
      final l = Listing.fromJson({
        'id': 1,
        'title': 'Forward available',
        'attributes': {'position': 'Forward', 'foot': 'Right', 'empty': ''},
      });
      final keys = {for (final a in l.attributes) a.label: a.value};
      expect(keys['position'], 'Forward');
      expect(keys['foot'], 'Right');
      // Empty values are dropped.
      expect(keys.containsKey('empty'), isFalse);
    });

    test('falls back to a list of {label,value} objects', () {
      final l = Listing.fromJson({
        'id': 2,
        'title': 'X',
        'attributes': [
          {'label': 'Height', 'value': '180'},
          {'key': 'Weight', 'value': '75'},
        ],
      });
      final keys = {for (final a in l.attributes) a.label: a.value};
      expect(keys['Height'], '180');
      expect(keys['Weight'], '75');
    });

    test('maps status enum + media url/path fallback', () {
      final l = Listing.fromJson({
        'id': 3,
        'title': 'Y',
        'status': 'pending_payment',
        'media': [
          {'id': 1, 'type': 'image', 'path': 'listings/3/a.jpg'},
        ],
      });
      expect(l.status, ListingStatus.pendingPayment);
      expect(l.media.single.url, 'listings/3/a.jpg');
    });

    test('unknown / absent status', () {
      expect(listingStatusFrom(null), ListingStatus.unknown);
      expect(listingStatusFrom('weird'), ListingStatus.unknown);
      expect(listingStatusFrom('published'), ListingStatus.published);
    });
  });
}
