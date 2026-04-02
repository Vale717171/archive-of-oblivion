// lib/core/storage/dialogue_history_service.dart
// Author: GitHub Copilot — 2026-04-02
// Persists the conversation history to SQLite (dialogue_history table).
// Used by GameEngineNotifier to maintain a diegetic memory for future LLM context.

import 'database_service.dart';

class DialogueHistoryService {
  static final DialogueHistoryService instance =
      DialogueHistoryService._privateConstructor();
  DialogueHistoryService._privateConstructor();

  final _db = DatabaseService.instance;

  /// Save a single exchange to the history.
  /// [role] must be one of: 'user' | 'llm' | 'system'
  Future<void> save({required String role, required String content}) async {
    final db = await _db.database;
    await db.insert('dialogue_history', {
      'role': role,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Return the [limit] most recent entries, newest first.
  Future<List<Map<String, dynamic>>> recent({int limit = 20}) async {
    final db = await _db.database;
    return db.query(
      'dialogue_history',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  /// Return the last [limit] entries in chronological order (oldest first).
  /// Useful for building an LLM context window.
  Future<List<Map<String, dynamic>>> contextWindow({int limit = 10}) async {
    final db = await _db.database;
    final rows = await db.query(
      'dialogue_history',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return rows.reversed.toList();
  }

  /// Delete all history (e.g., on new game).
  Future<void> clear() async {
    final db = await _db.database;
    await db.delete('dialogue_history');
  }
}
