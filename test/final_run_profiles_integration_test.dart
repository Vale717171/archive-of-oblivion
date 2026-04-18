import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:archive_of_oblivion/features/game/final_arc_adjudication.dart';
import 'package:archive_of_oblivion/features/game/memory/memory_module.dart';
import 'package:archive_of_oblivion/features/game/nucleus/nucleus_adjudication.dart';
import 'package:archive_of_oblivion/features/game/nucleus/nucleus_module.dart';
import 'package:archive_of_oblivion/features/game/progression_service.dart';
import 'package:archive_of_oblivion/features/game/zone/zone_module.dart';
import 'package:archive_of_oblivion/features/parser/parser_state.dart';
import 'package:archive_of_oblivion/features/state/game_state_provider.dart';

class _RunProfile {
  final String name;
  final Set<String> puzzles;
  final Map<String, int> counters;
  final List<String> inventory;
  final int psychoWeight;
  final String nucleusInput;
  final String? expectedEndingNode;
  final String expectedZoneSource;
  final bool expectMemoryReady;

  const _RunProfile({
    required this.name,
    required this.puzzles,
    required this.counters,
    required this.inventory,
    required this.psychoWeight,
    required this.nucleusInput,
    required this.expectedEndingNode,
    required this.expectedZoneSource,
    required this.expectMemoryReady,
  });
}

Map<String, Object?> _toDbRow(GameState s) => {
      'id': 1,
      'current_node': s.currentNode,
      'completed_puzzles': jsonEncode(s.completedPuzzles.toList()),
      'puzzle_counters': jsonEncode(s.puzzleCounters),
      'inventory': jsonEncode(s.inventory),
      'psycho_weight': s.psychoWeight,
      'last_played': DateTime(2026, 4, 18).toIso8601String(),
    };

NucleusTurnResolution _resolveNucleus(_RunProfile p) {
  return NucleusModule.resolveTurn(
    cmd: ParsedCommand(
      verb: CommandVerb.unknown,
      args: const [],
      rawInput: p.nucleusInput,
    ),
    nodeId: 'il_nucleo',
    evaluationResponse: const EngineResponse(narrativeText: 'fallback'),
    puzzles: p.puzzles,
    counters: p.counters,
    inventory: p.inventory,
    psychoWeight: p.psychoWeight,
  );
}

void main() {
  const baselinePuzzles = {
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
  };

  final profiles = <_RunProfile>[
    _RunProfile(
      name: 'acceptance_oriented',
      puzzles: baselinePuzzles,
      counters: const {
        'quote_exposure_seen': 24,
        'sys_notebook_habitation': 11,
        'sys_contradictions': 1,
        'sys_weight_verbal': 8,
        'sys_weight_symbolic': 4,
        'memory_childhood_specific_count': 1,
        'memory_youth_specific_count': 1,
        'memory_maturity_costly_count': 1,
        'memory_meta_specific_count': 4,
        'memory_meta_costly_count': 3,
        'zone_meta_quality_tier_2': 3,
        'zone_meta_contradiction_resolved_count': 2,
        'zone_meta_contradiction_intensified_count': 0,
      },
      inventory: const ['notebook', 'ataraxia', 'the constant'],
      psychoWeight: 1,
      nucleusInput: 'imperfection and human warmth',
      expectedEndingNode: 'finale_acceptance',
      expectedZoneSource: 'weight_verbal',
      expectMemoryReady: true,
    ),
    _RunProfile(
      name: 'oblivion_oriented',
      puzzles: {
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
        'quote_exposure_seen': 23,
        'sys_notebook_habitation': 6,
        'sys_contradictions': 6,
        'sys_weight_verbal': 2,
        'sys_weight_symbolic': 1,
        'memory_meta_specific_count': 1,
        'memory_meta_costly_count': 0,
        'zone_meta_quality_tier_2': 0,
        'zone_meta_contradiction_resolved_count': 0,
        'zone_meta_contradiction_intensified_count': 3,
      },
      inventory: const ['notebook', 'mirror shard', 'clock', 'ticket'],
      psychoWeight: 8,
      nucleusInput: 'i accept oblivion',
      expectedEndingNode: 'finale_oblivion',
      expectedZoneSource: 'contradiction',
      expectMemoryReady: false,
    ),
    _RunProfile(
      name: 'eternal_zone_oriented',
      puzzles: baselinePuzzles,
      counters: const {
        'quote_exposure_seen': 22,
        'sys_notebook_habitation': 10,
        'sys_contradictions': 2,
        'sys_weight_verbal': 3,
        'sys_weight_symbolic': 8,
        'memory_childhood_specific_count': 1,
        'memory_youth_specific_count': 1,
        'memory_maturity_costly_count': 1,
        'memory_meta_specific_count': 3,
        'memory_meta_costly_count': 2,
        'zone_meta_quality_tier_2': 3,
        'zone_meta_contradiction_resolved_count': 1,
        'zone_meta_contradiction_intensified_count': 1,
      },
      inventory: const ['notebook', 'the proportion', 'ticket'],
      psychoWeight: 2,
      nucleusInput: 'i want to stay',
      expectedEndingNode: 'finale_eternal_zone',
      expectedZoneSource: 'weight_symbolic',
      expectMemoryReady: true,
    ),
    _RunProfile(
      name: 'testimony_oriented',
      puzzles: baselinePuzzles,
      counters: const {
        'quote_exposure_seen': 30,
        'sys_notebook_habitation': 14,
        'sys_contradictions': 1,
        'sys_weight_verbal': 9,
        'sys_weight_symbolic': 4,
        'memory_childhood_specific_count': 1,
        'memory_youth_specific_count': 1,
        'memory_maturity_costly_count': 1,
        'memory_old_age_costly_count': 1,
        'memory_meta_specific_count': 4,
        'memory_meta_costly_count': 4,
        'zone_meta_quality_tier_2': 4,
        'zone_meta_contradiction_resolved_count': 3,
        'zone_meta_contradiction_intensified_count': 0,
      },
      inventory: const ['notebook', 'ataraxia', 'the proportion'],
      psychoWeight: 1,
      nucleusInput: 'i bear witness',
      expectedEndingNode: 'finale_testimony',
      expectedZoneSource: 'weight_verbal',
      expectMemoryReady: true,
    ),
    _RunProfile(
      name: 'contradictory_under_integrated',
      puzzles: const {'garden_complete', 'ritual_complete'},
      counters: const {
        'quote_exposure_seen': 8,
        'sys_notebook_habitation': 3,
        'sys_contradictions': 5,
        'memory_meta_specific_count': 0,
        'memory_meta_costly_count': 0,
        'zone_meta_quality_tier_2': 0,
        'zone_meta_contradiction_resolved_count': 0,
        'zone_meta_contradiction_intensified_count': 2,
      },
      inventory: const ['notebook', 'mirror shard'],
      psychoWeight: 6,
      nucleusInput: 'acceptance',
      expectedEndingNode: null,
      expectedZoneSource: 'contradiction',
      expectMemoryReady: false,
    ),
    _RunProfile(
      name: 'advanced_but_evasive',
      puzzles: baselinePuzzles,
      counters: const {
        'quote_exposure_seen': 24,
        'sys_notebook_habitation': 9,
        'sys_contradictions': 2,
        'sys_weight_verbal': 7,
        'sys_weight_symbolic': 5,
        'memory_childhood_specific_count': 1,
        'memory_youth_specific_count': 1,
        'memory_maturity_costly_count': 1,
        'memory_meta_specific_count': 3,
        'memory_meta_costly_count': 2,
        'zone_meta_quality_tier_2': 2,
        'zone_meta_contradiction_resolved_count': 0,
        'zone_meta_contradiction_intensified_count': 2,
      },
      inventory: const ['notebook', 'ticket'],
      psychoWeight: 3,
      nucleusInput: 'human warmth and acceptance',
      expectedEndingNode: null,
      expectedZoneSource: 'weight_verbal',
      expectMemoryReady: true,
    ),
  ];

  group('Full-run profile validation', () {
    test(
        'profiles produce stable progression, coherent signals, and expected endings',
        () {
      final argumentSignatures = <String, String>{};

      for (final profile in profiles) {
        final progression = ProgressionService.applyTurn(
          cmd: const ParsedCommand(
            verb: CommandVerb.help,
            args: [],
            rawInput: 'help',
          ),
          response: const EngineResponse(narrativeText: 'x'),
          nodeId: 'la_soglia',
          puzzles: profile.puzzles,
          counters: profile.counters,
        );

        expect(
          progression.puzzles.contains('ritual_complete'),
          isTrue,
          reason: '${profile.name}: sector progression must stay stable',
        );

        final gameState = GameState(
          currentNode: 'il_nucleo',
          completedPuzzles: profile.puzzles,
          puzzleCounters: profile.counters,
          inventory: profile.inventory,
          psychoWeight: profile.psychoWeight,
        );
        final restored = GameState.fromRow(_toDbRow(gameState));

        final snapshot = FinalArcAdjudication.aggregate(
          puzzles: restored.completedPuzzles,
          counters: restored.puzzleCounters,
          inventory: restored.inventory,
          psychoWeight: restored.psychoWeight,
        );

        final memoryInput = MemoryModule.buildEpitaphInput(
          puzzles: restored.completedPuzzles,
          counters: restored.puzzleCounters,
          inventory: restored.inventory,
          psychoWeight: restored.psychoWeight,
        );
        final zonePrompt = ZoneModule.previewPrompt(
          encounter: restored.puzzleCounters['zone_encounters'] ?? 0,
          puzzles: restored.completedPuzzles,
          counters: restored.puzzleCounters,
          inventory: restored.inventory,
          psychoWeight: restored.psychoWeight,
        );

        expect(
          snapshot.memoryReady,
          profile.expectMemoryReady,
          reason: '${profile.name}: Memory readiness should be coherent',
        );
        expect(
          zonePrompt.source,
          profile.expectedZoneSource,
          reason:
              '${profile.name}: Zone prompt source should match run profile',
        );
        expect(
          memoryInput.answeredChambers.length,
          inInclusiveRange(0, 4),
          reason: '${profile.name}: Memory chamber state must remain bounded',
        );

        final eligibility = NucleusAdjudication.evaluate(snapshot);
        final arguments = NucleusAdjudication.buildArguments(
          snapshot: snapshot,
          eligibility: eligibility,
        );
        final signature =
            '${arguments.antagonistArguments.join('|')}::${arguments.availableStances.join(',')}';
        argumentSignatures[profile.name] = signature;

        final result = _resolveNucleus(profile);
        expect(
          result.response.newNode,
          profile.expectedEndingNode,
          reason: '${profile.name}: ending should match intended run profile',
        );

        final replayResult = NucleusModule.resolveTurn(
          cmd: ParsedCommand(
            verb: CommandVerb.unknown,
            args: const [],
            rawInput: profile.nucleusInput,
          ),
          nodeId: 'il_nucleo',
          evaluationResponse: const EngineResponse(narrativeText: 'fallback'),
          puzzles: restored.completedPuzzles,
          counters: restored.puzzleCounters,
          inventory: restored.inventory,
          psychoWeight: restored.psychoWeight,
        );

        expect(
          replayResult.response.newNode,
          result.response.newNode,
          reason: '${profile.name}: save/load continuity must preserve outcome',
        );
      }

      expect(
        argumentSignatures['acceptance_oriented'],
        isNot(argumentSignatures['oblivion_oriented']),
      );
      expect(
        argumentSignatures['acceptance_oriented'],
        isNot(argumentSignatures['eternal_zone_oriented']),
      );
      expect(
        argumentSignatures['testimony_oriented'],
        isNot(argumentSignatures['advanced_but_evasive']),
      );
    });
  });
}
