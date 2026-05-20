import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/categories/presentation/screens/categories_screen.dart';
import '../../features/links/presentation/screens/home_screen.dart';
import 'main_shell.dart';

/// GoRouter provider with auth redirect guard
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isOnAuth = state.matchedLocation.startsWith('/auth');
      final isOnSplash = state.matchedLocation == '/splash';

      // Still loading auth state
      if (authState.isLoading) return null;

      // If not logged in, redirect to sign-in (unless already on auth pages)
      if (!isLoggedIn && !isOnAuth && !isOnSplash) {
        return '/auth/sign-in';
      }

      // If logged in and on auth/splash pages, redirect to home
      if (isLoggedIn && (isOnAuth || isOnSplash)) {
        return '/home';
      }

      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth routes
      GoRoute(
        path: '/auth/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/auth/sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main app with bottom nav shell
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/categories',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CategoriesScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});
