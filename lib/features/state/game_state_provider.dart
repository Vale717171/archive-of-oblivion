// lib/features/state/game_state_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart'; // required for ConflictAlgorithm
import '../../core/storage/database_service.dart';

class GameState {
  final String currentNode;
  GameState({required this.currentNode});
}

class GameStateNotifier extends AsyncNotifier<GameState> {
  final _dbService = DatabaseService.instance;

  @override
  Future<GameState> build() async {
    final db = await _dbService.database;
    final maps =
        await db.query('game_state', orderBy: 'last_played DESC', limit: 1);

    if (maps.isNotEmpty) {
      return GameState(currentNode: maps.first['current_node'] as String);
    }
    // Nodo iniziale
    return GameState(currentNode: 'intro_void');
  }

  /// Aggiorna o crea la riga (single source of truth)
  Future<void> updateNode(String newNode) async {
    final db = await _dbService.database;

    await db.insert(
      'game_state',
      {
        'id': 1, // forza single-row: senza questo ConflictAlgorithm.replace non ha mai un conflitto da gestire
        'current_node': newNode,
        'last_played': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    state = AsyncValue.data(GameState(currentNode: newNode));
  }
}

final gameStateProvider =
    AsyncNotifierProvider<GameStateNotifier, GameState>(
        () => GameStateNotifier());
