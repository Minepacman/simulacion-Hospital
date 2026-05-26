import 'dart:math' as math;

/// Lineal Congruencial (LCG)
class GeneradorAleatorio {
  int _semilla;

  static const int _m = 2147483647;
  static const int _a = 48271;
  static const int _c = 0;

  GeneradorAleatorio(this._semilla);

  double siguiente() {
    _semilla = (_a * _semilla + _c) % _m;
    return _semilla / _m;
  }

  /// Distribución Exponencial usando Método de la Transformada Inversa

  double exponencial(double lambda) {
    if (lambda <= 0) {
      throw ArgumentError('Lambda debe ser positivo');
    }

    double u = siguiente();
    if (u == 0.0) u = 0.0000001;

    return (-1.0 / lambda) * math.log(1.0 - u);
  }

  /// Distribución Normal usando el Método de Box-Muller

  double normal(double media, double desviacion) {
    if (desviacion <= 0) {
      throw ArgumentError('La desviación debe ser positiva');
    }

    double u1 = siguiente();
    double u2 = siguiente();

    if (u1 == 0.0) u1 = 0.0000001;

    double z0 = math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2);

    return media + desviacion * z0;
  }

  int enteroEntre(int min, int max) {
    return min + (siguiente() * (max - min)).floor();
  }

  bool booleanoConProbabilidad(double p) {
    return siguiente() < p;
  }
}
