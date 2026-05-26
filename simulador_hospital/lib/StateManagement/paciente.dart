import '../simulationEngine/generador_aleatorio.dart';
/// Estados posibles de un paciente en el sistema
enum EstadoPaciente {
  enEspera,
  enAtencion,
  enObservacion,
  hospitalizado,
  enRecuperacion, 
  dadoDeAlta,
  citaPerdida,
  fallecido,      
}

enum AreaHospital {
  consultaExterna,
  urgencias,
  hospitalizacion,
}

enum NivelTriage {
  reanimacionRojo,
  emergenciaNaranja,
  urgenciaAmarillo,
  urgenciaMenorVerde,
  sinUrgenciaAzul
}

/// Entidad Paciente en el sistema
class Paciente {
  final int id;
  final AreaHospital area;
  final int diaSimulacion;
  late double tiempoLlegada;

  double tiempoInicioAtencion = 0.0;
  double tiempoFinAtencion = 0.0;
  double tiempoSalida = 0.0;

  EstadoPaciente estado = EstadoPaciente.enEspera;

  // para consulta externa
  double? horaCitaProgramada;
  double? retrasoReal;

  // para urgencias
  bool? requiereHospitalizacion;

  double? limiteSupervivenciaEspera;

  NivelTriage? triage;

  Paciente({
    required this.id,
    required this.area,
    required this.tiempoLlegada,
    required this.diaSimulacion,
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
    if (tiempoInicioAtencion == 0.0 || tiempoFinAtencion == 0.0) return 0.0;
    return tiempoFinAtencion - tiempoInicioAtencion;
  }

  void calcularLimiteSupervivencia(GeneradorAleatorio rng) {
    if (triage == null) return;
    
    // Modelamos la resistencia como una variable aleatoria exponencial o normal
    // Los pacientes críticos (Rojo) toleran muy pocos minutos en promedio
    switch (triage!) {
      case NivelTriage.reanimacionRojo:
        limiteSupervivenciaEspera = tiempoLlegada + rng.exponencial(1.0 / 20.0); // promedio 20 mins
        break;
      case NivelTriage.emergenciaNaranja:
        limiteSupervivenciaEspera = tiempoLlegada + rng.exponencial(1.0 / 60.0); // promedio 60 mins
        break;
      case NivelTriage.urgenciaAmarillo:
        limiteSupervivenciaEspera = tiempoLlegada + rng.exponencial(1.0 / 240.0); // promedio 4 horas
        break;
      default:
        limiteSupervivenciaEspera = double.infinity; // Verde y Azul no fallecen por espera
    }
  }

  /// Empaqueta los datos del paciente para insertarlos en SQLite
  Map<String, dynamic> toMap(int simulacionId) {
    return {
      'simulacion_id': simulacionId,
      'paciente_id_local': id,
      'area': area.toString().split('.').last,
      'triage': triage?.toString().split('.').last ?? 'ninguno',
      'tiempo_llegada': tiempoLlegada,
      'tiempo_espera': tiempoEspera,
      'tiempo_atencion': tiempoAtencion,
      'tiempo_salida': tiempoSalida,
      'estado_final': estado.toString().split('.').last,
      'retraso_cita': retrasoReal ?? 0.0,
    };
  }

  @override
  String toString() {
    String nombreArea = area.toString().split('.').last;
    String nombreEstado = estado.toString().split('.').last;
    return 'Paciente #$id [$nombreArea] - $nombreEstado';
  }

  
}
