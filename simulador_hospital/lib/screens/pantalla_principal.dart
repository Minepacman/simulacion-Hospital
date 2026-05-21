import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hospital_simulator/Controllers/config.dart';

import '../simulador_hospital.dart';
import 'pantalla_configuracion.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  final SimuladorHospital _simulador = SimuladorHospital();

  String _periodoSeleccionado = 'Días';
  final TextEditingController _cantidadController =
      TextEditingController(text: '1');

  @override
  void dispose() {
    _simulador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulador Hospital',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings), 
            onPressed: _simulador.simulacionEnCurso
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PantallaConfiguracion()),
                    );
                  },
            tooltip: 'Ajustar Parámetros',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _simulador.simulacionEnCurso
                ? null
                : () => _simulador.resetear(),
            tooltip: 'Reiniciar Simulación',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _simulador,
        builder: (context, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBotonSimular(),
                const SizedBox(height: 24),
                if (_simulador.simulacionEnCurso) ...[
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 16),
                  Text(
                    'Réplica ${_simulador.replicaActual} de ${Config.numeroReplicas}...\nSimulando Día ${_simulador.diaActual} de ${_simulador.diasTotalesObjetivo}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ] else if (_simulador.simulacionCompletada) ...[
                  _buildTarjetasResumen(),
                  const SizedBox(height: 24),
                  _buildSeccionGrafica(),
                ] else ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: Text(
                        'Presiona "Iniciar Simulación" para comenzar.\nSe simularán 12 horas de operación (8:00 AM - 8:00 PM).',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBotonSimular() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Configuración de la Ejecución',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _cantidadController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: _periodoSeleccionado,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: ['Días', 'Semanas', 'Meses', 'Años']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: _simulador.simulacionEnCurso
                        ? null
                        : (String? newValue) {
                            setState(() {
                              _periodoSeleccionado = newValue!;
                            });
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _simulador.simulacionEnCurso
                    ? null
                    : () {
                        int cantidad =
                            int.tryParse(_cantidadController.text) ?? 1;
                        if (cantidad <= 0) cantidad = 1;

                        _simulador.ejecutarSimulacionPeriodo(
                            _periodoSeleccionado, cantidad);
                      },
                icon: const Icon(Icons.play_arrow),
                label: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text('Iniciar Simulación',
                      style: TextStyle(fontSize: 16)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTarjetasResumen() {
    final m = _simulador.metricas;
    final intervalos =
        _simulador.intervalos; // Extraemos los intervalos calculados

    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _IndicadorMetrica(
              titulo: 'Consulta Externa (IC 95%)',
              icono: Icons.medical_services_outlined,
              color: Colors.blue,
              datos: [
                'Atendidos/día: ${m.pacientesAtendidosConsulta}',
                'Espera: ${intervalos['esperaConsulta']} min',
                'Cola Máxima: ${m.maximoColaConsulta}',
                'Uso Médicos: ${intervalos['usoConsulta']}%',
              ],
            )),
            const SizedBox(width: 16),
            Expanded(
                child: _IndicadorMetrica(
              titulo: 'Urgencias (IC 95%)',
              icono: Icons.local_hospital_outlined,
              color: Colors.red,
              datos: [
                'Atendidos/día: ${m.pacientesAtendidosUrgencias}',
                'Espera: ${intervalos['esperaUrgencias']} min',
                'Cola Máxima: ${m.maximoColaUrgencias}',
                'Uso Médicos: ${intervalos['usoUrgencias']}%',
              ],
            )),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bed, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Uso de Camas: ${intervalos['usoCamas']}%',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Saturación de Camas: ${intervalos['satCamas']}% | Riesgo Global: ${intervalos['satGlobal']}%',
                  style: TextStyle(
                      color: Colors.red.shade700, fontWeight: FontWeight.w600),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeccionGrafica() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tamaño de Colas en el Tiempo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                _Leyenda(color: Colors.blue, texto: 'Consulta Externa'),
                SizedBox(width: 16),
                _Leyenda(color: Colors.red, texto: 'Urgencias'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text('Minutos de Simulación'),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value % 120 == 0) {
                            return Text(value.toInt().toString());
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text('Pacientes en Cola'),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == value.toInt()) {
                            return Text(value.toInt().toString());
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey.shade300)),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _simulador.historialReloj
                          .map((e) => FlSpot(
                                e['tiempo'] as double,
                                (e['colaConsulta'] as int).toDouble(),
                              ))
                          .toList(),
                      isCurved: true,
                      color: Colors.blue,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                          show: true, color: Colors.blue.withOpacity(0.1)),
                    ),
                    LineChartBarData(
                      spots: _simulador.historialReloj
                          .map((e) => FlSpot(
                                e['tiempo'] as double,
                                (e['colaUrgencias'] as int).toDouble(),
                              ))
                          .toList(),
                      isCurved: true,
                      color: Colors.red,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                          show: true, color: Colors.red.withOpacity(0.1)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndicadorMetrica extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color color;
  final List<String> datos;

  const _IndicadorMetrica({
    required this.titulo,
    required this.icono,
    required this.color,
    required this.datos,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...datos.map((dato) => Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(dato, style: const TextStyle(fontSize: 13)),
                )),
          ],
        ),
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  final Color color;
  final String texto;

  const _Leyenda({required this.color, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
