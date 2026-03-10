import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sampling_tables.dart';

part 'sampling_dao.g.dart';

@DriftAccessor(tables: [LocalSamplingSessions, LocalSamplingPoints])
class SamplingDao extends DatabaseAccessor<AppDatabase> with _$SamplingDaoMixin {
  SamplingDao(super.db);

  // ── Sessions ────────────────────────────────────────────────────────────────

  /// Stream reactivo de todas las sesiones (UI se actualiza automáticamente).
  Stream<List<LocalSamplingSession>> watchAllSessions() =>
      (select(localSamplingSessions)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  Future<List<LocalSamplingSession>> getSessionsByField(String fieldId) =>
      (select(localSamplingSessions)..where((t) => t.fieldId.equals(fieldId))).get();

  Future<LocalSamplingSession?> getSessionById(String id) =>
      (select(localSamplingSessions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsertSession(LocalSamplingSessionsCompanion session) =>
      into(localSamplingSessions).insertOnConflictUpdate(session);

  Future<void> upsertSessions(List<LocalSamplingSessionsCompanion> sessions) =>
      batch((b) => b.insertAllOnConflictUpdate(localSamplingSessions, sessions));

  Future<void> markSessionSynced(String id) => (update(localSamplingSessions)
        ..where((t) => t.id.equals(id)))
      .write(const LocalSamplingSessionsCompanion(syncStatus: Value('synced')));

  Future<List<LocalSamplingSession>> getPendingSessions() =>
      (select(localSamplingSessions)..where((t) => t.syncStatus.equals('pending'))).get();

  // ── Points ──────────────────────────────────────────────────────────────────

  Stream<List<LocalSamplingPoint>> watchPointsForSession(String sessionId) =>
      (select(localSamplingPoints)..where((t) => t.sessionId.equals(sessionId))).watch();

  Future<List<LocalSamplingPoint>> getPointsForSession(String sessionId) =>
      (select(localSamplingPoints)..where((t) => t.sessionId.equals(sessionId))).get();

  Future<LocalSamplingPoint?> getPointById(String id) =>
      (select(localSamplingPoints)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsertPoint(LocalSamplingPointsCompanion point) =>
      into(localSamplingPoints).insertOnConflictUpdate(point);

  Future<void> upsertPoints(List<LocalSamplingPointsCompanion> points) =>
      batch((b) => b.insertAllOnConflictUpdate(localSamplingPoints, points));

  Future<List<LocalSamplingPoint>> getPendingPoints() =>
      (select(localSamplingPoints)..where((t) => t.syncStatus.equals('pending'))).get();

  Future<void> markPointSynced(String id) => (update(localSamplingPoints)
        ..where((t) => t.id.equals(id)))
      .write(const LocalSamplingPointsCompanion(syncStatus: Value('synced')));

  Future<void> deletePoint(String id) =>
      (delete(localSamplingPoints)..where((t) => t.id.equals(id))).go();
}
