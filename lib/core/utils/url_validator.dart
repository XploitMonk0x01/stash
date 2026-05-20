/// URL validation utility
class UrlValidator {
  UrlValidator._();

  /// Check if a string is a valid URL (must start with http:// or https://)
  static bool isValidUrl(String url) {
    if (url.trim().isEmpty) return false;
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return false;
    return uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  /// Extract the domain from a URL (e.g., "google.com" from "https://www.google.com/search")
  static String? extractDomain(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.host.isEmpty) return null;
    final host = uri.host;
    // Remove 'www.' prefix
    if (host.startsWith('www.')) {
      return host.substring(4);
    }
    return host;
  }

  /// Build a Google favicon URL for a given domain
  static String getFaviconUrl(String url) {
    final domain = extractDomain(url);
    if (domain == null) return '';
    return 'https://www.google.com/s2/favicons?domain=$domain&sz=64';
  }

  /// Sanitize and normalize a URL
  static String sanitize(String url) {
    var sanitized = url.trim();
    if (!sanitized.startsWith('http://') && !sanitized.startsWith('https://')) {
      sanitized = 'https://$sanitized';
    }
    return sanitized;
  }
}
