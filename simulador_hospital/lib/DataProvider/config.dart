class Config {
  static Map<String, Map<String, Map<String, double>>> matricesMarkovUrgencias =
      {
    'reanimacionRojo': {
      'enAtencion': {
        'hospitalizado': 0.95,
        'enObservacion': 0.05,
        'dadoDeAlta': 0.0
      },
      'enObservacion': {'hospitalizado': 0.80, 'dadoDeAlta': 0.20}
    },
    'emergenciaNaranja': {
      'enAtencion': {
        'hospitalizado': 0.60,
        'enObservacion': 0.35,
        'dadoDeAlta': 0.05
      },
      'enObservacion': {'hospitalizado': 0.40, 'dadoDeAlta': 0.60}
    },
    'urgenciaAmarillo': {
      'enAtencion': {
        'enObservacion': 0.70,
        'dadoDeAlta': 0.25,
        'hospitalizado': 0.05
      },
      'enObservacion': {'dadoDeAlta': 0.90, 'hospitalizado': 0.10}
    },
    'urgenciaMenorVerde': {
      'enAtencion': {
        'dadoDeAlta': 0.85,
        'enObservacion': 0.15,
        'hospitalizado': 0.0
      },
      'enObservacion': {'dadoDeAlta': 0.99, 'hospitalizado': 0.01}
    },
    'sinUrgenciaAzul': {

      'enAtencion': {
        'dadoDeAlta': 1.0,
        'enObservacion': 0.0,
        'hospitalizado': 0.0
      },
      'enObservacion': {'dadoDeAlta': 1.0, 'hospitalizado': 0.0}
    }
    
  };

  static Map<String, Map<String, double>> matrizTransicionConsulta = {
    'enAtencion': {
      'dadoDeAlta': 0.95,
      'hospitalizado': 0.05,
    }
  };

  static int horaInicio = 8 * 60;
  static int horaFin = 20 * 60;
  static int minutosSimulacion = horaFin - horaInicio;

  // Consulta Externa
  static int citasProgramadasPorDia = 40;
  static double tiempoPromedioConsulta = 15.0;
  static double desviacionRetraso = 10.0; // parametro de la distribucion normal
  static double limiteRetrasoPermitido = 10.0;

  //parametros poiison
  static double lambdaUrgencias = 0.1;
  static double tiempoPromedioUrgencia = 25.0;
  static double tiempoPromedioObservacion = 120.0;

  // Hospitalización
  static double probUrgenciaAHospitalizacion = 0.25;
  static double tiempoPromedioHospitalizacion = 4320.0;

  static int numeroMedicosConsulta = 3;
  static int numeroMedicosUrgencias = 2;
  static int numeroCamas = 10;

  static int numeroReplicas = 5;

  //triage
  static List<double> probabilidadesTriage = [0.05, 0.15, 0.35, 0.30, 0.15];
}
