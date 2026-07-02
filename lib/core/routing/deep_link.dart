import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// The shared `action_type` + `action_value` contract used by **both** banners
/// (Phase 3) and notifications (Phase 8). Built once here.
@immutable
class DeepLink {
  const DeepLink({required this.actionType, this.actionValue});

  final String actionType;
  final String? actionValue;

  factory DeepLink.fromJson(Map<String, dynamic> json) => DeepLink(
        actionType: (json['action_type'] ?? 'none').toString(),
        actionValue: json['action_value']?.toString(),
      );

  bool get isActionable => actionType != 'none' && actionType.isNotEmpty;
}

/// Routes a [DeepLink] target. `url` opens externally; entity types push their
/// detail route (`fixture`/`listing`/`club`/`fan_group` are all live as of
/// Phase 6). Any still-unmatched push falls through to the router's styled
/// `errorBuilder` (`RouteErrorScreen`), not a raw error page.
Future<void> handleDeepLink(BuildContext context, DeepLink link) async {
  final value = link.actionValue;
  switch (link.actionType) {
    case 'url':
      if (value != null && value.isNotEmpty) {
        final uri = Uri.tryParse(value);
        // Uri.tryParse is lenient (schemeless/free text parses non-null), so
        // require a scheme and a handler, and swallow launch failures.
        if (uri != null && uri.hasScheme) {
          try {
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } catch (_) {/* unlaunchable URL — ignore */}
        }
      }
      break;
    case 'fixture':
      if (value != null) context.push('/fixtures/$value');
      break;
    case 'listing':
      if (value != null) context.push('/listings/$value');
      break;
    case 'club':
      if (value != null) context.push('/clubs/$value');
      break;
    case 'fan_group':
      if (value != null) context.push('/fan-groups/$value');
      break;
    case 'none':
    default:
      break;
  }
}
