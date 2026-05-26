import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GraficaColas extends StatelessWidget {
  final List<Map<String, dynamic>> historial;

  const GraficaColas({super.key, required this.historial});

  // 1. EL MÉTODO DE SOPORTE SE DECLARA AQUÍ (A nivel de la clase)
  LineChartBarData _crearLinea(List<Map<String, dynamic>> historial, String llave, Color color) {
    return LineChartBarData(
      spots: historial.map((e) => FlSpot(e['tiempo'] as double, (e[llave] as int).toDouble())).toList(),
      isCurved: true,
      color: color,
      dotData: const FlDotData(show: false),
    );
  }

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
                // 2. Y AQUÍ SIMPLEMENTE LO MANDAS A LLAMAR
                _crearLinea(historial, 'medicosConsulta', Colors.blue),
                _crearLinea(historial, 'medicosUrgencias', Colors.red),
              ],
            ),
          ),
        ),
      ],
    );
  }
}