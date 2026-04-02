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
    return await _loadState();
  }

  Future<GameState> _loadState() async {
    final db = await _dbService.database;
    final rows = await db.query(
      'game_state',
      orderBy: 'last_played DESC',
      limit: 1,
    );

    if (rows.isNotEmpty) {
      return GameState(currentNode: rows.first['current_node'] as String);
    }

    // Nodo iniziale di default se non ci sono salvataggi
    return GameState(currentNode: 'intro_void');
  }

  Future<void> updateNode(String newNode) async {
    final db = await _dbService.database;
    final now = DateTime.now().toIso8601String();

    final existing = await db.query('game_state', limit: 1);
    if (existing.isEmpty) {
      await db.insert('game_state', {
        'current_node': newNode,
        'last_played': now,
      });
    } else {
      await db.update(
        'game_state',
        {'current_node': newNode, 'last_played': now},
      );
    }

    state = const AsyncValue.loading();
    state = AsyncValue.data(await _loadState());
  }
}

final gameStateProvider =
    AsyncNotifierProvider<GameStateNotifier, GameState>(
  () => GameStateNotifier(),
);
