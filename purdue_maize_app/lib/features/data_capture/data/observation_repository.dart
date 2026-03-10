import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_models.dart';
import '../../../core/providers/database_provider.dart';

const _uuid = Uuid();

class ObservationRepository {
  ObservationRepository({required this.dao, required this.api});

  final ObservationDao dao;
  final ApiClient api;

  // ── Queries ───────────────────────────────────────────────────────────────────

  Stream<List<LocalObservation>> watchForPoint(String samplingPointId) =>
      dao.watchForPoint(samplingPointId);

  Stream<List<LocalMediaFile>> watchMediaForObservation(String observationId) =>
      dao.watchMediaForObservation(observationId);

  Future<List<LocalObservation>> query({
    int? diseaseId,
    DateTime? from,
    DateTime? to,
    double? minIncidence,
    double? maxIncidence,
  }) =>
      dao.query(
        diseaseId: diseaseId,
        from: from,
        to: to,
        minIncidence: minIncidence,
        maxIncidence: maxIncidence,
      );

  // ── Write (offline-first) ─────────────────────────────────────────────────────

  /// Guarda la observación localmente. El sync al servidor lo gestiona SyncService.
  Future<LocalObservation> saveObservation({
    required String samplingPointId,
    required int diseaseId,
    double? incidencePct,
    double? severityValue,
    String? severityScale,
    String? cultivar,
    String? phenologicalStage,
    String? plantingDate,
    bool? irrigation,
    bool? fungicideApplied,
    String? fertilizationNotes,
    String? notes,
    required DateTime observedAt,
  }) async {
    final id = _uuid.v4();
    final companion = LocalObservationsCompanion(
      id: Value(id),
      samplingPointId: Value(samplingPointId),
      diseaseId: Value(diseaseId),
      incidencePct: Value(incidencePct),
      severityValue: Value(severityValue),
      severityScale: Value(severityScale),
      cultivar: Value(cultivar),
      phenologicalStage: Value(phenologicalStage),
      plantingDate: Value(plantingDate),
      irrigation: Value(irrigation),
      fungicideApplied: Value(fungicideApplied),
      fertilizationNotes: Value(fertilizationNotes),
      notes: Value(notes),
      observedAt: Value(observedAt),
      syncStatus: const Value('pending'),
      createdAt: Value(DateTime.now()),
    );
    await dao.upsertObservation(companion);
    return (await dao.getById(id))!;
  }

  /// Adjunta un archivo de imagen o audio a una observación localmente.
  Future<LocalMediaFile> attachMedia({
    required String observationId,
    required File file,
    required String mediaType, // 'image' | 'audio'
    double? durationSeconds,
    String? mimeType,
  }) async {
    final id = _uuid.v4();
    final stat = await file.stat();
    final companion = LocalMediaFilesCompanion(
      id: Value(id),
      observationId: Value(observationId),
      mediaType: Value(mediaType),
      localPath: Value(file.path),
      fileSizeBytes: Value(stat.size),
      durationSeconds: Value(durationSeconds),
      mimeType: Value(mimeType),
      syncStatus: const Value('pending'),
      createdAt: Value(DateTime.now()),
    );
    await dao.insertMedia(companion);
    final all = await dao.getMediaForObservation(observationId);
    return all.firstWhere((m) => m.id == id);
  }

  Future<void> deleteMedia(String id) => dao.deleteMedia(id);
  Future<void> deleteObservation(String id) => dao.deleteObservation(id);

  // ── Sync helpers (llamados por SyncService) ────────────────────────────────────

  Future<List<LocalObservation>> getPendingObservations() => dao.getPending();
  Future<List<LocalMediaFile>> getPendingMedia() => dao.getPendingMedia();

  Future<void> syncObservation(LocalObservation obs) async {
    final payload = ApiObservationCreate(
      samplingPointId: obs.samplingPointId,
      diseaseId: obs.diseaseId,
      incidencePct: obs.incidencePct,
      severityValue: obs.severityValue,
      severityScale: obs.severityScale,
      cultivar: obs.cultivar,
      phenologicalStage: obs.phenologicalStage,
      plantingDate: obs.plantingDate,
      irrigation: obs.irrigation,
      fungicideApplied: obs.fungicideApplied,
      fertilizationNotes: obs.fertilizationNotes,
      notes: obs.notes,
      observedAt: obs.observedAt.toIso8601String(),
    );
    await api.createObservation(payload);
    await dao.markSynced(obs.id);
  }

  Future<void> syncMediaFile(LocalMediaFile media) async {
    final file = File(media.localPath);
    if (!await file.exists()) return; // archivo eliminado del dispositivo
    final result = await api.uploadMedia(media.observationId, file);
    await dao.markMediaSynced(media.id, result.id);
  }
}

// ── Riverpod ──────────────────────────────────────────────────────────────────

final observationRepositoryProvider = Provider<ObservationRepository>((ref) {
  return ObservationRepository(
    dao: ref.watch(observationDaoProvider),
    api: ref.watch(apiClientProvider),
  );
});

/// Observaciones de un punto específico (para el formulario y el mapa).
final observationsForPointProvider = StreamProvider.family<List<LocalObservation>, String>(
  (ref, pointId) => ref.watch(observationRepositoryProvider).watchForPoint(pointId),
);

/// Media de una observación específica.
final mediaForObservationProvider = StreamProvider.family<List<LocalMediaFile>, String>(
  (ref, obsId) => ref.watch(observationRepositoryProvider).watchMediaForObservation(obsId),
);
