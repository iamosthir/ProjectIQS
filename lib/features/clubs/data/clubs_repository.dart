import 'package:iqs_flutter/core/api/api_models.dart';
import 'package:iqs_flutter/core/network/api_client.dart';

import 'club.dart';
import 'club_detail.dart';

/// Clubs directory + per-club news. (Phase 5 expands this with club detail,
/// org-chart sub-sections, verify-request and club-admin CRUD.)
class ClubsRepository {
  ClubsRepository(this._api);

  final ApiClient _api;

  Future<Paginated<Club>> clubs({
    String? q,
    String? governorate,
    int page = 1,
  }) {
    final query = <String, dynamic>{'page': page, 'per_page': 20};
    if (q != null && q.isNotEmpty) query['q'] = q;
    if (governorate != null) query['governorate'] = governorate;
    return _api.getPaged('/clubs', query: query, parseItem: Club.fromJson);
  }

  Future<Paginated<ClubNews>> clubNews(
    int clubId, {
    String? clubName,
    int page = 1,
  }) =>
      _api.getPaged(
        '/clubs/$clubId/news',
        query: {'page': page, 'per_page': 20},
        parseItem: (j) =>
            ClubNews.fromJson(j, clubId: clubId, clubName: clubName),
      );

  Future<ClubDetail> clubDetail(int id) => _api.get(
        '/clubs/$id',
        parse: (d) => ClubDetail.fromJson((d as Map).cast<String, dynamic>()),
      );

  /// Full article (increments views server-side; carries `content`).
  Future<ClubNews> clubNewsArticle(int clubId, int newsId) => _api.get(
        '/clubs/$clubId/news/$newsId',
        parse: (d) =>
            ClubNews.fromJson((d as Map).cast<String, dynamic>(), clubId: clubId),
      );

  /// `method` ∈ message|voice|video. Returns 403 when the feature flag is off.
  Future<void> verifyRequest(int clubId,
      {required String method, String? note}) {
    final body = <String, dynamic>{'method': method};
    if (note != null && note.isNotEmpty) body['note'] = note;
    return _api.post('/clubs/$clubId/verify-request', data: body, parse: (_) {});
  }

  // ---- club-admin (Phase 5B) — gated on my-club 200 (else 403) ----

  Future<ClubDetail> myClub() => _api.get(
        '/my-club',
        parse: (d) => ClubDetail.fromJson((d as Map).cast<String, dynamic>()),
      );

  /// Partial update (raw `_ar/_en` + location/contact/social).
  Future<ClubDetail> updateMyClub(Map<String, dynamic> body) => _api.put(
        '/my-club',
        data: body,
        parse: (d) => ClubDetail.fromJson((d as Map).cast<String, dynamic>()),
      );

  // News + child writes return raw model JSON (snake_case, both langs) — we
  // ignore the body and refetch my-club instead, so these parse to void.
  Future<void> createClubNews(Map<String, dynamic> body) =>
      _api.post('/my-club/news', data: body, parse: (_) {});

  Future<void> updateClubNews(int id, Map<String, dynamic> body) =>
      _api.put('/my-club/news/$id', data: body, parse: (_) {});

  Future<void> deleteClubNews(int id) =>
      _api.delete('/my-club/news/$id', parse: (_) {});

  /// `type` ∈ board|staff|titles|captains|competitions.
  Future<void> createChild(String type, Map<String, dynamic> body) =>
      _api.post('/my-club/$type', data: body, parse: (_) {});

  Future<void> updateChild(String type, int id, Map<String, dynamic> body) =>
      _api.put('/my-club/$type/$id', data: body, parse: (_) {});

  Future<void> deleteChild(String type, int id) =>
      _api.delete('/my-club/$type/$id', parse: (_) {});
}
