import '../config/env.dart';

/// Converts a **relative storage path** from the API (e.g. `listings/12/x.jpg`)
/// into an absolute URL (`$storageBase/storage/listings/12/x.jpg`).
///
/// Returns null for null/empty input. Pass-through for values that are already
/// absolute URLs. Use everywhere an image/logo/media/photo/cv field is rendered.
String? assetUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final clean = path.startsWith('/') ? path.substring(1) : path;
  return '${Env.storageBase}/storage/$clean';
}
