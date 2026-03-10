import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/purdue_theme.dart';
import '../../core/auth/auth_provider.dart';
import 'sync_indicator.dart';

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indexFromPath(location),
        onDestinationSelected: (i) => _navigate(context, i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Sampling',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Capture',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Explorer',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Modeling',
          ),
        ],
      ),
      // Drawer de perfil / logout
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: PurdueColors.black,
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 32,
                      backgroundColor: PurdueColors.boilermakerGold,
                      child: Icon(Icons.person, color: PurdueColors.black, size: 36),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      authState.fullName ?? 'Usuario',
                      style: const TextStyle(color: PurdueColors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      authState.email ?? '',
                      style: const TextStyle(color: PurdueColors.railwayGray, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('Sincronización'),
                trailing: const SyncIndicator(),
                onTap: () {},
              ),
              const Divider(),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout, color: PurdueColors.riskHigh),
                title: const Text('Cerrar sesión', style: TextStyle(color: PurdueColors.riskHigh)),
                onTap: () async {
                  Navigator.pop(context); // cerrar drawer
                  await ref.read(authProvider.notifier).logout();
                  // El router redirect redirige a /login automáticamente
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  int _indexFromPath(String path) {
    if (path.startsWith('/sampling')) return 0;
    if (path.startsWith('/capture')) return 1;
    if (path.startsWith('/explorer')) return 2;
    if (path.startsWith('/modeling')) return 3;
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    final paths = ['/sampling', '/capture', '/explorer', '/modeling'];
    context.go(paths[index]);
  }
}
