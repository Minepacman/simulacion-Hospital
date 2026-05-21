class Config {
  static Map<String, Map<String, double>> matrizTransicionUrgencias = {
    'enAtencion': {
      'dadoDeAlta': 0.20,
      'enObservacion': 0.55,
      'hospitalizado': 0.25,
    },
    'enObservacion': {
      'dadoDeAlta': 0.85, // se va uwu
      'hospitalizado': 0.15, //valio queso y se queda en cama
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
