import 'package:drift/drift.dart';

/// Catálogo de enfermedades cacheado desde el API.
class LocalDiseases extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get commonName => text().nullable()();
  TextColumn get pathogen => text().nullable()();
  TextColumn get pathogenType => text().nullable()(); // fungal|bacterial|viral
  TextColumn get crop => text().withDefault(const Constant('maize'))();

  @override
  Set<Column> get primaryKey => {id};
}
