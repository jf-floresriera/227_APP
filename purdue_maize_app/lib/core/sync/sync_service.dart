import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../../features/sampling/data/sampling_repository.dart';
import '../../features/data_capture/data/observation_repository.dart';

/// Estado de sincronización visible en la UI.
enum SyncState { idle, syncing, error }

class SyncStatus {
  const SyncStatus({
    this.state = SyncState.idle,
    this.pendingCount = 0,
    this.lastSyncAt,
    this.lastError,
  });

  final SyncState state;
  final int pendingCount;
  final DateTime? lastSyncAt;
  final String? lastError;

  SyncStatus copyWith({
    SyncState? state,
    int? pendingCount,
    DateTime? lastSyncAt,
    String? lastError,
  }) =>
      SyncStatus(
        state: state ?? this.state,
        pendingCount: pendingCount ?? this.pendingCount,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        lastError: lastError,
      );
}

/// SyncService: escucha la conectividad y sube los registros pendientes.
///
/// Orden de sincronización:
///   1. Sesiones de muestreo (con sus puntos)
///   2. Observaciones
///   3. Archivos multimedia (imágenes y audios)
///
/// Si alguna entidad falla, se continúa con la siguiente para maximizar
/// la cantidad de datos sincronizados en cada ventana de conexión.
class SyncService extends Notifier<SyncStatus> {
  @override
  SyncStatus build() {
    // Escuchar cambios de conectividad
    final connectivity = Connectivity();
    final sub = connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) syncAll();
    });
    ref.onDispose(sub.cancel);

    // Sincronizar al inicializar si hay conexión
    _checkAndSync();
    return const SyncStatus();
  }

  Future<void> _checkAndSync() async {
    final results = await Connectivity().checkConnectivity();
    if (results.any((r) => r != ConnectivityResult.none)) {
      await syncAll();
    }
  }

  Future<void> syncAll() async {
    if (state.state == SyncState.syncing) return;
    state = state.copyWith(state: SyncState.syncing);

    try {
      final samplingRepo = ref.read(samplingRepositoryProvider);
      final obsRepo = ref.read(observationRepositoryProvider);

      int synced = 0;

      // 1. Sesiones pendientes (incluye sus puntos)
      final pendingSessions = await samplingRepo.dao.getPendingSessions();
      for (final session in pendingSessions) {
        try {
          await samplingRepo.syncSession(session);
          synced++;
        } catch (e) {
          // Continuar con la siguiente sesión
        }
      }

      // 2. Observaciones pendientes
      final pendingObs = await obsRepo.getPendingObservations();
      for (final obs in pendingObs) {
        try {
          await obsRepo.syncObservation(obs);
          synced++;
        } catch (e) {
          // Continuar con la siguiente observación
        }
      }

      // 3. Archivos multimedia pendientes
      final pendingMedia = await obsRepo.getPendingMedia();
      for (final media in pendingMedia) {
        try {
          await obsRepo.syncMediaFile(media);
          synced++;
        } catch (e) {
          // Continuar con el siguiente archivo
        }
      }

      // Recalcular cuántos siguen pendientes después del intento
      final remaining = (await samplingRepo.dao.getPendingSessions()).length +
          (await obsRepo.getPendingObservations()).length +
          (await obsRepo.getPendingMedia()).length;

      state = state.copyWith(
        state: SyncState.idle,
        pendingCount: remaining,
        lastSyncAt: DateTime.now(),
        lastError: null,
      );
    } catch (e) {
      state = state.copyWith(
        state: SyncState.error,
        lastError: e.toString(),
      );
    }
  }
}

// ── Riverpod ──────────────────────────────────────────────────────────────────

final syncServiceProvider = NotifierProvider<SyncService, SyncStatus>(SyncService.new);

/// Indica si el dispositivo tiene conexión actualmente.
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map(
        (results) => results.any((r) => r != ConnectivityResult.none),
      );
});
