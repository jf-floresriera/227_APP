import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/purdue_theme.dart';

/// Pantalla de mapa para registrar puntos de muestreo.
/// Muestra el polígono del lote, los puntos generados/manuales y permite
/// navegar a la captura de datos desde cada punto.
class SamplingMapScreen extends StatefulWidget {
  const SamplingMapScreen({super.key, this.sessionId});
  final String? sessionId;

  @override
  State<SamplingMapScreen> createState() => _SamplingMapScreenState();
}

class _SamplingMapScreenState extends State<SamplingMapScreen> {
  final _mapController = MapController();
  final List<LatLng> _samplingPoints = [];
  bool _isAddingPoint = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de muestreo'),
        actions: [
          IconButton(
            icon: Icon(_isAddingPoint ? Icons.touch_app : Icons.add_location),
            tooltip: _isAddingPoint ? 'Modo: tocando para agregar' : 'Agregar punto manualmente',
            onPressed: () => setState(() => _isAddingPoint = !_isAddingPoint),
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _saveSession,
            tooltip: 'Guardar sesión',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(40.4259, -86.9081), // Purdue, West Lafayette
              initialZoom: 15,
              onTap: _isAddingPoint ? (_, latlng) => _addPoint(latlng) : null,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'edu.purdue.maize_monitor',
              ),
              // TODO: PolygonLayer para el polígono del lote
              MarkerLayer(
                markers: _samplingPoints.asMap().entries.map((e) {
                  return Marker(
                    point: e.value,
                    width: 36,
                    height: 36,
                    child: GestureDetector(
                      onTap: () => _onPointTap(e.key, e.value),
                      child: const Icon(Icons.circle, color: PurdueColors.agedGold, size: 28),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          if (_isAddingPoint)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                color: PurdueColors.boilermakerGold,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.touch_app, color: PurdueColors.black),
                      const SizedBox(width: 8),
                      Text(
                        'Toca el mapa para agregar un punto',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomSheet: _PointsCountBar(count: _samplingPoints.length),
    );
  }

  void _addPoint(LatLng latlng) {
    setState(() => _samplingPoints.add(latlng));
  }

  void _onPointTap(int index, LatLng latlng) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _PointActionSheet(
        index: index,
        latlng: latlng,
        onCapture: () {
          Navigator.pop(context);
          // TODO: navegar a captura de datos con el punto
        },
        onDelete: () {
          setState(() => _samplingPoints.removeAt(index));
          Navigator.pop(context);
        },
      ),
    );
  }

  void _saveSession() {
    // TODO: llamar al provider para guardar la sesión
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesión guardada localmente')),
    );
  }
}

class _PointsCountBar extends StatelessWidget {
  const _PointsCountBar({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: PurdueColors.black,
      child: Row(
        children: [
          const Icon(Icons.location_on, color: PurdueColors.boilermakerGold),
          const SizedBox(width: 8),
          Text('$count punto${count != 1 ? 's' : ''}', style: const TextStyle(color: PurdueColors.white)),
        ],
      ),
    );
  }
}

class _PointActionSheet extends StatelessWidget {
  const _PointActionSheet({
    required this.index,
    required this.latlng,
    required this.onCapture,
    required this.onDelete,
  });

  final int index;
  final LatLng latlng;
  final VoidCallback onCapture;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Punto #${index + 1}', style: Theme.of(context).textTheme.titleMedium),
          Text(
            '${latlng.latitude.toStringAsFixed(6)}, ${latlng.longitude.toStringAsFixed(6)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Registrar datos'),
                  onPressed: onCapture,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: PurdueColors.riskHigh),
                onPressed: onDelete,
                tooltip: 'Eliminar punto',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
