import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_models.dart';
import '../../../core/providers/database_provider.dart';

const _uuid = Uuid();

class SamplingRepository {
  SamplingRepository({required this.dao, required this.api});

  final SamplingDao dao;
  final ApiClient api;

  // ── Sessions ────────────────────────────────────────────────────────────────

  Stream<List<LocalSamplingSession>> watchSessions() => dao.watchAllSessions();

  /// Crea una sesión localmente (sync_status = 'pending') y la retorna.
  /// La sincronización al servidor la maneja SyncService.
  Future<LocalSamplingSession> createSessionLocally({
    required String fieldId,
    required String fieldName,
    required String samplingType,
    required DateTime sessionDate,
    String? notes,
    required String userId,
  }) async {
    final id = _uuid.v4();
    final companion = LocalSamplingSessionsCompanion(
      id: Value(id),
      fieldId: Value(fieldId),
      fieldName: Value(fieldName),
      samplingType: Value(samplingType),
      sessionDate: Value(sessionDate),
      notes: Value(notes),
      syncStatus: const Value('pending'),
      createdBy: Value(userId),
      createdAt: Value(DateTime.now()),
    );
    await dao.upsertSession(companion);
    return (await dao.getSessionById(id))!;
  }

  /// Sincroniza una sesión pendiente al servidor.
  Future<void> syncSession(LocalSamplingSession session) async {
    final points = await dao.getPointsForSession(session.id);
    final payload = ApiSamplingSessionCreate(
      fieldId: session.fieldId,
      samplingType: session.samplingType,
      sessionDate: session.sessionDate.toIso8601String().substring(0, 10),
      notes: session.notes,
      points: points.map((p) => ApiSamplingPointCreate(
        pointCode: p.pointCode,
        location: ApiPointCoords(latitude: p.latitude, longitude: p.longitude, altitudeM: p.altitudeM),
        recordedAt: p.recordedAt.toIso8601String(),
      )).toList(),
    );

    await api.createSession(payload);
    await dao.markSessionSynced(session.id);
    for (final p in points) {
      await dao.markPointSynced(p.id);
    }
  }

  // ── Points ──────────────────────────────────────────────────────────────────

  Stream<List<LocalSamplingPoint>> watchPointsForSession(String sessionId) =>
      dao.watchPointsForSession(sessionId);

  Future<LocalSamplingPoint> addPoint({
    required String sessionId,
    required double latitude,
    required double longitude,
    double? altitudeM,
    String? pointCode,
  }) async {
    final id = _uuid.v4();
    final companion = LocalSamplingPointsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      pointCode: Value(pointCode),
      latitude: Value(latitude),
      longitude: Value(longitude),
      altitudeM: Value(altitudeM),
      syncStatus: const Value('pending'),
      recordedAt: Value(DateTime.now()),
      createdAt: Value(DateTime.now()),
    );
    await dao.upsertPoint(companion);
    return (await dao.getPointById(id))!;
  }

  Future<void> deletePoint(String id) => dao.deletePoint(id);
}

// ── Riverpod ──────────────────────────────────────────────────────────────────

final samplingRepositoryProvider = Provider<SamplingRepository>((ref) {
  return SamplingRepository(
    dao: ref.watch(samplingDaoProvider),
    api: ref.watch(apiClientProvider),
  );
});

/// Stream de sesiones de muestreo para la UI.
final samplingSessionsProvider = StreamProvider<List<LocalSamplingSession>>((ref) {
  return ref.watch(samplingRepositoryProvider).watchSessions();
});

/// Stream de puntos de una sesión específica.
final samplingPointsProvider = StreamProvider.family<List<LocalSamplingPoint>, String>(
  (ref, sessionId) => ref.watch(samplingRepositoryProvider).watchPointsForSession(sessionId),
);
