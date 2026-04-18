import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:archive_of_oblivion/features/game/final_arc_adjudication.dart';
import 'package:archive_of_oblivion/features/game/nucleus/nucleus_adjudication.dart';
import 'package:archive_of_oblivion/features/game/nucleus/nucleus_module.dart';
import 'package:archive_of_oblivion/features/parser/parser_state.dart';
import 'package:archive_of_oblivion/features/state/game_state_provider.dart';

Map<String, Object?> _toDbRow(GameState s) => {
      'id': 1,
      'current_node': s.currentNode,
      'completed_puzzles': jsonEncode(s.completedPuzzles.toList()),
      'puzzle_counters': jsonEncode(s.puzzleCounters),
      'inventory': jsonEncode(s.inventory),
      'psycho_weight': s.psychoWeight,
      'last_played': DateTime(2026, 4, 18).toIso8601String(),
    };

NucleusTurnResolution _resolve(
  String raw, {
  required Set<String> puzzles,
  required Map<String, int> counters,
  required List<String> inventory,
  int psychoWeight = 0,
}) {
  return NucleusModule.resolveTurn(
    cmd: ParsedCommand(
      verb: CommandVerb.unknown,
      args: const [],
      rawInput: raw,
    ),
    nodeId: 'il_nucleo',
    evaluationResponse: const EngineResponse(narrativeText: 'base'),
    puzzles: puzzles,
    counters: counters,
    inventory: inventory,
    psychoWeight: psychoWeight,
  );
}

void main() {
  group('Nucleus argument sets', () {
    test('different run profiles produce different argument sets', () {
      final integrated = FinalArcAdjudication.aggregate(
        puzzles: const {
          'garden_complete',
          'obs_complete',
          'gallery_complete',
          'lab_complete',
          'ritual_complete',
          'memory_epitaph_ready',
          'sys_deep_garden',
          'sys_deep_observatory',
          'sys_deep_gallery',
          'sys_deep_laboratory',
        },
        counters: const {
          'quote_exposure_seen': 26,
          'sys_notebook_habitation': 12,
          'sys_contradictions': 1,
          'zone_meta_quality_tier_2': 3,
          'zone_meta_contradiction_resolved_count': 2,
          'zone_meta_contradiction_intensified_count': 0,
          'memory_meta_costly_count': 3,
          'memory_meta_specific_count': 4,
        },
        inventory: const ['notebook', 'ataraxia', 'the constant'],
        psychoWeight: 1,
      );
      final fractured = FinalArcAdjudication.aggregate(
        puzzles: const {
          'garden_complete',
          'obs_complete',
          'gallery_complete',
          'lab_complete',
          'ritual_complete',
        },
        counters: const {
          'quote_exposure_seen': 20,
          'sys_notebook_habitation': 4,
          'sys_contradictions': 6,
          'zone_meta_contradiction_intensified_count': 3,
          'zone_meta_quality_tier_2': 0,
          'memory_meta_costly_count': 0,
          'memory_meta_specific_count': 1,
        },
        inventory: const ['notebook', 'mirror shard', 'ticket', 'clock'],
        psychoWeight: 8,
      );

      final integratedEligibility = NucleusAdjudication.evaluate(integrated);
      final fracturedEligibility = NucleusAdjudication.evaluate(fractured);
      final integratedArgs = NucleusAdjudication.buildArguments(
        snapshot: integrated,
        eligibility: integratedEligibility,
      );
      final fracturedArgs = NucleusAdjudication.buildArguments(
        snapshot: fractured,
        eligibility: fracturedEligibility,
      );

      expect(
        integratedArgs.antagonistArguments,
        isNot(equals(fracturedArgs.antagonistArguments)),
      );
      expect(integratedArgs.availableStances,
          isNot(fracturedArgs.availableStances));
    });
  });

  group('Ending adjudication', () {
    test('Acceptance cannot trigger from contradictory under-integrated run',
        () {
      final result = _resolve(
        'imperfection is human warmth',
        puzzles: const {'ritual_complete'},
        counters: const {
          'sys_contradictions': 5,
          'quote_exposure_seen': 6,
          'sys_notebook_habitation': 3,
        },
        inventory: const ['notebook', 'mirror shard'],
        psychoWeight: 5,
      );

      expect(result.response.newNode, isNot('finale_acceptance'));
      expect(result.response.incrementCounter, 'boss_attempts');
    });

    test(
        'Oblivion can emerge from erasure-readiness even with advanced progression',
        () {
      final result = _resolve(
        'I accept oblivion',
        puzzles: const {
          'garden_complete',
          'obs_complete',
          'gallery_complete',
          'lab_complete',
          'ritual_complete',
          'sys_deep_garden',
          'sys_deep_observatory',
          'sys_deep_gallery',
          'sys_deep_laboratory',
        },
        counters: const {
          'sys_contradictions': 6,
          'quote_exposure_seen': 24,
          'sys_notebook_habitation': 5,
          'zone_meta_contradiction_intensified_count': 3,
        },
        inventory: const ['notebook', 'mirror shard', 'clock', 'ticket'],
        psychoWeight: 7,
      );

      expect(result.response.newNode, 'finale_oblivion');
    });

    test('Eternal Zone emerges from interpretive richness without integration',
        () {
      final result = _resolve(
        'I want to stay',
        puzzles: const {
          'garden_complete',
          'obs_complete',
          'gallery_complete',
          'lab_complete',
          'ritual_complete',
          'sys_deep_garden',
          'sys_deep_observatory',
          'sys_deep_gallery',
        },
        counters: const {
          'sys_contradictions': 3,
          'quote_exposure_seen': 22,
          'sys_notebook_habitation': 10,
          'zone_meta_quality_tier_2': 2,
          'zone_meta_contradiction_resolved_count': 0,
          'zone_meta_contradiction_intensified_count': 1,
          'memory_meta_costly_count': 1,
        },
        inventory: const ['notebook', 'ataraxia'],
        psychoWeight: 2,
      );

      expect(result.response.newNode, 'finale_eternal_zone');
    });

    test('Testimony is rare and does not overlap trivially with Acceptance',
        () {
      final almostAcceptance = _resolve(
        'I testify',
        puzzles: const {
          'garden_complete',
          'obs_complete',
          'gallery_complete',
          'lab_complete',
          'ritual_complete',
          'memory_epitaph_ready',
          'sys_deep_garden',
          'sys_deep_observatory',
          'sys_deep_gallery',
        },
        counters: const {
          'sys_contradictions': 1,
          'quote_exposure_seen': 20,
          'sys_notebook_habitation': 9,
          'zone_meta_quality_tier_2': 2,
          'memory_meta_costly_count': 2,
          'memory_meta_specific_count': 3,
        },
        inventory: const ['notebook', 'ataraxia'],
        psychoWeight: 1,
      );
      expect(almostAcceptance.response.newNode, isNot('finale_testimony'));

      final rareBalance = _resolve(
        'I bear witness',
        puzzles: const {
          'garden_complete',
          'obs_complete',
          'gallery_complete',
          'lab_complete',
          'ritual_complete',
          'memory_epitaph_ready',
          'sys_deep_garden',
          'sys_deep_observatory',
          'sys_deep_gallery',
          'sys_deep_laboratory',
        },
        counters: const {
          'sys_contradictions': 1,
          'quote_exposure_seen': 28,
          'sys_notebook_habitation': 13,
          'zone_meta_quality_tier_2': 4,
          'zone_meta_contradiction_resolved_count': 3,
          'zone_meta_contradiction_intensified_count': 0,
          'memory_meta_costly_count': 4,
          'memory_meta_specific_count': 4,
        },
        inventory: const ['notebook', 'ataraxia', 'the proportion'],
        psychoWeight: 1,
      );

      expect(rareBalance.response.newNode, 'finale_testimony');
    });
  });

  group('Nucleus persistence stability', () {
    test('final outcome remains stable across save/load', () {
      final saved = GameState(
        currentNode: 'il_nucleo',
        completedPuzzles: const {
          'garden_complete',
          'obs_complete',
          'gallery_complete',
          'lab_complete',
          'ritual_complete',
          'memory_epitaph_ready',
          'sys_deep_garden',
          'sys_deep_observatory',
          'sys_deep_gallery',
          'sys_deep_laboratory',
        },
        puzzleCounters: const {
          'sys_contradictions': 1,
          'quote_exposure_seen': 28,
          'sys_notebook_habitation': 13,
          'zone_meta_quality_tier_2': 4,
          'zone_meta_contradiction_resolved_count': 3,
          'zone_meta_contradiction_intensified_count': 0,
          'memory_meta_costly_count': 4,
          'memory_meta_specific_count': 4,
        },
        inventory: const ['notebook', 'ataraxia', 'the proportion'],
        psychoWeight: 1,
      );

      final restored = GameState.fromRow(_toDbRow(saved));
      final before = _resolve(
        'I bear witness',
        puzzles: saved.completedPuzzles,
        counters: saved.puzzleCounters,
        inventory: saved.inventory,
        psychoWeight: saved.psychoWeight,
      );
      final after = _resolve(
        'I bear witness',
        puzzles: restored.completedPuzzles,
        counters: restored.puzzleCounters,
        inventory: restored.inventory,
        psychoWeight: restored.psychoWeight,
      );

      expect(before.response.newNode, 'finale_testimony');
      expect(after.response.newNode, before.response.newNode);
    });

    test('partial missing final-arc metadata remains backward-safe', () {
      final legacy = GameState(
        currentNode: 'il_nucleo',
        completedPuzzles: const {'ritual_complete'},
        puzzleCounters: const {
          'quote_exposure_seen': 18,
        },
        inventory: const ['notebook'],
      );
      final restored = GameState.fromRow(_toDbRow(legacy));

      final result = _resolve(
        'imperfection',
        puzzles: restored.completedPuzzles,
        counters: restored.puzzleCounters,
        inventory: restored.inventory,
        psychoWeight: restored.psychoWeight,
      );

      expect(result.response.newNode, isNull);
      expect(result.response.narrativeText.isNotEmpty, isTrue);
    });
  });
}
