import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/purdue_theme.dart';

/// Módulo 2b — Data Explorer: filtros espacio-temporales y visualizaciones.
class DataExplorerScreen extends StatefulWidget {
  const DataExplorerScreen({super.key});

  @override
  State<DataExplorerScreen> createState() => _DataExplorerScreenState();
}

class _DataExplorerScreenState extends State<DataExplorerScreen>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 2, vsync: this);

  // Filtros activos
  DateTimeRange? _dateRange;
  String? _selectedDisease;
  String? _selectedField;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Explorer'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: PurdueColors.boilermakerGold,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Gráficas'),
            Tab(icon: Icon(Icons.table_rows_outlined), text: 'Tabla'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFiltersSheet,
            tooltip: 'Filtros',
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: _exportCSV,
            tooltip: 'Exportar CSV',
          ),
        ],
      ),
      body: Column(
        children: [
          _ActiveFiltersBar(
            dateRange: _dateRange,
            disease: _selectedDisease,
            field: _selectedField,
            onClear: () => setState(() {
              _dateRange = null;
              _selectedDisease = null;
              _selectedField = null;
            }),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ChartsTab(),
                _TableTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFiltersSheet(BuildContext context) {
    // TODO: bottom sheet con DateRangePicker, selección de enfermedad y parcela
  }

  void _exportCSV() {
    // TODO: generar CSV desde datos filtrados y compartir via Share plugin
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exportando datos...')),
    );
  }
}

class _ActiveFiltersBar extends StatelessWidget {
  const _ActiveFiltersBar({
    required this.dateRange,
    required this.disease,
    required this.field,
    required this.onClear,
  });

  final DateTimeRange? dateRange;
  final String? disease;
  final String? field;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasFilters = dateRange != null || disease != null || field != null;
    if (!hasFilters) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: PurdueColors.sandstone,
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 16, color: PurdueColors.agedGold),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                if (disease != null) Chip(label: Text(disease!), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                if (field != null) Chip(label: Text(field!), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ],
            ),
          ),
          TextButton(onPressed: onClear, child: const Text('Limpiar')),
        ],
      ),
    );
  }
}

class _ChartsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: cargar datos reales desde Riverpod provider
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Incidencia vs. tiempo', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
              titlesData: const FlTitlesData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: const [
                    FlSpot(0, 5), FlSpot(1, 8), FlSpot(2, 12),
                    FlSpot(3, 18), FlSpot(4, 25), FlSpot(5, 22),
                  ],
                  isCurved: true,
                  color: PurdueColors.agedGold,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Severidad por enfermedad', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              barGroups: [
                BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 35, color: PurdueColors.riskHigh)]),
                BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 20, color: PurdueColors.riskMedium)]),
                BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 8, color: PurdueColors.riskLow)]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TableTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: DataTable con datos filtrados desde Riverpod
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Fecha')),
          DataColumn(label: Text('Parcela')),
          DataColumn(label: Text('Enfermedad')),
          DataColumn(label: Text('Incidencia %')),
          DataColumn(label: Text('Severidad')),
        ],
        rows: const [],
      ),
    );
  }
}
