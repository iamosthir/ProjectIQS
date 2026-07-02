import 'package:flutter/foundation.dart';

import 'package:iqs_flutter/core/util/date_fmt.dart';

/// A fan group (`GET /fan-groups`). NOTE the read↔write asymmetry: reads use
/// `group_logo`/`url`/`video`; writes use `*_path` (`group_logo_path`, …).
@immutable
class FanGroup {
  const FanGroup({
    required this.id,
    required this.name,
    this.slug,
    this.clubId,
    this.groupLogo,
    this.clubLogo,
    this.cover,
    this.governorate,
    this.city,
    this.foundedYear,
    this.isOfficial = false,
    this.isVerified = false,
    this.createdAt,
  });

  final int id;
  final String name;
  final String? slug;
  final int? clubId;
  final String? groupLogo;
  final String? clubLogo;
  final String? cover;
  final String? governorate;
  final String? city;
  final int? foundedYear;
  final bool isOfficial;
  final bool isVerified;
  final DateTime? createdAt;

  factory FanGroup.fromJson(Map<String, dynamic> j) => FanGroup(
        id: (j['id'] as num).toInt(),
        name: j['name']?.toString() ?? '',
        slug: j['slug'] as String?,
        clubId: (j['club_id'] as num?)?.toInt(),
        groupLogo: j['group_logo'] as String?,
        clubLogo: j['club_logo'] as String?,
        cover: j['cover'] as String?,
        governorate: j['governorate'] as String?,
        city: j['city'] as String?,
        foundedYear: (j['founded_year'] as num?)?.toInt(),
        isOfficial: j['is_official'] == true,
        isVerified: j['is_verified'] == true,
        createdAt: DateFmt.tryParse(j['created_at'] as String?),
      );
}

/// `GET /fan-groups/:id/media` — `type` ∈ image | video.
@immutable
class FanGroupMedia {
  const FanGroupMedia({
    required this.id,
    required this.type,
    this.url,
    this.thumbnail,
    this.title,
    this.displayOrder = 0,
  });
  final int id;
  final String type; // image | video
  final String? url;
  final String? thumbnail;
  final String? title;
  final int displayOrder;

  bool get isVideo => type == 'video';

  factory FanGroupMedia.fromJson(Map<String, dynamic> j) => FanGroupMedia(
        id: (j['id'] as num).toInt(),
        type: j['type']?.toString() ?? 'image',
        url: j['url'] as String?,
        thumbnail: j['thumbnail'] as String?,
        title: j['title'] as String?,
        displayOrder: (j['display_order'] as num?)?.toInt() ?? 0,
      );
}

/// `GET /fan-groups/:id/chants` — video chant with lyrics.
@immutable
class FanGroupChant {
  const FanGroupChant({
    required this.id,
    required this.title,
    this.video,
    this.thumbnail,
    this.lyrics,
    this.displayOrder = 0,
  });
  final int id;
  final String title;
  final String? video;
  final String? thumbnail;
  final String? lyrics;
  final int displayOrder;

  factory FanGroupChant.fromJson(Map<String, dynamic> j) => FanGroupChant(
        id: (j['id'] as num).toInt(),
        title: j['title']?.toString() ?? '',
        video: j['video'] as String?,
        thumbnail: j['thumbnail'] as String?,
        lyrics: j['lyrics'] as String?,
        displayOrder: (j['display_order'] as num?)?.toInt() ?? 0,
      );
}

@immutable
class FanGroupDocument {
  const FanGroupDocument({
    required this.id,
    required this.title,
    this.url,
    this.mimeType,
  });
  final int id;
  final String title;
  final String? url;
  final String? mimeType;

  factory FanGroupDocument.fromJson(Map<String, dynamic> j) => FanGroupDocument(
        id: (j['id'] as num).toInt(),
        title: j['title']?.toString() ?? '',
        url: j['url'] as String?,
        mimeType: j['mime_type'] as String?,
      );
}

@immutable
class FanGroupContact {
  const FanGroupContact({this.phone, this.facebook, this.instagram, this.twitter});
  final String? phone;
  final String? facebook;
  final String? instagram;
  final String? twitter;

  bool get hasAny =>
      [phone, facebook, instagram, twitter].any((v) => v != null && v.isNotEmpty);

  factory FanGroupContact.fromJson(Map<String, dynamic> j) => FanGroupContact(
        phone: j['phone'] as String?,
        facebook: j['facebook'] as String?,
        instagram: j['instagram'] as String?,
        twitter: j['twitter'] as String?,
      );
}

/// `GET /fan-groups/:id` — profile + counts + contact + documents.
@immutable
class FanGroupDetail {
  const FanGroupDetail({
    required this.group,
    this.description,
    this.contact = const FanGroupContact(),
    this.photosCount = 0,
    this.videosCount = 0,
    this.chantsCount = 0,
    this.documents = const [],
  });

  final FanGroup group;
  final String? description;
  final FanGroupContact contact;
  final int photosCount;
  final int videosCount;
  final int chantsCount;
  final List<FanGroupDocument> documents;

  int get id => group.id;
  String get name => group.name;

  factory FanGroupDetail.fromJson(Map<String, dynamic> j) {
    final counts = (j['counts'] as Map?)?.cast<String, dynamic>() ?? const {};
    return FanGroupDetail(
      group: FanGroup.fromJson(j),
      description: j['description'] as String?,
      contact: j['contact'] is Map
          ? FanGroupContact.fromJson((j['contact'] as Map).cast<String, dynamic>())
          : const FanGroupContact(),
      photosCount: (counts['photos'] as num?)?.toInt() ?? 0,
      videosCount: (counts['videos'] as num?)?.toInt() ?? 0,
      chantsCount: (counts['chants'] as num?)?.toInt() ?? 0,
      documents: (j['documents'] is List)
          ? (j['documents'] as List)
              .map((e) =>
                  FanGroupDocument.fromJson((e as Map).cast<String, dynamic>()))
              .toList()
          : const [],
    );
  }
}
