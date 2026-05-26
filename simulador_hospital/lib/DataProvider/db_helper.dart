// lib/DataProvider/db_helper.dart
import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'hospital_sim_history.db');

    return await openDatabase(
      path,
      version: 2, 
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS pacientes');
        await db.execute('DROP TABLE IF EXISTS snapshots');
        await db.execute('DROP TABLE IF EXISTS simulaciones');
        await _createTables(db, newVersion);
      },
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // 1. Tabla de Simulaciones (Cabecera)
    await db.execute('''
      CREATE TABLE simulaciones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha_ejecucion TEXT,
        duracion_dias INTEGER,
        configuracion_json TEXT,
        total_atendidos INTEGER
      )
    ''');

    // 2. Tabla de Pacientes (Registro detallado para las tablas)
    await db.execute('''
      CREATE TABLE pacientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        simulacion_id INTEGER,
        paciente_id_local INTEGER,
        dia_simulacion INTEGER, 
        area TEXT,
        triage TEXT,
        tiempo_llegada REAL,
        tiempo_espera REAL,
        tiempo_atencion REAL,
        tiempo_salida REAL,
        estado_final TEXT,
        retraso_cita REAL,
        FOREIGN KEY (simulacion_id) REFERENCES simulaciones (id) ON DELETE CASCADE
      )
    ''');

    // 3. Tabla de Snapshots (Para gráficas dinámicas)
    await db.execute('''
      CREATE TABLE snapshots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        simulacion_id INTEGER,
        minuto INTEGER,
        cola_consulta INTEGER,
        cola_urgencias INTEGER,
        uso_camas REAL,
        FOREIGN KEY (simulacion_id) REFERENCES simulaciones (id) ON DELETE CASCADE
      )
    ''');
  }

  // ==========================================
  // MÉTODOS DE INSERCIÓN MASIVA (BATCH)
  // ==========================================

  /// Inserta una nueva simulación y devuelve su ID generado
  Future<int> insertarSimulacion(int dias, Map<String, dynamic> config, int totalAtendidos) async {
    final db = await database;
    return await db.insert('simulaciones', {
      'fecha_ejecucion': DateTime.now().toIso8601String(),
      'duracion_dias': dias,
      'configuracion_json': jsonEncode(config),
      'total_atendidos': totalAtendidos,
    });
  }

  /// Inserta miles de pacientes en una sola transacción para máximo rendimiento
  Future<void> insertarPacientesBatch(int simulacionId, List<Map<String, dynamic>> pacientes) async {
    final db = await database;
    final batch = db.batch();
    for (var p in pacientes) {
      p['simulacion_id'] = simulacionId;
      batch.insert('pacientes', p);
    }
    await batch.commit(noResult: true);
  }

  /// Inserta los snapshots históricos en bloque
  Future<void> insertarSnapshotsBatch(int simulacionId, List<Map<String, dynamic>> snapshots) async {
    final db = await database;
    final batch = db.batch();
    for (var s in snapshots) {
      s['simulacion_id'] = simulacionId;
      batch.insert('snapshots', s);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> obtenerPacientesPorSimulacion(int simulacionId) async {
    final db = await database;
    // Hacemos la consulta ordenada por el tiempo de llegada
    return await db.query(
      'pacientes',
      where: 'simulacion_id = ?',
      whereArgs: [simulacionId],
      orderBy: 'tiempo_llegada ASC'
    );
  }
}