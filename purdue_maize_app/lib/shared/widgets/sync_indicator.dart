import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/sync/sync_service.dart';
import '../../core/theme/purdue_theme.dart';

/// Indicador de sincronización para la AppBar.
/// Muestra un ícono según el estado: sin conexión, sincronizando, todo sync.
class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncServiceProvider);
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? false;

    return GestureDetector(
      onTap: () => _showSyncDetails(context, syncStatus, isOnline, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: _buildIcon(syncStatus, isOnline),
      ),
    );
  }

  Widget _buildIcon(SyncStatus status, bool isOnline) {
    if (!isOnline) {
      return const Icon(Icons.cloud_off_outlined, color: PurdueColors.dust);
    }
    return switch (status.state) {
      SyncState.syncing => const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: PurdueColors.boilermakerGold,
          ),
        ),
      SyncState.error => const Icon(Icons.sync_problem, color: PurdueColors.riskHigh),
      SyncState.idle => status.pendingCount > 0
          ? Badge(
              label: Text('${status.pendingCount}'),
              backgroundColor: PurdueColors.riskMedium,
              child: const Icon(Icons.cloud_upload_outlined, color: PurdueColors.boilermakerGold),
            )
          : const Icon(Icons.cloud_done_outlined, color: PurdueColors.riskLow),
    };
  }

  void _showSyncDetails(
    BuildContext context,
    SyncStatus status,
    bool isOnline,
    WidgetRef ref,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sincronización', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _InfoRow(label: 'Conexión', value: isOnline ? 'En línea' : 'Sin conexión'),
            _InfoRow(label: 'Registros pendientes', value: '${status.pendingCount}'),
            if (status.lastSyncAt != null)
              _InfoRow(
                label: 'Última sync',
                value: _formatTime(status.lastSyncAt!),
              ),
            if (status.lastError != null)
              _InfoRow(label: 'Error', value: status.lastError!, isError: true),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.sync),
                label: const Text('Sincronizar ahora'),
                onPressed: status.state == SyncState.syncing || !isOnline
                    ? null
                    : () {
                        Navigator.pop(context);
                        ref.read(syncServiceProvider.notifier).syncAll();
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Hace un momento';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    return 'Hace ${diff.inHours} h';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.isError = false});
  final String label;
  final String value;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isError ? PurdueColors.riskHigh : null,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
