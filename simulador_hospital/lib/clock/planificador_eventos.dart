import 'package:collection/collection.dart';
import '../StateManagement/estado_hospital.dart';
import '../simulationEngine/motor_simulacion.dart';
import 'evento.dart';

class PlanificadorEventos {
  final PriorityQueue<Evento> eventosFuturos = PriorityQueue<Evento>();
  final EstadoHospital estado;
  late final MotorSimulacion motor;

  PlanificadorEventos(this.estado) {
    motor = MotorSimulacion(estado, this);
  }

  void programarEvento(Evento evento) {
    eventosFuturos.add(evento);
  }

  void limpiar() {
    eventosFuturos.clear();
  }

  /// Ejecuta el bucle de eventos para un único día lógico
  void ejecutarDia(double minutosMaximos) {
    motor.generarEventosIniciales();

    while (eventosFuturos.isNotEmpty && estado.reloj < minutosMaximos) {
      final evento = eventosFuturos.removeFirst();
      
      // Sincronizar Ejecución (Paso 4 del diagrama)
      estado.actualizarReloj(evento.tiempo);
      
      // El motor procesa el comportamiento lógico del evento
      motor.procesarEvento(evento);

      // Muestreo discreto de métricas cada minuto entero
      if (estado.reloj.floor() % 1 == 0) {
        estado.registrarSnapshot();
      }
    }
  }
}