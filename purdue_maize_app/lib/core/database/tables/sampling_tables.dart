import 'package:drift/drift.dart';

/// Sesiones de muestreo guardadas localmente.
class LocalSamplingSessions extends Table {
  TextColumn get id => text()();
  TextColumn get fieldId => text()();
  TextColumn get fieldName => text().withDefault(const Constant(''))(); // cached for display
  TextColumn get samplingType => text()(); // systematic|random|transect|directed
  DateTimeColumn get sessionDate => dateTime()();
  TextColumn get notes => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get createdBy => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Puntos georreferenciados dentro de una sesión.
class LocalSamplingPoints extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(LocalSamplingSessions, #id)();
  TextColumn get pointCode => text().nullable()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get altitudeM => real().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get recordedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
