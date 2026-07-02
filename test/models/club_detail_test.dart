import 'package:flutter_test/flutter_test.dart';

import 'package:iqs_flutter/features/clubs/data/club_detail.dart';

void main() {
  group('ClubDetail.fromJson', () {
    test('parses decimal lat/lng whether STRING (Laravel decimal cast) or num',
        () {
      // Regression: Laravel `decimal:N` serializes to a JSON string; a strict
      // `as num` cast crashed the whole club screen (Phase 5A HIGH).
      final asString = ClubDetail.fromJson({
        'id': 1,
        'name': 'الزوراء',
        'location': {
          'address': 'بغداد',
          'latitude': '33.3152000',
          'longitude': '44.3661000',
        },
      });
      expect(asString.latitude, closeTo(33.3152, 0.0001));
      expect(asString.longitude, closeTo(44.3661, 0.0001));
      expect(asString.address, 'بغداد');

      final asNum = ClubDetail.fromJson({
        'id': 1,
        'name': 'X',
        'location': {'latitude': 33.3, 'longitude': 44.3},
      });
      expect(asNum.latitude, 33.3);
    });

    test('tolerates a missing location block', () {
      final c = ClubDetail.fromJson({'id': 2, 'name': 'Y'});
      expect(c.latitude, isNull);
      expect(c.longitude, isNull);
      expect(c.address, isNull);
    });

    test('parses org-chart sub-lists and hides team-tabs when team_id null', () {
      final c = ClubDetail.fromJson({
        'id': 3,
        'name': 'Z',
        'team_id': null,
        'is_verified': true,
        'board': [
          {'id': 1, 'name': 'Chair', 'position': 'President'},
        ],
        'titles': [
          {'id': 1, 'title': 'Cup', 'count': 3},
        ],
        'contact': {'phone': '07700000001'},
      });
      expect(c.teamId, isNull);
      expect(c.isVerified, isTrue);
      expect(c.board.single.name, 'Chair');
      expect(c.titles.single.count, 3);
      expect(c.contact.hasAny, isTrue);
    });

    test('empty/absent sub-lists default to const []', () {
      final c = ClubDetail.fromJson({'id': 4, 'name': 'W'});
      expect(c.board, isEmpty);
      expect(c.staff, isEmpty);
      expect(c.titles, isEmpty);
      expect(c.captains, isEmpty);
      expect(c.competitions, isEmpty);
      expect(c.contact.hasAny, isFalse);
    });
  });
}
