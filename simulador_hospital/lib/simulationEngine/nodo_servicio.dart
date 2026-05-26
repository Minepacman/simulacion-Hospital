import 'generador_aleatorio.dart';

class NodoServicio {
  final String identificador;
  final String? recursoAsociado;
  final double Function(GeneradorAleatorio rng) generadorTiempoAtencion;
  final Map<String, double> transicionesMarkov;

  NodoServicio({
    required this.identificador,
    this.recursoAsociado,
    required this.generadorTiempoAtencion,
    required this.transicionesMarkov,
  });

  String obtenerSiguienteEstado(GeneradorAleatorio rng) {
    double u = rng.siguiente();
    double acumulada = 0.0;

    for (var transicion in transicionesMarkov.entries) {
      acumulada += transicion.value;
      if (u <= acumulada) return transicion.key;
    }
    return 'dadoDeAlta';
  }
}