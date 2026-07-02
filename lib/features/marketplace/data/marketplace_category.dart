import 'package:flutter/foundation.dart';

/// A dynamic attribute field declared by a category's `field_schema`. Drives the
/// create/edit listing form (Phase 4B).
@immutable
class CategoryField {
  const CategoryField({
    required this.key,
    required this.type,
    this.labelAr,
    this.labelEn,
    this.required = false,
  });

  final String key;
  final String type; // text | number | select | ...
  final String? labelAr;
  final String? labelEn;
  final bool required;

  String label(String locale) =>
      (locale == 'ar' ? labelAr : labelEn) ?? labelEn ?? labelAr ?? key;

  factory CategoryField.fromJson(Map<String, dynamic> j) => CategoryField(
        key: j['key']?.toString() ?? '',
        type: j['type']?.toString() ?? 'text',
        labelAr: j['label_ar'] as String?,
        labelEn: j['label_en'] as String?,
        required: j['required'] == true,
      );
}

/// A category's `field_schema`: dynamic [fields] + per-type media limits.
@immutable
class CategoryFieldSchema {
  const CategoryFieldSchema({
    this.fields = const [],
    this.imageLimit = 0,
    this.videoLimit = 0,
    this.documentLimit = 0,
  });

  final List<CategoryField> fields;
  final int imageLimit;
  final int videoLimit;
  final int documentLimit;

  factory CategoryFieldSchema.fromJson(Map<String, dynamic> j) {
    final media = (j['media'] as Map?)?.cast<String, dynamic>() ?? const {};
    return CategoryFieldSchema(
      fields: ((j['fields'] as List?) ?? const [])
          .map((e) => CategoryField.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      imageLimit: (media['image'] as num?)?.toInt() ?? 0,
      videoLimit: (media['video'] as num?)?.toInt() ?? 0,
      documentLimit: (media['document'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A marketplace category (`GET /marketplace/categories`, a tree). Leaf
/// categories carry pricing + [fieldSchema] for listings.
@immutable
class MarketplaceCategory {
  const MarketplaceCategory({
    required this.id,
    required this.key,
    this.parentId,
    required this.name,
    this.description,
    this.icon,
    this.basePrice = 0,
    this.currency = 'IQD',
    this.isFree = false,
    this.pricingNote,
    this.fieldSchema,
    this.requiresContactButton = false,
    this.listingDurationDays,
    this.children = const [],
  });

  final int id;
  final String key;
  final int? parentId;
  final String name;
  final String? description;
  final String? icon;
  final int basePrice;
  final String currency;
  final bool isFree;
  final String? pricingNote;
  final CategoryFieldSchema? fieldSchema;
  final bool requiresContactButton;
  final int? listingDurationDays;
  final List<MarketplaceCategory> children;

  bool get isLeaf => children.isEmpty;
  bool get isPaid => !isFree && basePrice > 0;

  factory MarketplaceCategory.fromJson(Map<String, dynamic> j) =>
      MarketplaceCategory(
        id: (j['id'] as num).toInt(),
        key: j['key']?.toString() ?? '',
        parentId: (j['parent_id'] as num?)?.toInt(),
        name: j['name']?.toString() ?? '',
        description: j['description'] as String?,
        icon: j['icon'] as String?,
        basePrice: (j['base_price'] as num?)?.toInt() ?? 0,
        currency: j['currency']?.toString() ?? 'IQD',
        isFree: j['is_free'] == true,
        pricingNote: j['pricing_note'] as String?,
        fieldSchema: j['field_schema'] is Map
            ? CategoryFieldSchema.fromJson(
                (j['field_schema'] as Map).cast<String, dynamic>())
            : null,
        requiresContactButton: j['requires_contact_button'] == true,
        listingDurationDays: (j['listing_duration_days'] as num?)?.toInt(),
        children: ((j['children'] as List?) ?? const [])
            .map((e) =>
                MarketplaceCategory.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

/// Flattens a category tree to its leaf categories (those listings live in).
List<MarketplaceCategory> flattenLeafCategories(
    List<MarketplaceCategory> tree) {
  final out = <MarketplaceCategory>[];
  void walk(MarketplaceCategory c) {
    if (c.isLeaf) {
      out.add(c);
    } else {
      for (final child in c.children) {
        walk(child);
      }
    }
  }

  for (final c in tree) {
    walk(c);
  }
  return out;
}
