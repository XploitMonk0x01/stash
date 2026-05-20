

**Summary**
- Project: Stash — Flutter app (Riverpod, GoRouter, Firebase) for saving links; offline Firestore enabled. Key files inspected: main.dart, app_router.dart, app_theme.dart, share_intent_handler.dart, metadata_service.dart, link_repository.dart, link_card.dart, home_screen.dart.

**Applied Skills**
- Followed guidance from `flutter-expert` and `flutter-pro-ui` SKILLs to prioritize performance, Riverpod patterns, polished Material 3, glassmorphism, slivers, and micro-animations.

**Potential Features to Add (low-effort → high-impact)**
- **Metadata Caching:** Cache metadata results (in-memory + local prefs or small DB) to avoid repeated network fetches. Target: metadata_service.dart.
- **Soft-Delete / Restore:** Implement soft-delete with an `is_deleted` flag or archive collection so "undo" truly restores original record (preserve id). Target: link_repository.dart.
- **Background Metadata Fetching:** Use an isolate or background worker to fetch and update metadata after link creation (non-blocking add).
- **Improved Delete Confirmation:** Add an optional confirm sheet before destructive delete (or an undo snackbar that reinstates same id).
- **Composite Index Documentation / Automation:** Detect queries that need composite indexes (e.g., favourites + order) and surface a one-click or README instruction to create them.
- **Polish UI Templates:** Apply glassmorphism and subtle staggered animations to `AddLinkSheet` and `LinkCard` using `flutter_animate` (per `flutter-pro-ui`).
- **Golden Widget Tests:** Add golden tests for `LinkCard` and `EmptyState` to keep UI consistent.

**Bugs / Fixes & Improvements**
- **Undo not restoring original id:** `LinkRepository.addLink` creates a new doc id. Current undo logic in `LinkCard` calls `repo.addLink(link)` which will not restore the original doc id. Fix: provide `repo.restoreLink(LinkModel)` that sets the document with the original id (`_linksRef.doc(link.id).set(...)`).
  - File: link_repository.dart
- **Delete confirmation UX:** `Dismissible.confirmDismiss` returns `true` unconditionally. Consider confirming destructive deletes or moving to soft-delete.
  - File: link_card.dart
- **Lack of network/timeouts in metadata fetch:** `MetadataService.fetchMetadata` wraps `MetadataFetch.extract` without timeout or caching; add a timeout and cache results; handle user-agent or HEAD checks for robust favicon detection.
  - File: metadata_service.dart
- **Error handling & user feedback:** Many repository methods (`addLink`, `updateLink`, etc.) do not surface errors to the UI. Wrap Firestore calls with try/catch and return Result/Failure or rethrow with clear messages; show Snackbars on failures.
  - Files: link_repository.dart and consumers like link_card.dart
- **Theming & performance:** `AppTheme` constructs many `GoogleFonts.roboto` instances for each text style; create a single `TextTheme` or cache font text styles to reduce work at runtime.
  - File: app_theme.dart
- **Share Intent URL validation:** `ShareIntentHandler` extracts the first matched URL but doesn't validate with `UrlValidator` before publishing; use validation and normalization (trim, ensure scheme).
  - File: share_intent_handler.dart

**Code Review — Key Recommendations**
- **link_repository.dart**
  - Suggest adding `restoreLink(LinkModel)` to set doc with original id.
  - Consider server-side filtering and composite indexes for frequent queries to reduce client bandwidth (or add an opt-in index setup doc).
  - Add input validation and try/catch with clear error propagation.
- **link_card.dart**
  - Change undo action to call `restoreLink(...)` that sets the same doc id.
  - `confirmDismiss` should present an optional confirmation (or use soft-delete).
  - Consider awaiting repository calls and handling failures (show error snackbar if delete failed).
  - Minor: reduce duplication in CachedNetworkImage branches by resolving faviconUrl above widget build.
- **metadata_service.dart**
  - Add a short timeout (e.g., 5s) around `MetadataFetch.extract`.
  - Add a small LRU cache keyed by URL to avoid repeated calls.
  - On failure, fallback to a deterministic favicon via `UrlValidator.getFaviconUrl`.
- **app_theme.dart**
  - Consolidate `GoogleFonts.roboto` creation; compute once then reuse in `_buildTextTheme`.
  - Mark immutable ThemeData pieces with `const` where possible.
- **share_intent_handler.dart**
  - Validate URLs with `UrlValidator.isValidUrl` before setting `sharedUrl.value`.
  - Handle multiple URLs and strip extraneous punctuation.
- **app_router.dart**
  - `redirect` logic is clear; ensure `authStateProvider` loading state is handled robustly (already checked). Consider handling unknown routes with an error builder.

**Observations**
- The app already follows many `flutter-pro-ui` recommendations: uses `CustomScrollView`/Slivers, `flutter_animate` on lists, and polished theming.
- No obvious TODO/FIXME markers found in lib. Codebase is tidy and feature-focused.

**Next Steps / Offer**
- I can implement the top fixes now (pick one):
  1. Implement `restoreLink` and fix undo behavior.
  2. Add timeout + caching to `MetadataService`.
  3. Replace physical delete with soft-delete and confirm sheet in `LinkCard`.
  4. Refactor `AppTheme` to reduce repeated GoogleFonts calls.

