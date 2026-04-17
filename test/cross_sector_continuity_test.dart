import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:archive_of_oblivion/features/game/garden/garden_module.dart';
import 'package:archive_of_oblivion/features/game/memory/memory_module.dart';
import 'package:archive_of_oblivion/features/game/observatory/observatory_module.dart';
import 'package:archive_of_oblivion/features/game/progression_service.dart';
import 'package:archive_of_oblivion/features/game/final_arc_adjudication.dart';
import 'package:archive_of_oblivion/features/parser/parser_state.dart';
import 'package:archive_of_oblivion/features/state/game_state_provider.dart';

Map<String, Object?> _toDbRow(GameState s) => {
      'id': 1,
      'current_node': s.currentNode,
      'completed_puzzles': jsonEncode(s.completedPuzzles.toList()),
      'puzzle_counters': jsonEncode(s.puzzleCounters),
      'inventory': jsonEncode(s.inventory),
      'psycho_weight': s.psychoWeight,
      'last_played': DateTime(2026, 4, 17).toIso8601String(),
    };

GameState _fromDbRow(Map<String, Object?> row) => GameState.fromRow(row);

void main() {
  group('Cross-sector continuity', () {
    test('obtain one simulacrum, save/load, and continue ritual placement', () {
      final saved = GameState(
        currentNode: 'la_soglia',
        completedPuzzles: const {'garden_complete', 'garden_revisited'},
        puzzleCounters: const {'depth_garden': 7},
        inventory: const ['notebook', 'ataraxia'],
        psychoWeight: 0,
      );

      final restored = _fromDbRow(_toDbRow(saved));
      final response = MemoryModule.handleDrop(
        cmd: const ParsedCommand(
          verb: CommandVerb.drop,
          args: ['ataraxia', 'in', 'cup'],
          rawInput: 'drop ataraxia in cup',
        ),
        state: MemoryStateView(
          nodeId: 'quinto_ritual_chamber',
          completedPuzzles: restored.completedPuzzles,
          puzzleCounters: restored.puzzleCounters,
          inventory: restored.inventory,
          psychoWeight: restored.psychoWeight,
          runtime: MemoryModule.deriveRuntime(
            puzzles: restored.completedPuzzles,
            counters: restored.puzzleCounters,
            inventory: restored.inventory,
            psychoWeight: restored.psychoWeight,
          ),
        ),
      );

      expect(response, isNotNull);
      expect(response!.completePuzzle, 'cup_ataraxia');
    });

    test('revisit hook eligibility survives persistence roundtrip', () {
      final saved = GameState(
        currentNode: 'la_soglia',
        completedPuzzles: const {'obs_complete'},
        puzzleCounters: const {'depth_observatory': 7},
        inventory: const ['notebook', 'the constant'],
      );
      final restored = _fromDbRow(_toDbRow(saved));

      final revisit = ObservatoryModule.onEnterNode(
        fromNode: 'la_soglia',
        destNode: 'obs_antechamber',
        state: ObservatoryStateView(
          nodeId: 'obs_antechamber',
          completedPuzzles: restored.completedPuzzles,
          puzzleCounters: restored.puzzleCounters,
          inventory: restored.inventory,
        ),
      );

      expect(revisit, isNotNull);
      expect(revisit!.completePuzzle, 'obs_revisited');
    });

    test('deep completion markers persist and re-evaluate coherently', () {
      final basePuzzles = {
        'garden_complete',
        'garden_revisited',
        'garden_cross_sector_hint',
      };
      final baseCounters = {'depth_garden': 7};
      final first = ProgressionService.applyTurn(
        cmd: const ParsedCommand(
          verb: CommandVerb.examine,
          args: [],
          rawInput: 'look',
        ),
        response: const EngineResponse(narrativeText: 'x'),
        nodeId: 'garden_portico',
        puzzles: basePuzzles,
        counters: baseCounters,
      );

      final saved = GameState(
        currentNode: 'garden_portico',
        completedPuzzles: first.puzzles,
        puzzleCounters: first.counters,
        inventory: const ['notebook', 'ataraxia'],
      );
      final restored = _fromDbRow(_toDbRow(saved));

      expect(restored.completedPuzzles, contains('sys_deep_garden'));
      expect(restored.completedPuzzles, contains('garden_deep_complete'));
      expect(
        GardenModule.isDeepComplete(
          puzzles: restored.completedPuzzles,
          counters: restored.puzzleCounters,
        ),
        isTrue,
      );
    });

    test('threshold resonance input updates across multiple sectors', () {
      final puzzles = {
        'garden_complete',
        'garden_revisited',
        'garden_cross_sector_hint',
        'obs_complete',
        'obs_revisited',
        'obs_cross_sector_hint',
      };
      final counters = {
        'depth_garden': 7,
        'depth_observatory': 7,
        'obs_lens_mode_moon': 1,
        'obs_lens_mode_mercury': 1,
      };

      final result = ProgressionService.applyTurn(
        cmd: const ParsedCommand(
          verb: CommandVerb.examine,
          args: ['pedestal'],
          rawInput: 'examine pedestal',
        ),
        response: const EngineResponse(
          narrativeText: 'x',
          needsDemiurge: true,
        ),
        nodeId: 'la_soglia',
        puzzles: puzzles,
        counters: counters,
      );

      expect(result.puzzles, contains('sys_deep_garden'));
      expect(result.puzzles, contains('sys_deep_observatory'));
      expect(
        result.counters[ProgressionService.thresholdResonanceInputCounter],
        2,
      );
    });

    test(
        'legacy-like save with missing memory quality counters degrades safely',
        () {
      final legacyRow = {
        'id': 1,
        'current_node': 'quinto_landing',
        'completed_puzzles': jsonEncode(<String>[]),
        'puzzle_counters': jsonEncode(<String, int>{}),
        'inventory': jsonEncode(<String>['notebook']),
        'psycho_weight': 0,
      };
      final restored = _fromDbRow(legacyRow);
      final runtime = MemoryModule.deriveRuntime(
        puzzles: restored.completedPuzzles,
        counters: restored.puzzleCounters,
        inventory: restored.inventory,
        psychoWeight: restored.psychoWeight,
      );

      expect(runtime.chambersComplete, isFalse);
      expect(runtime.depthThresholdMet, isFalse);
      expect(runtime.quoteThresholdMet, isFalse);
      expect(runtime.epitaphInput.specificAnswers, 0);
      expect(runtime.epitaphInput.costlyAnswers, 0);
    });

    test('memory and zone metadata survive persistence roundtrip', () {
      final saved = GameState(
        currentNode: 'la_zona',
        completedPuzzles: const {
          'zone_prompt_2_source_contradiction',
          'zone_prompt_2_tag_contradiction',
          'memory_childhood',
          'memory_youth',
        },
        puzzleCounters: const {
          'zone_encounters': 2,
          'zone_meta_responses': 3,
          'zone_meta_quality_sum': 4,
          'memory_meta_quality_sum': 5,
          'memory_meta_specific_count': 3,
          'memory_meta_costly_count': 1,
        },
        inventory: const ['notebook'],
      );
      final restored = _fromDbRow(_toDbRow(saved));
      final adjudication = FinalArcAdjudication.aggregate(
        puzzles: restored.completedPuzzles,
        counters: restored.puzzleCounters,
        inventory: restored.inventory,
        psychoWeight: restored.psychoWeight,
      );

      expect(adjudication.zoneResponses, 3);
      expect(adjudication.memoryQualityScore, 5);
      expect(adjudication.memorySpecificCount, 3);
      expect(adjudication.memoryCostlyCount, 1);
    });
  });
}
