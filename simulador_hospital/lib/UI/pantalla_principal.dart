import 'package:flutter/material.dart';

import '../DataProvider/config.dart';
import '../StateManagement/estado_hospital.dart';
import '../vizualizroengine/grafica_colas.dart';
import 'pantalla_configuracion.dart';
import 'pantalla_historial_pacientes.dart'; 

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  final EstadoHospital _estado = EstadoHospital();

  String _periodoSeleccionado = 'Días';
  final TextEditingController _cantidadController = TextEditingController(text: '1');

  @override
  void dispose() {
    _estado.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulador Hospital', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _estado.simulacionEnCurso
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PantallaConfiguracion()),
                    );
                  },
            tooltip: 'Ajustar Parámetros',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _estado.simulacionEnCurso ? null : () => _estado.inicializarRecursos(),
            tooltip: 'Reiniciar Simulación',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _estado,
        builder: (context, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBotonSimular(),
                const SizedBox(height: 24),
                if (_estado.simulacionEnCurso) ...[
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 16),
                  Text(
                    'Réplica ${_estado.replicaActual} de ${Config.numeroReplicas}...\nSimulando Día ${_estado.diaActual} de ${_estado.diasTotalesObjetivo}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ] else if (_estado.simulacionCompletada) ...[
                  _buildTarjetasResumen(),
                  const SizedBox(height: 24),

                  GraficaColas(historial: _estado.historialReloj),

                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_estado.simulacionIdActual != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PantallaHistorialPacientes(
                              simulacionId: _estado.simulacionIdActual!,
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.table_view),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text('Ver Registros de Pacientes', style: TextStyle(fontSize: 16)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
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
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: ['Días', 'Semanas', 'Meses', 'Años'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: _estado.simulacionEnCurso
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
                onPressed: _estado.simulacionEnCurso
                    ? null
                    : () {
                        int cantidad = int.tryParse(_cantidadController.text) ?? 1;
                        if (cantidad <= 0) cantidad = 1;
                        _estado.ejecutarSimulacionPeriodo(_periodoSeleccionado, cantidad);
                      },
                icon: const Icon(Icons.play_arrow),
                label: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text('Iniciar Simulación', style: TextStyle(fontSize: 16)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTarjetasResumen() {
    final m = _estado.metricas;
    final intervalos = _estado.intervalos;

    double tasaMortalidad = 0.0;
    int totalAtendidosYFallecidos = m.pacientesAtendidosUrgencias + m.totalFallecidos;
    if (totalAtendidosYFallecidos > 0) {
      tasaMortalidad = (m.totalFallecidos / totalAtendidosYFallecidos) * 100;
    }

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
              ),
            ),
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
                  // NUEVA LÍNEA DE MORTALIDAD:
                  'Fallecidos: ${m.totalFallecidos} (${tasaMortalidad.toStringAsFixed(1)}%)', 
                ],
              ),
            ),
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Saturación de Camas: ${intervalos['satCamas']}% | Riesgo Global: ${intervalos['satGlobal']}%',
                  style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600),
                )
              ],
            ),
          ),
        ),
      ],
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
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