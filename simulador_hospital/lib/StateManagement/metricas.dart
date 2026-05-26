import 'dart:math' as math;
import 'paciente.dart';

class IntervaloConfianza {
  final double media;
  final double margenError;

  IntervaloConfianza(this.media, this.margenError);

  @override
  String toString() =>
      '${media.toStringAsFixed(1)} ± ${margenError.toStringAsFixed(2)}';
}

class Estadisticas {
  static IntervaloConfianza calcularCI(List<double> datos, {double z = 1.96}) {
    if (datos.isEmpty) return IntervaloConfianza(0.0, 0.0);
    if (datos.length == 1) return IntervaloConfianza(datos.first, 0.0);

    double media = datos.reduce((a, b) => a + b) / datos.length;

    double sumaVariaciones = 0;
    for (double x in datos) {
      sumaVariaciones += math.pow(x - media, 2);
    }
    double varianza = sumaVariaciones / (datos.length - 1);
    double desviacionEstandar = math.sqrt(varianza);

    double margenError = z * (desviacionEstandar / math.sqrt(datos.length));

    return IntervaloConfianza(media, margenError);
  }
}

class Metricas {
  // ==========================================
  // VARIABLES DE ESTADO Y MÁXIMOS
  // ==========================================
  int maximoColaConsulta = 0;
  int maximoColaUrgencias = 0;
  
  List<double> tiemposEsperaConsulta = [];
  List<double> tiemposEsperaUrgencias = [];

  List<double> tiemposTotalesConsulta = [];
  List<double> tiemposTotalesUrgencias = [];
  List<double> tiemposTotalesHospitalizacion = [];

  List<int> tamanosColaConsulta = [];
  List<int> tamanosColaUrgencias = [];

  // Contadores
  int pacientesAtendidosConsulta = 0;
  int pacientesAtendidosUrgencias = 0;
  int pacientesHospitalizados = 0;
  int citasPerdidas = 0;
  
  // Mortalidad
  int totalFallecidos = 0;
  List<Map<String, dynamic>> registrosMortalidad = [];

  List<double> utilizacionMedicosConsulta = [];
  List<double> utilizacionMedicosUrgencias = [];
  List<double> utilizacionCamas = [];

  // ==========================================
  // MÉTODOS DE REGISTRO
  // ==========================================
  void registrarEsperaConsulta(double tiempo) {
    tiemposEsperaConsulta.add(tiempo);
  }

  void registrarEsperaUrgencias(double tiempo) {
    tiemposEsperaUrgencias.add(tiempo);
  }

  void registrarTamanoCola(int tamanoConsulta, int tamanoUrgencias) {
    tamanosColaConsulta.add(tamanoConsulta);
    tamanosColaUrgencias.add(tamanoUrgencias);
  }

  void registrarFinSistema(Paciente paciente, String nodoSalida) {
    double tiempoTotal = paciente.tiempoEnSistema;

    if (nodoSalida == 'consultaExterna') {
      pacientesAtendidosConsulta++;
      tiemposTotalesConsulta.add(tiempoTotal);
    } else if (nodoSalida == 'hospitalizacion') {
      pacientesHospitalizados++;
      tiemposTotalesHospitalizacion.add(tiempoTotal);
    } else {
      pacientesAtendidosUrgencias++;
      tiemposTotalesUrgencias.add(tiempoTotal);
    }
  }

  void registrarFallecimiento(Paciente paciente, int camasOcupadas) {
    totalFallecidos++;
    registrosMortalidad.add({
      'paciente_id': paciente.id,
      'triage': paciente.triage.toString().split('.').last,
      'tiempo_espera': paciente.tiempoEspera,
      'camas_momento': camasOcupadas,
      'dia': paciente.diaSimulacion
    });
  }

  // ==========================================
  // GETTERS DE PROMEDIOS Y PROBABILIDADES
  // ==========================================
  double get promedioEsperaConsulta {
    if (tiemposEsperaConsulta.isEmpty) return 0.0;
    return tiemposEsperaConsulta.reduce((a, b) => a + b) / tiemposEsperaConsulta.length;
  }

  double get promedioEsperaUrgencias {
    if (tiemposEsperaUrgencias.isEmpty) return 0.0;
    return tiemposEsperaUrgencias.reduce((a, b) => a + b) / tiemposEsperaUrgencias.length;
  }

  double get promedioTamanoColaConsulta {
    if (tamanosColaConsulta.isEmpty) return 0.0;
    return tamanosColaConsulta.reduce((a, b) => a + b) / tamanosColaConsulta.length;
  }

  double get promedioTamanoColaUrgencias {
    if (tamanosColaUrgencias.isEmpty) return 0.0;
    return tamanosColaUrgencias.reduce((a, b) => a + b) / tamanosColaUrgencias.length;
  }

  double get promedioUtilizacionMedicosConsulta {
    if (utilizacionMedicosConsulta.isEmpty) return 0.0;
    return utilizacionMedicosConsulta.reduce((a, b) => a + b) / utilizacionMedicosConsulta.length;
  }

  double get promedioUtilizacionMedicosUrgencias {
    if (utilizacionMedicosUrgencias.isEmpty) return 0.0;
    return utilizacionMedicosUrgencias.reduce((a, b) => a + b) / utilizacionMedicosUrgencias.length;
  }

  double get promedioUtilizacionCamas {
    if (utilizacionCamas.isEmpty) return 0.0;
    return utilizacionCamas.reduce((a, b) => a + b) / utilizacionCamas.length;
  }

  double get probabilidadSaturacionConsulta {
    if (utilizacionMedicosConsulta.isEmpty) return 0.0;
    int snapshotsSaturados = utilizacionMedicosConsulta.where((u) => u >= 1.0).length;
    return snapshotsSaturados / utilizacionMedicosConsulta.length;
  }

  double get probabilidadSaturacionUrgencias {
    if (utilizacionMedicosUrgencias.isEmpty) return 0.0;
    int snapshotsSaturados = utilizacionMedicosUrgencias.where((u) => u >= 1.0).length;
    return snapshotsSaturados / utilizacionMedicosUrgencias.length;
  }

  double get probabilidadSaturacionCamas {
    if (utilizacionCamas.isEmpty) return 0.0;
    int snapshotsSaturados = utilizacionCamas.where((u) => u >= 1.0).length;
    return snapshotsSaturados / utilizacionCamas.length;
  }

  double get probabilidadSaturacionGlobal {
    if (utilizacionCamas.isEmpty) return 0.0;
    int snapshotsSaturados = 0;
    for (int i = 0; i < utilizacionCamas.length; i++) {
      if (utilizacionMedicosUrgencias[i] >= 1.0 || utilizacionCamas[i] >= 1.0) {
        snapshotsSaturados++;
      }
    }
    return snapshotsSaturados / utilizacionCamas.length;
  }

  // ==========================================
  // UTILIDADES (Reset y Clonación)
  // ==========================================
  void reset() {
    maximoColaConsulta = 0;
    maximoColaUrgencias = 0;
    tiemposEsperaConsulta.clear();
    tiemposEsperaUrgencias.clear();
    tiemposTotalesConsulta.clear();
    tiemposTotalesUrgencias.clear();
    tiemposTotalesHospitalizacion.clear();
    tamanosColaConsulta.clear();
    tamanosColaUrgencias.clear();
    utilizacionMedicosConsulta.clear();
    utilizacionMedicosUrgencias.clear();
    utilizacionCamas.clear();

    totalFallecidos = 0;
    registrosMortalidad.clear();
    pacientesAtendidosConsulta = 0;
    pacientesAtendidosUrgencias = 0;
    pacientesHospitalizados = 0;
    citasPerdidas = 0;
  }

  Metricas clonar() {
    final nuevas = Metricas();
    // Clonamos listas
    nuevas.tiemposEsperaConsulta = List.from(tiemposEsperaConsulta);
    nuevas.tiemposEsperaUrgencias = List.from(tiemposEsperaUrgencias);
    nuevas.tamanosColaConsulta = List.from(tamanosColaConsulta);
    nuevas.tamanosColaUrgencias = List.from(tamanosColaUrgencias);
    nuevas.utilizacionMedicosConsulta = List.from(utilizacionMedicosConsulta);
    nuevas.utilizacionMedicosUrgencias = List.from(utilizacionMedicosUrgencias);
    nuevas.utilizacionCamas = List.from(utilizacionCamas);
    // Clonamos contadores y máximos
    nuevas.maximoColaConsulta = maximoColaConsulta;
    nuevas.maximoColaUrgencias = maximoColaUrgencias;
    nuevas.pacientesAtendidosConsulta = pacientesAtendidosConsulta;
    nuevas.pacientesAtendidosUrgencias = pacientesAtendidosUrgencias;
    nuevas.pacientesHospitalizados = pacientesHospitalizados;
    nuevas.citasPerdidas = citasPerdidas;
    nuevas.totalFallecidos = totalFallecidos;
    return nuevas;
  }
}