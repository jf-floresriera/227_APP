import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_models.dart';
import '../../../core/providers/database_provider.dart';
import 'package:drift/drift.dart';

/// Lista de enfermedades: primero desde cache local, luego refresca del API.
final diseasesProvider = FutureProvider<List<LocalDisease>>((ref) async {
  final dao = ref.watch(diseaseDaoProvider);
  final local = await dao.getAll();

  // Si ya hay datos en cache, devueltos de inmediato y refrescar en background.
  if (local.isNotEmpty) {
    _refreshDiseases(ref);
    return local;
  }

  // Primera vez: descargar del API y cachear.
  await _refreshDiseases(ref);
  return dao.getAll();
});

/// Stream reactivo del catálogo de enfermedades (para la UI).
final diseasesStreamProvider = StreamProvider<List<LocalDisease>>((ref) {
  return ref.watch(diseaseDaoProvider).watchAll();
});

Future<void> _refreshDiseases(Ref ref) async {
  try {
    final api = ref.read(apiClientProvider);
    final dao = ref.read(diseaseDaoProvider);
    final remote = await api.getDiseases();
    await dao.replaceAll(remote
        .map((d) => LocalDiseasesCompanion(
              id: Value(d.id),
              name: Value(d.name),
              commonName: Value(d.commonName),
              pathogen: Value(d.pathogen),
              pathogenType: Value(d.pathogenType),
              crop: Value(d.crop),
            ))
        .toList());
  } catch (_) {
    // Sin conexión — usar cache existente.
  }
}
