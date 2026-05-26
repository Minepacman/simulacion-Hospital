// lib/simulationEngine/eventos/evento_llegada.dart
import 'package:hospital_simulator/simulationEngine/evento_simulacion.dart';
import 'package:hospital_simulator/simulationEngine/nodo_servicio.dart';
import 'package:hospital_simulator/simulationEngine/generador_aleatorio.dart';
import 'package:hospital_simulator/StateManagement/paciente.dart';
import 'package:hospital_simulator/StateManagement/estado_hospital.dart';
import 'package:hospital_simulator/clock/planificador_eventos.dart';
import 'package:hospital_simulator/DataProvider/config.dart';
import 'package:hospital_simulator/simulationEngine/eventos/evento_fin_atencion.dart';
import 'package:hospital_simulator/simulationEngine/eventos/evento_fallecimiento.dart'; 

class EventoLlegada extends EventoSimulacion {
  final String nodoInicialId;

  // Constructor optimizado con la sintaxis moderna de Dart
  EventoLlegada({
    required super.tiempo,
    super.paciente,
    required this.nodoInicialId,
  });

  @override
  void ejecutar(EstadoHospital estado, PlanificadorEventos planificador, GeneradorAleatorio rng) {
    final pac = paciente ?? Paciente(
      id: estado.contadorPacientes++, 
      area: _mapearArea(nodoInicialId), 
      tiempoLlegada: tiempo,
      diaSimulacion: estado.diaActual
    );

    if (pac.area == AreaHospital.urgencias && pac.triage == null) {
      pac.triage = _determinarTriage(rng);
      
      pac.calcularLimiteSupervivencia(rng);
      if (pac.limiteSupervivenciaEspera != double.infinity && 
          pac.limiteSupervivenciaEspera! < Config.minutosSimulacion) {
        planificador.programarEvento(EventoFallecimiento(
          tiempo: pac.limiteSupervivenciaEspera!,
          paciente: pac,
        ));
      }
    }
    
    final nodo = Config.grafoHospital[nodoInicialId]!;
    
    estado.encolarPaciente(nodo.recursoAsociado, pac);
    
    _intentarAsignarRecurso(nodo, estado, planificador, rng);

    if (nodoInicialId == 'urgenciasAtencion') {
      double proximaLlegada = tiempo + rng.exponencial(Config.lambdaUrgencias);
      if (proximaLlegada < Config.minutosSimulacion) {
        planificador.programarEvento(EventoLlegada(
          tiempo: proximaLlegada, 
          nodoInicialId: 'urgenciasAtencion'
        ));
      }
    }
  }
  
  AreaHospital _mapearArea(String id) {
    if (id == 'consultaExterna') return AreaHospital.consultaExterna;
    return AreaHospital.urgencias;
  }

  NivelTriage _determinarTriage(GeneradorAleatorio rng) {
    double u = rng.siguiente();
    double acumulada = 0.0;
    for (int i = 0; i < Config.probabilidadesTriage.length; i++) {
      acumulada += Config.probabilidadesTriage[i];
      if (u <= acumulada) return NivelTriage.values[i];
    }
    return NivelTriage.sinUrgenciaAzul;
  }

  void _intentarAsignarRecurso(NodoServicio nodo, EstadoHospital estado, PlanificadorEventos planificador, GeneradorAleatorio rng) {
    final recurso = estado.getRecursoPorNombre(nodo.recursoAsociado);
    
    // NOTA: Asegúrate de usar tienePacientesEnCola y desencolarSiguiente, NO obtenerColaPorRecurso
    if (estado.tienePacientesEnCola(nodo.recursoAsociado) && (recurso == null || recurso.hayDisponible)) {
      final p = estado.desencolarSiguiente(nodo.recursoAsociado);
      
      recurso?.ocupar();
      p.estado = EstadoPaciente.enAtencion;
      p.tiempoInicioAtencion = estado.reloj;

      // ==========================================
      // ¡AQUÍ RECONECTAMOS LAS MÉTRICAS GLOBALES!
      // ==========================================
      if (nodo.recursoAsociado == 'medicosConsulta') {
        estado.metricas.tiemposEsperaConsulta.add(p.tiempoEspera);
        if (estado.colaConsulta.length > estado.metricas.maximoColaConsulta) {
          estado.metricas.maximoColaConsulta = estado.colaConsulta.length;
        }
      } else if (nodo.recursoAsociado == 'medicosUrgencias') {
        estado.metricas.tiemposEsperaUrgencias.add(p.tiempoEspera);
        if (estado.colaUrgencias.length > estado.metricas.maximoColaUrgencias) {
          estado.metricas.maximoColaUrgencias = estado.colaUrgencias.length;
        }
      }
      // ==========================================

      double duracion = nodo.generadorTiempoAtencion(rng);
      planificador.programarEvento(EventoFinAtencion(
        tiempo: estado.reloj + duracion,
        paciente: p,
        nodoActualId: nodo.identificador,
      ));
    }
  }
}