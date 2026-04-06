// lib/features/state/game_state_provider.dart
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart'; // required for ConflictAlgorithm
import '../../core/storage/database_service.dart';

class GameState {
  final String currentNode;
  final Set<String> completedPuzzles;
  final Map<String, int> puzzleCounters;
  final List<String> inventory;
  final int psychoWeight;

  GameState({
    required this.currentNode,
    this.completedPuzzles = const {},
    this.puzzleCounters = const {},
    this.inventory = const ['notebook'],
    this.psychoWeight = 0,
  });

  /// Deserializza una riga del DB (`game_state`) in un [GameState].
  factory GameState.fromRow(Map<String, Object?> row) {
    return GameState(
      currentNode:      row['current_node'] as String,
      completedPuzzles: Set<String>.from(
          jsonDecode(row['completed_puzzles'] as String? ?? '[]') as List),
      puzzleCounters:   Map<String, int>.from(
          (jsonDecode(row['puzzle_counters'] as String? ?? '{}') as Map)
              .map((k, v) => MapEntry(k as String, (v as num).toInt()))),
      inventory:        List<String>.from(
          jsonDecode(row['inventory'] as String? ?? '["notebook"]') as List),
      psychoWeight:     row['psycho_weight'] as int? ?? 0,
    );
  }
}

class GameStateNotifier extends AsyncNotifier<GameState> {
  final _dbService = DatabaseService.instance;

  @override
  Future<GameState> build() async {
    final db = await _dbService.database;
    final maps = await db.query('game_state', where: 'id = 1', limit: 1);

    if (maps.isNotEmpty) {
      try {
        return GameState.fromRow(maps.first);
      } catch (_) {
        return GameState(currentNode: 'intro_void');
      }
    }
    // Prima esecuzione: nodo iniziale
    return GameState(currentNode: 'intro_void');
  }

  /// Salva l'intero stato del motore — chiamata alla fine di ogni processInput.
  Future<void> saveEngineState({
    required String currentNode,
    required Set<String> completedPuzzles,
    required Map<String, int> puzzleCounters,
    required List<String> inventory,
    required int psychoWeight,
  }) async {
    final db = await _dbService.database;
    await db.insert(
      'game_state',
      {
        'id':               1,
        'current_node':     currentNode,
        'completed_puzzles': jsonEncode(completedPuzzles.toList()),
        'puzzle_counters':  jsonEncode(puzzleCounters),
        'inventory':        jsonEncode(inventory),
        'psycho_weight':    psychoWeight,
        'last_played':      DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    state = AsyncValue.data(GameState(
      currentNode:      currentNode,
      completedPuzzles: completedPuzzles,
      puzzleCounters:   puzzleCounters,
      inventory:        inventory,
      psychoWeight:     psychoWeight,
    ));
  }

  /// Retrocompatibilità — aggiorna solo il nodo corrente senza toccare
  /// gli altri campi (usato nei punti in cui il nodo cambia ma lo stato
  /// completo non è ancora disponibile).
  Future<void> updateNode(String newNode) async {
    final current = state.valueOrNull;
    await saveEngineState(
      currentNode:      newNode,
      completedPuzzles: current?.completedPuzzles ?? const {},
      puzzleCounters:   current?.puzzleCounters   ?? const {},
      inventory:        current?.inventory         ?? const ['notebook'],
      psychoWeight:     current?.psychoWeight      ?? 0,
    );
  }

  Future<void> resetGameState() async {
    await saveEngineState(
      currentNode: 'intro_void',
      completedPuzzles: const {},
      puzzleCounters: const {},
      inventory: const ['notebook'],
      psychoWeight: 0,
    );
  }
}

final gameStateProvider =
    AsyncNotifierProvider<GameStateNotifier, GameState>(
        () => GameStateNotifier());
