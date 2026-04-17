import 'package:flutter_test/flutter_test.dart';

import 'package:archive_of_oblivion/features/game/game_node.dart';
import 'package:archive_of_oblivion/features/game/garden/garden_module.dart';
import 'package:archive_of_oblivion/features/game/garden/garden_sector.dart';
import 'package:archive_of_oblivion/features/game/observatory/observatory_module.dart';
import 'package:archive_of_oblivion/features/game/observatory/observatory_sector.dart';
import 'package:archive_of_oblivion/features/game/sector_router.dart';
import 'package:archive_of_oblivion/features/parser/parser_state.dart';

void main() {
  const router = SectorRouter([GardenSectorHandler()]);

  GardenStateView state({
    required String nodeId,
    Set<String> puzzles = const {},
    Map<String, int> counters = const {},
    List<String> inventory = const ['notebook'],
    int psychoWeight = 0,
  }) {
    return GardenStateView(
      nodeId: nodeId,
      completedPuzzles: puzzles,
      puzzleCounters: counters,
      inventory: inventory,
      psychoWeight: psychoWeight,
    );
  }

  group('SectorRouter command routing', () {
    test('routes garden command to garden sector handler', () {
      final response = router.routeCommand(
        SectorCommandContext(
          cmd: const ParsedCommand(
            verb: CommandVerb.arrange,
            args: [
              'prudence',
              'friendship',
              'pleasure',
              'simplicity',
              'absence',
              'tranquillity',
              'memory'
            ],
            rawInput:
                'arrange leaves prudence friendship pleasure simplicity absence tranquillity memory',
          ),
          nodeId: 'garden_cypress',
          node: GardenModule.roomDefinitions['garden_cypress']!,
          gameState: state(
            nodeId: 'garden_cypress',
            puzzles: const {'garden_columns_read', 'garden_leaves_read'},
          ),
        ),
      );

      expect(response, isNotNull);
      expect(response!.completePuzzle, 'leaves_arranged');
    });

    test('returns null for unrelated node', () {
      final response = router.routeCommand(
        SectorCommandContext(
          cmd: const ParsedCommand(
            verb: CommandVerb.arrange,
            args: ['x'],
            rawInput: 'arrange x',
          ),
          nodeId: 'obs_dome',
          node: const NodeDef(title: 'x', description: 'x', exits: {}),
          gameState: state(nodeId: 'obs_dome'),
        ),
      );

      expect(response, isNull);
    });
  });

  group('SectorRouter enter hooks', () {
    test('routes revisit enter hook', () {
      final response = router.onEnterNode(
        SectorEnterContext(
          fromNode: 'la_soglia',
          destNode: 'garden_portico',
          gameState: state(
            nodeId: 'la_soglia',
            puzzles: const {'garden_complete'},
          ),
        ),
      );

      expect(response, isNotNull);
      expect(response!.completePuzzle, 'garden_revisited');
    });
  });

  group('Observatory routing', () {
    const observatoryRouter = SectorRouter([
      GardenSectorHandler(),
      ObservatorySectorHandler(),
    ]);

    ObservatoryStateView obsState({
      required String nodeId,
      Set<String> puzzles = const {},
      Map<String, int> counters = const {},
    }) {
      return ObservatoryStateView(
        nodeId: nodeId,
        completedPuzzles: puzzles,
        puzzleCounters: counters,
        inventory: const ['notebook'],
      );
    }

    test('routes observatory combine to observatory handler', () {
      final response = observatoryRouter.routeCommand(
        SectorCommandContext(
          cmd: const ParsedCommand(
            verb: CommandVerb.combine,
            args: ['moon', 'mercury', 'sun'],
            rawInput: 'combine moon mercury sun',
          ),
          nodeId: 'obs_antechamber',
          node: ObservatoryModule.roomDefinitions['obs_antechamber']!,
          gameState: obsState(nodeId: 'obs_antechamber'),
        ),
      );

      expect(response, isNotNull);
      expect(response!.completePuzzle, 'lenses_combined');
    });
  });
}
