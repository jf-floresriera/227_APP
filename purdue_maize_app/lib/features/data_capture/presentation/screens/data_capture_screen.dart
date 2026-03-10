import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/purdue_theme.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../shared/widgets/sync_indicator.dart';
import '../../data/observation_repository.dart';
import '../../../../core/database/app_database.dart';

/// Módulo 2 — Lista de observaciones pendientes de sincronizar.
class DataCaptureScreen extends ConsumerWidget {
  const DataCaptureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Capture'),
        actions: const [SyncIndicator()],
      ),
      body: Column(
        children: [
          const _SyncStatusBanner(),
          Expanded(child: _PendingObservationsList()),
        ],
      ),
    );
  }
}

class _SyncStatusBanner extends ConsumerWidget {
  const _SyncStatusBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? false;
    final syncStatus = ref.watch(syncServiceProvider);

    Color bannerColor;
    IconData icon;
    String message;

    if (syncStatus.state == SyncState.syncing) {
      bannerColor = PurdueColors.boilermakerGold.withOpacity(0.15);
      icon = Icons.sync;
      message = 'Sincronizando...';
    } else if (!isOnline) {
      bannerColor = PurdueColors.riskMedium.withOpacity(0.12);
      icon = Icons.cloud_off_outlined;
      message = 'Sin conexión — datos guardados localmente';
    } else if (syncStatus.pendingCount > 0) {
      bannerColor = PurdueColors.riskMedium.withOpacity(0.12);
      icon = Icons.cloud_upload_outlined;
      message = '${syncStatus.pendingCount} registro(s) pendiente(s) de sincronizar';
    } else {
      bannerColor = PurdueColors.riskLow.withOpacity(0.12);
      icon = Icons.cloud_done_outlined;
      message = 'Todo sincronizado';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: bannerColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: PurdueColors.steel),
          const SizedBox(width: 8),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _PendingObservationsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mostrar todas las observaciones pendientes de sync
    final obsRepo = ref.watch(observationRepositoryProvider);

    return FutureBuilder<List<LocalObservation>>(
      future: obsRepo.getPendingObservations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final pending = snapshot.data ?? [];
        if (pending.isEmpty) return const _EmptyPendingState();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pending.length,
          itemBuilder: (context, i) => _ObservationTile(obs: pending[i]),
        );
      },
    );
  }
}

class _ObservationTile extends StatelessWidget {
  const _ObservationTile({required this.obs});
  final LocalObservation obs;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy – HH:mm');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: obs.syncStatus == 'pending' ? PurdueColors.riskMedium : PurdueColors.riskLow,
          ),
        ),
        title: Text('Enfermedad ID: ${obs.diseaseId}', style: Theme.of(context).textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (obs.incidencePct != null)
              Text('Incidencia: ${obs.incidencePct!.toStringAsFixed(1)} %'),
            Text(fmt.format(obs.observedAt)),
          ],
        ),
        trailing: Icon(
          obs.syncStatus == 'pending' ? Icons.schedule : Icons.check_circle_outline,
          color: obs.syncStatus == 'pending' ? PurdueColors.riskMedium : PurdueColors.riskLow,
        ),
      ),
    );
  }
}

class _EmptyPendingState extends StatelessWidget {
  const _EmptyPendingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 64, color: PurdueColors.dust),
          const SizedBox(height: 16),
          Text('Sin observaciones pendientes', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            'Registra observaciones desde el módulo Sampling',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
