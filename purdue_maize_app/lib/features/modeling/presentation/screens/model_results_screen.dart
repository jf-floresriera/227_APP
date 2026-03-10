import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/purdue_theme.dart';

/// Módulo 3 — Visualización de resultados del modelo:
///   • Mapa de riesgo por colores
///   • Curva observado vs. predicho
///   • Métricas (RMSE, R²)
///   • Exportar GeoJSON / CSV
class ModelResultsScreen extends StatefulWidget {
  const ModelResultsScreen({super.key, required this.runId});
  final String runId;

  @override
  State<ModelResultsScreen> createState() => _ModelResultsScreenState();
}

class _ModelResultsScreenState extends State<ModelResultsScreen>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 3, vsync: this);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados del modelo'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: PurdueColors.boilermakerGold,
          tabs: const [
            Tab(text: 'Mapa'),
            Tab(text: 'Curvas'),
            Tab(text: 'Métricas'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _onExport,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'csv', child: Text('Exportar CSV')),
              PopupMenuItem(value: 'geojson', child: Text('Exportar GeoJSON')),
              PopupMenuItem(value: 'png', child: Text('Exportar imagen')),
            ],
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RiskMapTab(runId: widget.runId),
          _CurvesTab(),
          _MetricsTab(),
        ],
      ),
    );
  }

  void _onExport(String format) {
    // TODO: llamar al endpoint /api/v1/modeling/runs/{runId}/results/{format}
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exportando como $format...')),
    );
  }
}

class _RiskMapTab extends StatelessWidget {
  const _RiskMapTab({required this.runId});
  final String runId;

  @override
  Widget build(BuildContext context) {
    // TODO: cargar resultados GeoJSON y pintar marcadores con color de riesgo
    return Stack(
      children: [
        FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(40.4259, -86.9081),
            initialZoom: 14,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'edu.purdue.maize_monitor',
            ),
            // TODO: CircleLayer o MarkerLayer con colores de riesgo desde API
          ],
        ),
        Positioned(
          bottom: 16, right: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Riesgo', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  for (final (label, color) in [
                    ('Muy alto', PurdueColors.riskVeryHigh),
                    ('Alto', PurdueColors.riskHigh),
                    ('Medio', PurdueColors.riskMedium),
                    ('Bajo', PurdueColors.riskLow),
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(label, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CurvesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: cargar series observado/predicho desde API
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Incidencia observada vs. predicha', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                lineBarsData: [
                  // Observado
                  LineChartBarData(
                    spots: const [FlSpot(0, 5), FlSpot(1, 9), FlSpot(2, 14), FlSpot(3, 20)],
                    isCurved: true,
                    color: PurdueColors.agedGold,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                  // Predicho
                  LineChartBarData(
                    spots: const [FlSpot(0, 5), FlSpot(1, 8), FlSpot(2, 15), FlSpot(3, 19)],
                    isCurved: true,
                    color: PurdueColors.riskMedium,
                    barWidth: 2,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(color: PurdueColors.agedGold, label: 'Observado'),
              const SizedBox(width: 24),
              _Legend(color: PurdueColors.riskMedium, label: 'Predicho', dashed: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: cargar métricas reales desde ModelRun.metrics
    final metrics = {'RMSE': '0.124', 'R²': '0.83', 'MAE': '0.098', 'Bias': '-0.011'};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Desempeño del modelo', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        ...metrics.entries.map((e) => Card(
          child: ListTile(
            title: Text(e.key, style: Theme.of(context).textTheme.titleMedium),
            trailing: Text(
              e.value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: PurdueColors.agedGold),
            ),
          ),
        )),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, this.dashed = false});
  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24, height: 3,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
