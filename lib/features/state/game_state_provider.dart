import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final maps = await db.query('game_state',
        orderBy: 'last_played DESC', limit: 1);

    if (maps.isNotEmpty) {
      return GameState(currentNode: maps.first['current_node'] as String);
    }
    // Nodo iniziale di default se non ci sono salvataggi
    return GameState(currentNode: 'intro_void');
  }

  Future<void> updateNode(String newNode) async {
    final db = await _dbService.database;
    await db.insert('game_state', {'current_node': newNode});
    state = AsyncValue.data(GameState(currentNode: newNode));
  }
}

final gameStateProvider =
    AsyncNotifierProvider<GameStateNotifier, GameState>(() {
  return GameStateNotifier();
});
