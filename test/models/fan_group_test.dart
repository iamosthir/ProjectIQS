import 'package:flutter_test/flutter_test.dart';

import 'package:iqs_flutter/features/fan_groups/data/fan_group.dart';

void main() {
  group('FanGroupDetail.fromJson', () {
    test('maps counts, contact and documents', () {
      final fg = FanGroupDetail.fromJson({
        'id': 5,
        'name': 'الترسانة',
        'group_logo': 'fan-groups/5/logo.png',
        'is_official': true,
        'description': 'وصف',
        'counts': {'photos': 12, 'videos': 3, 'chants': 7},
        'contact': {'phone': '07700000001', 'facebook': 'fb/x'},
        'documents': [
          {'id': 1, 'title': 'Doc', 'url': 'fan-groups/5/d.pdf', 'mime_type': 'application/pdf'},
        ],
      });
      expect(fg.id, 5);
      expect(fg.name, 'الترسانة');
      expect(fg.group.isOfficial, isTrue);
      expect(fg.photosCount, 12);
      expect(fg.videosCount, 3);
      expect(fg.chantsCount, 7);
      expect(fg.contact.hasAny, isTrue);
      expect(fg.documents.single.title, 'Doc');
    });

    test('defaults counts/documents when absent', () {
      final fg = FanGroupDetail.fromJson({'id': 6, 'name': 'X'});
      expect(fg.photosCount, 0);
      expect(fg.videosCount, 0);
      expect(fg.chantsCount, 0);
      expect(fg.documents, isEmpty);
      expect(fg.contact.hasAny, isFalse);
    });
  });

  test('FanGroupMedia.isVideo', () {
    final v = FanGroupMedia.fromJson({'id': 1, 'type': 'video', 'url': 'x'});
    final i = FanGroupMedia.fromJson({'id': 2, 'type': 'image', 'url': 'y'});
    expect(v.isVideo, isTrue);
    expect(i.isVideo, isFalse);
  });

  test('FanGroup.fromJson reads group_logo / official / verified flags', () {
    final g = FanGroup.fromJson({
      'id': 9,
      'name': 'G',
      'group_logo': 'p.png',
      'is_official': false,
      'is_verified': true,
      'governorate': 'Baghdad',
    });
    expect(g.groupLogo, 'p.png');
    expect(g.isOfficial, isFalse);
    expect(g.isVerified, isTrue);
  });
}
