import 'package:iqs_flutter/core/api/api_models.dart';
import 'package:iqs_flutter/core/network/api_client.dart';

import 'fan_group.dart';

/// Fan-groups consumer reads (Phase 6A). Group-admin writes (Phase 6B).
class FanGroupsRepository {
  FanGroupsRepository(this._api);

  final ApiClient _api;

  Future<Paginated<FanGroup>> fanGroups({
    int? club,
    String? governorate,
    String? q,
    int page = 1,
  }) {
    final query = <String, dynamic>{'page': page, 'per_page': 20};
    if (club != null) query['club'] = club;
    if (governorate != null) query['governorate'] = governorate;
    if (q != null && q.isNotEmpty) query['q'] = q;
    return _api.getPaged('/fan-groups', query: query, parseItem: FanGroup.fromJson);
  }

  Future<FanGroupDetail> fanGroupDetail(int id) => _api.get(
        '/fan-groups/$id',
        parse: (d) => FanGroupDetail.fromJson((d as Map).cast<String, dynamic>()),
      );

  /// `type` ∈ image | video.
  Future<Paginated<FanGroupMedia>> fanGroupMedia(int id,
      {String? type, int page = 1}) {
    final query = <String, dynamic>{'page': page, 'per_page': 30};
    if (type != null) query['type'] = type;
    return _api.getPaged(
      '/fan-groups/$id/media',
      query: query,
      parseItem: FanGroupMedia.fromJson,
    );
  }

  Future<List<FanGroupChant>> fanGroupChants(int id) => _api.get(
        '/fan-groups/$id/chants',
        parse: (d) => (d as List)
            .map((e) =>
                FanGroupChant.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );

  /// `method` ∈ message|voice|video. 403 when the feature flag is off.
  Future<void> verifyRequest(int id, {required String method, String? note}) {
    final body = <String, dynamic>{'method': method};
    if (note != null && note.isNotEmpty) body['note'] = note;
    return _api.post('/fan-groups/$id/verify-request', data: body, parse: (_) {});
  }

  // ---- group-admin (Phase 6B) — gated on my-fan-group 200 (else 403) ----
  //
  // NOTE: the mobile API exposes NO file-upload endpoint for fan groups —
  // storeMedia/storeChant/storeDocument require a pre-uploaded storage `path`
  // string (only `listings/{id}/media` accepts raw files). So mobile supports
  // edit-profile + list/delete of media/chants/documents; *creating* them is
  // deferred to the web admin until an upload endpoint exists.

  Future<FanGroupDetail> myFanGroup() => _api.get(
        '/my-fan-group',
        parse: (d) => FanGroupDetail.fromJson((d as Map).cast<String, dynamic>()),
      );

  /// Partial update (raw `_ar/_en` + location/contact/social). Image `*_path`
  /// fields are omitted (no mobile upload) and stay untouched (`sometimes`).
  Future<FanGroupDetail> updateMyFanGroup(Map<String, dynamic> body) => _api.put(
        '/my-fan-group',
        data: body,
        parse: (d) => FanGroupDetail.fromJson((d as Map).cast<String, dynamic>()),
      );

  Future<void> deleteMedia(int mediaId) =>
      _api.delete('/my-fan-group/media/$mediaId', parse: (_) {});

  Future<void> deleteChant(int chantId) =>
      _api.delete('/my-fan-group/chants/$chantId', parse: (_) {});

  Future<void> deleteDocument(int documentId) =>
      _api.delete('/my-fan-group/documents/$documentId', parse: (_) {});
}
