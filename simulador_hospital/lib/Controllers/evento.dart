import 'paciente.dart';

/// Tipos de eventos en el sistema
enum TipoEvento {
  llegadaConsulta,
  llegadaUrgencia,
  finConsulta,
  finUrgencia,
  finObservacion,
  ingresoHospitalizacion,
  altaHospitalizacion,
}

class Evento implements Comparable<Evento> {
  final TipoEvento tipo;
  final double tiempo; // En minutos desde el inicio
  final Paciente? paciente;

  Evento({
    required this.tipo,
    required this.tiempo,
    this.paciente,
  });

  @override
  int compareTo(Evento otro) {
    // Ordenar por tiempo
    return tiempo.compareTo(otro.tiempo);
  }

  @override
  String toString() {
    String nombreTipo = tipo.toString().split('.').last;
    String nombrePaciente = paciente != null ? 'P${paciente!.id}' : 'N/A';
    return 'Evento($nombreTipo, t=${tiempo.toStringAsFixed(2)}, $nombrePaciente)';
  }

  String get tiempoFormateado {
    int totalMinutos = tiempo.floor();
    int horas = (totalMinutos ~/ 60) + 8;
    int minutos = totalMinutos % 60;
    return '${horas.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')}';
  }
}
