import 'package:flutter/foundation.dart';

import 'package:iqs_flutter/core/util/date_fmt.dart';
import 'package:iqs_flutter/shared/l10n/app_localizations.dart';

/// Listing status (`status` field). Free listings enter `pending_review`; paid
/// ones enter `pending_payment` (→ Phase 7).
enum ListingStatus {
  draft,
  pendingPayment,
  pendingReview,
  published,
  rejected,
  expired,
  suspended,
  unknown,
}

ListingStatus listingStatusFrom(String? s) {
  switch (s) {
    case 'draft':
      return ListingStatus.draft;
    case 'pending_payment':
      return ListingStatus.pendingPayment;
    case 'pending_review':
      return ListingStatus.pendingReview;
    case 'published':
      return ListingStatus.published;
    case 'rejected':
      return ListingStatus.rejected;
    case 'expired':
      return ListingStatus.expired;
    case 'suspended':
      return ListingStatus.suspended;
    default:
      return ListingStatus.unknown;
  }
}

String listingStatusLabel(ListingStatus s, AppLocalizations l) {
  switch (s) {
    case ListingStatus.draft:
      return l.sellerStatusDraft;
    case ListingStatus.pendingPayment:
      return l.sellerStatusPendingPayment;
    case ListingStatus.pendingReview:
      return l.sellerStatusPendingReview;
    case ListingStatus.published:
      return l.sellerStatusPublished;
    case ListingStatus.rejected:
      return l.sellerStatusRejected;
    case ListingStatus.expired:
      return l.sellerStatusExpired;
    case ListingStatus.suspended:
      return l.sellerStatusSuspended;
    case ListingStatus.unknown:
      return '';
  }
}

@immutable
class CategoryRef {
  const CategoryRef({required this.id, required this.name});
  final int id;
  final String name;
  factory CategoryRef.fromJson(Map<String, dynamic> j) => CategoryRef(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: j['name']?.toString() ?? '',
      );
}

@immutable
class StoreRef {
  const StoreRef({
    required this.id,
    required this.name,
    this.slug,
    this.isVerified = false,
  });
  final int id;
  final String name;
  final String? slug;
  final bool isVerified;
  factory StoreRef.fromJson(Map<String, dynamic> j) => StoreRef(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: j['name']?.toString() ?? '',
        slug: j['slug'] as String?,
        isVerified: j['is_verified'] == true,
      );
}

@immutable
class ListingMedia {
  const ListingMedia({
    required this.id,
    required this.type,
    this.url,
    this.thumbnail,
    this.title,
    this.displayOrder = 0,
  });
  final int id;
  final String type; // image | video | document
  final String? url;
  final String? thumbnail;
  final String? title;
  final int displayOrder;
  factory ListingMedia.fromJson(Map<String, dynamic> j) => ListingMedia(
        id: (j['id'] as num?)?.toInt() ?? 0,
        type: j['type']?.toString() ?? 'image',
        url: (j['url'] ?? j['path']) as String?,
        thumbnail: j['thumbnail'] as String?,
        title: j['title'] as String?,
        displayOrder: (j['display_order'] as num?)?.toInt() ?? 0,
      );
}

@immutable
class ListingAttribute {
  const ListingAttribute({required this.label, required this.value});
  final String label;
  final String value;
}

/// Result of `POST /marketplace/listings/:id/contact`. `available:false` means
/// "proceed through the platform" (channels withheld).
@immutable
class ListingContact {
  const ListingContact({
    this.available = false,
    this.phone,
    this.whatsapp,
    this.email,
  });
  final bool available;
  final String? phone;
  final String? whatsapp;
  final String? email;

  bool get hasChannel =>
      (phone?.isNotEmpty ?? false) ||
      (whatsapp?.isNotEmpty ?? false) ||
      (email?.isNotEmpty ?? false);

  factory ListingContact.fromJson(Map<String, dynamic> j) => ListingContact(
        available: j['available'] == true,
        phone: j['phone'] as String?,
        whatsapp: j['whatsapp'] as String?,
        email: j['email'] as String?,
      );
}

/// A marketplace listing (a player/coach-style ad).
@immutable
class Listing {
  const Listing({
    required this.id,
    required this.title,
    this.slug,
    this.status = ListingStatus.unknown,
    this.category,
    this.fullName,
    this.photo,
    this.age,
    this.country,
    this.nationality,
    this.governorate,
    this.city,
    this.attributes = const [],
    this.cv,
    this.isFeatured = false,
    this.viewsCount = 0,
    this.contactsCount = 0,
    this.contactAvailable,
    this.media = const [],
    this.store,
    this.publishedAt,
    this.expiresAt,
    this.createdAt,
    this.rejectionReason,
  });

  final int id;
  final String title;
  final String? slug;
  final ListingStatus status;
  final CategoryRef? category;
  final String? fullName;
  final String? photo;
  final int? age;
  final String? country;
  final String? nationality;
  final String? governorate;
  final String? city;
  final List<ListingAttribute> attributes;
  final String? cv;
  final bool isFeatured;
  final int viewsCount;
  final int contactsCount;
  final bool? contactAvailable;
  final List<ListingMedia> media;
  final StoreRef? store;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final String? rejectionReason;

  factory Listing.fromJson(Map<String, dynamic> j) => Listing(
        id: (j['id'] as num).toInt(),
        title: j['title']?.toString() ?? '',
        slug: j['slug'] as String?,
        status: listingStatusFrom(j['status']?.toString()),
        category: j['category'] is Map
            ? CategoryRef.fromJson((j['category'] as Map).cast<String, dynamic>())
            : null,
        fullName: j['full_name'] as String?,
        photo: j['photo'] as String?,
        age: (j['age'] as num?)?.toInt(),
        country: j['country'] as String?,
        nationality: j['nationality'] as String?,
        governorate: j['governorate'] as String?,
        city: j['city'] as String?,
        attributes: _parseAttributes(j['attributes']),
        cv: j['cv'] as String?,
        isFeatured: j['is_featured'] == true,
        viewsCount: (j['views_count'] as num?)?.toInt() ?? 0,
        contactsCount: (j['contacts_count'] as num?)?.toInt() ?? 0,
        contactAvailable: j['contact_available'] as bool?,
        media: ((j['media'] as List?) ?? const [])
            .map((e) =>
                ListingMedia.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        store: j['store'] is Map
            ? StoreRef.fromJson((j['store'] as Map).cast<String, dynamic>())
            : null,
        publishedAt: DateFmt.tryParse(j['published_at'] as String?),
        expiresAt: DateFmt.tryParse(j['expires_at'] as String?),
        createdAt: DateFmt.tryParse(j['created_at'] as String?),
        rejectionReason: j['rejection_reason'] as String?,
      );

  static List<ListingAttribute> _parseAttributes(dynamic raw) {
    final out = <ListingAttribute>[];
    // Canonical shape: an associative map keyed by the category field key
    // (e.g. {"position":"Forward"}). Labels live in the category field_schema.
    if (raw is Map) {
      raw.forEach((k, v) {
        final value = v?.toString();
        if (value != null && value.isNotEmpty) {
          out.add(ListingAttribute(label: k.toString(), value: value));
        }
      });
      return out;
    }
    // Fallback: a list of {label|key, value} objects.
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          final label = (item['label'] ?? item['key'])?.toString();
          final value = item['value']?.toString();
          if (label != null && value != null && value.isNotEmpty) {
            out.add(ListingAttribute(label: label, value: value));
          }
        }
      }
    }
    return out;
  }
}
