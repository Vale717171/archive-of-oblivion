// lib/core/services/save_service.dart
// Multi-slot save system for L'Archivio dell'Oblio.
//
// Slots:
//   0 — Auto-save (updated every 6 commands or on sector change, silently)
//   1-3 — Manual saves
//
// Each slot is a snapshot of game_state + psycho_profile at a point in time.
// Player memories and dialogue history are session-wide and are NOT per-slot.

import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../storage/database_service.dart';

/// A snapshot of game + profile state stored in a save slot.
class SaveSlot {
  final int slot;

  // Game state
  final String currentNode;
  final Set<String> completedPuzzles;
  final Map<String, int> puzzleCounters;
  final List<String> inventory;
  final int psychoWeight;

  // Psycho profile
  final int lucidity;
  final int oblivionLevel;
  final int anxiety;
  final int phase;
  final int awarenessLevel;
  final int proustAffinity;
  final int tarkovskijAffinity;
  final int sethAffinity;

  // Preview metadata
  final String sectorLabel;
  final DateTime? savedAt; // null → slot is empty

  const SaveSlot({
    required this.slot,
    required this.currentNode,
    required this.completedPuzzles,
    required this.puzzleCounters,
    required this.inventory,
    required this.psychoWeight,
    required this.lucidity,
    required this.oblivionLevel,
    required this.anxiety,
    required this.phase,
    required this.awarenessLevel,
    required this.proustAffinity,
    required this.tarkovskijAffinity,
    required this.sethAffinity,
    required this.sectorLabel,
    required this.savedAt,
  });

  bool get isEmpty => savedAt == null || currentNode.isEmpty;

  factory SaveSlot.empty(int slot) => SaveSlot(
        slot: slot,
        currentNode: '',
        completedPuzzles: const {},
        puzzleCounters: const {},
        inventory: const ['notebook'],
        psychoWeight: 0,
        lucidity: 50,
        oblivionLevel: 0,
        anxiety: 10,
        phase: 1,
        awarenessLevel: 0,
        proustAffinity: 0,
        tarkovskijAffinity: 0,
        sethAffinity: 0,
        sectorLabel: '',
        savedAt: null,
      );

  factory SaveSlot.fromMap(Map<String, dynamic> m) {
    final savedAtRaw = m['saved_at'] as String? ?? '';
    return SaveSlot(
      slot: m['slot'] as int,
      currentNode: m['current_node'] as String? ?? '',
      completedPuzzles: Set<String>.from(
          (jsonDecode(m['completed_puzzles'] as String? ?? '[]') as List)),
      puzzleCounters: Map<String, int>.from(
          (jsonDecode(m['puzzle_counters'] as String? ?? '{}') as Map)),
      inventory: List<String>.from(
          (jsonDecode(m['inventory'] as String? ?? '["notebook"]') as List)),
      psychoWeight: m['psycho_weight'] as int? ?? 0,
      lucidity: m['lucidity'] as int? ?? 50,
      oblivionLevel: m['oblivion_level'] as int? ?? 0,
      anxiety: m['anxiety'] as int? ?? 10,
      phase: m['phase'] as int? ?? 1,
      awarenessLevel: m['awareness_level'] as int? ?? 0,
      proustAffinity: m['proust_affinity'] as int? ?? 0,
      tarkovskijAffinity: m['tarkovskij_affinity'] as int? ?? 0,
      sethAffinity: m['seth_affinity'] as int? ?? 0,
      sectorLabel: m['sector_label'] as String? ?? '',
      savedAt: savedAtRaw.isNotEmpty
          ? DateTime.tryParse(savedAtRaw)
          : null,
    );
  }
}

/// Singleton save-slot manager.
class SaveService {
  SaveService._();
  static final SaveService instance = SaveService._();

  // ── Write ────────────────────────────────────────────────────────────────────

  /// Writes the current game + profile state to [slot] (0–3).
  Future<void> saveToSlot(
    int slot, {
    required String currentNode,
    required Set<String> completedPuzzles,
    required Map<String, int> puzzleCounters,
    required List<String> inventory,
    required int psychoWeight,
    required int lucidity,
    required int oblivionLevel,
    required int anxiety,
    required int phase,
    required int awarenessLevel,
    required int proustAffinity,
    required int tarkovskijAffinity,
    required int sethAffinity,
    required String sectorLabel,
  }) async {
    final db = await DatabaseService.instance.database;
    await db.insert(
      'save_slots',
      {
        'slot': slot,
        'current_node': currentNode,
        'completed_puzzles': jsonEncode(completedPuzzles.toList()),
        'puzzle_counters': jsonEncode(puzzleCounters),
        'inventory': jsonEncode(inventory),
        'psycho_weight': psychoWeight,
        'lucidity': lucidity,
        'oblivion_level': oblivionLevel,
        'anxiety': anxiety,
        'phase': phase,
        'awareness_level': awarenessLevel,
        'proust_affinity': proustAffinity,
        'tarkovskij_affinity': tarkovskijAffinity,
        'seth_affinity': sethAffinity,
        'sector_label': sectorLabel,
        'saved_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── Read ─────────────────────────────────────────────────────────────────────

  /// Returns the slot data for [slot], or an empty slot if it has never been saved.
  Future<SaveSlot> readSlot(int slot) async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query(
      'save_slots',
      where: 'slot = ?',
      whereArgs: [slot],
      limit: 1,
    );
    if (rows.isEmpty) return SaveSlot.empty(slot);
    return SaveSlot.fromMap(rows.first);
  }

  /// Returns all four slots (0–3) in order.
  /// Missing slots are returned as empty.
  Future<List<SaveSlot>> listSlots() async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query('save_slots', orderBy: 'slot ASC');
    final bySlot = {for (final r in rows) r['slot'] as int: SaveSlot.fromMap(r)};
    return [
      for (int i = 0; i <= 3; i++) bySlot[i] ?? SaveSlot.empty(i),
    ];
  }

  // ── Restore ──────────────────────────────────────────────────────────────────

  /// Writes [slot] data back to the live `game_state` and `psycho_profile` rows.
  /// After this call the engine providers must be refreshed to pick up the change.
  Future<void> restoreToLive(SaveSlot slot) async {
    final db = await DatabaseService.instance.database;
    await db.transaction((txn) async {
      await txn.insert(
        'game_state',
        {
          'id': 1,
          'current_node': slot.currentNode,
          'completed_puzzles': jsonEncode(slot.completedPuzzles.toList()),
          'puzzle_counters': jsonEncode(slot.puzzleCounters),
          'inventory': jsonEncode(slot.inventory),
          'psycho_weight': slot.psychoWeight,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.update(
        'psycho_profile',
        {
          'lucidity': slot.lucidity,
          'oblivion_level': slot.oblivionLevel,
          'anxiety': slot.anxiety,
          'phase': slot.phase,
          'awareness_level': slot.awarenessLevel,
          'proust_affinity': slot.proustAffinity,
          'tarkovskij_affinity': slot.tarkovskijAffinity,
          'seth_affinity': slot.sethAffinity,
        },
        where: 'id = 1',
      );
    });
  }
}
