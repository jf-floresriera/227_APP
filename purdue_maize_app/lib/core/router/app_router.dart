import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/sampling/presentation/screens/sampling_screen.dart';
import '../../features/sampling/presentation/screens/sampling_map_screen.dart';
import '../../features/data_capture/presentation/screens/data_capture_screen.dart';
import '../../features/data_capture/presentation/screens/observation_form_screen.dart';
import '../../features/data_explorer/presentation/screens/data_explorer_screen.dart';
import '../../features/modeling/presentation/screens/modeling_screen.dart';
import '../../features/modeling/presentation/screens/model_results_screen.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../auth/auth_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Rutas protegidas: cualquier path que empiece con estas raíces requiere auth.
const _protectedPrefixes = ['/sampling', '/capture', '/explorer', '/modeling'];

GoRouter buildAppRouter(WidgetRef ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final goingToLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !goingToLogin) return '/login';
      if (isLoggedIn && goingToLogin) return '/sampling';
      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ── App principal (con bottom nav) ─────────────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          // ── Módulo 1: Sampling ──────────────────────────────────────────
          GoRoute(
            path: '/sampling',
            pageBuilder: (context, state) => const NoTransitionPage(child: SamplingScreen()),
            routes: [
              GoRoute(
                path: 'map',
                builder: (context, state) {
                  final sessionId = state.uri.queryParameters['sessionId'];
                  return SamplingMapScreen(sessionId: sessionId);
                },
              ),
            ],
          ),

          // ── Módulo 2: Data Capture ──────────────────────────────────────
          GoRoute(
            path: '/capture',
            pageBuilder: (context, state) => const NoTransitionPage(child: DataCaptureScreen()),
            routes: [
              GoRoute(
                path: 'observe/:pointId',
                builder: (context, state) {
                  return ObservationFormScreen(
                    samplingPointId: state.pathParameters['pointId']!,
                  );
                },
              ),
            ],
          ),

          // ── Módulo 2b: Data Explorer ────────────────────────────────────
          GoRoute(
            path: '/explorer',
            pageBuilder: (context, state) => const NoTransitionPage(child: DataExplorerScreen()),
          ),

          // ── Módulo 3: Modeling ──────────────────────────────────────────
          GoRoute(
            path: '/modeling',
            pageBuilder: (context, state) => const NoTransitionPage(child: ModelingScreen()),
            routes: [
              GoRoute(
                path: 'results/:runId',
                builder: (context, state) {
                  return ModelResultsScreen(runId: state.pathParameters['runId']!);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Listenable que notifica a GoRouter cuando cambia el estado de auth.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(WidgetRef ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}

/// Provider del router — se recrea cuando cambia el auth state.
final appRouterProvider = Provider<GoRouter>((ref) {
  // Nota: GoRouter necesita un WidgetRef para el guard.
  // Se construye como singleton aquí; el refresh lo maneja _AuthListenable.
  return _buildStaticRouter(ref);
});

GoRouter _buildStaticRouter(Ref ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.isAuthenticated;
      final goingToLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !goingToLogin) return '/login';
      if (isLoggedIn && goingToLogin) return '/sampling';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/sampling',
            pageBuilder: (_, __) => const NoTransitionPage(child: SamplingScreen()),
            routes: [
              GoRoute(
                path: 'map',
                builder: (_, state) => SamplingMapScreen(
                  sessionId: state.uri.queryParameters['sessionId'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/capture',
            pageBuilder: (_, __) => const NoTransitionPage(child: DataCaptureScreen()),
            routes: [
              GoRoute(
                path: 'observe/:pointId',
                builder: (_, state) => ObservationFormScreen(
                  samplingPointId: state.pathParameters['pointId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/explorer',
            pageBuilder: (_, __) => const NoTransitionPage(child: DataExplorerScreen()),
          ),
          GoRoute(
            path: '/modeling',
            pageBuilder: (_, __) => const NoTransitionPage(child: ModelingScreen()),
            routes: [
              GoRoute(
                path: 'results/:runId',
                builder: (_, state) => ModelResultsScreen(
                  runId: state.pathParameters['runId']!,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
