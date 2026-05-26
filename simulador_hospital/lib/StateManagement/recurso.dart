class Recurso {
  final String nombre;
  final int capacidadTotal;
  int enUso = 0;

  List<double> historialUtilizacion = [];

  Recurso({
    required this.nombre,
    required this.capacidadTotal,
  });

  /// recursos disponibles
  bool get hayDisponible => enUso < capacidadTotal;

  /// Número de recursos libres
  int get disponibles => capacidadTotal - enUso;

  /// Ocupar un recurso
  void ocupar() {
    if (!hayDisponible) {
      throw StateError('No hay recursos disponibles en $nombre');
    }
    enUso++;
  }

  /// Liberar un recurso
  void liberar() {
    if (enUso <= 0) {
      throw StateError('No hay recursos ocupados para liberar en $nombre');
    }
    enUso--;
  }

  double get utilizacion => enUso / capacidadTotal;

  void registrarUtilizacion() {
    historialUtilizacion.add(utilizacion);
  }

  double get utilizacionPromedio {
    if (historialUtilizacion.isEmpty) return 0.0;
    return historialUtilizacion.reduce((a, b) => a + b) /
        historialUtilizacion.length;
  }

  void reset() {
    enUso = 0;
    historialUtilizacion.clear();
  }

  @override
  String toString() {
    return '$nombre: $enUso/$capacidadTotal (${(utilizacion * 100).toStringAsFixed(1)}%)';
  }
}
