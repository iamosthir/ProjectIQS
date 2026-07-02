import 'package:iqs_flutter/core/network/api_client.dart';

import 'app_banner.dart';
import 'search_result.dart';

/// Banners + global search.
class DiscoveryRepository {
  DiscoveryRepository(this._api);

  final ApiClient _api;

  /// All banners (no `placement` param — group client-side; a CSV placement
  /// returns an empty list because the backend does single-value equality).
  Future<List<AppBanner>> banners() => _api.get(
        '/banners',
        parse: (d) => (d as List)
            .map((e) => AppBanner.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );

  /// `GET /search?q&type` — unwraps `data.results`. `type` is optional.
  Future<List<SearchResult>> search(String q, {String? type}) {
    final query = <String, dynamic>{'q': q};
    if (type != null) query['type'] = type;
    return _api.get(
      '/search',
      query: query,
      parse: (d) {
        final results = (d is Map ? d['results'] : null) as List? ?? const [];
        return results
            .map((e) =>
                SearchResult.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
      },
    );
  }
}
