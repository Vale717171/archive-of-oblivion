import 'package:flutter_test/flutter_test.dart';

import 'package:archive_of_oblivion/features/game/gallery/gallery_sector.dart';
import 'package:archive_of_oblivion/features/game/game_node.dart';
import 'package:archive_of_oblivion/features/game/garden/garden_sector.dart';
import 'package:archive_of_oblivion/features/game/laboratory/laboratory_sector.dart';
import 'package:archive_of_oblivion/features/game/memory/memory_sector.dart';
import 'package:archive_of_oblivion/features/game/observatory/observatory_sector.dart';
import 'package:archive_of_oblivion/features/game/sector_contract.dart';
import 'package:archive_of_oblivion/features/game/sector_router.dart';
import 'package:archive_of_oblivion/features/parser/parser_state.dart';

void main() {
  final router = SectorRouter([
    GardenSectorHandler(),
    ObservatorySectorHandler(),
    GallerySectorHandler(),
    LaboratorySectorHandler(),
    MemorySectorHandler(),
  ]);

  const snapshot = SectorRuntimeSnapshot(
    completedPuzzles: {},
    puzzleCounters: {},
    inventory: ['notebook'],
    psychoWeight: 0,
  );

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
          node: gardenSectorContract.roomDefinitions['garden_cypress']!,
          snapshot: const SectorRuntimeSnapshot(
            completedPuzzles: {'garden_columns_read', 'garden_leaves_read'},
            puzzleCounters: {},
            inventory: ['notebook'],
            psychoWeight: 0,
          ),
        ),
      );

      expect(response, isNotNull);
      expect(response!.completePuzzle, 'leaves_arranged');
    });

    test('routes observatory command to observatory sector handler', () {
      final response = router.routeCommand(
        SectorCommandContext(
          cmd: const ParsedCommand(
            verb: CommandVerb.combine,
            args: ['moon', 'mercury', 'sun'],
            rawInput: 'combine moon mercury sun',
          ),
          nodeId: 'obs_antechamber',
          node: observatorySectorContract.roomDefinitions['obs_antechamber']!,
          snapshot: snapshot,
        ),
      );

      expect(response, isNotNull);
      expect(response!.completePuzzle, 'lenses_combined');
    });

    test('routes gallery command to gallery sector handler', () {
      final response = router.routeCommand(
        SectorCommandContext(
          cmd: const ParsedCommand(
            verb: CommandVerb.walk,
            args: ['backward'],
            rawInput: 'walk backward',
          ),
          nodeId: 'gallery_hall',
          node: gallerySectorContract.roomDefinitions['gallery_hall']!,
          snapshot: snapshot,
        ),
      );

      expect(response, isNotNull);
      expect(response!.completePuzzle, 'hall_backward_walked');
    });

    test('routes laboratory command to laboratory sector handler', () {
      final response = router.routeCommand(
        SectorCommandContext(
          cmd: const ParsedCommand(
            verb: CommandVerb.offer,
            args: ['I', 'release', 'certainty'],
            rawInput: 'offer I release certainty',
          ),
          nodeId: 'lab_vestibule',
          node: laboratorySectorContract.roomDefinitions['lab_vestibule']!,
          snapshot: snapshot,
        ),
      );

      expect(response, isNotNull);
      expect(response!.incrementCounter, 'lab_offers_count');
    });

    test('routes memory command to memory sector handler', () {
      final response = router.routeCommand(
        SectorCommandContext(
          cmd: const ParsedCommand(
            verb: CommandVerb.write,
            args: ['forgiveness'],
            rawInput: 'write forgiveness',
          ),
          nodeId: 'quinto_childhood',
          node: memorySectorContract.roomDefinitions['quinto_childhood']!,
          snapshot: snapshot,
        ),
      );

      expect(response, isNotNull);
      expect(response!.completePuzzle, 'memory_childhood');
      expect(response.playerMemoryKey, 'memory_childhood');
    });

    test('returns null for unrelated node', () {
      final response = router.routeCommand(
        SectorCommandContext(
          cmd: const ParsedCommand(
            verb: CommandVerb.arrange,
            args: ['x'],
            rawInput: 'arrange x',
          ),
          nodeId: 'lab_alembic',
          node: const NodeDef(title: 'x', description: 'x', exits: {}),
          snapshot: snapshot,
        ),
      );

      expect(response, isNull);
    });
  });

  group('SectorRouter enter hooks', () {
    test('routes revisit enter hook', () {
      final response = router.onEnterNode(
        const SectorEnterContext(
          fromNode: 'la_soglia',
          destNode: 'garden_portico',
          snapshot: SectorRuntimeSnapshot(
            completedPuzzles: {'garden_complete'},
            puzzleCounters: {},
            inventory: ['notebook'],
            psychoWeight: 0,
          ),
        ),
      );

      expect(response, isNotNull);
      expect(response!.completePuzzle, 'garden_revisited');
    });
  });
}
