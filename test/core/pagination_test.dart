import 'package:flutter_test/flutter_test.dart';

import 'package:iqs_flutter/core/api/api_models.dart';

void main() {
  group('PageMeta', () {
    test('hasMore = current_page < last_page', () {
      final m = PageMeta.fromJson({
        'current_page': 1,
        'per_page': 20,
        'total': 50,
        'last_page': 3,
      });
      expect(m.hasMore, isTrue);
      expect(m.currentPage, 1);

      final last = PageMeta.fromJson({
        'current_page': 3,
        'per_page': 20,
        'total': 50,
        'last_page': 3,
      });
      expect(last.hasMore, isFalse);
    });

    test('single() fallback for bare-array endpoints', () {
      final m = PageMeta.single(8);
      expect(m.hasMore, isFalse);
      expect(m.total, 8);
      expect(m.lastPage, 1);
    });

    test('defaults when keys are missing', () {
      final m = PageMeta.fromJson({});
      expect(m.currentPage, 1);
      expect(m.lastPage, 1);
      expect(m.hasMore, isFalse);
    });
  });

  group('Paginated', () {
    test('appended carries the latest meta', () {
      final p1 = Paginated<int>(
        items: const [1, 2],
        meta: PageMeta.fromJson(
            {'current_page': 1, 'per_page': 2, 'total': 4, 'last_page': 2}),
      );
      final p2 = Paginated<int>(
        items: const [3, 4],
        meta: PageMeta.fromJson(
            {'current_page': 2, 'per_page': 2, 'total': 4, 'last_page': 2}),
      );
      final merged = p1.appended(p2);
      expect(merged.items, [1, 2, 3, 4]);
      expect(merged.currentPage, 2);
      expect(merged.hasMore, isFalse);
    });

    test('empty()', () {
      final e = Paginated.empty<String>();
      expect(e.items, isEmpty);
      expect(e.hasMore, isFalse);
    });
  });
}
