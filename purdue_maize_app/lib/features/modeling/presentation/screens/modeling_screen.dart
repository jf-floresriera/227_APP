import 'package:flutter/material.dart';
import '../../../../core/theme/purdue_theme.dart';

/// Módulo 3 — Configuración y ejecución de modelos predictivos.
class ModelingScreen extends StatefulWidget {
  const ModelingScreen({super.key});

  @override
  State<ModelingScreen> createState() => _ModelingScreenState();
}

class _ModelingScreenState extends State<ModelingScreen> {
  String? _selectedField;
  String? _selectedDisease;
  String _modelType = 'random_forest';
  int _horizonDays = 14;

  // Variables de entrada activas
  bool _useClimate = true;
  bool _useHistory = true;
  bool _useImagery = false;
  bool _useManagement = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modeling'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {},
            tooltip: 'Ejecuciones anteriores',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Configurar modelo', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Selecciona parcela, enfermedad y variables de entrada para ejecutar el modelo.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Selección de parcela y enfermedad
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Objetivo', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  // TODO: dropdown con parcelas desde API
                  DropdownButtonFormField<String>(
                    value: _selectedField,
                    decoration: const InputDecoration(labelText: 'Parcela'),
                    items: const [DropdownMenuItem(value: 'field_1', child: Text('Parcela Norte'))],
                    onChanged: (v) => setState(() => _selectedField = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedDisease,
                    decoration: const InputDecoration(labelText: 'Enfermedad objetivo'),
                    items: const [
                      DropdownMenuItem(value: 'nlb', child: Text('Northern Corn Leaf Blight')),
                      DropdownMenuItem(value: 'gls', child: Text('Gray Leaf Spot')),
                      DropdownMenuItem(value: 'cr', child: Text('Common Rust')),
                      DropdownMenuItem(value: 'tar_spot', child: Text('Tar Spot')),
                    ],
                    onChanged: (v) => setState(() => _selectedDisease = v),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Tipo de modelo
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tipo de modelo', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ..._modelOptions.map((opt) => RadioListTile<String>(
                    value: opt.key,
                    groupValue: _modelType,
                    title: Text(opt.label),
                    subtitle: Text(opt.description, style: Theme.of(context).textTheme.bodyMedium),
                    onChanged: (v) => setState(() => _modelType = v!),
                    activeColor: PurdueColors.boilermakerGold,
                    contentPadding: EdgeInsets.zero,
                  )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Horizonte temporal
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Horizonte de predicción', style: Theme.of(context).textTheme.titleMedium),
                  Slider(
                    value: _horizonDays.toDouble(),
                    min: 7, max: 60, divisions: 10,
                    label: '$_horizonDays días',
                    activeColor: PurdueColors.boilermakerGold,
                    onChanged: (v) => setState(() => _horizonDays = v.round()),
                  ),
                  Center(child: Text('$_horizonDays días hacia adelante')),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Variables de entrada
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Variables de entrada', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Datos climáticos'),
                    subtitle: const Text('Temperatura, humedad, precipitación'),
                    value: _useClimate,
                    onChanged: (v) => setState(() => _useClimate = v),
                    activeColor: PurdueColors.boilermakerGold,
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('Historial de incidencia'),
                    subtitle: const Text('Observaciones previas de campo'),
                    value: _useHistory,
                    onChanged: (v) => setState(() => _useHistory = v),
                    activeColor: PurdueColors.boilermakerGold,
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('Imágenes (UAV / satélite)'),
                    subtitle: const Text('Índices espectrales NDVI, NDRE'),
                    value: _useImagery,
                    onChanged: (v) => setState(() => _useImagery = v),
                    activeColor: PurdueColors.boilermakerGold,
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('Datos de manejo'),
                    subtitle: const Text('Fungicidas, cultivar, riego'),
                    value: _useManagement,
                    onChanged: (v) => setState(() => _useManagement = v),
                    activeColor: PurdueColors.boilermakerGold,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Ejecutar modelo'),
            onPressed: (_selectedField != null && _selectedDisease != null) ? _submit : null,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _submit() {
    // TODO: llamar a Riverpod provider → POST /api/v1/modeling/runs
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modelo enviado — en ejecución...')),
    );
  }
}

const _modelOptions = [
  (key: 'regression', label: 'Regresión logística', description: 'Rápido, interpretable, pocos datos.'),
  (key: 'random_forest', label: 'Random Forest', description: 'Balanceo entre precisión e interpretabilidad.'),
  (key: 'lstm_spatiotemporal', label: 'LSTM Espacio-temporal', description: 'Alta capacidad; requiere más datos históricos.'),
];
