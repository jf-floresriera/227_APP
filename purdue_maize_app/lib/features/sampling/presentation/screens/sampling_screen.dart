import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/purdue_theme.dart';

/// Módulo 1 — Pantalla principal de Sampling.
/// Muestra los tipos de esquema de muestreo disponibles y las sesiones recientes.
class SamplingScreen extends StatelessWidget {
  const SamplingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sampling'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {},
            tooltip: 'Historial de sesiones',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Nueva sesión de muestreo', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Selecciona el tipo de esquema para comenzar.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          _SamplingTypeGrid(
            onSelect: (type) => context.go('/sampling/map?type=$type'),
          ),
          const SizedBox(height: 32),
          Text('Sesiones recientes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const _RecentSessionsList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: PurdueColors.boilermakerGold,
        foregroundColor: PurdueColors.black,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Nueva sesión'),
        onPressed: () => _showNewSessionDialog(context),
      ),
    );
  }

  void _showNewSessionDialog(BuildContext context) {
    // TODO: bottom sheet con selector de parcela y tipo de muestreo
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _NewSessionSheet(),
    );
  }
}

class _SamplingTypeGrid extends StatelessWidget {
  const _SamplingTypeGrid({required this.onSelect});
  final void Function(String type) onSelect;

  static const _types = [
    (icon: Icons.grid_on, label: 'Sistemático', subtitle: 'Grilla regular', key: 'systematic'),
    (icon: Icons.shuffle, label: 'Aleatorio', subtitle: 'Puntos al azar', key: 'random'),
    (icon: Icons.linear_scale, label: 'Transectos', subtitle: 'Líneas de muestreo', key: 'transect'),
    (icon: Icons.warning_amber, label: 'Dirigido', subtitle: 'Zonas con sospecha', key: 'directed'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: _types.map((t) {
        return InkWell(
          onTap: () => onSelect(t.key),
          borderRadius: BorderRadius.circular(12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(t.icon, size: 32, color: PurdueColors.agedGold),
                  const SizedBox(height: 8),
                  Text(t.label, style: Theme.of(context).textTheme.titleMedium),
                  Text(t.subtitle, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RecentSessionsList extends StatelessWidget {
  const _RecentSessionsList();

  @override
  Widget build(BuildContext context) {
    // TODO: conectar con Riverpod provider → API
    return const Center(child: Text('No hay sesiones recientes.'));
  }
}

class _NewSessionSheet extends StatelessWidget {
  const _NewSessionSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nueva sesión', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          // TODO: selector de parcela, fecha, tipo
          const TextField(decoration: InputDecoration(labelText: 'Parcela')),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abrir mapa'),
            ),
          ),
        ],
      ),
    );
  }
}
