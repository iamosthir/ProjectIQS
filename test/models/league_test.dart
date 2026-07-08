import 'package:flutter_test/flutter_test.dart';

import 'package:iqs_flutter/features/matches/data/league.dart';

/// League/Season mappers — the season-picker (league detail) and the league
/// filter chips (matches feed) both depend on this parse.
void main() {
  group('League.fromJson', () {
    test('parses the seasons list newest-first with is_current', () {
      final league = League.fromJson({
        'id': 5,
        'name': 'الدوري العراقي',
        'is_featured': true,
        'current_season': {'id': 22, 'year': 2025, 'label': '2025-2026'},
        'seasons': [
          {'id': 22, 'year': 2025, 'label': '2025-2026', 'is_current': true},
          {'id': 21, 'year': 2024, 'label': '2024-2025', 'is_current': false},
        ],
      });

      expect(league.isFeatured, isTrue);
      expect(league.seasons, hasLength(2));
      expect(league.seasons.first.year, 2025);
      expect(league.seasons.first.isCurrent, isTrue);
      expect(league.seasons.last.isCurrent, isFalse);
      expect(league.currentSeason?.id, 22);
    });

    test('missing seasons key yields an empty list (list rows)', () {
      final league = League.fromJson({'id': 5, 'name': 'x'});
      expect(league.seasons, isEmpty);
      expect(league.currentSeason, isNull);
    });

    test('Season.displayLabel falls back from label to year', () {
      expect(
        Season.fromJson({'id': 1, 'year': 2025, 'label': '2025-2026'})
            .displayLabel,
        '2025-2026',
      );
      expect(Season.fromJson({'id': 1, 'year': 2025}).displayLabel, '2025');
      expect(Season.fromJson({'id': 1}).displayLabel, '');
    });
  });
}
