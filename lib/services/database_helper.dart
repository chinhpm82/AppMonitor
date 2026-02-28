import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    sqfliteFfiInit();
    var databaseFactory = databaseFactoryFfi;
    
    final Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, 'roblox_monitor.db');

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS play_logs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              start_time TEXT,
              end_time TEXT,
              duration_seconds INTEGER,
              type TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS settings (
              key TEXT PRIMARY KEY,
              value TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS system_logs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              timestamp TEXT,
              message TEXT,
              level TEXT
            )
          ''');
        },
        onOpen: (db) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS system_logs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              timestamp TEXT,
              message TEXT,
              level TEXT
            )
          ''');
        },
      ),
    );
  }

  static Future<void> logSystemEvent(String message, {String level = 'INFO'}) async {
    final db = await database;
    await db.insert('system_logs', {
      'timestamp': DateTime.now().toIso8601String(),
      'message': message,
      'level': level,
    });
    // Keep only last 200 logs to avoid bloating
    await db.execute('DELETE FROM system_logs WHERE id NOT IN (SELECT id FROM system_logs ORDER BY id DESC LIMIT 200)');
  }

  static Future<List<Map<String, dynamic>>> getSystemLogs() async {
    final db = await database;
    return await db.query('system_logs', orderBy: 'id DESC', limit: 100);
  }

  static Future<void> logPlay(DateTime start, DateTime end, int duration, String type) async {
    final db = await database;
    await db.insert('play_logs', {
      'start_time': start.toIso8601String(),
      'end_time': end.toIso8601String(),
      'duration_seconds': duration,
      'type': type,
    });
  }

  static Future<List<Map<String, dynamic>>> getLogs() async {
    final db = await database;
    return await db.query('play_logs', orderBy: 'start_time DESC');
  }

  static Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<String?> getSetting(String key) async {
    final db = await database;
    final results = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (results.isNotEmpty) {
      return results.first['value'] as String;
    }
    return null;
  }
}
