import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GraficaColas extends StatelessWidget {
  final List<Map<String, dynamic>> historial;

  const GraficaColas({super.key, required this.historial});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tamaño de Colas en el Tiempo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        SizedBox(
          height: 250,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
              lineBarsData: [
                LineChartBarData(
                  spots: historial.map((e) => FlSpot(e['tiempo'] as double, (e['colaConsulta'] as int).toDouble())).toList(),
                  isCurved: true,
                  color: Colors.blue,
                  dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: historial.map((e) => FlSpot(e['tiempo'] as double, (e['colaUrgencias'] as int).toDouble())).toList(),
                  isCurved: true,
                  color: Colors.red,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}