// lib/clock/planificador_eventos.dart
import 'package:collection/collection.dart';
import '../StateManagement/estado_hospital.dart';
import '../simulationEngine/motor_simulacion.dart';
import '../simulationEngine/evento_simulacion.dart'; 

class PlanificadorEventos {
  final PriorityQueue<EventoSimulacion> eventosFuturos = PriorityQueue<EventoSimulacion>();
  final EstadoHospital estado;
  late final MotorSimulacion motor;

  PlanificadorEventos(this.estado) {
    motor = MotorSimulacion(estado, this);
  }

  void programarEvento(EventoSimulacion evento) {
    eventosFuturos.add(evento);
  }

  void limpiar() {
    eventosFuturos.clear();
  }

  void ejecutarDia(double minutosMaximos) {
    motor.generarEventosIniciales();
    
    // Rastreador para evitar guardar miles de snapshots innecesarios
    int ultimoMinutoRegistrado = -1;

    while (eventosFuturos.isNotEmpty && estado.reloj < minutosMaximos) {
      final evento = eventosFuturos.removeFirst();
      
      estado.actualizarReloj(evento.tiempo);
      evento.ejecutar(estado, this, motor.rng);

      // SOLUCIÓN: Solo guardamos snapshot si realmente avanzamos de minuto
      int minutoActual = estado.reloj.floor();
      if (minutoActual > ultimoMinutoRegistrado) {
        ultimoMinutoRegistrado = minutoActual;
        estado.registrarSnapshot();
      }
    }
  }
}