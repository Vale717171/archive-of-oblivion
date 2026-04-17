import 'package:flutter_test/flutter_test.dart';

import 'package:archive_of_oblivion/features/game/gallery/gallery_module.dart';
import 'package:archive_of_oblivion/features/parser/parser_state.dart';

void main() {
  GalleryStateView state({
    required String nodeId,
    Set<String> puzzles = const {},
    Map<String, int> counters = const {},
    List<String> inventory = const ['notebook'],
    int psychoWeight = 0,
  }) {
    return GalleryStateView(
      nodeId: nodeId,
      completedPuzzles: puzzles,
      puzzleCounters: counters,
      inventory: inventory,
      psychoWeight: psychoWeight,
    );
  }

  group('Gallery corridor progression', () {
    test('reverse corridor cannot be solved by straightforward movement alone',
        () {
      final forward = GalleryModule.handleWalk(
        cmd: const ParsedCommand(
          verb: CommandVerb.walk,
          args: ['forward'],
          rawInput: 'walk forward',
        ),
        state: state(nodeId: 'gallery_hall'),
      );
      expect(forward, isNotNull);
      expect(forward!.completePuzzle, isNull);

      final backward = GalleryModule.handleWalk(
        cmd: const ParsedCommand(
          verb: CommandVerb.walk,
          args: ['backward'],
          rawInput: 'walk backward',
        ),
        state: state(nodeId: 'gallery_hall'),
      );
      expect(backward, isNotNull);
      expect(backward!.completePuzzle, 'hall_backward_walked');
    });

    test('symmetry hall distinguishes fertile anomaly from random interaction',
        () {
      final random = GalleryModule.handlePress(
        cmd: const ParsedCommand(
          verb: CommandVerb.press,
          args: ['wall'],
          rawInput: 'press wall',
        ),
        state: state(nodeId: 'gallery_corridor'),
      );
      expect(random, isNotNull);
      expect(random!.completePuzzle, isNull);

      final fertile = GalleryModule.handlePress(
        cmd: const ParsedCommand(
          verb: CommandVerb.press,
          args: ['anomalous', 'tile'],
          rawInput: 'press anomalous tile',
        ),
        state: state(nodeId: 'gallery_corridor'),
      );
      expect(fertile, isNotNull);
      expect(fertile!.completePuzzle, 'corridor_tile_pressed');
    });

    test(
        'proportion room distinguishes correct from merely elegant construction',
        () {
      final elegant = GalleryModule.handleWrite(
        cmd: const ParsedCommand(
          verb: CommandVerb.write,
          args: ['golden', 'spiral'],
          rawInput: 'write golden spiral',
        ),
        state: state(nodeId: 'gallery_proportions'),
      );
      expect(elegant, isNotNull);
      expect(elegant!.completePuzzle, isNull);

      final correct = GalleryModule.handleWrite(
        cmd: const ParsedCommand(
          verb: CommandVerb.write,
          args: ['construct', 'pentagon', 'with', 'compass'],
          rawInput: 'construct pentagon with compass',
        ),
        state: state(nodeId: 'gallery_proportions'),
      );
      expect(correct, isNotNull);
      expect(correct!.completePuzzle, 'proportion_pentagon_drawn');
    });
  });

  group('Gallery wings and sacrifice', () {
    test('copies wing and originals wing have distinct logic paths', () {
      final copies = GalleryModule.handleWrite(
        cmd: const ParsedCommand(
          verb: CommandVerb.write,
          args: ['missing', 'hand', 'at', 'the', 'edge'],
          rawInput: 'write missing hand at the edge',
        ),
        state: state(nodeId: 'gallery_copies'),
      );
      expect(copies, isNotNull);
      expect(copies!.incrementCounter, 'gallery_copies_described');

      final originalsShort = GalleryModule.handleWrite(
        cmd: const ParsedCommand(
          verb: CommandVerb.write,
          args: ['short', 'line'],
          rawInput: 'write short line',
        ),
        state: state(nodeId: 'gallery_originals'),
      );
      expect(originalsShort, isNotNull);
      expect(originalsShort!.completePuzzle, isNull);
      expect(originalsShort.narrativeText, contains('Fifty are required'));
    });

    test('twin chambers require meaningful sacrifice, not arbitrary dumping',
        () {
      final arbitrary = GalleryModule.handleDrop(
        cmd: const ParsedCommand(
          verb: CommandVerb.drop,
          args: ['spoon'],
          rawInput: 'drop spoon',
        ),
        state: state(
            nodeId: 'gallery_dark', inventory: const ['notebook', 'spoon']),
      );
      expect(arbitrary, isNotNull);
      expect(arbitrary!.completePuzzle, isNull);

      final meaningful = GalleryModule.handleDrop(
        cmd: const ParsedCommand(
          verb: CommandVerb.drop,
          args: ['stylus'],
          rawInput: 'drop stylus',
        ),
        state: state(
            nodeId: 'gallery_dark', inventory: const ['notebook', 'stylus']),
      );
      expect(meaningful, isNotNull);
      expect(meaningful!.completePuzzle, 'gallery_item_abandoned');
    });
  });

  group('Mirror logic and completion depth', () {
    test('mirror break outcome changes depending on state and timing', () {
      final chaotic = GalleryModule.handleBreak(
        cmd: const ParsedCommand(
          verb: CommandVerb.breakObj,
          args: ['mirror'],
          rawInput: 'break mirror',
        ),
        state: state(nodeId: 'gallery_central', psychoWeight: 2),
      );
      expect(chaotic, isNotNull);
      expect(chaotic!.completePuzzle, 'gallery_mirror_broken_chaos');

      final tooSoon = GalleryModule.handleBreak(
        cmd: const ParsedCommand(
          verb: CommandVerb.breakObj,
          args: ['mirror'],
          rawInput: 'break mirror',
        ),
        state: state(nodeId: 'gallery_central'),
      );
      expect(tooSoon, isNotNull);
      expect(tooSoon!.completePuzzle, isNull);

      final aligned = GalleryModule.handleBreak(
        cmd: const ParsedCommand(
          verb: CommandVerb.breakObj,
          args: ['mirror'],
          rawInput: 'break mirror',
        ),
        state: state(
          nodeId: 'gallery_central',
          puzzles: const {'gallery_mirror_window_open'},
        ),
      );
      expect(aligned, isNotNull);
      expect(aligned!.completePuzzle, 'gallery_complete');
      expect(aligned.grantItem, 'the proportion');
    });

    test('deep completion is stricter than surface completion', () {
      expect(GalleryModule.isSurfaceComplete({'gallery_complete'}), isTrue);
      expect(
        GalleryModule.isDeepComplete(
          puzzles: {'gallery_complete'},
          counters: {'depth_gallery': 7},
        ),
        isFalse,
      );

      expect(
        GalleryModule.isDeepComplete(
          puzzles: {
            'gallery_complete',
            'gallery_revisited',
            'gallery_cross_sector_hint',
            'gallery_reflection_triggered',
          },
          counters: {'depth_gallery': 7},
        ),
        isTrue,
      );
    });
  });
}
