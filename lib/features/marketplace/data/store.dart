import 'package:flutter/foundation.dart';

import 'package:iqs_flutter/core/util/date_fmt.dart';

/// A seller's marketplace store (`GET /marketplace/my-store`). The read
/// resource is localized; writes send raw `_ar/_en` columns (`name_ar`, etc.).
@immutable
class Store {
  const Store({
    required this.id,
    required this.name,
    this.slug,
    this.logo,
    this.cover,
    this.bio,
    this.phone,
    this.whatsapp,
    this.email,
    this.governorate,
    this.city,
    this.isVerified = false,
    this.status = 'active',
    this.listingsCount = 0,
    this.createdAt,
  });

  final int id;
  final String name;
  final String? slug;
  final String? logo;
  final String? cover;
  final String? bio;
  final String? phone;
  final String? whatsapp;
  final String? email;
  final String? governorate;
  final String? city;
  final bool isVerified;
  final String status;
  final int listingsCount;
  final DateTime? createdAt;

  factory Store.fromJson(Map<String, dynamic> j) => Store(
        id: (j['id'] as num).toInt(),
        name: j['name']?.toString() ?? '',
        slug: j['slug'] as String?,
        logo: j['logo'] as String?,
        cover: j['cover'] as String?,
        bio: j['bio'] as String?,
        phone: j['phone'] as String?,
        whatsapp: j['whatsapp'] as String?,
        email: j['email'] as String?,
        governorate: j['governorate'] as String?,
        city: j['city'] as String?,
        isVerified: j['is_verified'] == true,
        status: j['status']?.toString() ?? 'active',
        listingsCount: (j['listings_count'] as num?)?.toInt() ?? 0,
        createdAt: DateFmt.tryParse(j['created_at'] as String?),
      );
}
