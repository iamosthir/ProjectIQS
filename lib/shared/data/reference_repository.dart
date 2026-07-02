import 'package:iqs_flutter/core/network/api_client.dart';
import 'package:iqs_flutter/shared/models/app_config.dart';
import 'package:iqs_flutter/shared/models/app_page.dart';
import 'package:iqs_flutter/shared/models/governorate.dart';

/// Public reference data: app config (version gate + settings), governorates,
/// and static legal/info pages. All three are reachable pre-auth.
class ReferenceRepository {
  ReferenceRepository(this._api);

  final ApiClient _api;

  Future<AppConfig> appConfig({
    required String platform,
    required String version,
  }) =>
      _api.get(
        '/app/config',
        query: {'platform': platform, 'version': version},
        parse: (d) => AppConfig.fromJson((d as Map).cast<String, dynamic>()),
      );

  Future<List<Governorate>> governorates() => _api.get(
        '/governorates',
        parse: (d) => (d as List)
            .map((e) => Governorate.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );

  Future<AppPage> page(String slug) => _api.get(
        '/pages/$slug',
        parse: (d) => AppPage.fromJson((d as Map).cast<String, dynamic>()),
      );
}
