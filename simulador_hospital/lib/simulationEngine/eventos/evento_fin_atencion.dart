// lib/simulationEngine/eventos/evento_fin_atencion.dart
import '../evento_simulacion.dart';
import '../nodo_servicio.dart'; // IMPORTACIÓN FALTANTE AGREGADA
import '../generador_aleatorio.dart';
import '../../StateManagement/paciente.dart';
import '../../StateManagement/estado_hospital.dart';
import '../../clock/planificador_eventos.dart';
import '../../DataProvider/config.dart';
import 'evento_llegada.dart';

class EventoFinAtencion extends EventoSimulacion {
  final String nodoActualId;

  EventoFinAtencion({
    required super.tiempo,
    required super.paciente,
    required this.nodoActualId,
  });

  @override
  void ejecutar(EstadoHospital estado, PlanificadorEventos planificador, GeneradorAleatorio rng) {
    final nodoActual = Config.grafoHospital[nodoActualId]!;
    
    // Liberar recurso de forma dinámica
    final recurso = estado.getRecursoPorNombre(nodoActual.recursoAsociado);
    recurso?.liberar();
    
    paciente!.tiempoFinAtencion = tiempo;

    // Consultar el grafo estocástico de Markov para transicionar
    String siguienteNodoId = nodoActual.obtenerSiguienteEstado(rng);

    if (siguienteNodoId == 'dadoDeAlta') {
      paciente!.tiempoSalida = tiempo;
      paciente!.estado = EstadoPaciente.dadoDeAlta;
      estado.metricas.registrarFinSistema(paciente!, nodoActualId);
      estado.registrarPacienteCompletado(paciente!);
    } else {
      // El paciente viaja al siguiente nodo del grafo encadenando un nuevo evento de entrada
      planificador.programarEvento(EventoLlegada(
        tiempo: tiempo,
        paciente: paciente,
        nodoInicialId: siguienteNodoId,
      ));
    }

    // El recurso liberado intenta procesar al siguiente paciente en su cola
    _revisarColaPendiente(nodoActual, estado, planificador, rng);
  }

  void _revisarColaPendiente(NodoServicio nodo, EstadoHospital estado, PlanificadorEventos planificador, GeneradorAleatorio rng) {
    final recurso = estado.getRecursoPorNombre(nodo.recursoAsociado);

    // Utilizamos la nueva abstracción segura en lugar de obtenerColaPorRecurso
    if (estado.tienePacientesEnCola(nodo.recursoAsociado) && (recurso == null || recurso.hayDisponible)) {
      final p = estado.desencolarSiguiente(nodo.recursoAsociado);
      
      recurso?.ocupar();
      p.estado = EstadoPaciente.enAtencion;
      p.tiempoInicioAtencion = estado.reloj;

      // ==========================================
      // REGISTRO DE MÉTRICAS GLOBALES
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