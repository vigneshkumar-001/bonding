import 'dart:ui';

import 'package:bonding_app/ui/image_preview_screen.dart';
import 'package:bonding_app/ui/app_loader.dart';
import 'package:bonding_app/theme/brand_theme.dart';
import 'package:bonding_app/ui/seeded_gradient.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class StaffHeroCard extends StatelessWidget {
  final String seed;
  final String title;
  final bool online;
  final List<String> tags;
  final String? description;
  final Widget actions;
  final String? subtitle;
  final String? imageUrl;

  const StaffHeroCard({
    super.key,
    required this.seed,
    required this.title,
    required this.online,
    required this.tags,
    required this.actions,
    this.description,
    this.subtitle,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final brand = BrandTheme.of(context);
    final cs = Theme.of(context).colorScheme;
    final gradient = seededCardGradient(seed);
    final heroTag = 'staff_image_$seed';
    final canPreview = imageUrl != null && imageUrl!.trim().isNotEmpty;
    final placeholderInitials = initialsFromName(title);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroHeader(
                gradient: gradient,
                imageUrl: imageUrl,
                heroTag: heroTag,
                placeholderInitials: placeholderInitials,
                onTap: !canPreview
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ImagePreviewScreen(
                              heroTag: heroTag,
                              imageUrl: imageUrl!,
                              title: title,
                            ),
                          ),
                        );
                      },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.98),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (subtitle != null && subtitle!.trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    subtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _StatusPill(
                          online: online,
                          onlineColor: brand.online,
                          offlineColor: brand.offline,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (tags.isNotEmpty) ...[
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: tags
                            .take(6)
                            .map(
                              (t) => _TagChip(
                                text: t,
                                borderColor: Colors.white.withValues(alpha: 0.16),
                                textColor: cs.onSurfaceVariant,
                                backgroundColor: Colors.white.withValues(alpha: 0.06),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (description != null && description!.trim().isNotEmpty) ...[
                      Text(
                        description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          height: 1.25,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    actions,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final LinearGradient gradient;
  final String? imageUrl;
  final String heroTag;
  final VoidCallback? onTap;
  final String placeholderInitials;

  const _HeroHeader({
    required this.gradient,
    required this.imageUrl,
    required this.heroTag,
    required this.onTap,
    required this.placeholderInitials,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    return SizedBox(
      height: 170,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
          if (hasImage)
            Hero(
              tag: heroTag,
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Center(
                  child: AppLoader(
                    radius: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withValues(alpha: 0.8),
                  ),
                ),
                errorWidget: (_, __, ___) => _InitialsPlaceholder(
                  initials: placeholderInitials,
                ),
              ),
            ),
          if (!hasImage) _InitialsPlaceholder(initials: placeholderInitials),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.60),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialsPlaceholder extends StatelessWidget {
  final String initials;

  const _InitialsPlaceholder({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.22),
          fontSize: 64,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String text;
  final Color borderColor;
  final Color backgroundColor;
  final Color textColor;

  const _TagChip({
    required this.text,
    required this.borderColor,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool online;
  final Color onlineColor;
  final Color offlineColor;

  const _StatusPill({
    required this.online,
    required this.onlineColor,
    required this.offlineColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = online ? onlineColor : offlineColor;
    final statusBg = statusColor.withValues(alpha: 0.18);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: statusColor.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            online ? 'Online' : 'Offline',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.95),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
