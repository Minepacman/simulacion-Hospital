// lib/screens/pantalla_configuracion.dart
import 'package:flutter/material.dart';
import '../DataProvider/config.dart';

class PantallaConfiguracion extends StatefulWidget {
  const PantallaConfiguracion({super.key});

  @override
  State<PantallaConfiguracion> createState() => _PantallaConfiguracionState();
}

class _PantallaConfiguracionState extends State<PantallaConfiguracion> {
  final _formKey = GlobalKey<FormState>();

  final _citasController =
      TextEditingController(text: Config.citasProgramadasPorDia.toString());
  final _tiempoConsultaController =
      TextEditingController(text: Config.tiempoPromedioConsulta.toString());
  final _medicosConsultaController =
      TextEditingController(text: Config.numeroMedicosConsulta.toString());

  final _lambdaController =
      TextEditingController(text: Config.lambdaUrgencias.toString());
  final _tiempoUrgenciaController =
      TextEditingController(text: Config.tiempoPromedioUrgencia.toString());
  final _medicosUrgenciasController =
      TextEditingController(text: Config.numeroMedicosUrgencias.toString());

  final _probHospitalizacionController = TextEditingController(
      text: (Config.probUrgenciaAHospitalizacion * 100).toString());
  final _camasController =
      TextEditingController(text: Config.numeroCamas.toString());

  final _rojoController = TextEditingController(
      text: (Config.probabilidadesTriage[0] * 100).toStringAsFixed(1));
  final _naranjaController = TextEditingController(
      text: (Config.probabilidadesTriage[1] * 100).toStringAsFixed(1));
  final _amarilloController = TextEditingController(
      text: (Config.probabilidadesTriage[2] * 100).toStringAsFixed(1));
  final _verdeController = TextEditingController(
      text: (Config.probabilidadesTriage[3] * 100).toStringAsFixed(1));
  final _azulController = TextEditingController(
      text: (Config.probabilidadesTriage[4] * 100).toStringAsFixed(1));

  final _replicasController =
      TextEditingController(text: Config.numeroReplicas.toString());
  @override
  void dispose() {
    _citasController.dispose();
    _tiempoConsultaController.dispose();
    _medicosConsultaController.dispose();
    _lambdaController.dispose();
    _tiempoUrgenciaController.dispose();
    _medicosUrgenciasController.dispose();
    _probHospitalizacionController.dispose();
    _camasController.dispose();

    _rojoController.dispose();
    _naranjaController.dispose();
    _amarilloController.dispose();
    _verdeController.dispose();
    _azulController.dispose();
    super.dispose();
  }

  void _guardarConfiguracion() {
    if (_formKey.currentState!.validate()) {
      final pRojo = double.parse(_rojoController.text);
      final pNaranja = double.parse(_naranjaController.text);
      final pAmarillo = double.parse(_amarilloController.text);
      final pVerde = double.parse(_verdeController.text);
      final pAzul = double.parse(_azulController.text);
      Config.numeroReplicas = int.parse(_replicasController.text);
      final sumaTotal = pRojo + pNaranja + pAmarillo + pVerde + pAzul;

      if ((sumaTotal - 100.0).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(
                'Error: La suma de las probabilidades de Triage debe ser exactamente 100% (Actual: ${sumaTotal.toStringAsFixed(1)}%)'),
          ),
        );
        return;
      }

      setState(() {
        Config.citasProgramadasPorDia = int.parse(_citasController.text);
        Config.tiempoPromedioConsulta =
            double.parse(_tiempoConsultaController.text);
        Config.numeroMedicosConsulta =
            int.parse(_medicosConsultaController.text);

        Config.lambdaUrgencias = double.parse(_lambdaController.text);
        Config.tiempoPromedioUrgencia =
            double.parse(_tiempoUrgenciaController.text);
        Config.numeroMedicosUrgencias =
            int.parse(_medicosUrgenciasController.text);

        Config.probUrgenciaAHospitalizacion =
            double.parse(_probHospitalizacionController.text) / 100.0;
        Config.numeroCamas = int.parse(_camasController.text);

        Config.probabilidadesTriage = [
          pRojo / 100.0,
          pNaranja / 100.0,
          pAmarillo / 100.0,
          pVerde / 100.0,
          pAzul / 100.0,
        ];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración guardada exitosamente')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Parámetros',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSeccionCard(
                titulo: 'Consulta Externa',
                color: Colors.blue,
                icon: Icons.medical_services,
                children: [
                  _buildInputField(
                    label: 'Número de Réplicas (Intervalo Confianza)',
                    controller: _replicasController,
                    isInteger: true,
                  ),
                  _buildInputField(
                    label: 'Citas programadas por día',
                    controller: _citasController,
                    isInteger: true,
                  ),
                  _buildInputField(
                    label: 'Tiempo promedio de consulta (min)',
                    controller: _tiempoConsultaController,
                  ),
                  _buildInputField(
                    label: 'Número de médicos asignados',
                    controller: _medicosConsultaController,
                    isInteger: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSeccionCard(
                titulo: 'Urgencias (Proceso Poisson)',
                color: Colors.red,
                icon: Icons.local_hospital,
                children: [
                  _buildInputField(
                    label: 'Tasa de llegada (λ pacientes/min)',
                    controller: _lambdaController,
                  ),
                  _buildInputField(
                    label: 'Tiempo promedio de atención (min)',
                    controller: _tiempoUrgenciaController,
                  ),
                  _buildInputField(
                    label: 'Número de médicos en urgencias',
                    controller: _medicosUrgenciasController,
                    isInteger: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSeccionCard(
                titulo: 'Distribución de Triage (%)',
                color: Colors.orange.shade700,
                icon: Icons.gavel,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      'Asigna el porcentaje de aparición para cada nivel. La suma total de los 5 campos debe dar exactamente 100%.',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                  _buildInputField(
                    label: 'Nivel 1 - Reanimación (Rojo) %',
                    controller: _rojoController,
                  ),
                  _buildInputField(
                    label: 'Nivel 2 - Emergencia (Naranja) %',
                    controller: _naranjaController,
                  ),
                  _buildInputField(
                    label: 'Nivel 3 - Urgencia (Amarillo) %',
                    controller: _amarilloController,
                  ),
                  _buildInputField(
                    label: 'Nivel 4 - Urgencia Menor (Verde) %',
                    controller: _verdeController,
                  ),
                  _buildInputField(
                    label: 'Nivel 5 - Sin Urgencia (Azul) %',
                    controller: _azulController,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSeccionCard(
                titulo: 'Hospitalización y Recursos',
                color: Colors.green,
                icon: Icons.hotel,
                children: [
                  _buildInputField(
                    label: 'Probabilidad de internado desde Urgencias (%)',
                    controller: _probHospitalizacionController,
                  ),
                  _buildInputField(
                    label: 'Número total de camas disponibles',
                    controller: _camasController,
                    isInteger: true,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _guardarConfiguracion,
                icon: const Icon(Icons.save),
                label: const Padding(
                  padding: EdgeInsets.all(14.0),
                  child: Text('Guardar Cambios',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionCard({
    required String titulo,
    required Color color,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool isInteger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Este campo es obligatorio';
          }
          final n = double.tryParse(value);
          if (n == null || n < 0)
            return 'Ingrese un valor válido mayor o igual a 0';

          if (isInteger) {
            final idx = int.tryParse(value);
            if (idx == null || idx <= 0)
              return 'Ingrese un número entero mayor a 0';
          }
          return null;
        },
      ),
    );
  }
}
