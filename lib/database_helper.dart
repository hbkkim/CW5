import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'aquarium.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE aquarium_settings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fish_count INTEGER,
            fish_speed REAL,
            fish_color TEXT
          )
        ''');
      },
    );
  }

  Future<void> saveAquariumSettings(int fishCount, double fishSpeed, String fishColor) async {
    final db = await database;
    await db.insert(
      'aquarium_settings',
      {
        'fish_count': fishCount,
        'fish_speed': fishSpeed,
        'fish_color': fishColor,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getAquariumSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('aquarium_settings');

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }
}
