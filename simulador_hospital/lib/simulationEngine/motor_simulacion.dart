// lib/simulationEngine/motor_simulacion.dart
import 'package:hospital_simulator/DataProvider/config.dart';
import 'package:hospital_simulator/StateManagement/estado_hospital.dart';
import 'package:hospital_simulator/StateManagement/paciente.dart';
import 'package:hospital_simulator/clock/planificador_eventos.dart';
import 'package:hospital_simulator/simulationEngine/generador_aleatorio.dart';
import 'package:hospital_simulator/simulationEngine/eventos/evento_llegada.dart'; 

class MotorSimulacion {
  final EstadoHospital estado;
  final PlanificadorEventos planificador;
  late final GeneradorAleatorio rng;

  MotorSimulacion(this.estado, this.planificador) {
    rng = GeneradorAleatorio(DateTime.now().millisecondsSinceEpoch % 100000);
  }

  void generarEventosIniciales() {
    _generarCitasProgramadas();
    
    double tiempoLlegada = rng.exponencial(Config.lambdaUrgencias);
    planificador.programarEvento(EventoLlegada(
      tiempo: tiempoLlegada, 
      nodoInicialId: 'urgenciasAtencion'
    ));
  }

  void _generarCitasProgramadas() {
    int numCitas = Config.citasProgramadasPorDia;
    double intervalo = Config.minutosSimulacion / numCitas;
    
    for (int i = 0; i < numCitas; i++) {
      double horaProgramada = i * intervalo;
      
      double retraso = rng.normal(0, Config.desviacionRetraso);
      double tiempoRealLlegada = horaProgramada + retraso;
      
      Paciente paciente = Paciente(
        id: estado.contadorPacientes++,
        area: AreaHospital.consultaExterna,
        tiempoLlegada: tiempoRealLlegada,
        diaSimulacion: estado.diaActual,
        horaCitaProgramada: horaProgramada,
      );
      paciente.retrasoReal = retraso;

      if (retraso > Config.limiteRetrasoPermitido) {
        paciente.estado = EstadoPaciente.citaPerdida;
        paciente.tiempoSalida = tiempoRealLlegada; 
        
        estado.metricas.citasPerdidas++;
        estado.registrarPacienteCompletado(paciente);
        continue; 
      }

      planificador.programarEvento(EventoLlegada(
        tiempo: tiempoRealLlegada,
        paciente: paciente,
        nodoInicialId: 'consultaExterna',
      ));
    }
  }
}