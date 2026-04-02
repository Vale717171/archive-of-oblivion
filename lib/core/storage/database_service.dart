import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static const _databaseName = "oblivion_archive.db";
  static const _databaseVersion = 1;

  // Singleton pattern per evitare accessi concorrenti non sicuri
  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    // 1. Stato del Gioco
    await db.execute('''
      CREATE TABLE game_state (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        current_node TEXT NOT NULL,
        last_played TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 2. Profilo Psicologico (influenzato dalle scelte e dall'LLM)
    await db.execute('''
      CREATE TABLE psycho_profile (
        id INTEGER PRIMARY KEY CHECK (id = 1), -- Assicura una sola riga
        lucidity INTEGER DEFAULT 50,
        oblivion_level INTEGER DEFAULT 0,
        anxiety INTEGER DEFAULT 10
      )
    ''');

    // 3. Cronologia Dialoghi (Memoria LLM)
    // Usiamo indici su timestamp per query veloci quando peschiamo il context window
    await db.execute('''
      CREATE TABLE dialogue_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role TEXT NOT NULL CHECK(role IN ('user', 'llm', 'system')),
        content TEXT NOT NULL,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_dialogue_time ON dialogue_history(timestamp)');

    // Inizializza il profilo psicologico di base
    await db.insert('psycho_profile', {'id': 1});
  }
}
