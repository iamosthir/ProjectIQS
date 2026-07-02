import 'package:dio/dio.dart';

import 'package:iqs_flutter/core/api/api_models.dart';
import 'package:iqs_flutter/core/network/api_client.dart';

import 'listing.dart';
import 'marketplace_category.dart';
import 'store.dart';

/// Marketplace consumer reads (Phase 4A). Seller writes (stores, my-listings,
/// listing CRUD, media) are added in Phase 4B.
class MarketplaceRepository {
  MarketplaceRepository(this._api);

  final ApiClient _api;

  Future<List<MarketplaceCategory>> categories() => _api.get(
        '/marketplace/categories',
        parse: (d) => (d as List)
            .map((e) => MarketplaceCategory.fromJson(
                (e as Map).cast<String, dynamic>()))
            .toList(),
      );

  Future<Paginated<Listing>> listings({
    int? category,
    String? governorate,
    bool? featured,
    String? q,
    int page = 1,
  }) {
    final query = <String, dynamic>{'page': page, 'per_page': 20};
    if (category != null) query['category'] = category;
    if (governorate != null) query['governorate'] = governorate;
    if (featured == true) query['featured'] = 1;
    if (q != null && q.isNotEmpty) query['q'] = q;
    return _api.getPaged(
      '/marketplace/listings',
      query: query,
      parseItem: Listing.fromJson,
    );
  }

  Future<Listing> listing(int id) => _api.get(
        '/marketplace/listings/$id',
        parse: (d) => Listing.fromJson((d as Map).cast<String, dynamic>()),
      );

  /// Reveals contact channels (`available:false` → proceed via the platform).
  Future<ListingContact> contact(int id) => _api.post(
        '/marketplace/listings/$id/contact',
        parse: (d) => ListingContact.fromJson((d as Map).cast<String, dynamic>()),
      );

  // ---- seller (Phase 4B) ----

  /// `data:null` when the user has no store yet.
  Future<Store?> myStore() => _api.get<Store?>(
        '/marketplace/my-store',
        parse: (d) =>
            d == null ? null : Store.fromJson((d as Map).cast<String, dynamic>()),
      );

  /// First create auto-assigns the `seller` role; a 2nd create returns 422.
  /// Body uses raw `_ar/_en` columns (`name_ar` required).
  Future<Store> createStore(Map<String, dynamic> body) => _api.post(
        '/marketplace/stores',
        data: body,
        parse: (d) => Store.fromJson((d as Map).cast<String, dynamic>()),
      );

  Future<Store> updateStore(int id, Map<String, dynamic> body) => _api.put(
        '/marketplace/stores/$id',
        data: body,
        parse: (d) => Store.fromJson((d as Map).cast<String, dynamic>()),
      );

  /// All of the seller's listings across every status (paginated).
  Future<Paginated<Listing>> myListings({int page = 1}) => _api.getPaged(
        '/marketplace/my-listings',
        query: {'page': page, 'per_page': 20},
        parseItem: Listing.fromJson,
      );

  /// Body: `category_id`, `title_ar`(req), `title_en?`, `full_name?`, `age?`,
  /// `nationality?`, `governorate?`, `city?`, `attributes?` (map keyed by field
  /// key). Free category → `pending_review`; paid → `pending_payment` (Phase 7).
  Future<Listing> createListing(Map<String, dynamic> body) => _api.post(
        '/marketplace/listings',
        data: body,
        parse: (d) => Listing.fromJson((d as Map).cast<String, dynamic>()),
      );

  /// Editing a published/rejected/expired listing re-enters `pending_review`.
  Future<Listing> updateListing(int id, Map<String, dynamic> body) => _api.put(
        '/marketplace/listings/$id',
        data: body,
        parse: (d) => Listing.fromJson((d as Map).cast<String, dynamic>()),
      );

  Future<void> deleteListing(int id) =>
      _api.delete('/marketplace/listings/$id', parse: (_) {});

  /// Multipart upload (`file` + `type`). Per-type limits come from the
  /// category's `field_schema.media` (422 when full). The backend has NO media
  /// delete endpoint — uploads only.
  Future<ListingMedia> uploadMedia(
    int listingId, {
    required String filePath,
    required String type,
  }) async {
    final form = FormData.fromMap({
      'type': type,
      'file': await MultipartFile.fromFile(filePath),
    });
    return _api.postMultipart(
      '/marketplace/listings/$listingId/media',
      data: form,
      parse: (d) => ListingMedia.fromJson((d as Map).cast<String, dynamic>()),
    );
  }
}
