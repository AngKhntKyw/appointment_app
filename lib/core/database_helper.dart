import 'package:appointment_app/models/appointment.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('appointments.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE appointments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        appointmentDateTime TEXT NOT NULL,
        addressLat REAL, 
        addressLng REAL,
        mockId TEXT
      )
    ''');
  }

  Future<int> createAppointment(Appointment appointment) async {
    final db = await instance.database;
    return await db.insert('appointments', appointment.toMap());
  }

  Future<List<Appointment>> readAllAppointments() async {
    final db = await instance.database;
    final result = await db.query('appointments');
    return result.map((map) => Appointment.fromMap(map)).toList();
  }

  Future<Appointment?> getAppointmentById(int id) async {
    final db = await instance.database;

    final result = await db.query(
      'appointments',
      where: 'id = ?',
      whereArgs: [id],
    );

    return Appointment.fromMap(result.first);
  }

  Future<int> updateAppointment(Appointment appointment) async {
    final db = await instance.database;
    return await db.update(
      'appointments',
      appointment.toMap(),
      where: 'id = ?',
      whereArgs: [appointment.id],
    );
  }

  Future<int> deleteAppointment(int id) async {
    final db = await instance.database;
    return await db.delete(
      'appointments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Appointment>> searchAppointments(
      {String? query, DateTime? filterDate}) async {
    final db = await instance.database;
    final whereClause = <String>[];
    final whereArgs = <dynamic>[];

    if (query != null) {
      whereClause.add('(name LIKE ? OR description LIKE ?)');
      whereArgs.addAll(['%$query%', '%$query%']);
    }

    if (filterDate != null) {
      whereClause.add('DATE(appointmentDateTime) = DATE(?)');
      whereArgs.add(filterDate.toIso8601String());
    }

    final result = await db.query(
      'appointments',
      where: whereClause.isNotEmpty ? whereClause.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );
    return result.map((map) => Appointment.fromMap(map)).toList();
  }
}
