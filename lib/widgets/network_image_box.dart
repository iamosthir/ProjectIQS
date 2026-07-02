import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Network image with graceful loading + error placeholders, backed by
/// `cached_network_image` so images are cached on disk app-wide.
///
/// API and placeholders are unchanged from the original (loading spinner /
/// broken-image icon over a soft grey box). Pass absolute URLs — for API
/// storage paths, run them through `assetUrl(...)` first.
class NetworkImageBox extends StatelessWidget {
  const NetworkImageBox({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    Widget image = url.isEmpty
        ? _placeholder(loading: false)
        : CachedNetworkImage(
            imageUrl: url,
            width: width,
            height: height,
            fit: fit,
            placeholder: (context, _) => _placeholder(loading: true),
            errorWidget: (context, _, _) => _placeholder(loading: false),
          );
    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _placeholder({required bool loading}) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFDFE7E0),
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textMuted,
              ),
            )
          : Icon(
              Icons.image_outlined,
              color: AppColors.textMuted.withValues(alpha: 0.6),
              size: 28,
            ),
    );
  }
}
