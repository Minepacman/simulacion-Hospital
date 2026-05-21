/// Estados posibles de un paciente en el sistema
enum EstadoPaciente {
  enEspera,
  enAtencion,
  enObservacion,
  hospitalizado,
  dadoDeAlta,
  citaPerdida,
}

enum AreaHospital {
  consultaExterna,
  urgencias,
  hospitalizacion,
}

/// Entidad Paciente en el sistema
class Paciente {
  final int id;
  final AreaHospital area;
  late double tiempoLlegada;

  double tiempoInicioAtencion = 0.0;
  double tiempoFinAtencion = 0.0;
  double tiempoSalida = 0.0;

  EstadoPaciente estado = EstadoPaciente.enEspera;

  // Para consulta externa
  double? horaCitaProgramada;
  double? retrasoReal;

  // Para urgencias
  bool? requiereHospitalizacion;

  Paciente({
    required this.id,
    required this.area,
    required this.tiempoLlegada,
    this.horaCitaProgramada,
  });

  double get tiempoEspera {
    if (tiempoInicioAtencion == 0.0) return 0.0;
    return tiempoInicioAtencion - tiempoLlegada;
  }

  double get tiempoEnSistema {
    if (tiempoSalida == 0.0) return 0.0;
    return tiempoSalida - tiempoLlegada;
  }

  double get tiempoAtencion {
    if (tiempoFinAtencion == 0.0 || tiempoInicioAtencion == 0.0) return 0.0;
    return tiempoFinAtencion - tiempoInicioAtencion;
  }

  @override
  String toString() {
    String nombreArea = area.toString().split('.').last;
    String nombreEstado = estado.toString().split('.').last;
    return 'Paciente #$id [$nombreArea] - $nombreEstado';
  }
}
