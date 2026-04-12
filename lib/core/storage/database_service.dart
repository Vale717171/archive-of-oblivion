import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static const _databaseName = "oblivion_archive.db";
  static const _databaseVersion = 9;
  static const int defaultLucidity = 50;
  static const int defaultOblivionLevel = 0;
  static const int defaultAnxiety = 10;
  static const int defaultPhase = 1;
  static const int defaultAwarenessLevel = 0;
  static const Map<String, Object?> defaultPsychoProfileRow = {
    'id': 1,
    'lucidity': defaultLucidity,
    'oblivion_level': defaultOblivionLevel,
    'anxiety': defaultAnxiety,
    'phase': defaultPhase,
    'awareness_level': defaultAwarenessLevel,
    'proust_affinity': 0,
    'tarkovskij_affinity': 0,
    'seth_affinity': 0,
  };
  static const Map<String, Object?> defaultAppSettingsRow = {
    'id': 1,
    'instant_text': 0,
    'reduce_motion': 0,
    'high_contrast': 0,
    'command_assist': 1,
    'music_enabled': 1,
    'music_volume': 0.85,
    'sfx_enabled': 1,
    'sfx_volume': 0.90,
    'text_scale': 1.0,
    'typewriter_millis': 22,
    'mute_in_background': 1,
    'enable_haptics': 1,
  };

  // Singleton pattern per evitare accessi concorrenti non sicuri
  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  static Database? _database;
  static Completer<Database>? _initCompleter;

  Future<Database> get database async {
    if (_database != null) return _database!;
    // Use a Completer to ensure only one _initDatabase() runs at a time
    if (_initCompleter != null) return _initCompleter!.future;
    _initCompleter = Completer<Database>();
    try {
      _database = await _initDatabase();
      _initCompleter!.complete(_database!);
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null;
      rethrow;
    }
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

    // 2. Profilo Psicologico (influenzato dalle scelte del giocatore)
    await db.execute('''
      CREATE TABLE psycho_profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        lucidity INTEGER DEFAULT 50,
        oblivion_level INTEGER DEFAULT 0,
        anxiety INTEGER DEFAULT 10
      )
    ''');

    // 3. Cronologia Dialoghi (memoria diegetica della sessione)
    // Usiamo indici su timestamp per query veloci quando peschiamo la cronologia recente.
    await db.execute('''
      CREATE TABLE dialogue_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role TEXT NOT NULL CHECK(role IN ('user', 'llm', 'demiurge', 'system')),
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

    await db.execute('''
      CREATE TABLE app_settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        instant_text INTEGER NOT NULL DEFAULT 0,
        reduce_motion INTEGER NOT NULL DEFAULT 0,
        high_contrast INTEGER NOT NULL DEFAULT 0,
        command_assist INTEGER NOT NULL DEFAULT 1,
        music_enabled INTEGER NOT NULL DEFAULT 1,
        music_volume REAL NOT NULL DEFAULT 0.85,
        sfx_enabled INTEGER NOT NULL DEFAULT 1,
        sfx_volume REAL NOT NULL DEFAULT 0.90,
        text_scale REAL NOT NULL DEFAULT 1.0,
        typewriter_millis INTEGER NOT NULL DEFAULT 22
      )
    ''');

    // 5. Save slots (slot 0 = auto-save, 1-3 = manual)
    await db.execute('''
      CREATE TABLE save_slots (
        slot INTEGER PRIMARY KEY,
        current_node TEXT NOT NULL DEFAULT '',
        completed_puzzles TEXT NOT NULL DEFAULT '[]',
        puzzle_counters TEXT NOT NULL DEFAULT '{}',
        inventory TEXT NOT NULL DEFAULT '["notebook"]',
        psycho_weight INTEGER NOT NULL DEFAULT 0,
        lucidity INTEGER NOT NULL DEFAULT 50,
        oblivion_level INTEGER NOT NULL DEFAULT 0,
        anxiety INTEGER NOT NULL DEFAULT 10,
        phase INTEGER NOT NULL DEFAULT 1,
        awareness_level INTEGER NOT NULL DEFAULT 0,
        proust_affinity INTEGER NOT NULL DEFAULT 0,
        tarkovskij_affinity INTEGER NOT NULL DEFAULT 0,
        seth_affinity INTEGER NOT NULL DEFAULT 0,
        sector_label TEXT NOT NULL DEFAULT '',
        saved_at TEXT NOT NULL DEFAULT ''
      )
    ''');

    // Inizializza il profilo psicologico di base
    await db.insert('psycho_profile', defaultPsychoProfileRow);
    await db.insert('app_settings', defaultAppSettingsRow);
  }

  // ── Versioning protocol ──────────────────────────────────────────────────────
  //
  // Every schema change MUST:
  //   1. Bump `_databaseVersion` by 1.
  //   2. Add a new `if (oldVersion < N)` block at the bottom of `_onUpgrade`.
  //   3. Use `_addColumnIfNotExists` when adding columns — NEVER raw ALTER TABLE.
  //      This keeps every step idempotent (safe even if a migration was partially
  //      applied) and prevents "duplicate column name" crashes.
  //   4. Wrap the block in `db.transaction` for atomicity.
  //   5. Never DROP or RENAME columns already used by running installs — add new
  //      columns with a DEFAULT value so existing rows are automatically filled.
  //
  // Example for a future v6 (new column on game_state):
  //
  //   if (oldVersion < 6) {
  //     await db.transaction((txn) async {
  //       await _addColumnIfNotExists(
  //         txn, 'game_state', 'new_ending_flag',
  //         'INTEGER NOT NULL DEFAULT 0',
  //       );
  //     });
  //   }
  // ─────────────────────────────────────────────────────────────────────────────

  /// Safely adds [column] to [table] only when it is not already present.
  ///
  /// SQLite does not support `ALTER TABLE … ADD COLUMN IF NOT EXISTS`, so we
  /// query `PRAGMA table_info` first.  This makes every upgrade step idempotent:
  /// re-running the same migration on a database that already has the column is
  /// a no-op instead of a crash.
  ///
  /// [table] and [column] must be valid SQLite identifiers (letters, digits,
  /// underscores only). [definition] must be a type + optional constraint
  /// expression using only the characters allowed in SQL DDL.  These
  /// preconditions are enforced at runtime to prevent SQL injection even though
  /// this is a private method called only with hard-coded literals.
  Future<void> _addColumnIfNotExists(
    DatabaseExecutor db,
    String table,
    String column,
    String definition,
  ) async {
    // Validate that table and column look like plain SQL identifiers.
    final identifierRe = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');
    assert(identifierRe.hasMatch(table),
        '_addColumnIfNotExists: invalid table name: $table');
    assert(identifierRe.hasMatch(column),
        '_addColumnIfNotExists: invalid column name: $column');

    final tableInfo = await db.rawQuery('PRAGMA table_info($table)');
    final exists = tableInfo.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v1 → v2: espandi game_state con colonne engine + crea player_memories.
      // Usa _addColumnIfNotExists per rendere il passo idempotente.
      await db.transaction((txn) async {
        await _addColumnIfNotExists(txn, 'game_state', 'completed_puzzles',
            'TEXT NOT NULL DEFAULT \'[]\'');
        await _addColumnIfNotExists(txn, 'game_state', 'puzzle_counters',
            'TEXT NOT NULL DEFAULT \'{}\'');
        await _addColumnIfNotExists(txn, 'game_state', 'inventory',
            'TEXT NOT NULL DEFAULT \'["notebook"]\'');
        await _addColumnIfNotExists(txn, 'game_state', 'psycho_weight',
            'INTEGER NOT NULL DEFAULT 0');

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
    if (oldVersion < 3) {
      // v2 → v3: ricrea dialogue_history con CHECK su role e migra i dati.
      await db.transaction((txn) async {
        await txn.execute(
            'ALTER TABLE dialogue_history RENAME TO dialogue_history_old');
        await txn.execute('''
          CREATE TABLE dialogue_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            role TEXT NOT NULL CHECK(role IN ('user', 'llm', 'demiurge', 'system')),
            content TEXT NOT NULL,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        await txn.execute('''
          INSERT INTO dialogue_history (id, role, content, timestamp)
          SELECT id,
                 CASE WHEN role = 'llm' THEN 'demiurge' ELSE role END,
                 content,
                 timestamp
          FROM dialogue_history_old
        ''');
        await txn.execute(
            'CREATE INDEX idx_dialogue_time ON dialogue_history(timestamp)');
        await txn.execute('DROP TABLE dialogue_history_old');
      });
    }
    if (oldVersion < 4) {
      // v3 → v4: crea app_settings (include già le colonne audio).
      await db.transaction((txn) async {
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS app_settings (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            instant_text INTEGER NOT NULL DEFAULT 0,
            reduce_motion INTEGER NOT NULL DEFAULT 0,
            high_contrast INTEGER NOT NULL DEFAULT 0,
            command_assist INTEGER NOT NULL DEFAULT 1,
            music_enabled INTEGER NOT NULL DEFAULT 1,
            music_volume REAL NOT NULL DEFAULT 0.85,
            sfx_enabled INTEGER NOT NULL DEFAULT 1,
            sfx_volume REAL NOT NULL DEFAULT 0.90,
            text_scale REAL NOT NULL DEFAULT 1.0,
            typewriter_millis INTEGER NOT NULL DEFAULT 22
          )
        ''');
        await txn.insert(
          'app_settings',
          defaultAppSettingsRow,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
    }
    // v4 → v5: no schema changes — audio columns (music_enabled, music_volume,
    // sfx_enabled, sfx_volume) were already included in the v4 CREATE TABLE.
    // The ALTER TABLE statements that used to live here were redundant and
    // caused a "duplicate column name" crash on any upgrade path through v4.
    if (oldVersion < 6) {
      // v5 → v6: add mute_in_background column to app_settings.
      await db.transaction((txn) async {
        await _addColumnIfNotExists(
          txn,
          'app_settings',
          'mute_in_background',
          'INTEGER NOT NULL DEFAULT 1',
        );
      });
    }
    if (oldVersion < 7) {
      // v6 → v7: add enable_haptics column to app_settings.
      await db.transaction((txn) async {
        await _addColumnIfNotExists(
          txn,
          'app_settings',
          'enable_haptics',
          'INTEGER NOT NULL DEFAULT 1',
        );
      });
    }
    if (oldVersion < 8) {
      // v7 → v8: add phase system columns to psycho_profile.
      await db.transaction((txn) async {
        await _addColumnIfNotExists(txn, 'psycho_profile', 'phase',
            'INTEGER NOT NULL DEFAULT 1');
        await _addColumnIfNotExists(txn, 'psycho_profile', 'awareness_level',
            'INTEGER NOT NULL DEFAULT 0');
        await _addColumnIfNotExists(txn, 'psycho_profile', 'proust_affinity',
            'INTEGER NOT NULL DEFAULT 0');
        await _addColumnIfNotExists(txn, 'psycho_profile', 'tarkovskij_affinity',
            'INTEGER NOT NULL DEFAULT 0');
        await _addColumnIfNotExists(txn, 'psycho_profile', 'seth_affinity',
            'INTEGER NOT NULL DEFAULT 0');
      });
    }
    if (oldVersion < 9) {
      // v8 → v9: create save_slots table (slot 0 = auto-save, 1-3 = manual).
      await db.execute('''
        CREATE TABLE IF NOT EXISTS save_slots (
          slot INTEGER PRIMARY KEY,
          current_node TEXT NOT NULL DEFAULT '',
          completed_puzzles TEXT NOT NULL DEFAULT '[]',
          puzzle_counters TEXT NOT NULL DEFAULT '{}',
          inventory TEXT NOT NULL DEFAULT '["notebook"]',
          psycho_weight INTEGER NOT NULL DEFAULT 0,
          lucidity INTEGER NOT NULL DEFAULT 50,
          oblivion_level INTEGER NOT NULL DEFAULT 0,
          anxiety INTEGER NOT NULL DEFAULT 10,
          phase INTEGER NOT NULL DEFAULT 1,
          awareness_level INTEGER NOT NULL DEFAULT 0,
          proust_affinity INTEGER NOT NULL DEFAULT 0,
          tarkovskij_affinity INTEGER NOT NULL DEFAULT 0,
          seth_affinity INTEGER NOT NULL DEFAULT 0,
          sector_label TEXT NOT NULL DEFAULT '',
          saved_at TEXT NOT NULL DEFAULT ''
        )
      ''');
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

  /// Deletes all saved player memories.
  Future<void> clearAllMemories() async {
    final db = await database;
    await db.delete('player_memories');
  }
}
