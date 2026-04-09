// test/game_state_persistence_test.dart
//
// Verifies game-state persistence without requiring a live SQLite connection.
//
// Strategy: the persistence contract is encoded entirely in two pure-Dart
// operations:
//   • save  — GameStateNotifier.saveEngineState() serialises state fields to
//             a Map<String, Object?> and inserts it into the `game_state` table.
//   • load  — GameStateNotifier.build() reads that row and passes it to
//             GameState.fromRow(), which is the only place deserialisation lives.
//
// By exercising these two operations directly we validate the complete
// round-trip without platform channels or Riverpod container setup.
//
// The four-node journey tested:
//   1. intro_void      (sector: soglia   — node override  → 'soglia')
//   2. la_soglia       (sector: soglia   — node override  → 'soglia')
//   3. garden_cypress  (sector: giardino — sector base    → 'giardino')
//   4. garden_fountain (sector: giardino — room override  → 'giardino_fountain')

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:archive_of_oblivion/features/audio/audio_track_catalog.dart';
import 'package:archive_of_oblivion/features/state/game_state_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Mirrors what [GameStateNotifier.saveEngineState] writes to the DB.
Map<String, Object?> _toDbRow(GameState s) => {
      'id': 1,
      'current_node': s.currentNode,
      'completed_puzzles': jsonEncode(s.completedPuzzles.toList()),
      'puzzle_counters': jsonEncode(s.puzzleCounters),
      'inventory': jsonEncode(s.inventory),
      'psycho_weight': s.psychoWeight,
      'last_played': DateTime(2026, 4, 9).toIso8601String(),
    };

/// Mirrors what [GameStateNotifier.build] reads from the DB.
GameState _fromDbRow(Map<String, Object?> row) => GameState.fromRow(row);

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // The four nodes visited during this simulated play session.
  const journey = <String>[
    'intro_void',       // starting position
    'la_soglia',        // threshold — prologue ends
    'garden_cypress',   // Garden sector, main plaza
    'garden_fountain',  // Garden sector, fountain room (final node before save)
  ];

  // Expected audio tracks for each node in the journey.
  // Values must match AudioTrackCatalog._nodeOverrides / _sectorBaseKeys.
  const expectedTracks = <String, String>{
    'intro_void':       'soglia',            // node override
    'la_soglia':        'soglia',            // node override
    'garden_cypress':   'giardino',          // sector base
    'garden_fountain':  'giardino_fountain', // room override
  };

  // ── 1. Audio track resolution ─────────────────────────────────────────────

  group('audio track resolution for journey nodes', () {
    for (final node in journey) {
      test('$node → ${expectedTracks[node]}', () {
        final track = AudioTrackCatalog.trackForNode(node);
        expect(
          track,
          equals(expectedTracks[node]),
          reason: 'Node "$node" must resolve to track "${expectedTracks[node]}"',
        );
      });
    }
  });

  // ── 2. Per-node serialisation roundtrip ───────────────────────────────────

  group('serialisation roundtrip for each journey step', () {
    for (var i = 0; i < journey.length; i++) {
      final node = journey[i];
      test('step ${i + 1}: $node survives save → reload', () {
        // Build realistic game variables that accumulate as the journey progresses.
        final state = GameState(
          currentNode:      node,
          completedPuzzles: i > 0 ? const {'intro_complete'} : const {},
          puzzleCounters:   {'zone_encounters': i, 'consecutive_transits': i},
          inventory:        i > 1
              ? const ['notebook', 'ataraxia']
              : const ['notebook'],
          psychoWeight:     i * 8,
        );

        // Save (serialise) → simulate reset → reload (deserialise).
        final restored = _fromDbRow(_toDbRow(state));

        expect(restored.currentNode, equals(node));
        expect(restored.completedPuzzles, equals(state.completedPuzzles));
        expect(restored.puzzleCounters, equals(state.puzzleCounters));
        expect(restored.inventory, equals(state.inventory));
        expect(restored.psychoWeight, equals(state.psychoWeight));
      });
    }
  });

  // ── 3. Full save → reset → reload cycle ──────────────────────────────────

  group('full save → reset → reload cycle', () {
    test(
      'currentNode and audio track at garden_fountain are preserved exactly',
      () {
        // ── Step 1: state at the end of the four-node journey ──────────────
        const finalNode = 'garden_fountain';
        final trackBeforeSave = AudioTrackCatalog.trackForNode(finalNode);

        final stateBeforeSave = GameState(
          currentNode:      finalNode,
          completedPuzzles: const {'intro_complete', 'leaves_arranged'},
          puzzleCounters:   const {
            'zone_encounters': 2,
            'consecutive_transits': 1,
          },
          inventory:        const ['notebook', 'ataraxia'],
          psychoWeight:     24,
        );

        // ── Step 2: save ────────────────────────────────────────────────────
        final savedRow = _toDbRow(stateBeforeSave);

        // ── Step 3: reset — discard the in-memory engine state, then reload
        //           by deserialising the persisted row (mirrors the provider
        //           rebuild that GameEngineNotifier.build() triggers after a
        //           reset or cold start). ────────────────────────────────────
        final restoredState = _fromDbRow(savedRow);

        // ── Step 4: assertions ──────────────────────────────────────────────
        expect(
          restoredState.currentNode,
          equals(finalNode),
          reason: 'currentNode must survive save → reset → reload',
        );

        final trackAfterReload =
            AudioTrackCatalog.trackForNode(restoredState.currentNode);
        expect(
          trackAfterReload,
          equals(trackBeforeSave),
          reason: 'Audio track must be identical before save and after reload',
        );
      },
    );

    test('game variables (puzzles, counters, inventory, weight) are identical after reload', () {
      const node = 'garden_fountain';

      final original = GameState(
        currentNode:      node,
        completedPuzzles: const {'intro_complete', 'leaves_arranged'},
        puzzleCounters:   const {'zone_encounters': 3, 'consecutive_transits': 2},
        inventory:        const ['notebook', 'ataraxia', 'the constant'],
        psychoWeight:     35,
      );

      final restored = _fromDbRow(_toDbRow(original));

      expect(restored.completedPuzzles, equals(original.completedPuzzles),
          reason: 'completedPuzzles must not change across persistence');
      expect(restored.puzzleCounters, equals(original.puzzleCounters),
          reason: 'puzzleCounters must not change across persistence');
      expect(restored.inventory, equals(original.inventory),
          reason: 'inventory must not change across persistence');
      expect(restored.psychoWeight, equals(original.psychoWeight),
          reason: 'psychoWeight must not change across persistence');
    });

    test('empty puzzles and counters serialise to empty collections (not null)', () {
      final state = GameState(
        currentNode:      'intro_void',
        completedPuzzles: const {},
        puzzleCounters:   const {},
        inventory:        const ['notebook'],
        psychoWeight:     0,
      );

      final restored = _fromDbRow(_toDbRow(state));

      expect(restored.completedPuzzles, isEmpty);
      expect(restored.puzzleCounters, isEmpty);
    });
  });
}
