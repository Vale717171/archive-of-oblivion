import 'package:flutter_test/flutter_test.dart';

import 'package:archive_of_oblivion/features/game/progression_service.dart';
import 'package:archive_of_oblivion/features/parser/parser_state.dart';

void main() {
  group('ProgressionService depth updates', () {
    test('records unique meaningful signatures once', () {
      final first = ProgressionService.applyTurn(
        cmd: const ParsedCommand(
          verb: CommandVerb.examine,
          args: ['leaves'],
          rawInput: 'examine leaves',
        ),
        response: const EngineResponse(
          narrativeText: 'x',
          needsDemiurge: true,
        ),
        nodeId: 'garden_cypress',
        puzzles: const {},
        counters: const {},
      );
      expect(first.counters[ProgressionService.depthCounterKey('garden')], 1);

      final second = ProgressionService.applyTurn(
        cmd: const ParsedCommand(
          verb: CommandVerb.examine,
          args: ['leaves'],
          rawInput: 'examine leaves',
        ),
        response: const EngineResponse(
          narrativeText: 'x',
          needsDemiurge: true,
        ),
        nodeId: 'garden_cypress',
        puzzles: first.puzzles,
        counters: first.counters,
      );
      expect(second.counters[ProgressionService.depthCounterKey('garden')], 1);
    });
  });

  group('ProgressionService completion markers', () {
    test('adds surface and deep markers with generalized rules', () {
      final counters = {
        ProgressionService.depthCounterKey('garden'): 7,
      };
      final puzzles = {
        'garden_complete',
        'garden_revisited',
        'garden_cross_sector_hint',
      };

      final result = ProgressionService.applyTurn(
        cmd: const ParsedCommand(
          verb: CommandVerb.examine,
          args: [],
          rawInput: 'look',
        ),
        response: const EngineResponse(narrativeText: 'x'),
        nodeId: 'garden_portico',
        puzzles: puzzles,
        counters: counters,
      );

      expect(result.puzzles, contains('progress_surface_garden'));
      expect(result.puzzles, contains('progress_deep_garden'));
      expect(result.puzzles, contains('sys_deep_garden'));
      expect(result.puzzles, contains('garden_surface_complete'));
      expect(result.puzzles, contains('garden_deep_complete'));
      expect(
        result.counters[ProgressionService.thresholdResonanceInputCounter],
        greaterThanOrEqualTo(1),
      );
    });
  });
}
