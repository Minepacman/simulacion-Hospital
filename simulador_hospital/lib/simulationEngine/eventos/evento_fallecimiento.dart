// lib/simulationEngine/eventos/evento_fallecimiento.dart
import '../evento_simulacion.dart';
import '../../StateManagement/paciente.dart';
import '../../StateManagement/estado_hospital.dart';
import '../../clock/planificador_eventos.dart';
import '../generador_aleatorio.dart';

class EventoFallecimiento extends EventoSimulacion {
  
  EventoFallecimiento({
    required double tiempo,
    required Paciente paciente,
  }) : super(tiempo: tiempo, paciente: paciente);

  @override
  void ejecutar(EstadoHospital estado, PlanificadorEventos planificador, GeneradorAleatorio rng) {
    // CONDICIÓN CRÍTICA: Si el paciente sigue en espera cuando el reloj llega a su límite, fallece
    if (paciente!.estado == EstadoPaciente.enEspera) {
      paciente!.estado = EstadoPaciente.fallecido;
      paciente!.tiempoSalida = tiempo;
      
      // Registrar en estadísticas clínicas
      estado.metricas.registrarFallecimiento(paciente!, estado.camas.enUso);
      estado.registrarPacienteCompletado(paciente!);
      
      // Remover físicamente de la cola de urgencias para que el médico no lo atienda
      estado.colaUrgencias.remove(paciente!);
    }
  }
}