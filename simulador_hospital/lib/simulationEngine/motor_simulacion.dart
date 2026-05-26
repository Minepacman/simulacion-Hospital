import '../DataProvider/config.dart';
import '../StateManagement/estado_hospital.dart';
import '../StateManagement/paciente.dart';
import '../clock/planificador_eventos.dart';
import '../clock/evento.dart';
import 'generador_aleatorio.dart';

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
    planificador.programarEvento(Evento(tipo: TipoEvento.llegadaUrgencia, tiempo: tiempoLlegada));
  }

  void _generarCitasProgramadas() {
    int numCitas = Config.citasProgramadasPorDia;
    double intervalo = Config.minutosSimulacion / numCitas;
    for (int i = 0; i < numCitas; i++) {
      double horaProgramada = i * intervalo;
      planificador.programarEvento(Evento(
        tipo: TipoEvento.llegadaConsulta,
        tiempo: horaProgramada,
        paciente: Paciente(
          id: estado.contadorPacientes++,
          area: AreaHospital.consultaExterna,
          tiempoLlegada: horaProgramada,
          horaCitaProgramada: horaProgramada,
        ),
      ));
    }
  }

  void procesarEvento(Evento evento) {
    switch (evento.tipo) {
      case TipoEvento.llegadaConsulta: _procesarLlegadaConsulta(evento); break;
      case TipoEvento.llegadaUrgencia: _procesarLlegadaUrgencia(evento); break;
      case TipoEvento.finConsulta: _procesarFinConsulta(evento); break;
      case TipoEvento.finUrgencia: _procesarFinUrgencia(evento); break;
      case TipoEvento.finObservacion: _procesarFinObservacion(evento); break;
      case TipoEvento.ingresoHospitalizacion: _procesarIngresoHospitalizacion(evento); break;
      case TipoEvento.altaHospitalizacion: _procesarAltaHospitalizacion(evento); break;
    }
  }

  void _procesarLlegadaConsulta(Evento evento) {
    final paciente = evento.paciente!;
    double retraso = rng.normal(0, Config.desviacionRetraso);
    paciente.retrasoReal = retraso;

    if (retraso > Config.limiteRetrasoPermitido) {
      paciente.estado = EstadoPaciente.citaPerdida;
      estado.metricas.citasPerdidas++;
      return;
    }

    paciente.tiempoLlegada = estado.reloj + retraso;
    estado.colaConsulta.add(paciente);
    _intentarAsignarMedicoConsulta();
  }

  void _intentarAsignarMedicoConsulta() {
    if (estado.colaConsulta.isEmpty || !estado.medicosConsulta.hayDisponible) return;
    final paciente = estado.colaConsulta.removeFirst();
    estado.medicosConsulta.ocupar();
    paciente.estado = EstadoPaciente.enAtencion;
    paciente.tiempoInicioAtencion = estado.reloj;
    estado.metricas.registrarEsperaConsulta(paciente.tiempoEspera);

    double duracion = rng.exponencial(1.0 / Config.tiempoPromedioConsulta);
    planificador.programarEvento(Evento(tipo: TipoEvento.finConsulta, tiempo: estado.reloj + duracion, paciente: paciente));
  }

  void _procesarLlegadaUrgencia(Evento evento) {
    final paciente = Paciente(id: estado.contadorPacientes++, area: AreaHospital.urgencias, tiempoLlegada: estado.reloj);
    paciente.triage = _determinarTriage();
    estado.colaUrgencias.add(paciente);

    double proximaLlegada = estado.reloj + rng.exponencial(Config.lambdaUrgencias);
    if (proximaLlegada < Config.minutosSimulacion) {
      planificador.programarEvento(Evento(tipo: TipoEvento.llegadaUrgencia, tiempo: proximaLlegada));
    }
    _intentarAsignarMedicoUrgencias();
  }

  void _intentarAsignarMedicoUrgencias() {
    if (estado.colaUrgencias.isEmpty || !estado.medicosUrgencias.hayDisponible) return;
    final paciente = estado.colaUrgencias.removeFirst();
    estado.medicosUrgencias.ocupar();
    paciente.estado = EstadoPaciente.enAtencion;
    paciente.tiempoInicioAtencion = estado.reloj;
    estado.metricas.registrarEsperaUrgencias(paciente.tiempoEspera);

    double duracion = rng.exponencial(1.0 / Config.tiempoPromedioUrgencia);
    planificador.programarEvento(Evento(tipo: TipoEvento.finUrgencia, tiempo: estado.reloj + duracion, paciente: paciente));
  }

  void _procesarFinConsulta(Evento evento) {
    final paciente = evento.paciente!;
    estado.medicosConsulta.liberar();
    paciente.tiempoFinAtencion = estado.reloj;
    paciente.tiempoSalida = estado.reloj;
    paciente.estado = EstadoPaciente.dadoDeAlta;
    estado.metricas.pacientesAtendidosConsulta++;
    estado.metricas.tiemposTotalesConsulta.add(paciente.tiempoEnSistema);
    _intentarAsignarMedicoConsulta();
  }

  void _procesarFinUrgencia(Evento evento) {
    final paciente = evento.paciente!;
    estado.medicosUrgencias.liberar();
    paciente.tiempoFinAtencion = estado.reloj;
    estado.metricas.pacientesAtendidosUrgencias++;

    EstadoPaciente siguienteDestino = _determinarMarkovUrgencias(paciente.triage!, EstadoPaciente.enAtencion);

    if (siguienteDestino == EstadoPaciente.hospitalizado) {
      paciente.requiereHospitalizacion = true;
      planificador.programarEvento(Evento(tipo: TipoEvento.ingresoHospitalizacion, tiempo: estado.reloj, paciente: paciente));
    } else if (siguienteDestino == EstadoPaciente.enObservacion) {
      paciente.estado = EstadoPaciente.enObservacion;
      double duracionObservacion = rng.exponencial(1.0 / Config.tiempoPromedioObservacion);
      planificador.programarEvento(Evento(tipo: TipoEvento.finObservacion, tiempo: estado.reloj + duracionObservacion, paciente: paciente));
    } else {
      paciente.tiempoSalida = estado.reloj;
      paciente.estado = EstadoPaciente.dadoDeAlta;
      estado.metricas.tiemposTotalesUrgencias.add(paciente.tiempoEnSistema);
    }
    _intentarAsignarMedicoUrgencias();
  }

  void _procesarFinObservacion(Evento evento) {
    final paciente = evento.paciente!;
    EstadoPaciente siguienteDestino = _determinarMarkovUrgencias(paciente.triage!, EstadoPaciente.enObservacion);

    if (siguienteDestino == EstadoPaciente.hospitalizado) {
      paciente.requiereHospitalizacion = true;
      planificador.programarEvento(Evento(tipo: TipoEvento.ingresoHospitalizacion, tiempo: estado.reloj, paciente: paciente));
    } else {
      paciente.tiempoSalida = estado.reloj;
      paciente.estado = EstadoPaciente.dadoDeAlta;
      estado.metricas.tiemposTotalesUrgencias.add(paciente.tiempoEnSistema);
    }
  }

  void _procesarIngresoHospitalizacion(Evento evento) {
    final paciente = evento.paciente!;
    if (!estado.camas.hayDisponible) {
      paciente.tiempoSalida = estado.reloj;
      paciente.estado = EstadoPaciente.dadoDeAlta;
      estado.metricas.tiemposTotalesUrgencias.add(paciente.tiempoEnSistema);
      return;
    }
    estado.camas.ocupar();
    paciente.estado = EstadoPaciente.hospitalizado;
    estado.metricas.pacientesHospitalizados++;

    double duracion = rng.exponencial(1.0 / Config.tiempoPromedioHospitalizacion);
    planificador.programarEvento(Evento(tipo: TipoEvento.altaHospitalizacion, tiempo: estado.reloj + duracion, paciente: paciente));
  }

  void _procesarAltaHospitalizacion(Evento evento) {
    final paciente = evento.paciente!;
    estado.camas.liberar();
    paciente.tiempoSalida = estado.reloj;
    paciente.estado = EstadoPaciente.dadoDeAlta;
    estado.metricas.tiemposTotalesHospitalizacion.add(paciente.tiempoEnSistema);
  }

  NivelTriage _determinarTriage() {
    double u = rng.siguiente();
    double acumulada = 0.0;
    for (int i = 0; i < Config.probabilidadesTriage.length; i++) {
      acumulada += Config.probabilidadesTriage[i];
      if (u <= acumulada) return NivelTriage.values[i];
    }
    return NivelTriage.sinUrgenciaAzul;
  }

  EstadoPaciente _determinarMarkovUrgencias(NivelTriage triage, EstadoPaciente actual) {
    String claveTriage = triage.toString().split('.').last;
    String claveEstado = actual.toString().split('.').last;
    if (!Config.matricesMarkovUrgencias.containsKey(claveTriage)) return EstadoPaciente.dadoDeAlta;
    
    final matrizEspecifica = Config.matricesMarkovUrgencias[claveTriage]!;
    if (!matrizEspecifica.containsKey(claveEstado)) return EstadoPaciente.dadoDeAlta;

    Map<String, double> transiciones = matrizEspecifica[claveEstado]!;
    double u = rng.siguiente();
    double acumulada = 0.0;

    for (var entry in transiciones.entries) {
      acumulada += entry.value;
      if (u <= acumulada) {
        return EstadoPaciente.values.firstWhere((e) => e.toString().split('.').last == entry.key);
      }
    }
    return EstadoPaciente.dadoDeAlta;
  }
}