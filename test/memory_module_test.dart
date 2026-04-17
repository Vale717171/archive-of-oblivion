import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:archive_of_oblivion/features/game/memory/memory_module.dart';
import 'package:archive_of_oblivion/features/parser/parser_state.dart';
import 'package:archive_of_oblivion/features/state/game_state_provider.dart';

void main() {
  MemoryStateView state({
    required String nodeId,
    Set<String> puzzles = const {},
    Map<String, int> counters = const {},
    List<String> inventory = const ['notebook'],
    int psychoWeight = 0,
  }) {
    return MemoryStateView(
      nodeId: nodeId,
      completedPuzzles: puzzles,
      puzzleCounters: counters,
      inventory: inventory,
      psychoWeight: psychoWeight,
      runtime: MemoryModule.deriveRuntime(
        puzzles: puzzles,
        counters: counters,
        inventory: inventory,
        psychoWeight: psychoWeight,
      ),
    );
  }

  group('Memory chamber answers', () {
    test('stores and evaluates distinct answer states per chamber', () {
      final childhood = MemoryModule.handleWrite(
        cmd: const ParsedCommand(
          verb: CommandVerb.write,
          args: ['forgiveness'],
          rawInput: 'write forgiveness',
        ),
        state: state(nodeId: 'quinto_childhood'),
      );
      expect(childhood, isNotNull);
      expect(childhood!.completePuzzle, 'memory_childhood');

      final youth = MemoryModule.handleWrite(
        cmd: const ParsedCommand(
          verb: CommandVerb.write,
          args: ['i', 'promised', 'my', 'friend', 'i', 'would', 'return'],
          rawInput: 'write i promised my friend i would return',
        ),
        state: state(nodeId: 'quinto_youth'),
      );
      expect(youth, isNotNull);
      expect(youth!.completePuzzle, 'memory_youth');
      expect(youth.incrementCounter, 'memory_youth_specific_count');

      final maturity = MemoryModule.handleSay(
        cmd: const ParsedCommand(
          verb: CommandVerb.say,
          args: ['i', 'left', 'before', 'you', 'could', 'answer'],
          rawInput: 'say i left before you could answer',
        ),
        state: state(nodeId: 'quinto_maturity'),
      );
      expect(maturity, isNotNull);
      expect(maturity!.completePuzzle, 'memory_maturity');
      expect(maturity.incrementCounter, 'memory_maturity_costly_count');

      final oldAge = MemoryModule.handleWrite(
        cmd: const ParsedCommand(
          verb: CommandVerb.write,
          args: ['steady', 'in', 'winter', 'with', 'an', 'open', 'hand'],
          rawInput: 'write steady in winter with an open hand',
        ),
        state: state(nodeId: 'quinto_old_age'),
      );
      expect(oldAge, isNotNull);
      expect(oldAge!.completePuzzle, 'memory_old_age');
    });

    test('distinguishes generic/decorative from specific/costly', () {
      final generic = MemoryModule.handleWrite(
        cmd: const ParsedCommand(
          verb: CommandVerb.write,
          args: ['life', 'is', 'beautiful'],
          rawInput: 'write life is beautiful',
        ),
        state: state(nodeId: 'quinto_youth'),
      );
      expect(generic, isNotNull);
      expect(generic!.completePuzzle, isNull);
      expect(generic.narrativeText, contains('rejects decorative'));

      final specific = MemoryModule.handleWrite(
        cmd: const ParsedCommand(
          verb: CommandVerb.write,
          args: ['i', 'promised', 'at', 'the', 'station', 'i', 'would', 'stay'],
          rawInput: 'write i promised at the station i would stay',
        ),
        state: state(nodeId: 'quinto_youth'),
      );
      expect(specific, isNotNull);
      expect(specific!.completePuzzle, 'memory_youth');
      expect(specific.incrementCounter, 'memory_youth_specific_count');

      final costly = MemoryModule.handleWrite(
        cmd: const ParsedCommand(
          verb: CommandVerb.write,
          args: ['i', 'failed', 'you', 'and', 'left', 'without', 'apologize'],
          rawInput: 'write i failed you and left without apologize',
        ),
        state: state(nodeId: 'quinto_old_age'),
      );
      expect(costly, isNotNull);
      expect(costly!.completePuzzle, 'memory_old_age');
      expect(costly.incrementCounter, 'memory_old_age_costly_count');
    });
  });

  group('Memory epitaph and chalice', () {
    test('epitaph inputs derive coherently from run state', () {
      final runtime = MemoryModule.deriveRuntime(
        puzzles: const {
          'memory_childhood',
          'memory_youth',
          'memory_maturity',
          'memory_old_age',
        },
        counters: const {
          'memory_youth_specific_count': 1,
          'memory_maturity_costly_count': 1,
          'memory_old_age_specific_count': 1,
          'sys_weight_verbal': 8,
          'sys_weight_symbolic': 4,
          'sys_contradictions': 2,
        },
        inventory: const ['notebook', 'ataraxia', 'coin'],
        psychoWeight: 3,
      );

      expect(runtime.epitaphInput.answeredChambers.length, 4);
      expect(runtime.epitaphInput.specificAnswers, 3);
      expect(runtime.epitaphInput.costlyAnswers, 1);
      expect(runtime.epitaphInput.dominantWeightAxis, 'verbal');
      expect(runtime.epitaphInput.contradictionCount, 2);
      expect(
          runtime.epitaphInput.unresolvedProtections, greaterThanOrEqualTo(2));
    });

    test('chalice progression only works when prerequisites are met', () {
      final blockedStir = MemoryModule.handleStir(
        state: state(nodeId: 'quinto_ritual_chamber'),
      );
      expect(blockedStir, isNotNull);
      expect(blockedStir!.completePuzzle, isNull);

      final placeOne = MemoryModule.handleDrop(
        cmd: const ParsedCommand(
          verb: CommandVerb.drop,
          args: ['ataraxia', 'in', 'cup'],
          rawInput: 'drop ataraxia in cup',
        ),
        state: state(
          nodeId: 'quinto_ritual_chamber',
          inventory: const ['notebook', 'ataraxia'],
        ),
      );
      expect(placeOne, isNotNull);
      expect(placeOne!.completePuzzle, 'cup_ataraxia');

      final blockedDrink = MemoryModule.handleDrink(
        state: state(
          nodeId: 'quinto_ritual_chamber',
          puzzles: const {
            'cup_ataraxia',
            'cup_the_constant',
            'cup_the_proportion',
            'cup_the_catalyst',
            'ritual_stirred',
          },
          counters: const {'depth_memory': 2, 'quote_exposure_seen': 50},
        ),
      );
      expect(blockedDrink, isNotNull);
      expect(blockedDrink!.completePuzzle, isNull);
      expect(blockedDrink.narrativeText, contains('still thin'));

      final success = MemoryModule.handleDrink(
        state: state(
          nodeId: 'quinto_ritual_chamber',
          puzzles: const {
            'cup_ataraxia',
            'cup_the_constant',
            'cup_the_proportion',
            'cup_the_catalyst',
            'ritual_stirred',
          },
          counters: const {'depth_memory': 4, 'quote_exposure_seen': 18},
        ),
      );
      expect(success, isNotNull);
      expect(success!.completePuzzle, 'ritual_complete');
      expect(success.newNode, 'il_nucleo');
    });
  });

  group('Memory persistence', () {
    test('save/load preserves memory progression fields', () {
      final original = GameState(
        currentNode: 'quinto_ritual_chamber',
        completedPuzzles: const {
          'memory_childhood',
          'memory_youth',
          'memory_maturity',
          'memory_old_age',
          'cup_ataraxia',
          'cup_the_constant',
          'ritual_stirred',
        },
        puzzleCounters: const {
          'memory_childhood_specific_count': 1,
          'memory_maturity_costly_count': 1,
          'depth_memory': 4,
          'quote_exposure_seen': 19,
        },
        inventory: const ['notebook', 'the proportion', 'the catalyst'],
        psychoWeight: 5,
      );

      final row = {
        'id': 1,
        'current_node': original.currentNode,
        'completed_puzzles': jsonEncode(original.completedPuzzles.toList()),
        'puzzle_counters': jsonEncode(original.puzzleCounters),
        'inventory': jsonEncode(original.inventory),
        'psycho_weight': original.psychoWeight,
      };
      final restored = GameState.fromRow(row);

      final runtime = MemoryModule.deriveRuntime(
        puzzles: restored.completedPuzzles,
        counters: restored.puzzleCounters,
        inventory: restored.inventory,
        psychoWeight: restored.psychoWeight,
      );

      expect(runtime.childhood.answered, isTrue);
      expect(runtime.youth.answered, isTrue);
      expect(runtime.maturity.answered, isTrue);
      expect(runtime.oldAge.answered, isTrue);
      expect(runtime.cupPlaced, contains('ataraxia'));
      expect(runtime.ritualStirred, isTrue);
      expect(runtime.depthThresholdMet, isTrue);
      expect(runtime.quoteThresholdMet, isTrue);
    });
  });
}
