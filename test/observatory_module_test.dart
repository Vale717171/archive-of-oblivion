import 'package:flutter_test/flutter_test.dart';

import 'package:archive_of_oblivion/features/game/observatory/observatory_module.dart';
import 'package:archive_of_oblivion/features/parser/parser_state.dart';

void main() {
  ObservatoryStateView state({
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

  group('Observatory lens mechanics', () {
    test('lenses produce distinct interpretations', () {
      final moon = ObservatoryModule.handleExamine(
        nodeId: 'obs_corridor',
        target: 'hypotheses',
        state: state(
          nodeId: 'obs_corridor',
          counters: const {'obs_lens_mode_moon': 1},
        ),
      );
      final mercury = ObservatoryModule.handleExamine(
        nodeId: 'obs_corridor',
        target: 'hypotheses',
        state: state(
          nodeId: 'obs_corridor',
          counters: const {'obs_lens_mode_mercury': 1},
        ),
      );
      final sun = ObservatoryModule.handleExamine(
        nodeId: 'obs_corridor',
        target: 'hypotheses',
        state: state(
          nodeId: 'obs_corridor',
          counters: const {'obs_lens_mode_sun': 1},
        ),
      );

      expect(moon, isNotNull);
      expect(mercury, isNotNull);
      expect(sun, isNotNull);
      expect(moon!.narrativeText, contains('Moon lens'));
      expect(mercury!.narrativeText, contains('Mercury lens'));
      expect(sun!.narrativeText, contains('Sun lens'));
      expect(moon.narrativeText, isNot(equals(mercury.narrativeText)));
      expect(mercury.narrativeText, isNot(equals(sun.narrativeText)));
    });
  });

  group('Observatory corridor progression', () {
    test('blindfold walk is required; normal inspection does not brute-force',
        () {
      final look = ObservatoryModule.handleExamine(
        nodeId: 'obs_corridor',
        target: 'branches',
        state: state(nodeId: 'obs_corridor'),
      );
      expect(look, isNotNull);
      expect(look!.completePuzzle, isNull);

      final normalWalk = ObservatoryModule.handleWalk(
        cmd: const ParsedCommand(
          verb: CommandVerb.walk,
          args: ['through'],
          rawInput: 'walk through',
        ),
        state: state(nodeId: 'obs_corridor'),
      );
      expect(normalWalk, isNotNull);
      expect(normalWalk!.completePuzzle, isNull);

      final blindfoldWalk = ObservatoryModule.handleWalk(
        cmd: const ParsedCommand(
          verb: CommandVerb.walk,
          args: ['blindfolded'],
          rawInput: 'walk blindfolded',
        ),
        state: state(nodeId: 'obs_corridor'),
      );
      expect(blindfoldWalk, isNotNull);
      expect(blindfoldWalk!.completePuzzle, 'heisenberg_walked');
    });
  });

  group('Observatory fluctuation chamber', () {
    test('requires seven waits before valid fluctuation measurement', () {
      final earlyMeasure = ObservatoryModule.handleMeasure(
        state: state(nodeId: 'obs_void'),
      );
      expect(earlyMeasure, isNotNull);
      expect(earlyMeasure!.completePuzzle, isNull);
      expect(earlyMeasure.narrativeText, contains('Wait'));

      final sixthWait = ObservatoryModule.handleWait(
        state: state(nodeId: 'obs_void', counters: const {'void_silence': 5}),
      );
      expect(sixthWait, isNotNull);
      expect(sixthWait!.completePuzzle, isNull);
      expect(sixthWait.incrementCounter, 'void_silence');

      final seventhWait = ObservatoryModule.handleWait(
        state: state(nodeId: 'obs_void', counters: const {'void_silence': 6}),
      );
      expect(seventhWait, isNotNull);
      expect(seventhWait!.completePuzzle, 'void_silence_complete');

      final finalMeasure = ObservatoryModule.handleMeasure(
        state: state(
          nodeId: 'obs_void',
          puzzles: const {'void_silence_complete'},
        ),
      );
      expect(finalMeasure, isNotNull);
      expect(finalMeasure!.completePuzzle, 'void_fluctuation_measured');
    });
  });

  group('Observatory constants archive', () {
    test('distinguishes true, partial, and false paths', () {
      final truePath = ObservatoryModule.handleEnterValue(
        cmd: const ParsedCommand(
          verb: CommandVerb.enterValue,
          args: ['1'],
          rawInput: 'enter 1',
        ),
        state: state(nodeId: 'obs_archive'),
      );
      expect(truePath, isNotNull);
      expect(truePath!.completePuzzle, 'archive_constant_entered');

      final partialPath = ObservatoryModule.handleEnterValue(
        cmd: const ParsedCommand(
          verb: CommandVerb.enterValue,
          args: ['137'],
          rawInput: 'enter 137',
        ),
        state: state(nodeId: 'obs_archive'),
      );
      expect(partialPath, isNotNull);
      expect(partialPath!.completePuzzle, isNull);
      expect(partialPath.incrementCounter, 'archive_partial_attempts');

      final falsePath = ObservatoryModule.handleEnterValue(
        cmd: const ParsedCommand(
          verb: CommandVerb.enterValue,
          args: ['banana'],
          rawInput: 'enter banana',
        ),
        state: state(nodeId: 'obs_archive'),
      );
      expect(falsePath, isNotNull);
      expect(falsePath!.completePuzzle, isNull);
      expect(falsePath.incrementCounter, isNull);
    });
  });

  group('Observatory completion depth', () {
    test('surface completion does not imply deep completion', () {
      final surfaceOnlyPuzzles = {'obs_complete'};
      final counters = {'depth_observatory': 7, 'obs_lens_mode_moon': 1};

      expect(ObservatoryModule.isSurfaceComplete(surfaceOnlyPuzzles), isTrue);
      expect(
        ObservatoryModule.isDeepComplete(
          puzzles: surfaceOnlyPuzzles,
          counters: counters,
        ),
        isFalse,
      );

      final deepPuzzles = {
        'obs_complete',
        'obs_revisited',
        'obs_cross_sector_hint',
      };
      final deepCounters = {
        'depth_observatory': 7,
        'obs_lens_mode_moon': 1,
        'obs_lens_mode_mercury': 1,
      };

      expect(
        ObservatoryModule.isDeepComplete(
          puzzles: deepPuzzles,
          counters: deepCounters,
        ),
        isTrue,
      );
    });
  });
}
