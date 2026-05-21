import 'dart:collection';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import 'Controllers/config.dart';
import 'Controllers/evento.dart';
import 'Controllers/paciente.dart';
import 'Controllers/recurso.dart';
import 'Controllers/metricas.dart';
import 'Controllers/generador_aleatorio.dart';

class SimuladorHospital with ChangeNotifier {
  double reloj = 0.0;

  int diaActual = 0;
  int diasTotalesObjetivo = 0;

  final PriorityQueue<Evento> _eventosFuturos = PriorityQueue<Evento>();

  final Queue<Paciente> _colaConsulta = Queue<Paciente>();

  late Recurso _medicosConsulta;
  late Recurso _medicosUrgencias;
  late Recurso _camas;

  late GeneradorAleatorio _rng;

  late Metricas _metricas;

  int _contadorPacientes = 0;

  bool _simulacionEnCurso = false;
  bool _simulacionCompletada = false;

  List<Map<String, dynamic>> _historialReloj = [];

  bool get simulacionEnCurso => _simulacionEnCurso;
  bool get simulacionCompletada => _simulacionCompletada;
  Metricas get metricas => _metricas;
  int get tamanoColaConsulta => _colaConsulta.length;
  int get tamanoColaUrgencias => _colaUrgencias.length;
  List<Map<String, dynamic>> get historialReloj => _historialReloj;

  Recurso get medicosConsulta => _medicosConsulta;
  Recurso get medicosUrgencias => _medicosUrgencias;
  Recurso get camas => _camas;

  final PriorityQueue<Paciente> _colaUrgencias =
      PriorityQueue<Paciente>((a, b) {
    int cmpGravedad = a.triage!.index.compareTo(b.triage!.index);
    if (cmpGravedad != 0) return cmpGravedad;
    return a.tiempoLlegada.compareTo(b.tiempoLlegada);
  });

  SimuladorHospital() {
    _inicializar();
  }

  NivelTriage _determinarTriage() {
    double u = _rng.siguiente();
    double probabilidadAcumulada = 0.0;

    for (int i = 0; i < Config.probabilidadesTriage.length; i++) {
      probabilidadAcumulada += Config.probabilidadesTriage[i];
      if (u <= probabilidadAcumulada) {
        return NivelTriage.values[i];
      }
    }
    return NivelTriage.sinUrgenciaAzul;
  }

  void _inicializar() {
    reloj = 0.0;
    _contadorPacientes = 0;
    _simulacionEnCurso = false;
    _simulacionCompletada = false;

    _medicosConsulta = Recurso(
      nombre: 'Médicos Consulta',
      capacidadTotal: Config.numeroMedicosConsulta,
    );

    _medicosUrgencias = Recurso(
      nombre: 'Médicos Urgencias',
      capacidadTotal: Config.numeroMedicosUrgencias,
    );

    _camas = Recurso(
      nombre: 'Camas',
      capacidadTotal: Config.numeroCamas,
    );

    _rng = GeneradorAleatorio(DateTime.now().millisecondsSinceEpoch % 100000);

    _metricas = Metricas();

    _historialReloj = [];
  }

  void resetear() {
    _eventosFuturos.clear();
    _colaConsulta.clear();
    _colaUrgencias.clear();

    _medicosConsulta.reset();
    _medicosUrgencias.reset();
    _camas.reset();

    _metricas.reset();

    _inicializar();
    notifyListeners();
  }

  Future<void> ejecutarSimulacionPeriodo(
      String tipoPeriodo, int cantidad) async {
    if (_simulacionEnCurso) return;

    int diasTotales = 1;
    switch (tipoPeriodo) {
      case 'Días':
        diasTotales = cantidad;
        break;
      case 'Semanas':
        diasTotales = cantidad * 7;
        break;
      case 'Meses':
        diasTotales = cantidad * 30;
        break;
      case 'Años':
        diasTotales = cantidad * 365;
        break;
    }

    _simulacionEnCurso = true;
    _simulacionCompletada = false;
    diasTotalesObjetivo = diasTotales;

    List<Metricas> historialMetricas = [];

    for (int i = 0; i < diasTotales; i++) {
      diaActual = i + 1;

      if (i % 10 == 0 || i == diasTotales - 1) {
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 10));
      }

      resetear();
      _ejecutarUnDiaRapido();
      historialMetricas.add(_metricas.clonar());
    }

    _consolidarMetricasGlobales(historialMetricas);

    _simulacionEnCurso = false;
    _simulacionCompletada = true;
    notifyListeners();
  }

  void _ejecutarUnDiaRapido() {
    _generarEventosIniciales();

    while (_eventosFuturos.isNotEmpty && reloj < Config.minutosSimulacion) {
      final evento = _eventosFuturos.removeFirst();
      reloj = evento.tiempo;
      _procesarEvento(evento);

      if (reloj.floor() % 1 == 0) {
        _registrarSnapshotMetricas();
      }
    }
  }

  void _consolidarMetricasGlobales(List<Metricas> historial) {
    if (historial.isEmpty) return;

    Metricas consolidado = Metricas();

    for (var m in historial) {
      consolidado.pacientesAtendidosConsulta += m.pacientesAtendidosConsulta;
      consolidado.pacientesAtendidosUrgencias += m.pacientesAtendidosUrgencias;
      consolidado.pacientesHospitalizados += m.pacientesHospitalizados;
      consolidado.citasPerdidas += m.citasPerdidas;

      consolidado.tiemposEsperaConsulta.addAll(m.tiemposEsperaConsulta);
      consolidado.tiemposEsperaUrgencias.addAll(m.tiemposEsperaUrgencias);
      consolidado.utilizacionMedicosConsulta
          .addAll(m.utilizacionMedicosConsulta);
      consolidado.utilizacionMedicosUrgencias
          .addAll(m.utilizacionMedicosUrgencias);
      consolidado.utilizacionCamas.addAll(m.utilizacionCamas);
      consolidado.tamanosColaConsulta.addAll(m.tamanosColaConsulta);
      consolidado.tamanosColaUrgencias.addAll(m.tamanosColaUrgencias);
    }

    int n = historial.length;
    consolidado.pacientesAtendidosConsulta =
        (consolidado.pacientesAtendidosConsulta / n).round();
    consolidado.pacientesAtendidosUrgencias =
        (consolidado.pacientesAtendidosUrgencias / n).round();
    consolidado.pacientesHospitalizados =
        (consolidado.pacientesHospitalizados / n).round();
    consolidado.citasPerdidas = (consolidado.citasPerdidas / n).round();

    _metricas = consolidado;
  }

  Future<void> ejecutarSimulacion() async {
    if (_simulacionEnCurso) return;

    resetear();
    _simulacionEnCurso = true;
    _simulacionCompletada = false;
    notifyListeners();

    _generarEventosIniciales();

    int contadorIteraciones = 0;
    while (_eventosFuturos.isNotEmpty && reloj < Config.minutosSimulacion) {
      final evento = _eventosFuturos.removeFirst();

      reloj = evento.tiempo;

      _procesarEvento(evento);

      if (contadorIteraciones % 10 == 0) {
        _registrarSnapshotMetricas();
      }

      contadorIteraciones++;

      if (contadorIteraciones % 50 == 0) {
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }

    _simulacionEnCurso = false;
    _simulacionCompletada = true;
    notifyListeners();
  }

  void _generarEventosIniciales() {
    _generarCitasProgramadas();

    double tiempoLlegada = _rng.exponencial(Config.lambdaUrgencias);
    _eventosFuturos.add(Evento(
      tipo: TipoEvento.llegadaUrgencia,
      tiempo: tiempoLlegada,
    ));
  }

  ///consulta externa
  void _generarCitasProgramadas() {
    int numCitas = Config.citasProgramadasPorDia;
    double intervalo = Config.minutosSimulacion / numCitas;

    for (int i = 0; i < numCitas; i++) {
      double horaProgramada = i * intervalo;

      _eventosFuturos.add(Evento(
        tipo: TipoEvento.llegadaConsulta,
        tiempo: horaProgramada,
        paciente: Paciente(
          id: _contadorPacientes++,
          area: AreaHospital.consultaExterna,
          tiempoLlegada: horaProgramada,
          horaCitaProgramada: horaProgramada,
        ),
      ));
    }
  }

  // segun evento
  void _procesarEvento(Evento evento) {
    switch (evento.tipo) {
      case TipoEvento.llegadaConsulta:
        _procesarLlegadaConsulta(evento);
        break;
      case TipoEvento.llegadaUrgencia:
        _procesarLlegadaUrgencia(evento);
        break;
      case TipoEvento.finConsulta:
        _procesarFinConsulta(evento);
        break;
      case TipoEvento.finUrgencia:
        _procesarFinUrgencia(evento);
        break;
      case TipoEvento.finObservacion:
        _procesarFinObservacion(evento);
        break;
      case TipoEvento.ingresoHospitalizacion:
        _procesarIngresoHospitalizacion(evento);
        break;
      case TipoEvento.altaHospitalizacion:
        _procesarAltaHospitalizacion(evento);
        break;
    }
  }

  void _procesarLlegadaConsulta(Evento evento) {
    final paciente = evento.paciente!;

    //retraso normal  XD
    double retraso = _rng.normal(0, Config.desviacionRetraso);
    paciente.retrasoReal = retraso;

    // retrasos
    if (retraso > Config.limiteRetrasoPermitido) {
      paciente.estado = EstadoPaciente.citaPerdida;
      _metricas.citasPerdidas++;
      return;
    }

    paciente.tiempoLlegada = reloj + retraso;
    _colaConsulta.add(paciente);

    _intentarAsignarMedicoConsulta();
  }

  /// llegada de paciente a urgencias
  void _procesarLlegadaUrgencia(Evento evento) {
    final paciente = Paciente(
      id: _contadorPacientes++,
      area: AreaHospital.urgencias,
      tiempoLlegada: reloj,
    );

    //nivel triage
    paciente.triage = _determinarTriage();

    // Agregar a la cola
    _colaUrgencias.add(paciente);

    // poisson
    double proximaLlegada = reloj + _rng.exponencial(Config.lambdaUrgencias);
    if (proximaLlegada < Config.minutosSimulacion) {
      _eventosFuturos.add(Evento(
        tipo: TipoEvento.llegadaUrgencia,
        tiempo: proximaLlegada,
      ));
    }

    // asigna medico
    _intentarAsignarMedicoUrgencias();
  }

  /// asigna medico a espera
  void _intentarAsignarMedicoConsulta() {
    if (_colaConsulta.isEmpty || !_medicosConsulta.hayDisponible) {
      return;
    }

    final paciente = _colaConsulta.removeFirst();

    _medicosConsulta.ocupar();

    // estado del paciente
    paciente.estado = EstadoPaciente.enAtencion;
    paciente.tiempoInicioAtencion = reloj;

    _metricas.registrarEsperaConsulta(paciente.tiempoEspera);

    // Generar tiempo de atención (Exponencial)
    double duracion = _rng.exponencial(1.0 / Config.tiempoPromedioConsulta);

    // Programar fin de consulta
    _eventosFuturos.add(Evento(
      tipo: TipoEvento.finConsulta,
      tiempo: reloj + duracion,
      paciente: paciente,
    ));
  }

  void _intentarAsignarMedicoUrgencias() {
    if (_colaUrgencias.isEmpty || !_medicosUrgencias.hayDisponible) {
      return;
    }

    final paciente = _colaUrgencias.removeFirst();

    // Ocupar médico
    _medicosUrgencias.ocupar();

    // Actualizar estado del paciente
    paciente.estado = EstadoPaciente.enAtencion;
    paciente.tiempoInicioAtencion = reloj;

    // Registrar tiempo de espera
    _metricas.registrarEsperaUrgencias(paciente.tiempoEspera);

    // Generar tiempo de atención (Exponencial)
    double duracion = _rng.exponencial(1.0 / Config.tiempoPromedioUrgencia);

    // Programar fin de urgencia
    _eventosFuturos.add(Evento(
      tipo: TipoEvento.finUrgencia,
      tiempo: reloj + duracion,
      paciente: paciente,
    ));
  }

  /// Procesar fin de consulta externa
  void _procesarFinConsulta(Evento evento) {
    final paciente = evento.paciente!;

    _medicosConsulta.liberar();

    paciente.tiempoFinAtencion = reloj;
    paciente.tiempoSalida = reloj;
    paciente.estado = EstadoPaciente.dadoDeAlta;

    _metricas.pacientesAtendidosConsulta++;
    _metricas.tiemposTotalesConsulta.add(paciente.tiempoEnSistema);

    _intentarAsignarMedicoConsulta();
  }

  void _procesarFinUrgencia(Evento evento) {
    final paciente = evento.paciente!;

    _medicosUrgencias.liberar();

    paciente.tiempoFinAtencion = reloj;

    _metricas.pacientesAtendidosUrgencias++;

    bool requiereHospitalizacion = _rng.booleanoConProbabilidad(
      Config.probUrgenciaAHospitalizacion,
    );

    paciente.requiereHospitalizacion = requiereHospitalizacion;
    if (paciente.triage == NivelTriage.sinUrgenciaAzul) {
      paciente.tiempoSalida = reloj;
      paciente.estado = EstadoPaciente.dadoDeAlta;
      _metricas.tiemposTotalesUrgencias.add(paciente.tiempoEnSistema);
      _intentarAsignarMedicoUrgencias();
      return;
    } else if (requiereHospitalizacion) {
      // se ingresa a hospitalizacion
      _eventosFuturos.add(Evento(
        tipo: TipoEvento.ingresoHospitalizacion,
        tiempo: reloj,
        paciente: paciente,
      ));
    } else {
      // observacion
      paciente.estado = EstadoPaciente.enObservacion;

      double duracionObservacion = _rng.exponencial(
        1.0 / Config.tiempoPromedioObservacion,
      );

      _eventosFuturos.add(Evento(
        tipo: TipoEvento.finObservacion,
        tiempo: reloj + duracionObservacion,
        paciente: paciente,
      ));
    }
    // si se puede atiende al siguiente
    _intentarAsignarMedicoUrgencias();
  }

  //Fin de la observasion
  void _procesarFinObservacion(Evento evento) {
    final paciente = evento.paciente!;

    paciente.tiempoSalida = reloj;
    paciente.estado = EstadoPaciente.dadoDeAlta;

    _metricas.tiemposTotalesUrgencias.add(paciente.tiempoEnSistema);
  }

  // hospitalizacion
  void _procesarIngresoHospitalizacion(Evento evento) {
    final paciente = evento.paciente!;

    // Verificar disponibilidad de camas
    if (!_camas.hayDisponible) {
      // No hay camas, dar de alta XD
      paciente.tiempoSalida = reloj;
      paciente.estado = EstadoPaciente.dadoDeAlta;
      _metricas.tiemposTotalesUrgencias.add(paciente.tiempoEnSistema);
      return;
    }

    _camas.ocupar();
    paciente.estado = EstadoPaciente.hospitalizado;

    _metricas.pacientesHospitalizados++;

    // tiempo exponencial
    double duracion = _rng.exponencial(
      1.0 / Config.tiempoPromedioHospitalizacion,
    );

    // alta de hospitalización
    _eventosFuturos.add(Evento(
      tipo: TipoEvento.altaHospitalizacion,
      tiempo: reloj + duracion,
      paciente: paciente,
    ));
  }

  void _procesarAltaHospitalizacion(Evento evento) {
    final paciente = evento.paciente!;

    // Liberar cama
    _camas.liberar();

    paciente.tiempoSalida = reloj;
    paciente.estado = EstadoPaciente.dadoDeAlta;

    _metricas.tiemposTotalesHospitalizacion.add(paciente.tiempoEnSistema);
  }

  /// registro de datos actuales
  void _registrarSnapshotMetricas() {
    _metricas.registrarTamanoCola(
      _colaConsulta.length,
      _colaUrgencias.length,
    );

    _medicosConsulta.registrarUtilizacion();
    _medicosUrgencias.registrarUtilizacion();
    _camas.registrarUtilizacion();

    _metricas.utilizacionMedicosConsulta.add(_medicosConsulta.utilizacion);
    _metricas.utilizacionMedicosUrgencias.add(_medicosUrgencias.utilizacion);
    _metricas.utilizacionCamas.add(_camas.utilizacion);

    // Guardar en historial
    _historialReloj.add({
      'tiempo': reloj,
      'colaConsulta': _colaConsulta.length,
      'colaUrgencias': _colaUrgencias.length,
      'utilizacionMedicosConsulta': _medicosConsulta.utilizacion,
      'utilizacionMedicosUrgencias': _medicosUrgencias.utilizacion,
      'utilizacionCamas': _camas.utilizacion,
    });
  }
}
