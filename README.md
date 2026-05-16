# simulacion-Hospital
Proyecto Final de la materia de simulación


Se desea modelar el comportamiento de las diferentes áreas de atención de un hospital considerando que existen llegadas aleatorias de pacientes, tiempos variables de atención, posibles cambios de estado del paciente, formación de colas y saturación del sistema. El objetivo es analizar los tiempos promedio de espera, utilización del personal, tamaño de colas, probabilidad de saturación y evolución del estado de pacientes mediante un software de simulación desarrollado a la medida. 

Se sabe que las llegadas de pacientes al área de urgencias siguen un proceso de Distribución de Poisson, y que un paciente que llega a urgencias tiene una probabilidad de pasar a hospitalización dependiendo de su estado clínico y la disponibilidad de recursos. Los tiempos entre llegadas podrán modelarse mediante una distribución exponencial asociada al proceso de Poisson. 

Los pacientes que llegan a consulta externa se atienden mediante un sistema de citas programadas. Sin embargo, las llegadas reales presentan perturbaciones aleatorias debido a retrasos, cancelaciones o adelantos. Por esta razón, el horario de llegada del paciente deberá modelarse como una desviación respecto a la hora programada utilizando una distribución normal con desviación estándar aproximada de 10 minutos. Si el paciente llega con más de 10 minutos de retraso, la cita se considera perdida y deberá reprogramarse. 

Por otro lado, los tiempos asociados al área de hospitalización deberán modelarse mediante distribuciones exponenciales relacionadas con la liberación de camas, duración de estancia hospitalaria y tiempos de permanencia de pacientes. El sistema deberá considerar que la disponibilidad de camas afecta dinámicamente la capacidad de admisión y el nivel de saturación hospitalaria. 

Usualmente, el ciclo de un paciente para el área de consulta externa es: 

{llegada, espera, consulta,salida} 

Para el área de urgencias: 

{llegada, triage, espera, consulta, observación, alta} 

 

o bien: 

{llegada, triage, espera, consulta, hospitalización} 

Para el área de hospitalización: 

{ingreso, asignación, atención, observación, alta} 

Sin embargo, los ciclos podrán modificarse dependiendo de la naturaleza de la atención médica, gravedad del paciente y disponibilidad de recursos hospitalarios. 

Se desea que la herramienta permita definir y modificar dinámicamente cualquier flujo de atención utilizando matrices de transición y modelos de estados, de forma que el comportamiento del sistema pueda representarse mediante Cadena de Markov o grafos de transición parametrizables. 

La simulación deberá desarrollarse utilizando un enfoque de Simulación de eventos discretos, considerando eventos como: 

llegada de pacientes, 
asignación de recursos, 
inicio y fin de atención, 
transición entre estados, 
liberación de camas, 
salida del sistema. 
Los números pseudoaleatorios deberán implementarse sin utilizar librerías externas especializadas, así como las transformaciones necesarias para construir las diferentes distribuciones probabilísticas utilizadas por el sistema. El estudiante podrá implementar algoritmos como generadores, así como métodos de transformación de distribuciones mediante transformada inversa, aceptación–rechazo o Box–Muller. 

El sistema deberá entregar las siguientes métricas: 

tiempo promedio de espera, 
utilización de recursos, 
tamaño promedio de colas, 
porcentaje de ocupación hospitalaria, 
número promedio de pacientes atendidos, 
probabilidad de saturación, 
distribución temporal de pacientes, 
utilización de camas y personal médico. 
Las métricas deberán analizarse en periodos semanales, mensuales y anuales y presentarse mediante un dashboard interactivo que permita visualizar la evolución temporal del sistema. 

Además, el sistema deberá permitir ejecutar múltiples simulaciones independientes para realizar análisis estadísticos, sensibilidad de parámetros e intervalos de confianza sobre las métricas obtenidas. 
