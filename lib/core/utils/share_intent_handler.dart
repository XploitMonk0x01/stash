import 'package:flutter/widgets.dart';
import 'package:share_handler/share_handler.dart';
import 'url_validator.dart';

/// Handles incoming share intents from other apps
class ShareIntentHandler {
  static final ShareIntentHandler _instance = ShareIntentHandler._();
  factory ShareIntentHandler() => _instance;
  ShareIntentHandler._();

  final ValueNotifier<String?> sharedUrl = ValueNotifier(null);

  /// Initialize the share handler and listen for incoming URLs
  void init() {
    final handler = ShareHandlerPlatform.instance;

    // Handle shared media while app is running
    handler.sharedMediaStream.listen((SharedMedia media) {
      _processSharedMedia(media);
    });

    // Handle shared media when app was closed
    handler.getInitialSharedMedia().then((SharedMedia? media) {
      if (media != null) {
        _processSharedMedia(media);
      }
    });
  }

  void _processSharedMedia(SharedMedia media) {
    // Extract URL from shared content
    final content = media.content;
    if (content != null && content.isNotEmpty) {
      // Try to find a URL in the shared text
      final urlPattern = RegExp(
        r'https?://[^\s<>"{}|\\^`\[\]]+',
        caseSensitive: false,
      );
      final match = urlPattern.firstMatch(content);
      String candidate = match?.group(0) ?? content;
      candidate = candidate.trim();
      if (UrlValidator.isValidUrl(candidate)) {
        sharedUrl.value = UrlValidator.sanitize(candidate);
      }
    }
  }

  /// Clear the shared URL after it's been consumed
  void clearSharedUrl() {
    sharedUrl.value = null;
  }
}
