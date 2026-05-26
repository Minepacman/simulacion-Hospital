// lib/UI/pantalla_historial_pacientes.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../DataProvider/db_helper.dart';
import 'tablas/fuente_pacientes.dart';

class PantallaHistorialPacientes extends StatefulWidget {
  final int simulacionId;

  const PantallaHistorialPacientes({super.key, required this.simulacionId});

  @override
  State<PantallaHistorialPacientes> createState() => _PantallaHistorialPacientesState();
}

class _PantallaHistorialPacientesState extends State<PantallaHistorialPacientes> {
  FuentePacientes? _fuentePacientes;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final datos = await DBHelper().obtenerPacientesPorSimulacion(widget.simulacionId);
    setState(() {
      _fuentePacientes = FuentePacientes(pacientesData: datos);
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registros de la Simulación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar a Excel',
            onPressed: () {
              // TODO: Implementaremos la exportación a Excel aquí
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exportación a Excel en construcción...')),
              );
            },
          )
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SfDataGrid(
              source: _fuentePacientes!,
              allowSorting: true,          // ¡Permite ordenar con un toque!
              allowMultiColumnSorting: true,
              columnWidthMode: ColumnWidthMode.auto,
              columns: <GridColumn>[
                GridColumn(
                  columnName: 'id',
                  width: 80,
                  label: _construirHeader('ID'),
                ),
                GridColumn(
                  columnName: 'dia',
                  width: 80,
                  label: _construirHeader('Día'),
                ),
                GridColumn(
                  columnName: 'area',
                  label: _construirHeader('Área'),
                ),
                GridColumn(
                  columnName: 'triage',
                  label: _construirHeader('Triage'),
                ),
                GridColumn(
                  columnName: 'resultado',
                  label: _construirHeader('Desempeño Vital'),
                ),
                GridColumn(
                  columnName: 'dias_internado',
                  label: _construirHeader('Días Estancia'),
                ),
                GridColumn(
                  columnName: 'espera',
                  label: _construirHeader('Min. Espera'),
                ),
                GridColumn(
                  columnName: 'estado',
                  label: _construirHeader('Estado Final'),
                ),
              ],
            ),
    );
  }

  Widget _construirHeader(String titulo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      alignment: Alignment.centerLeft,
      color: Colors.blue.shade50,
      child: Text(
        titulo,
        style: const TextStyle(fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}