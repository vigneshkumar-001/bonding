import 'package:cached_network_image/cached_network_image.dart';
import 'package:bonding_app/ui/app_loader.dart';
import 'package:flutter/material.dart';

class ImagePreviewScreen extends StatelessWidget {
  final String heroTag;
  final String imageUrl;
  final String? title;

  const ImagePreviewScreen({
    super.key,
    required this.heroTag,
    required this.imageUrl,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: null,
      ),
      body: SafeArea(
        child: Hero(
          tag: heroTag,
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => const AppLoader.center(
                  radius: 14,
                  color: Colors.white70,
                ),
                errorWidget: (_, __, ___) => Icon(
                  Icons.broken_image_outlined,
                  color: cs.onSurfaceVariant,
                  size: 42,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
