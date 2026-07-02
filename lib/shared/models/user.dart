import 'package:flutter/foundation.dart';

import 'package:iqs_flutter/core/util/date_fmt.dart';

/// Authenticated user. Maps the `verify-otp`/`me` user resource. The server
/// returns `governorate` as a localized **display string** (e.g. "Baghdad"),
/// not the code — writes (register/edit) send the governorate `code` separately.
@immutable
class User {
  const User({
    required this.id,
    required this.phone,
    this.name,
    this.email,
    this.avatar,
    this.governorate,
    this.gender,
    this.dateOfBirth,
    this.locale,
    this.supportedClubId,
    this.supportedTeamId,
    this.phoneVerified = false,
    this.isRegistrationCompleted = false,
    this.roles = const [],
    this.createdAt,
  });

  final int id;
  final String phone;
  final String? name;
  final String? email;
  final String? avatar;
  final String? governorate;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? locale;
  final int? supportedClubId;
  final int? supportedTeamId;
  final bool phoneVerified;
  final bool isRegistrationCompleted;
  final List<String> roles;
  final DateTime? createdAt;

  bool hasRole(String role) => roles.contains(role);

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: (j['id'] as num).toInt(),
        phone: j['phone']?.toString() ?? '',
        name: j['name'] as String?,
        email: j['email'] as String?,
        avatar: j['avatar'] as String?,
        governorate: j['governorate'] as String?,
        gender: j['gender'] as String?,
        dateOfBirth: DateFmt.tryParse(j['date_of_birth'] as String?),
        locale: j['locale'] as String?,
        supportedClubId: (j['supported_club_id'] as num?)?.toInt(),
        supportedTeamId: (j['supported_team_id'] as num?)?.toInt(),
        phoneVerified: j['phone_verified'] == true,
        isRegistrationCompleted: j['is_registration_completed'] == true,
        roles: (j['roles'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        createdAt: DateFmt.tryParse(j['created_at'] as String?),
      );

  User copyWith({
    String? name,
    String? email,
    String? avatar,
    String? governorate,
    String? gender,
    DateTime? dateOfBirth,
    String? locale,
    int? supportedClubId,
    int? supportedTeamId,
    bool? phoneVerified,
    bool? isRegistrationCompleted,
    List<String>? roles,
  }) =>
      User(
        id: id,
        phone: phone,
        name: name ?? this.name,
        email: email ?? this.email,
        avatar: avatar ?? this.avatar,
        governorate: governorate ?? this.governorate,
        gender: gender ?? this.gender,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        locale: locale ?? this.locale,
        supportedClubId: supportedClubId ?? this.supportedClubId,
        supportedTeamId: supportedTeamId ?? this.supportedTeamId,
        phoneVerified: phoneVerified ?? this.phoneVerified,
        isRegistrationCompleted:
            isRegistrationCompleted ?? this.isRegistrationCompleted,
        roles: roles ?? this.roles,
        createdAt: createdAt,
      );
}
