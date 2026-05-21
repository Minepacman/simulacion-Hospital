// lib/screens/pantalla_configuracion.dart
import 'package:flutter/material.dart';
import '../Controllers/config.dart';

class PantallaConfiguracion extends StatefulWidget {
  const PantallaConfiguracion({super.key});

  @override
  State<PantallaConfiguracion> createState() => _PantallaConfiguracionState();
}

class _PantallaConfiguracionState extends State<PantallaConfiguracion> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para Consulta Externa
  final _citasController =
      TextEditingController(text: Config.citasProgramadasPorDia.toString());
  final _tiempoConsultaController =
      TextEditingController(text: Config.tiempoPromedioConsulta.toString());
  final _medicosConsultaController =
      TextEditingController(text: Config.numeroMedicosConsulta.toString());

  // Controladores para Urgencias
  final _lambdaController =
      TextEditingController(text: Config.lambdaUrgencias.toString());
  final _tiempoUrgenciaController =
      TextEditingController(text: Config.tiempoPromedioUrgencia.toString());
  final _medicosUrgenciasController =
      TextEditingController(text: Config.numeroMedicosUrgencias.toString());

  // Controladores para Hospitalización y Camas
  final _probHospitalizacionController = TextEditingController(
      text: (Config.probUrgenciaAHospitalizacion * 100).toString());
  final _camasController =
      TextEditingController(text: Config.numeroCamas.toString());

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
    super.dispose();
  }

  void _guardarConfiguracion() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        // Asignar los nuevos valores globales
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
          if (isInteger) {
            final n = int.tryParse(value);
            if (n == null || n <= 0)
              return 'Ingrese un número entero válido mayor a 0';
          } else {
            final n = double.tryParse(value);
            if (n == null || n <= 0)
              return 'Ingrese un número decimal válido mayor a 0';
          }
          return null;
        },
      ),
    );
  }
}
