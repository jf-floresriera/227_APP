import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/purdue_theme.dart';
import 'core/router/app_router.dart';
import 'core/sync/sync_service.dart';
import 'core/auth/auth_provider.dart';

class PurdueMaizeApp extends ConsumerWidget {
  const PurdueMaizeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Inicializar SyncService al arrancar la app.
    ref.watch(syncServiceProvider);
    // Inicializar auth desde secure storage.
    ref.watch(authProvider);

    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Purdue Maize Monitor',
      theme: buildPurdueTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
