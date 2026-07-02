import 'package:flutter/foundation.dart';

import 'package:iqs_flutter/core/util/date_fmt.dart';

/// Minimal team reference (used in standings / top-scorers rows).
@immutable
class TeamRef {
  const TeamRef({required this.id, required this.name, this.logo});
  final int id;
  final String name;
  final String? logo;

  factory TeamRef.fromJson(Map<String, dynamic> j) => TeamRef(
        id: (j['id'] as num).toInt(),
        name: j['name']?.toString() ?? '',
        logo: j['logo'] as String?,
      );
}

/// `GET /teams/:id`.
@immutable
class Team {
  const Team({
    required this.id,
    required this.name,
    this.shortCode,
    this.logo,
    this.country,
    this.isNational = false,
    this.foundedYear,
    this.clubId,
    this.venueName,
    this.venueCity,
  });

  final int id;
  final String name;
  final String? shortCode;
  final String? logo;
  final String? country;
  final bool isNational;
  final int? foundedYear;
  final int? clubId;
  final String? venueName;
  final String? venueCity;

  factory Team.fromJson(Map<String, dynamic> j) {
    final venue = j['venue'];
    return Team(
      id: (j['id'] as num).toInt(),
      name: j['name']?.toString() ?? '',
      shortCode: j['short_code'] as String?,
      logo: j['logo'] as String?,
      country: j['country'] as String?,
      isNational: j['is_national'] == true,
      foundedYear: (j['founded_year'] as num?)?.toInt(),
      clubId: (j['club_id'] as num?)?.toInt(),
      venueName: venue is Map ? venue['name'] as String? : null,
      venueCity: venue is Map ? venue['city'] as String? : null,
    );
  }
}

/// `GET /players/:id` and squad rows (`number` present only in squad context).
@immutable
class Player {
  const Player({
    required this.id,
    required this.name,
    this.firstname,
    this.lastname,
    this.dateOfBirth,
    this.nationality,
    this.birthPlace,
    this.birthCountry,
    this.height,
    this.weight,
    this.photo,
    this.position,
    this.isInjured = false,
    this.number,
  });

  final int id;
  final String name;
  final String? firstname;
  final String? lastname;
  final DateTime? dateOfBirth;
  final String? nationality;
  final String? birthPlace;
  final String? birthCountry;
  final String? height;
  final String? weight;
  final String? photo;
  final String? position;
  final bool isInjured;
  final int? number;

  factory Player.fromJson(Map<String, dynamic> j) => Player(
        id: (j['id'] as num).toInt(),
        name: j['name']?.toString() ?? '',
        firstname: j['firstname'] as String?,
        lastname: j['lastname'] as String?,
        dateOfBirth: DateFmt.tryParse(j['date_of_birth'] as String?),
        nationality: j['nationality'] as String?,
        birthPlace: j['birth_place'] as String?,
        birthCountry: j['birth_country'] as String?,
        height: j['height']?.toString(),
        weight: j['weight']?.toString(),
        photo: j['photo'] as String?,
        position: j['position'] as String?,
        isInjured: j['is_injured'] == true,
        number: (j['number'] as num?)?.toInt(),
      );
}
