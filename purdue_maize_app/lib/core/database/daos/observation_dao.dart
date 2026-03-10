import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/observation_tables.dart';

part 'observation_dao.g.dart';

@DriftAccessor(tables: [LocalObservations, LocalMediaFiles])
class ObservationDao extends DatabaseAccessor<AppDatabase> with _$ObservationDaoMixin {
  ObservationDao(super.db);

  // ── Observations ─────────────────────────────────────────────────────────────

  Stream<List<LocalObservation>> watchForPoint(String samplingPointId) =>
      (select(localObservations)..where((t) => t.samplingPointId.equals(samplingPointId))).watch();

  Future<List<LocalObservation>> getForPoint(String samplingPointId) =>
      (select(localObservations)..where((t) => t.samplingPointId.equals(samplingPointId))).get();

  Future<LocalObservation?> getById(String id) =>
      (select(localObservations)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Retorna observaciones con filtros opcionales para el Data Explorer.
  Future<List<LocalObservation>> query({
    int? diseaseId,
    DateTime? from,
    DateTime? to,
    double? minIncidence,
    double? maxIncidence,
  }) {
    final q = select(localObservations);
    q.where((t) {
      Expression<bool> cond = const Constant(true);
      if (diseaseId != null) cond = cond & t.diseaseId.equals(diseaseId);
      if (from != null) cond = cond & t.observedAt.isBiggerOrEqualValue(from);
      if (to != null) cond = cond & t.observedAt.isSmallerOrEqualValue(to);
      if (minIncidence != null) cond = cond & t.incidencePct.isBiggerOrEqualValue(minIncidence);
      if (maxIncidence != null) cond = cond & t.incidencePct.isSmallerOrEqualValue(maxIncidence);
      return cond;
    });
    q.orderBy([(t) => OrderingTerm.desc(t.observedAt)]);
    return q.get();
  }

  Future<void> upsertObservation(LocalObservationsCompanion obs) =>
      into(localObservations).insertOnConflictUpdate(obs);

  Future<List<LocalObservation>> getPending() =>
      (select(localObservations)..where((t) => t.syncStatus.equals('pending'))).get();

  Future<void> markSynced(String id) => (update(localObservations)
        ..where((t) => t.id.equals(id)))
      .write(const LocalObservationsCompanion(syncStatus: Value('synced')));

  Future<void> deleteObservation(String id) =>
      (delete(localObservations)..where((t) => t.id.equals(id))).go();

  // ── Media files ───────────────────────────────────────────────────────────────

  Stream<List<LocalMediaFile>> watchMediaForObservation(String observationId) =>
      (select(localMediaFiles)..where((t) => t.observationId.equals(observationId))).watch();

  Future<List<LocalMediaFile>> getMediaForObservation(String observationId) =>
      (select(localMediaFiles)..where((t) => t.observationId.equals(observationId))).get();

  Future<void> insertMedia(LocalMediaFilesCompanion media) =>
      into(localMediaFiles).insert(media);

  Future<List<LocalMediaFile>> getPendingMedia() =>
      (select(localMediaFiles)..where((t) => t.syncStatus.equals('pending'))).get();

  Future<void> markMediaSynced(String id, String remoteId) =>
      (update(localMediaFiles)..where((t) => t.id.equals(id))).write(
        LocalMediaFilesCompanion(
          syncStatus: const Value('synced'),
          remoteId: Value(remoteId),
        ),
      );

  Future<void> deleteMedia(String id) =>
      (delete(localMediaFiles)..where((t) => t.id.equals(id))).go();
}
