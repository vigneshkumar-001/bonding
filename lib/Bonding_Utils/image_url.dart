// lib/Bonding_Utils/image_url.dart
//
// Normalizes profile/image URLs coming from the backend so they always render.
// Some endpoints return an absolute URL (https://…), others a relative path
// (e.g. "uploads/abc.jpg" or "/uploads/abc.jpg"). The strict avatar widgets
// only accepted absolute http(s) URLs, so relative paths fell back to the
// letter even when an image existed. This resolves both forms.

const String kImageOrigin = 'https://bnd.twoofus.tech';

/// Returns a loadable absolute URL, or null if there is no usable image.
String? resolveImageUrl(String? raw, {String origin = kImageOrigin}) {
  if (raw == null) return null;
  final t = raw.trim();
  if (t.isEmpty) return null;

  if (t.startsWith('http://') || t.startsWith('https://')) return t;
  if (t.startsWith('//')) return 'https:$t';
  if (t.startsWith('/')) return '$origin$t';
  return '$origin/$t';
}

/// Convenience: does this raw value point at an image we can try to load?
bool hasImageUrl(String? raw) => resolveImageUrl(raw) != null;
