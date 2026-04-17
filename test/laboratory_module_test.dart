import 'package:flutter_test/flutter_test.dart';

import 'package:archive_of_oblivion/features/game/laboratory/laboratory_module.dart';
import 'package:archive_of_oblivion/features/parser/parser_state.dart';

void main() {
  LaboratoryStateView state({
    required String nodeId,
    Set<String> puzzles = const {},
    Map<String, int> counters = const {},
    List<String> inventory = const ['notebook'],
    int psychoWeight = 0,
  }) {
    return LaboratoryStateView(
      nodeId: nodeId,
      completedPuzzles: puzzles,
      puzzleCounters: counters,
      inventory: inventory,
      psychoWeight: psychoWeight,
      runtime: LaboratoryModule.deriveRuntime(
        puzzles: puzzles,
        counters: counters,
      ),
    );
  }

  group('Laboratory offerings', () {
    test('rejects generic repetition and accepts distinct concepts', () {
      final generic = LaboratoryModule.handleOffer(
        cmd: const ParsedCommand(
          verb: CommandVerb.offer,
          args: ['truth'],
          rawInput: 'offer truth',
        ),
        state: state(nodeId: 'lab_vestibule'),
      );
      expect(generic, isNotNull);
      expect(generic!.incrementCounter, 'lab_offers_rejected');

      final accepted = LaboratoryModule.handleOffer(
        cmd: const ParsedCommand(
          verb: CommandVerb.offer,
          args: ['i', 'release', 'my', 'need', 'to', 'win'],
          rawInput: 'offer i release my need to win',
        ),
        state: state(nodeId: 'lab_vestibule'),
      );
      expect(accepted, isNotNull);
      expect(accepted!.incrementCounter, 'lab_offers_count');
      expect(accepted.completePuzzle, startsWith('lab_offer_concept_'));

      final repeated = LaboratoryModule.handleOffer(
        cmd: const ParsedCommand(
          verb: CommandVerb.offer,
          args: ['i', 'release', 'my', 'need', 'to', 'win'],
          rawInput: 'offer i release my need to win',
        ),
        state: state(
          nodeId: 'lab_vestibule',
          puzzles: {accepted.completePuzzle!},
          counters: const {'lab_offers_count': 1},
        ),
      );
      expect(repeated, isNotNull);
      expect(repeated!.incrementCounter, 'lab_offers_rejected');
    });
  });

  group('Laboratory state transitions', () {
    test('substance collection and transformation states are explicit', () {
      final runtime = LaboratoryModule.deriveRuntime(
        puzzles: const {
          'lab_symbols_deciphered',
          'lab_mercury_collected',
          'furnace_calcinating',
          'bain_marie_left',
        },
        counters: const {
          'furnace_waits': 2,
          'bain_marie_external': 1,
        },
      );

      expect(runtime.symbolsDeciphered, isTrue);
      expect(runtime.substancesCollected, contains('mercury'));
      expect(runtime.furnaceStarted, isTrue);
      expect(runtime.furnaceWaits, 2);
      expect(runtime.bainMarieStage, BainMarieStage.maturing);
      expect(runtime.bainMarieExternalVisits, 1);
    });

    test('furnace progression cannot be brute-forced by arbitrary order', () {
      final waitBeforeCalcinate = LaboratoryModule.handleWait(
        state: state(nodeId: 'lab_furnace'),
      );
      expect(waitBeforeCalcinate, isNotNull);
      expect(waitBeforeCalcinate!.completePuzzle, isNull);
      expect(waitBeforeCalcinate.narrativeText, contains('cold'));

      final calcinate = LaboratoryModule.handleUnknown(
        cmd: const ParsedCommand(
          verb: CommandVerb.unknown,
          args: [],
          rawInput: 'calcinate',
        ),
        state: state(
          nodeId: 'lab_furnace',
          puzzles: const {
            'lab_mercury_collected',
            'lab_sulphur_collected',
            'lab_salt_collected',
          },
        ),
      );
      expect(calcinate, isNotNull);
      expect(calcinate!.completePuzzle, 'furnace_calcinating');

      final nearEndWait = LaboratoryModule.handleWait(
        state: state(
          nodeId: 'lab_furnace',
          puzzles: const {'furnace_calcinating'},
          counters: const {'furnace_waits': 3},
        ),
      );
      expect(nearEndWait, isNotNull);
      expect(nearEndWait!.completePuzzle, isNull);

      final finalWait = LaboratoryModule.handleWait(
        state: state(
          nodeId: 'lab_furnace',
          puzzles: const {'furnace_calcinating'},
          counters: const {'furnace_waits': 4},
        ),
      );
      expect(finalWait, isNotNull);
      expect(finalWait!.completePuzzle, 'furnace_calcinated');
    });

    test('alembic temperature affects outcomes meaningfully', () {
      final wrong = LaboratoryModule.handleSetParam(
        cmd: const ParsedCommand(
          verb: CommandVerb.setParam,
          args: ['temperature', 'hot'],
          rawInput: 'set temperature hot',
        ),
        state: state(nodeId: 'lab_alembic'),
      );
      expect(wrong, isNotNull);
      expect(wrong!.completePuzzle, 'lab_alembic_overheated');
      expect(wrong.incrementCounter, 'lab_alembic_misfires');

      final gentle = LaboratoryModule.handleSetParam(
        cmd: const ParsedCommand(
          verb: CommandVerb.setParam,
          args: ['temperature', 'gentle'],
          rawInput: 'set temperature gentle',
        ),
        state: state(nodeId: 'lab_alembic'),
      );
      expect(gentle, isNotNull);
      expect(gentle!.completePuzzle, 'alembic_temperature_set');
      expect(gentle.incrementCounter, 'lab_alembic_degree_gentle');
    });

    test('bain-marie requires maturation conditions, not immediate reuse', () {
      final immediate = LaboratoryModule.applyNavigationTransition(
        fromNode: 'lab_bain_marie',
        destNode: 'lab_substances',
        puzzles: const {},
        counters: const {},
      );
      expect(immediate.puzzles, contains('bain_marie_left'));
      expect(immediate.puzzles, isNot(contains('bain_marie_complete')));

      final afterExternal = LaboratoryModule.applyNavigationTransition(
        fromNode: 'la_soglia',
        destNode: 'gallery_hall',
        puzzles: immediate.puzzles,
        counters: immediate.counters,
      );
      expect(afterExternal.counters['bain_marie_external'], 1);

      final matured = LaboratoryModule.applyNavigationTransition(
        fromNode: 'la_soglia',
        destNode: 'garden_portico',
        puzzles: afterExternal.puzzles,
        counters: {
          ...afterExternal.counters,
          'bain_marie_external': 2,
        },
      );
      expect(matured.puzzles, contains('bain_marie_complete'));
    });

    test('Great Work phases cannot be skipped out of sequence', () {
      final wrong = LaboratoryModule.handleDrop(
        cmd: const ParsedCommand(
          verb: CommandVerb.drop,
          args: ['moon'],
          rawInput: 'drop moon',
        ),
        state: state(nodeId: 'lab_great_work'),
      );
      expect(wrong, isNotNull);
      expect(wrong!.incrementCounter, isNull);
      expect(wrong.narrativeText, contains('next placement belongs to saturn'));

      final right = LaboratoryModule.handleDrop(
        cmd: const ParsedCommand(
          verb: CommandVerb.drop,
          args: ['saturn'],
          rawInput: 'drop saturn',
        ),
        state: state(nodeId: 'lab_great_work'),
      );
      expect(right, isNotNull);
      expect(right!.incrementCounter, 'great_work_step');
    });

    test('final breath only works when process is ready', () {
      final blocked = LaboratoryModule.handleBlow(
        state: state(nodeId: 'lab_sealed'),
      );
      expect(blocked, isNotNull);
      expect(blocked!.completePuzzle, isNull);
      expect(blocked.narrativeText, contains('unfinished'));

      final ready = LaboratoryModule.handleBlow(
        state: state(
          nodeId: 'lab_sealed',
          puzzles: const {
            'furnace_calcinated',
            'alembic_temperature_set',
            'bain_marie_complete',
            'lab_great_work_complete',
          },
        ),
      );
      expect(ready, isNotNull);
      expect(ready!.completePuzzle, 'lab_complete');
      expect(ready.grantItem, 'the catalyst');
    });
  });

  group('Laboratory completion depth', () {
    test('surface completion is distinct from deep completion', () {
      expect(LaboratoryModule.isSurfaceComplete({'lab_complete'}), isTrue);
      expect(
        LaboratoryModule.isDeepComplete(
          puzzles: {'lab_complete'},
          counters: {'depth_laboratory': 7},
        ),
        isFalse,
      );

      expect(
        LaboratoryModule.isDeepComplete(
          puzzles: {
            'lab_complete',
            'lab_process_ready',
            'lab_revisited',
            'lab_cross_sector_hint',
          },
          counters: {'depth_laboratory': 7},
        ),
        isTrue,
      );
    });
  });
}
