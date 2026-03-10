import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';

/// Singleton de la base de datos local. Se cierra automáticamente cuando
/// el ProviderScope es destruido (dispose del container).
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ── DAO providers ──────────────────────────────────────────────────────────────

final samplingDaoProvider = Provider<SamplingDao>(
  (ref) => ref.watch(databaseProvider).samplingDao,
);

final observationDaoProvider = Provider<ObservationDao>(
  (ref) => ref.watch(databaseProvider).observationDao,
);

final diseaseDaoProvider = Provider<DiseaseDao>(
  (ref) => ref.watch(databaseProvider).diseaseDao,
);
