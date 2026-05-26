import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import '../DataProvider/config.dart';
import '../clock/planificador_eventos.dart';
import 'paciente.dart';
import 'recurso.dart';
import 'metricas.dart';

class EstadoHospital with ChangeNotifier {
  double reloj = 0.0;
  int diaActual = 0;
  int diasTotalesObjetivo = 0;
  int replicaActual = 0;

  bool simulacionEnCurso = false;
  bool simulacionCompletada = false;

  // Estructuras de datos puras de estado
  final Queue<Paciente> colaConsulta = Queue<Paciente>();
  final PriorityQueue<Paciente> colaUrgencias = PriorityQueue<Paciente>((a, b) {
    int cmpGravedad = a.triage!.index.compareTo(b.triage!.index);
    if (cmpGravedad != 0) return cmpGravedad;
    return a.tiempoLlegada.compareTo(b.tiempoLlegada);
  });

  late Recurso medicosConsulta;
  late Recurso medicosUrgencias;
  late Recurso camas;
  
  Metricas metricas = Metricas();
  List<Map<String, dynamic>> historialReloj = [];
  Map<String, IntervaloConfianza> intervalos = {};

  int contadorPacientes = 0;

  void inicializarRecursos() {
    reloj = 0.0;
    contadorPacientes = 0;
    colaConsulta.clear();
    colaUrgencias.clear();

    medicosConsulta = Recurso(nombre: 'Médicos Consulta', capacidadTotal: Config.numeroMedicosConsulta);
    medicosUrgencias = Recurso(nombre: 'Médicos Urgencias', capacidadTotal: Config.numeroMedicosUrgencias);
    camas = Recurso(nombre: 'Camas', capacidadTotal: Config.numeroCamas);
    
    metricas.reset();
    historialReloj.clear();
  }

  void actualizarReloj(double nuevoTiempo) {
    reloj = nuevoTiempo;
  }

  void registrarSnapshot() {
    metricas.registrarTamanoCola(colaConsulta.length, colaUrgencias.length);
    medicosConsulta.registrarUtilizacion();
    medicosUrgencias.registrarUtilizacion();
    camas.registrarUtilizacion();

    metricas.utilizacionMedicosConsulta.add(medicosConsulta.utilizacion);
    metricas.utilizacionMedicosUrgencias.add(medicosUrgencias.utilizacion);
    metricas.utilizacionCamas.add(camas.utilizacion);

    historialReloj.add({
      'tiempo': reloj,
      'colaConsulta': colaConsulta.length,
      'colaUrgencias': colaUrgencias.length,
    });
  }

  Future<void> ejecutarSimulacionPeriodo(String tipoPeriodo, int cantidad) async {
    if (simulacionEnCurso) return;

    int diasTotales = 1;
    if (tipoPeriodo == 'Días') diasTotales = cantidad;
    if (tipoPeriodo == 'Semanas') diasTotales = cantidad * 7;
    if (tipoPeriodo == 'Meses') diasTotales = cantidad * 30;
    if (tipoPeriodo == 'Años') diasTotales = cantidad * 365;

    simulacionEnCurso = true;
    simulacionCompletada = false;
    diasTotalesObjetivo = diasTotales;

    List<Metricas> resultadosReplicas = [];
    final planificador = PlanificadorEventos(this);

    for (int r = 0; r < Config.numeroReplicas; r++) {
      replicaActual = r + 1;
      List<Metricas> historialDias = [];

      for (int i = 0; i < diasTotales; i++) {
        diaActual = i + 1;

        if (i % 10 == 0 || i == diasTotales - 1) {
          notifyListeners(); // Refresh Display
          await Future.delayed(const Duration(milliseconds: 1));
        }

        planificador.limpiar();
        inicializarRecursos();
        planificador.ejecutarDia(Config.minutosSimulacion.toDouble());
        historialDias.add(metricas.clonar());
      }
      resultadosReplicas.add(_consolidarDias(historialDias));
    }

    _calcularEstadisticasFinales(resultadosReplicas);
    simulacionEnCurso = false;
    simulacionCompletada = true;
    notifyListeners(); // Render final de resultados
  }

  Metricas _consolidarDias(List<Metricas> historial) {
    Metricas consolidado = Metricas();
    if (historial.isEmpty) return consolidado;
    for (var m in historial) {
      consolidado.pacientesAtendidosConsulta += m.pacientesAtendidosConsulta;
      consolidado.pacientesAtendidosUrgencias += m.pacientesAtendidosUrgencias;
      consolidado.pacientesHospitalizados += m.pacientesHospitalizados;
      consolidado.citasPerdidas += m.citasPerdidas;
      consolidado.tiemposEsperaConsulta.addAll(m.tiemposEsperaConsulta);
      consolidado.tiemposEsperaUrgencias.addAll(m.tiemposEsperaUrgencias);
      consolidado.utilizacionMedicosConsulta.addAll(m.utilizacionMedicosConsulta);
      consolidado.utilizacionMedicosUrgencias.addAll(m.utilizacionMedicosUrgencias);
      consolidado.utilizacionCamas.addAll(m.utilizacionCamas);
    }
    int n = historial.length;
    consolidado.pacientesAtendidosConsulta = (consolidado.pacientesAtendidosConsulta / n).round();
    consolidado.pacientesAtendidosUrgencias = (consolidado.pacientesAtendidosUrgencias / n).round();
    consolidado.pacientesHospitalizados = (consolidado.pacientesHospitalizados / n).round();
    consolidado.citasPerdidas = (consolidado.citasPerdidas / n).round();
    return consolidado;
  }

  void _calcularEstadisticasFinales(List<Metricas> replicas) {
    metricas = _consolidarDias(replicas);
    intervalos['esperaConsulta'] = Estadisticas.calcularCI(replicas.map((m) => m.promedioEsperaConsulta).toList());
    intervalos['esperaUrgencias'] = Estadisticas.calcularCI(replicas.map((m) => m.promedioEsperaUrgencias).toList());
    intervalos['usoConsulta'] = Estadisticas.calcularCI(replicas.map((m) => m.promedioUtilizacionMedicosConsulta * 100).toList());
    intervalos['usoUrgencias'] = Estadisticas.calcularCI(replicas.map((m) => m.promedioUtilizacionMedicosUrgencias * 100).toList());
    intervalos['usoCamas'] = Estadisticas.calcularCI(replicas.map((m) => m.promedioUtilizacionCamas * 100).toList());
    intervalos['satCamas'] = Estadisticas.calcularCI(replicas.map((m) => m.probabilidadSaturacionCamas * 100).toList());
    intervalos['satGlobal'] = Estadisticas.calcularCI(replicas.map((m) => m.probabilidadSaturacionGlobal * 100).toList());
  }
}