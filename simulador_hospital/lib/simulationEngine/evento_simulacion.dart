import '../StateManagement/estado_hospital.dart';
import '../clock/planificador_eventos.dart';
import 'generador_aleatorio.dart';
import '../StateManagement/paciente.dart';

abstract class EventoSimulacion implements Comparable<EventoSimulacion> {
  final double tiempo;
  final Paciente? paciente;

  EventoSimulacion({required this.tiempo, this.paciente});

  /// Cada evento implementa su propia lógica operativa sobre el estado
  void ejecutar(EstadoHospital estado, PlanificadorEventos planificador, GeneradorAleatorio rng);

  @override
  int compareTo(EventoSimulacion otro) => tiempo.compareTo(otro.tiempo);
}