import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'dart:async';

import '../../../core/utils/url_validator.dart';

/// Provider for MetadataService
final metadataServiceProvider = Provider<MetadataService>((ref) {
  return MetadataService();
});

/// Service for fetching URL metadata (page title, favicon, description)
class MetadataService {
  // Simple in-memory cache to avoid repeated network calls.
  // Key: normalized URL, Value: fetched metadata
  final Map<String, LinkMetadata> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheTTL = Duration(hours: 24);
  static const int _cacheMaxEntries = 200;

  /// Fetch metadata for a given URL
  /// Returns a map with title, favicon_url, and description
  Future<LinkMetadata> fetchMetadata(String url) async {
    try {
      if (!UrlValidator.isValidUrl(url)) return LinkMetadata.empty();

      // Return cached value if present and fresh
      final cached = _cache[url];
      final ts = _cacheTimestamps[url];
      if (cached != null && ts != null) {
        if (DateTime.now().difference(ts) < _cacheTTL) {
          return cached;
        } else {
          _cache.remove(url);
          _cacheTimestamps.remove(url);
        }
      }

      // Attempt to fetch metadata with a short timeout
      Metadata? data;
      try {
        data = await MetadataFetch.extract(url).timeout(const Duration(seconds: 5));
      } on TimeoutException {
        data = null;
      }

      final result = data == null
          ? LinkMetadata(
              title: '',
              faviconUrl: UrlValidator.getFaviconUrl(url),
              description: '',
            )
          : LinkMetadata(
              title: data.title ?? '',
              faviconUrl: data.image ?? UrlValidator.getFaviconUrl(url),
              description: data.description ?? '',
            );

      // Store in cache and enforce max entries
      _cache[url] = result;
      _cacheTimestamps[url] = DateTime.now();
      if (_cache.length > _cacheMaxEntries) {
        // Evict the oldest entry
        final oldestKey = _cacheTimestamps.entries
            .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
            .key;
        _cache.remove(oldestKey);
        _cacheTimestamps.remove(oldestKey);
      }

      return result;
    } catch (e) {
      // Gracefully return empty metadata on failure
      return LinkMetadata(
        title: '',
        faviconUrl: UrlValidator.getFaviconUrl(url),
        description: '',
      );
    }
  }
}

/// Holds fetched metadata for a link
class LinkMetadata {
  final String title;
  final String faviconUrl;
  final String description;

  const LinkMetadata({
    required this.title,
    required this.faviconUrl,
    required this.description,
  });

  factory LinkMetadata.empty() {
    return const LinkMetadata(title: '', faviconUrl: '', description: '');
  }

  bool get isEmpty => title.isEmpty && faviconUrl.isEmpty && description.isEmpty;
}
