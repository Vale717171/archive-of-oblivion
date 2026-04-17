import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:archive_of_oblivion/features/game/zone/zone_module.dart';
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

void main() {
  group('Zone prompts', () {
    test('derive from run state and differ meaningfully', () {
      final contradictionPrompt = ZoneModule.previewPrompt(
        encounter: 0,
        puzzles: const {'garden_complete'},
        counters: const {
          'sys_contradictions': 4,
          'sys_notebook_habitation': 2,
        },
        inventory: const ['notebook', 'mirror shard'],
        psychoWeight: 6,
      );

      final symbolicPrompt = ZoneModule.previewPrompt(
        encounter: 0,
        puzzles: const {
          'garden_complete',
          'obs_complete',
          'sys_deep_garden',
          'sys_deep_observatory',
          'memory_epitaph_ready',
        },
        counters: const {
          'sys_contradictions': 0,
          'sys_notebook_habitation': 10,
          'sys_weight_symbolic': 9,
          'sys_weight_verbal': 3,
          'memory_maturity_costly_count': 1,
          'memory_old_age_costly_count': 1,
          'memory_childhood_specific_count': 1,
          'memory_youth_specific_count': 1,
        },
        inventory: const ['notebook'],
        psychoWeight: 1,
      );

      expect(contradictionPrompt.source, 'contradiction');
      expect(symbolicPrompt.source, 'weight_symbolic');
      expect(contradictionPrompt.question, isNot(symbolicPrompt.question));
    });
  });

  group('Zone response evaluation', () {
    test('evasive and substantial responses diverge in outcomes', () {
      final evasive = ZoneModule.resolveZoneResponse(
        rawInput: 'I do not know',
        puzzles: const {
          'zone_prompt_1_source_contradiction',
          'zone_prompt_1_tag_contradiction',
        },
        counters: const {
          'zone_encounters': 1,
          'sys_contradictions': 2,
          'sys_zone_pressure': 1,
        },
      );

      final substantial = ZoneModule.resolveZoneResponse(
        rawInput:
            'I still carry the mirror shard because I was afraid to apologize by name on that winter street.',
        puzzles: const {
          'zone_prompt_1_source_contradiction',
          'zone_prompt_1_tag_contradiction',
          'zone_prompt_1_tag_proof',
        },
        counters: const {
          'zone_encounters': 1,
          'sys_contradictions': 2,
          'sys_zone_pressure': 3,
        },
      );

      expect(evasive.response.newNode, isNull);
      expect(evasive.counterUpdates['sys_contradictions'], 3);
      expect(evasive.counterUpdates['zone_meta_quality_tier_0'], 1);

      expect(substantial.response.newNode, 'la_soglia');
      expect(substantial.response.completePuzzle, 'zone_responded_1');
      expect(substantial.counterUpdates['sys_contradictions'], 1);
      expect(substantial.counterUpdates['zone_meta_quality_tier_2'], 1);
    });

    test('contradictions can intensify or resolve based on alignment', () {
      final intensify = ZoneModule.resolveZoneResponse(
        rawInput: 'nothing happened and everyone is fine',
        puzzles: const {
          'zone_prompt_2_source_contradiction',
          'zone_prompt_2_tag_contradiction',
        },
        counters: const {
          'zone_encounters': 2,
          'sys_contradictions': 1,
          'sys_zone_pressure': 0,
        },
      );

      final resolve = ZoneModule.resolveZoneResponse(
        rawInput:
            'I said I had let go, yet I kept the proof because I was afraid of being ordinary.',
        puzzles: const {
          'zone_prompt_2_source_contradiction',
          'zone_prompt_2_tag_contradiction',
          'zone_prompt_2_tag_ownership',
        },
        counters: const {
          'zone_encounters': 2,
          'sys_contradictions': 3,
          'sys_zone_pressure': 4,
        },
      );

      expect(intensify.counterUpdates['sys_contradictions'], 2);
      expect(resolve.counterUpdates['sys_contradictions'], 2);
      expect(
          resolve.counterUpdates['zone_meta_contradiction_resolved_count'], 1);
    });
  });

  group('Zone persistence compatibility', () {
    test('save/load preserves metadata and pending prompt context', () {
      final before = GameState(
        currentNode: 'la_zona',
        completedPuzzles: const {
          'zone_prompt_3_source_notebook',
          'zone_prompt_3_tag_notebook',
          'zone_prompt_3_tag_voice',
        },
        puzzleCounters: const {
          'zone_encounters': 3,
          'zone_meta_quality_sum': 4,
          'zone_meta_responses': 2,
          'sys_contradictions': 2,
          'sys_zone_pressure': 1,
        },
        inventory: const ['notebook'],
      );

      final restored = GameState.fromRow(_toDbRow(before));
      final outcome = ZoneModule.resolveZoneResponse(
        rawInput:
            'My notebook still hides a page where I never used my own voice.',
        puzzles: restored.completedPuzzles,
        counters: restored.puzzleCounters,
      );

      expect(outcome.response.completePuzzle, 'zone_responded_3');
      expect(outcome.counterUpdates['zone_meta_responses'], 3);
      expect(outcome.puzzleAdds,
          contains('zone_meta_encounter_3_source_notebook'));
    });

    test('legacy counters without metadata remain backward-safe', () {
      final legacy = GameState(
        currentNode: 'la_zona',
        completedPuzzles: const {'zone_prompt_1_source_weight_verbal'},
        puzzleCounters: const {
          'zone_encounters': 1,
          'sys_contradictions': 0,
        },
        inventory: const ['notebook'],
      );

      final restored = GameState.fromRow(_toDbRow(legacy));
      final outcome = ZoneModule.resolveZoneResponse(
        rawInput:
            'I keep repeating one sentence because saying less feels safer than saying true things.',
        puzzles: restored.completedPuzzles,
        counters: restored.puzzleCounters,
      );

      expect(outcome.counterUpdates['zone_meta_quality_sum'], isNotNull);
      expect(outcome.counterUpdates['zone_meta_responses'], 1);
    });
  });

  group('Zone activation turn integration', () {
    test('resolveTurn can replace transit with zone activation and markers',
        () {
      final resolution = ZoneModule.resolveTurn(
        cmd: const ParsedCommand(
          verb: CommandVerb.go,
          args: ['east'],
          rawInput: 'go east',
        ),
        nodeId: 'la_soglia',
        evaluationResponse: const EngineResponse(
          narrativeText: 'moving',
          newNode: 'garden_portico',
        ),
        puzzles: const {'garden_complete'},
        counters: const {
          'consecutive_transits': 2,
          'sys_contradictions': 2,
        },
        inventory: const ['notebook', 'ataraxia'],
        psychoWeight: 2,
        randomRoll: 0.0,
      );

      expect(resolution.response.newNode, 'la_zona');
      expect(resolution.counterUpdates['zone_encounters'], 1);
      expect(
        resolution.puzzleAdds.any((m) => m.startsWith('zone_prompt_1_source_')),
        isTrue,
      );
    });
  });
}
