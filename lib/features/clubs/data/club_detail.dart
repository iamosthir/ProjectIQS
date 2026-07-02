import 'package:flutter/foundation.dart';

/// Club contact / social links (`contact` block of the detail).
@immutable
class ClubContact {
  const ClubContact({
    this.phone,
    this.email,
    this.website,
    this.facebook,
    this.instagram,
    this.twitter,
  });

  final String? phone;
  final String? email;
  final String? website;
  final String? facebook;
  final String? instagram;
  final String? twitter;

  bool get hasAny =>
      [phone, email, website, facebook, instagram, twitter]
          .any((v) => v != null && v.isNotEmpty);

  factory ClubContact.fromJson(Map<String, dynamic> j) => ClubContact(
        phone: j['phone'] as String?,
        email: j['email'] as String?,
        website: j['website'] as String?,
        facebook: j['facebook'] as String?,
        instagram: j['instagram'] as String?,
        twitter: j['twitter'] as String?,
      );
}

/// Board member (org-chart node; `parentId` links the hierarchy).
@immutable
class BoardMember {
  const BoardMember({
    required this.id,
    this.parentId,
    required this.name,
    this.position,
    this.photo,
    this.displayOrder = 0,
  });
  final int id;
  final int? parentId;
  final String name;
  final String? position;
  final String? photo;
  final int displayOrder;

  factory BoardMember.fromJson(Map<String, dynamic> j) => BoardMember(
        id: (j['id'] as num).toInt(),
        parentId: (j['parent_id'] as num?)?.toInt(),
        name: j['name']?.toString() ?? '',
        position: j['position'] as String?,
        photo: j['photo'] as String?,
        displayOrder: (j['display_order'] as num?)?.toInt() ?? 0,
      );
}

@immutable
class StaffMember {
  const StaffMember({
    required this.id,
    required this.name,
    this.role,
    this.type,
    this.photo,
    this.bio,
  });
  final int id;
  final String name;
  final String? role;
  final String? type;
  final String? photo;
  final String? bio;

  factory StaffMember.fromJson(Map<String, dynamic> j) => StaffMember(
        id: (j['id'] as num).toInt(),
        name: j['name']?.toString() ?? '',
        role: j['role'] as String?,
        type: j['type'] as String?,
        photo: j['photo'] as String?,
        bio: j['bio'] as String?,
      );
}

@immutable
class ClubTitle {
  const ClubTitle({
    required this.id,
    required this.title,
    this.competition,
    this.season,
    this.year,
    this.count = 1,
    this.image,
  });
  final int id;
  final String title;
  final String? competition;
  final String? season;
  final int? year;
  final int count;
  final String? image;

  factory ClubTitle.fromJson(Map<String, dynamic> j) => ClubTitle(
        id: (j['id'] as num).toInt(),
        title: j['title']?.toString() ?? '',
        competition: j['competition'] as String?,
        season: j['season']?.toString(),
        year: (j['year'] as num?)?.toInt(),
        count: (j['count'] as num?)?.toInt() ?? 1,
        image: j['image'] as String?,
      );
}

@immutable
class Captain {
  const Captain({
    required this.id,
    required this.name,
    this.photo,
    this.periodFrom,
    this.periodTo,
    this.description,
  });
  final int id;
  final String name;
  final String? photo;
  final String? periodFrom;
  final String? periodTo;
  final String? description;

  factory Captain.fromJson(Map<String, dynamic> j) => Captain(
        id: (j['id'] as num).toInt(),
        name: j['name']?.toString() ?? '',
        photo: j['photo'] as String?,
        periodFrom: j['period_from']?.toString(),
        periodTo: j['period_to']?.toString(),
        description: j['description'] as String?,
      );
}

@immutable
class ClubCompetition {
  const ClubCompetition({
    required this.id,
    required this.name,
    this.season,
    this.status,
    this.leagueId,
  });
  final int id;
  final String name;
  final String? season;
  final String? status;
  final int? leagueId;

  factory ClubCompetition.fromJson(Map<String, dynamic> j) => ClubCompetition(
        id: (j['id'] as num).toInt(),
        name: j['name']?.toString() ?? '',
        season: j['season']?.toString(),
        status: j['status'] as String?,
        leagueId: (j['league_id'] as num?)?.toInt(),
      );
}

/// `GET /clubs/:id` — profile + org-chart sub-sections. The Matches/Players/
/// Statistics tabs require [teamId] (null → hide them).
@immutable
class ClubDetail {
  const ClubDetail({
    required this.id,
    required this.name,
    this.slug,
    this.logo,
    this.cover,
    this.governorate,
    this.city,
    this.foundedYear,
    this.isVerified = false,
    this.teamId,
    this.description,
    this.address,
    this.latitude,
    this.longitude,
    this.contact = const ClubContact(),
    this.board = const [],
    this.staff = const [],
    this.titles = const [],
    this.captains = const [],
    this.competitions = const [],
  });

  final int id;
  final String name;
  final String? slug;
  final String? logo;
  final String? cover;
  final String? governorate;
  final String? city;
  final int? foundedYear;
  final bool isVerified;
  final int? teamId;
  final String? description;
  final String? address;
  final double? latitude;
  final double? longitude;
  final ClubContact contact;
  final List<BoardMember> board;
  final List<StaffMember> staff;
  final List<ClubTitle> titles;
  final List<Captain> captains;
  final List<ClubCompetition> competitions;

  static List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) =>
      (raw is List)
          ? raw
              .map((e) => fromJson((e as Map).cast<String, dynamic>()))
              .toList()
          : const [];

  // Laravel's `decimal:N` cast serializes to a JSON *string*, so tolerate both.
  static double? _toDouble(dynamic v) => v == null
      ? null
      : (v is num ? v.toDouble() : double.tryParse(v.toString()));

  factory ClubDetail.fromJson(Map<String, dynamic> j) {
    final loc = (j['location'] as Map?)?.cast<String, dynamic>() ?? const {};
    return ClubDetail(
      id: (j['id'] as num).toInt(),
      name: j['name']?.toString() ?? '',
      slug: j['slug'] as String?,
      logo: j['logo'] as String?,
      cover: j['cover'] as String?,
      governorate: j['governorate'] as String?,
      city: j['city'] as String?,
      foundedYear: (j['founded_year'] as num?)?.toInt(),
      isVerified: j['is_verified'] == true,
      teamId: (j['team_id'] as num?)?.toInt(),
      description: j['description'] as String?,
      address: loc['address'] as String?,
      latitude: _toDouble(loc['latitude']),
      longitude: _toDouble(loc['longitude']),
      contact: j['contact'] is Map
          ? ClubContact.fromJson((j['contact'] as Map).cast<String, dynamic>())
          : const ClubContact(),
      board: _list(j['board'], BoardMember.fromJson),
      staff: _list(j['staff'], StaffMember.fromJson),
      titles: _list(j['titles'], ClubTitle.fromJson),
      captains: _list(j['captains'], Captain.fromJson),
      competitions: _list(j['competitions'], ClubCompetition.fromJson),
    );
  }
}
