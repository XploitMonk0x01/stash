import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import '../../../core/utils/url_validator.dart';

/// Provider for MetadataService
final metadataServiceProvider = Provider<MetadataService>((ref) {
  return MetadataService();
});

/// Service for fetching URL metadata (page title, favicon, description)
class MetadataService {
  /// Fetch metadata for a given URL
  /// Returns a map with title, favicon_url, and description
  Future<LinkMetadata> fetchMetadata(String url) async {
    try {
      if (!UrlValidator.isValidUrl(url)) {
        return LinkMetadata.empty();
      }

      final data = await MetadataFetch.extract(url);
      if (data == null) {
        return LinkMetadata(
          title: '',
          faviconUrl: UrlValidator.getFaviconUrl(url),
          description: '',
        );
      }

      return LinkMetadata(
        title: data.title ?? '',
        faviconUrl: data.image ?? UrlValidator.getFaviconUrl(url),
        description: data.description ?? '',
      );
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
