import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:flutter/foundation.dart';

import 'tables/sampling_tables.dart';
import 'tables/observation_tables.dart';
import 'tables/disease_tables.dart';
import 'daos/sampling_dao.dart';
import 'daos/observation_dao.dart';
import 'daos/disease_dao.dart';

export 'tables/sampling_tables.dart';
export 'tables/observation_tables.dart';
export 'tables/disease_tables.dart';
export 'daos/sampling_dao.dart';
export 'daos/observation_dao.dart';
export 'daos/disease_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    LocalSamplingSessions,
    LocalSamplingPoints,
    LocalDiseases,
    LocalObservations,
    LocalMediaFiles,
  ],
  daos: [
    SamplingDao,
    ObservationDao,
    DiseaseDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Agregar migraciones aquí en versiones futuras
        },
      );

  static QueryExecutor _openConnection() {
    return SqfliteQueryExecutor.inDatabaseFolder(
      path: 'maize_monitor.db',
      logStatements: kDebugMode,
    );
  }
}
