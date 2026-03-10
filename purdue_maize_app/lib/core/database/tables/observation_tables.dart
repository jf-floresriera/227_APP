import 'package:drift/drift.dart';
import 'sampling_tables.dart';
import 'disease_tables.dart';

/// Registro de enfermedad en un punto de muestreo.
/// Un punto puede tener múltiples observaciones (una por enfermedad).
class LocalObservations extends Table {
  TextColumn get id => text()();
  TextColumn get samplingPointId => text().references(LocalSamplingPoints, #id)();
  IntColumn get diseaseId => integer().references(LocalDiseases, #id)();

  // Incidencia: % plantas afectadas (0–100)
  RealColumn get incidencePct => real().nullable()();

  // Severidad: valor + escala
  RealColumn get severityValue => real().nullable()();
  TextColumn get severityScale => text().nullable()(); // percentage|1-9|1-5

  // Contexto agronómico
  TextColumn get cultivar => text().nullable()();
  TextColumn get phenologicalStage => text().nullable()();
  TextColumn get plantingDate => text().nullable()();
  BoolColumn get irrigation => boolean().nullable()();
  BoolColumn get fungicideApplied => boolean().nullable()();
  TextColumn get fertilizationNotes => text().nullable()();
  TextColumn get notes => text().nullable()();

  DateTimeColumn get observedAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Archivo multimedia adjunto a una observación.
class LocalMediaFiles extends Table {
  TextColumn get id => text()();
  TextColumn get observationId => text().references(LocalObservations, #id)();
  TextColumn get mediaType => text()(); // image|audio
  TextColumn get localPath => text()(); // ruta absoluta en el dispositivo
  TextColumn get remoteId => text().nullable()(); // id en el server (null = no subido)
  IntColumn get fileSizeBytes => integer().nullable()();
  RealColumn get durationSeconds => real().nullable()(); // solo audio
  TextColumn get mimeType => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
