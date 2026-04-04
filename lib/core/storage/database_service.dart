import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static const _databaseName = "oblivion_archive.db";
  static const _databaseVersion = 2;

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
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    // 1. Stato del Gioco (include persistenza completa del motore)
    await db.execute('''
      CREATE TABLE game_state (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        current_node TEXT NOT NULL DEFAULT 'intro_void',
        completed_puzzles TEXT NOT NULL DEFAULT '[]',
        puzzle_counters TEXT NOT NULL DEFAULT '{}',
        inventory TEXT NOT NULL DEFAULT '["notebook"]',
        psycho_weight INTEGER NOT NULL DEFAULT 0,
        last_played TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 2. Profilo Psicologico (influenzato dalle scelte e dall'LLM)
    await db.execute('''
      CREATE TABLE psycho_profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
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

    // 4. Memorie del giocatore — risposte proustiane e risposte alla Zona
    await db.execute('''
      CREATE TABLE player_memories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        memory_key TEXT NOT NULL UNIQUE,
        content TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Inizializza il profilo psicologico di base
    await db.insert('psycho_profile', {'id': 1});
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v1 → v2: espandi game_state con colonne engine + crea player_memories
      // Eseguito in una transazione per garantire atomicità della migrazione.
      await db.transaction((txn) async {
        await txn.execute(
            'ALTER TABLE game_state ADD COLUMN completed_puzzles TEXT NOT NULL DEFAULT \'[]\'');
        await txn.execute(
            'ALTER TABLE game_state ADD COLUMN puzzle_counters TEXT NOT NULL DEFAULT \'{}\'');
        await txn.execute(
            'ALTER TABLE game_state ADD COLUMN inventory TEXT NOT NULL DEFAULT \'["notebook"]\'');
        await txn.execute(
            'ALTER TABLE game_state ADD COLUMN psycho_weight INTEGER NOT NULL DEFAULT 0');

        await txn.execute('''
          CREATE TABLE IF NOT EXISTS player_memories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            memory_key TEXT NOT NULL UNIQUE,
            content TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      });
    }
  }

  // ── Player memories ──────────────────────────────────────────────────────────

  /// Salva (o aggiorna) una memoria del giocatore identificata da [key].
  Future<void> saveMemory({required String key, required String content}) async {
    final db = await database;
    await db.insert(
      'player_memories',
      {'memory_key': key, 'content': content},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Carica tutte le memorie del giocatore come mappa key → content.
  Future<Map<String, String>> loadAllMemories() async {
    final db = await database;
    final rows = await db.query('player_memories', orderBy: 'created_at ASC');
    return {
      for (final r in rows)
        r['memory_key'] as String: r['content'] as String,
    };
  }
}
