import '../../parser/parser_state.dart';
import '../game_node.dart';

class GalleryStateView {
  final String nodeId;
  final Set<String> completedPuzzles;
  final Map<String, int> puzzleCounters;
  final List<String> inventory;
  final int psychoWeight;

  const GalleryStateView({
    required this.nodeId,
    required this.completedPuzzles,
    required this.puzzleCounters,
    required this.inventory,
    required this.psychoWeight,
  });
}

class GalleryModule {
  static const String surfacePuzzle = 'gallery_complete';
  static const String surfaceMarkerPuzzle = 'gallery_surface_complete';
  static const String deepMarkerPuzzle = 'gallery_deep_complete';

  static const Set<String> _simulacra = {
    'ataraxia',
    'the constant',
    'the proportion',
    'the catalyst',
  };

  static const Set<String> _meaningfulSacrificeItems = {
    'stylus',
    'coin',
    'book',
    'compass',
    'lamp',
    'key',
    'page',
    'mirror shard',
    'earth',
    'moon lens',
    'mercury lens',
    'sun lens',
    'madeleine',
    'ticket',
    'glasses',
    'clock',
  };

  static const Map<String, Map<String, String>> exitGates = {
    'gallery_hall': {'south': 'hall_backward_walked'},
    'gallery_corridor': {'south': 'corridor_tile_pressed'},
    'gallery_proportions': {
      'east': 'proportion_pentagon_drawn',
      'west': 'proportion_pentagon_drawn',
    },
    'gallery_dark': {'east': 'gallery_item_abandoned'},
    'gallery_light': {'west': 'gallery_item_abandoned'},
  };

  static const Map<String, String> gateHints = {
    'hall_backward_walked':
        'The gallery corridor is sealed. The way forward is behind you.\n\n'
            'Hint: walk backward.',
    'corridor_tile_pressed':
        'The proportions room is locked. One tile does not belong.\n\n'
            'Hint: press anomalous tile.',
    'proportion_pentagon_drawn':
        'The wings are sealed. A geometric form must be constructed first.\n\n'
            'Hint: construct pentagon.',
    'gallery_item_abandoned': 'The tunnel between the chambers demands a price.\n\n'
        'Hint: drop something personally meaningful — the tunnel requires sacrifice, not disposal.',
  };

  static const Map<String, NodeDef> roomDefinitions = {
    'gallery_hall': NodeDef(
      title: 'Gallery of Mirrors — Hall of First Impression',
      description: 'The golden door opens to a long hall of mirrors.\n\n'
          'You see yourself from every angle. The reflections agree on '
          'your outline but not on your expression.\n\n'
          'At the south end, where a door should be, there is only mirror. '
          'But once — from the corner of your eye — there was something else.',
      exits: {
        'north': 'la_soglia',
        'back': 'la_soglia',
        'south': 'gallery_corridor'
      },
      examines: {
        'mirrors':
            'Thirty versions of the same face, each choosing a different truth.',
        'door': 'Where the south door should be: another mirror. '
            'Yet in the reflection, it is open.',
        'reflection':
            'You look directly at it. The door in the reflection is open. '
                'In the real wall, it is closed.',
      },
    ),
    'gallery_corridor': NodeDef(
      title: 'Symmetry Corridor',
      description:
          'A corridor where everything appears mathematically balanced.\n\n'
          'The floor mosaic mirrors itself from both axes — except for one tile near the east wall.\n\n'
          'At the far end: the door to Proportions.',
      exits: {'north': 'gallery_hall', 'south': 'gallery_proportions'},
      examines: {
        'mosaic': 'Black and white. Perfectly mirrored — except for one tile.',
        'tile': 'One tile fails symmetry by a fraction. Not random — fertile.',
        'east wall':
            'Near it, the anomaly waits like a deliberate error in a proof.',
      },
    ),
    'gallery_proportions': NodeDef(
      title: 'Room of Proportions',
      description: 'A drafting room with instruments laid in strict order.\n\n'
          'Compass. Straightedge. Chalk. A central slab with no drawing yet.\n\n'
          'Two arches wait closed: east to the copies, west to the originals.',
      exits: {
        'north': 'gallery_corridor',
        'east': 'gallery_copies',
        'west': 'gallery_originals',
      },
      examines: {
        'instruments': 'Classical tools. No shortcuts. No templates.',
        'slab': 'An empty construction field waiting for exact relation.',
        'doorways': 'Two arches: east for copies, west for originals.',
      },
    ),
    'gallery_copies': NodeDef(
      title: 'Wing of Copies',
      description:
          'A long gallery of reproductions, immaculate and subtly wrong.\n\n'
          'Each work is technically perfect. Each is missing one living element.\n\n'
          'A note: "Name what is absent. Three times."',
      exits: {'north': 'gallery_proportions', 'south': 'gallery_dark'},
      examines: {
        'copies':
            'Perfect copies. The gaps are visible only if you look for them.',
        'note': '"Name what is absent. Three times."',
        'gaps': 'Not errors. Omissions with intent.',
      },
    ),
    'gallery_originals': NodeDef(
      title: 'Wing of Originals',
      description: 'Bare walls and one waiting canvas.\n\nA sign reads: '
          '"Do not describe art. Produce one specific work that did not exist before this room."\n\n'
          'The passage south opens only after a substantial response.',
      exits: {'north': 'gallery_proportions', 'south': 'gallery_light'},
      examines: {
        'canvas': 'Blank, but not empty. It resists generic intent.',
        'sign': '"Specificity or silence. The room rejects elegant evasion."',
        'walls': 'Untouched, as if waiting for your first honest mark.',
      },
    ),
    'gallery_dark': NodeDef(
      title: 'Dark Chamber',
      description: 'A room nearly without light.\n\n'
          'Vision yields to contour and memory. In the east wall, a low tunnel '
          'toward a room you cannot yet reach.\n\n'
          'An inscription: "Passage requires sacrifice, not disposal."',
      exits: {
        'north': 'gallery_copies',
        'east': 'gallery_light',
        'south': 'gallery_central',
      },
      examines: {
        'darkness': 'Vision without light. Objects defined by relation.',
        'tunnel':
            'A low tunnel east. The blockage is evaluative, not physical.',
        'inscription':
            '"Passage requires sacrifice, not disposal. Leave what still holds you."',
      },
    ),
    'gallery_light': NodeDef(
      title: 'Light Chamber',
      description: 'A room entirely lit.\n\n'
          'No shadows remain. Every edge is visible and strangely flat.\n\n'
          'The same low tunnel continues west from here.',
      exits: {
        'north': 'gallery_originals',
        'west': 'gallery_dark',
        'south': 'gallery_central',
      },
      examines: {
        'light': 'Total visibility; almost no depth.',
        'tunnel': 'A low west tunnel linking this chamber to its opposite.',
        'objects':
            'Completely visible, therefore difficult to value correctly.',
      },
    ),
    'gallery_central': NodeDef(
      title: 'Central Gallery — The Perfect Mirror',
      description: 'A circular room. At its centre: the mirror.\n\n'
          'Not the room as it is, but the room as it would be under perfect honesty.\n\n'
          'A black-wood frame. No ornament. No mercy.',
      exits: {'north': 'gallery_dark', 'back': 'la_soglia'},
      examines: {
        'mirror':
            'Flawless. It shows you and what you are still refusing to relinquish.',
        'frame': 'Black wood, unadorned.',
        'reflection': 'It does not mimic you. It evaluates you.',
      },
    ),
  };

  static bool isGalleryNode(String nodeId) =>
      nodeId.startsWith('gallery_') || nodeId.startsWith('gal_');

  static bool isSurfaceComplete(Set<String> puzzles) =>
      puzzles.contains(surfacePuzzle);

  static bool isDeepComplete({
    required Set<String> puzzles,
    required Map<String, int> counters,
  }) {
    final depth = counters['depth_gallery'] ?? 0;
    return isSurfaceComplete(puzzles) &&
        puzzles.contains('gallery_revisited') &&
        puzzles.contains('gallery_cross_sector_hint') &&
        puzzles.contains('gallery_reflection_triggered') &&
        depth >= 7;
  }

  static Set<String> completionMarkers({
    required Set<String> puzzles,
    required Map<String, int> counters,
  }) {
    final adds = <String>{};
    if (isSurfaceComplete(puzzles) && !puzzles.contains(surfaceMarkerPuzzle)) {
      adds.add(surfaceMarkerPuzzle);
    }
    if (isDeepComplete(puzzles: puzzles, counters: counters) &&
        !puzzles.contains(deepMarkerPuzzle)) {
      adds.add(deepMarkerPuzzle);
      adds.add('sys_deep_gallery');
    }
    return adds;
  }

  static EngineResponse? onEnterNode({
    required String fromNode,
    required String destNode,
    required GalleryStateView state,
  }) {
    if (destNode == 'gallery_hall' &&
        state.completedPuzzles.contains(surfacePuzzle) &&
        !state.completedPuzzles.contains('gallery_revisited')) {
      return const EngineResponse(
        narrativeText: 'Hall of First Impression (returned)\n\n'
            'The mirrors now lag by a heartbeat, as if rehearsing a different outcome.\n\n'
            'From the western wing, a dry metallic breath answers your step.',
        newNode: 'gallery_hall',
        needsDemiurge: true,
        completePuzzle: 'gallery_revisited',
      );
    }
    return null;
  }

  static EngineResponse? handleExamine({
    required String nodeId,
    required String target,
    required GalleryStateView state,
  }) {
    if (nodeId == 'la_soglia' &&
        target.contains('pedestal') &&
        state.completedPuzzles.contains(surfacePuzzle) &&
        !state.completedPuzzles.contains('gallery_cross_sector_hint')) {
      return const EngineResponse(
        narrativeText: 'The Proportion settles in your palm.\n\n'
            'The violet wing answers with a low resonance, as if waiting for an operation not yet begun.',
        completePuzzle: 'gallery_cross_sector_hint',
        needsDemiurge: true,
      );
    }
    return null;
  }

  static EngineResponse? handleWalk({
    required ParsedCommand cmd,
    required GalleryStateView state,
  }) {
    if (state.nodeId != 'gallery_hall') return null;

    final mode = cmd.args.join(' ');
    if (mode.contains('backward') || mode.contains('back')) {
      if (state.completedPuzzles.contains('hall_backward_walked')) {
        return const EngineResponse(
          narrativeText: 'The corridor south is already open.',
        );
      }
      return const EngineResponse(
        narrativeText:
            'You walk backward, facing north, watching your reflection recede.\n\n'
            'Something shifts. Behind you — south — a door appears in the mirror. '
            'It was there all along. You were facing the wrong way.\n\n'
            'The corridor south is open.',
        needsDemiurge: true,
        lucidityDelta: 5,
        completePuzzle: 'hall_backward_walked',
      );
    }

    return const EngineResponse(
      narrativeText: 'Forward movement only extends the hallway.\n\n'
          'In this room, straightforwardness is not progress.',
    );
  }

  static EngineResponse? handlePress({
    required ParsedCommand cmd,
    required GalleryStateView state,
  }) {
    if (state.nodeId != 'gallery_corridor') return null;
    if (state.completedPuzzles.contains('corridor_tile_pressed')) {
      return const EngineResponse(
        narrativeText: 'The tile has been pressed. The way south is open.',
      );
    }

    final args = cmd.args.join(' ');
    if (args.contains('tile') ||
        args.contains('anomalous') ||
        args.contains('wrong') ||
        args.contains('fertile')) {
      return const EngineResponse(
        narrativeText: 'You press the fertile anomaly.\n\n'
            'It gives — slightly, decisively. The corridor accepts that symmetry '
            'depends on an asymmetry chosen on purpose.\n\n'
            'The way south opens.',
        needsDemiurge: true,
        lucidityDelta: 5,
        completePuzzle: 'corridor_tile_pressed',
      );
    }

    return const EngineResponse(
      narrativeText: 'The mosaic does not answer random pressure.\n\n'
          'Find the tile that differs as intention, not defect.',
    );
  }

  static EngineResponse? handleWrite({
    required ParsedCommand cmd,
    required GalleryStateView state,
  }) {
    if (state.nodeId == 'gallery_proportions') {
      final raw = cmd.rawInput.toLowerCase();
      if (state.completedPuzzles.contains('proportion_pentagon_drawn')) {
        return const EngineResponse(
          narrativeText:
              'The pentagon is already constructed. Both wings are open.',
        );
      }
      if (raw.contains('pentagon') &&
          (raw.contains('compass') ||
              raw.contains('straightedge') ||
              raw.contains('construct') ||
              raw.contains('inscribe'))) {
        return const EngineResponse(
          narrativeText: 'You construct the pentagon — compass, straightedge, '
              'the ancient method. It forms with a precision that feels inevitable.\n\n'
              'The two wings open: east for copies, west for originals.',
          needsDemiurge: true,
          lucidityDelta: 8,
          completePuzzle: 'proportion_pentagon_drawn',
          audioTrigger: 'calm',
        );
      }
      if (raw.contains('golden') ||
          raw.contains('fibonacci') ||
          raw.contains('hexagon') ||
          raw.contains('spiral')) {
        return const EngineResponse(
          narrativeText: 'Elegant, but evasive.\n\n'
              'The room asks for constructive relation, not ornamental proportion.\n\n'
              'Build the pentagon explicitly.',
        );
      }
      return const EngineResponse(
        narrativeText: 'The slab remains blank.\n\n'
            'This room yields to exact construction, not declaration.',
      );
    }

    if (state.nodeId == 'gallery_copies') {
      if (state.completedPuzzles.contains('gallery_copies_complete')) {
        return const EngineResponse(
          narrativeText:
              'You have already described the three missing elements.',
        );
      }
      if (cmd.args.isEmpty) {
        return const EngineResponse(
          narrativeText: 'Describe what is missing from one of the copies.',
        );
      }
      final text = cmd.args.join(' ').toLowerCase();
      final isAbsenceAware = text.contains('missing') ||
          text.contains('absent') ||
          text.contains('not there') ||
          text.contains('erased') ||
          text.contains('removed');
      if (!isAbsenceAware) {
        return const EngineResponse(
          narrativeText:
              'You describe what is present. The copy does not brighten.\n\n'
              'This wing opens only when absence is named as absence.',
        );
      }
      final described =
          (state.puzzleCounters['gallery_copies_described'] ?? 0) + 1;
      if (described < 3) {
        return EngineResponse(
          narrativeText: 'You name the absence.\n\n'
              'The copy brightens slightly — as if acknowledging '
              'that someone noticed. $described of three.',
          incrementCounter: 'gallery_copies_described',
        );
      }
      return const EngineResponse(
        narrativeText: 'The third description.\n\n'
            'All three gaps have been seen and named. '
            'The wing opens the passage south.',
        needsDemiurge: true,
        incrementCounter: 'gallery_copies_described',
        completePuzzle: 'gallery_copies_complete',
        lucidityDelta: 8,
      );
    }

    if (state.nodeId == 'gallery_originals') {
      if (state.completedPuzzles.contains('gallery_originals_complete')) {
        return const EngineResponse(
          narrativeText: 'The canvas already holds your work.',
        );
      }
      final words = cmd.rawInput
          .trim()
          .split(RegExp(r'\s+'))
          .skip(1)
          .where((w) => w.trim().isNotEmpty)
          .toList();
      if (words.length < 50) {
        return EngineResponse(
          narrativeText: 'The canvas does not accept this.\n\n'
              'The sign asks the truth of a specific moment. '
              'You have given ${words.length} words. '
              'Fifty are required — not for quantity, but because brevity here is evasion.',
        );
      }

      final text = words.join(' ').toLowerCase();
      final hasConcrete = [
        'window',
        'street',
        'room',
        'hand',
        'name',
        'voice',
        'table',
        'door'
      ].any(text.contains);
      final hasSelf = RegExp(r'\b(i|me|my|mine)\b').hasMatch(text);
      if (!hasConcrete || !hasSelf) {
        return const EngineResponse(
          narrativeText: 'Technically sufficient, existentially evasive.\n\n'
              'The room asks for a concrete scene and your position inside it.',
        );
      }

      return const EngineResponse(
        narrativeText: 'You paint.\n\n'
            'Not the painting itself — the act of it. '
            'When you stop, something exists that did not exist before.\n\n'
            'The passage south opens.',
        needsDemiurge: true,
        completePuzzle: 'gallery_originals_complete',
        lucidityDelta: 10,
        audioTrigger: 'calm',
      );
    }

    return null;
  }

  static EngineResponse? handleDrop({
    required ParsedCommand cmd,
    required GalleryStateView state,
  }) {
    if (state.nodeId != 'gallery_dark') return null;

    if (state.completedPuzzles.contains('gallery_item_abandoned')) {
      return const EngineResponse(
        narrativeText: 'The tunnel has already accepted your sacrifice.',
      );
    }
    if (cmd.args.isEmpty) {
      return const EngineResponse(
        narrativeText: 'Drop what?\n\n'
            'The tunnel asks for one meaningful relinquishment.',
      );
    }

    final target = cmd.args.join(' ');
    final match = state.inventory
        .where((i) => i.contains(target) || target.contains(i))
        .firstOrNull;
    if (match == null) {
      return const EngineResponse(
        narrativeText: 'You are not carrying that.',
      );
    }

    final lower = match.toLowerCase();
    if (lower == 'notebook') {
      return const EngineResponse(
        narrativeText: 'The notebook does not belong to this sacrifice.\n\n'
            'Choose something else that still holds you.',
      );
    }
    if (_simulacra.contains(lower)) {
      return const EngineResponse(
        narrativeText: 'The simulacra are not the price this tunnel asks.\n\n'
            'Leave something more ordinary and more personal.',
      );
    }

    final meaningful = _meaningfulSacrificeItems.any(lower.contains);
    if (!meaningful) {
      return EngineResponse(
        narrativeText: 'You set down the $match. Nothing answers.\n\n'
            'This reads as disposal, not sacrifice. The tunnel remains sealed.',
      );
    }

    return EngineResponse(
      narrativeText: 'You set down the $match.\n\n'
          'It remains on the floor with unexpected gravity. '
          'The tunnel between the chambers opens — as if the room believed you this time.',
      weightDelta: -1,
      anxietyDelta: -1,
      completePuzzle: 'gallery_item_abandoned',
      incrementCounter: 'gallery_sacrifice_count',
      lucidityDelta: 5,
      needsDemiurge: true,
    );
  }

  static EngineResponse? handleObserve({
    required GalleryStateView state,
  }) {
    if (state.nodeId == 'gallery_hall') {
      if (state.completedPuzzles.contains('hall_backward_walked') &&
          !state.completedPuzzles.contains('gallery_reflection_triggered')) {
        return const EngineResponse(
          narrativeText: 'You look into the mirrors a second time.\n\n'
              'Your reflection looks back — and it is not quite the one you left.\n\n'
              '"More fragile but more vivid, more unsubstantial, '
              'more persistent, more faithful."\n\n'
              'The images hold something you had forgotten was yours.',
          needsDemiurge: true,
          lucidityDelta: -5,
          anxietyDelta: 5,
          audioTrigger: 'sfx:proustian_trigger',
          completePuzzle: 'gallery_reflection_triggered',
        );
      }
      return const EngineResponse(
        narrativeText: 'The mirrors reflect you from every angle. '
            'None of them shows you looking at them.',
      );
    }

    if (state.nodeId == 'gallery_central') {
      if (state.completedPuzzles.contains(surfacePuzzle)) {
        return const EngineResponse(
          narrativeText:
              'The mirror is broken. The chamber keeps only the afterimage.',
        );
      }
      const prerequisites = {
        'hall_backward_walked',
        'corridor_tile_pressed',
        'proportion_pentagon_drawn',
        'gallery_copies_complete',
        'gallery_originals_complete',
        'gallery_item_abandoned',
      };
      final ready = prerequisites.every(state.completedPuzzles.contains);
      if (!ready) {
        return const EngineResponse(
          narrativeText: 'The mirror seduces you into premature certainty.\n\n'
              'It shows an elegant ending you have not yet earned.',
          incrementCounter: 'gallery_mirror_seduction',
        );
      }

      if (!state.completedPuzzles.contains('gallery_mirror_window_open')) {
        final count =
            (state.puzzleCounters['gallery_mirror_seduction'] ?? 0) + 1;
        if (count < 2) {
          return EngineResponse(
            narrativeText: 'The reflection steadies, then slips.\n\n'
                'Not yet. Stay with it one turn longer.',
            incrementCounter: 'gallery_mirror_seduction',
          );
        }
        return const EngineResponse(
          narrativeText:
              'For one heartbeat the reflection aligns perfectly.\n\n'
              'The mirror is vulnerable now. If you act, act immediately.',
          incrementCounter: 'gallery_mirror_seduction',
          completePuzzle: 'gallery_mirror_window_open',
          needsDemiurge: true,
        );
      }
      return const EngineResponse(
        narrativeText: 'The alignment holds for a breath. This is the moment.',
      );
    }

    return null;
  }

  static EngineResponse? handleBreak({
    required ParsedCommand cmd,
    required GalleryStateView state,
  }) {
    if (state.nodeId != 'gallery_central') return null;
    if (!cmd.rawInput.toLowerCase().contains('mirror')) {
      return const EngineResponse(
        narrativeText:
            'Break what? The mirror is the only thing here that waits for this.',
      );
    }
    if (state.completedPuzzles.contains(surfacePuzzle) ||
        state.completedPuzzles.contains('gallery_mirror_broken_chaos')) {
      return const EngineResponse(
        narrativeText: 'The mirror is already broken.',
      );
    }
    if (state.psychoWeight > 0) {
      return const EngineResponse(
        narrativeText: 'You break the mirror.\n\n'
            'It does not shatter cleanly. The fragments scatter, each reflecting '
            'a different version of you carrying something you should have left behind.\n\n'
            'No simulacrum appears. The proportion requires empty hands.\n\n'
            'The Gallery cannot be completed in this state.',
        needsDemiurge: true,
        lucidityDelta: -15,
        anxietyDelta: 20,
        oblivionDelta: 10,
        audioTrigger: 'anxious',
        completePuzzle: 'gallery_mirror_broken_chaos',
      );
    }
    if (!state.completedPuzzles.contains('gallery_mirror_window_open')) {
      return const EngineResponse(
        narrativeText: 'You strike too early.\n\n'
            'The mirror takes the force and returns only your own impatience.\n\n'
            'Watch the reflection until the timing opens.',
        anxietyDelta: 3,
      );
    }

    return const EngineResponse(
      narrativeText: 'You break the mirror.\n\n'
          'It shatters with a sound that is not glass — '
          'the sound of something that was pretending to be a boundary.\n\n'
          'The fragments arrange themselves on the floor in the shape of a pentagon, '
          'each piece a precise fraction of the whole.\n\n'
          'In the centre: a golden compass with no hinge. The Proportion.\n\n'
          '✦ You have recovered the proportion. The Archive marks the moment.',
      needsDemiurge: true,
      lucidityDelta: 15,
      anxietyDelta: -10,
      audioTrigger: 'simulacrum',
      grantItem: 'the proportion',
      completePuzzle: 'gallery_complete',
    );
  }
}
