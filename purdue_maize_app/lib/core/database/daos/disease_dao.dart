import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/disease_tables.dart';

part 'disease_dao.g.dart';

@DriftAccessor(tables: [LocalDiseases])
class DiseaseDao extends DatabaseAccessor<AppDatabase> with _$DiseaseDaoMixin {
  DiseaseDao(super.db);

  Stream<List<LocalDisease>> watchAll() => select(localDiseases).watch();

  Future<List<LocalDisease>> getAll() => select(localDiseases).get();

  Future<LocalDisease?> getById(int id) =>
      (select(localDiseases)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Reemplaza todo el catálogo con la respuesta del API.
  Future<void> replaceAll(List<LocalDiseasesCompanion> diseases) async {
    await transaction(() async {
      await delete(localDiseases).go();
      await batch((b) => b.insertAll(localDiseases, diseases));
    });
  }
}
