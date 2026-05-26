import '../../DataProvider/config.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class FuentePacientes extends DataGridSource {
  List<DataGridRow> _filasPacientes = [];

FuentePacientes({required List<Map<String, dynamic>> pacientesData}) {
    _filasPacientes = pacientesData.map<DataGridRow>((p) {
      
      String estadoFinal = p['estado_final'] ?? '';
      String resultadoVital = 'Saludable';
      if (estadoFinal == 'fallecido') {
        resultadoVital = 'Fallecio unu';
      } else if (p['area'] == 'urgencias' || p['area'] == 'hospitalizacion') {
        resultadoVital = 'Sobrevivio UWU';
      } else if (estadoFinal == 'citaPerdida') {
        resultadoVital = 'No atendido';
      }

      double tiempoLlegada = p['tiempo_llegada'] ?? 0.0;
      double tiempoSalida = p['tiempo_salida'] ?? 0.0;
      double diasInternado = 0.0;
      
      if (tiempoSalida > 0.0 && estadoFinal != 'citaPerdida' && estadoFinal != 'fallecido') {
         double tiempoTotal = tiempoSalida - tiempoLlegada;
         diasInternado = tiempoTotal / Config.minutosSimulacion;
      }

      return DataGridRow(cells: [
        DataGridCell<int>(columnName: 'id', value: p['paciente_id_local']),
        DataGridCell<int>(columnName: 'dia', value: p['dia_simulacion'] ?? 1),
        DataGridCell<String>(columnName: 'area', value: p['area']),
        DataGridCell<String>(columnName: 'triage', value: p['triage']),
        DataGridCell<String>(columnName: 'resultado', value: resultadoVital), // NUEVA
        DataGridCell<double>(columnName: 'dias_internado', value: diasInternado), // NUEVA
        DataGridCell<double>(columnName: 'espera', value: p['tiempo_espera']),
        DataGridCell<String>(columnName: 'estado', value: estadoFinal),
      ]);
    }).toList();
  }

  @override
  List<DataGridRow> get rows => _filasPacientes;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((dataGridCell) {
        
        Color? colorFondo;
        Color colorTexto = Colors.black;

        if (row.getCells().any((celda) => celda.value == 'fallecido')) {
          colorFondo = Colors.red.shade50;
          if (dataGridCell.columnName == 'resultado') colorTexto = Colors.red.shade900;
        } else if (row.getCells().any((celda) => celda.value == 'citaPerdida')) {
          colorFondo = Colors.orange.shade50;
        }

        return Container(
          color: colorFondo,
          alignment: (dataGridCell.value is num) ? Alignment.centerRight : Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            dataGridCell.value is double 
              ? (dataGridCell.value as double).toStringAsFixed(2) 
              : dataGridCell.value.toString(),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colorTexto, fontWeight: dataGridCell.columnName == 'resultado' ? FontWeight.bold : FontWeight.normal),
          ),
        );
      }).toList(),
    );
  }
}