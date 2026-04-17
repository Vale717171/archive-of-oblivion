import 'package:flutter_test/flutter_test.dart';

import 'package:archive_of_oblivion/features/game/systemic_state.dart';
import 'package:archive_of_oblivion/features/parser/parser_state.dart';

void main() {
  group('SystemicStateCodec.applyShells', () {
    test('increments verbal/symbolic/notebook axes on expressive commands', () {
      final counters = <String, int>{};
      final puzzles = <String>{};
      const cmd = ParsedCommand(
        verb: CommandVerb.write,
        args: ['i', 'remember'],
        rawInput: 'write i remember',
      );
      const response = EngineResponse(
        narrativeText: 'ok',
        needsDemiurge: true,
        completePuzzle: 'memory_childhood',
      );

      SystemicStateCodec.applyShells(
        cmd: cmd,
        response: response,
        nodeId: 'quinto_childhood',
        beforeInventory: const ['notebook'],
        afterInventory: const ['notebook'],
        psychoWeight: 0,
        counters: counters,
        puzzles: puzzles,
      );

      expect(counters['sys_weight_verbal'], 1);
      expect(counters['sys_weight_symbolic'], 1);
      expect(counters['sys_notebook_pages'], 1);
      expect(counters['sys_notebook_habitation'], 1);
    });

    test('registers contradiction when player says let go but carries relics',
        () {
      final counters = <String, int>{};
      final puzzles = <String>{};
      const cmd = ParsedCommand(
        verb: CommandVerb.say,
        args: ['i', 'let', 'go'],
        rawInput: 'say i let go',
      );
      const response = EngineResponse(narrativeText: 'ok');

      SystemicStateCodec.applyShells(
        cmd: cmd,
        response: response,
        nodeId: 'il_nucleo',
        beforeInventory: const ['notebook', 'mirror shard'],
        afterInventory: const ['notebook', 'mirror shard'],
        psychoWeight: 2,
        counters: counters,
        puzzles: puzzles,
      );

      expect(counters['sys_contradictions'], 1);
      expect(counters['sys_zone_pressure'], 2);
    });
  });

  test('zoneActivationBoost scales with pressure and is capped', () {
    expect(SystemicStateCodec.zoneActivationBoost({'sys_zone_pressure': 0}), 0);
    expect(SystemicStateCodec.zoneActivationBoost({'sys_zone_pressure': 3}),
        closeTo(0.09, 0.0001));
    expect(SystemicStateCodec.zoneActivationBoost({'sys_zone_pressure': 99}),
        0.20);
  });
}
