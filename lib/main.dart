import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/utils/share_intent_handler.dart';
import 'firebase_options.dart';
import 'features/links/presentation/widgets/add_link_sheet.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Initialize share handler
  ShareIntentHandler().init();

  runApp(const ProviderScope(child: StashApp()));
}

class StashApp extends ConsumerStatefulWidget {
  const StashApp({super.key});

  @override
  ConsumerState<StashApp> createState() => _StashAppState();
}

class _StashAppState extends ConsumerState<StashApp> {
  @override
  void initState() {
    super.initState();
    // Listen for shared URLs and open the add link sheet
    ShareIntentHandler().sharedUrl.addListener(_onSharedUrl);
  }

  @override
  void dispose() {
    ShareIntentHandler().sharedUrl.removeListener(_onSharedUrl);
    super.dispose();
  }

  void _onSharedUrl() {
    final url = ShareIntentHandler().sharedUrl.value;
    if (url != null && url.isNotEmpty) {
      // Wait for the app to be ready, then show the bottom sheet
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _navigatorKey.currentContext;
        if (context != null) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (_) => AddLinkSheet(prefilledUrl: url),
          ).then((_) {
            ShareIntentHandler().clearSharedUrl();
          });
        }
      });
    }
  }

  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Stash',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
