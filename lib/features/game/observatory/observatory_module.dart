import '../../parser/parser_state.dart';
import '../game_node.dart';

class ObservatoryStateView {
  final String nodeId;
  final Set<String> completedPuzzles;
  final Map<String, int> puzzleCounters;
  final List<String> inventory;

  const ObservatoryStateView({
    required this.nodeId,
    required this.completedPuzzles,
    required this.puzzleCounters,
    required this.inventory,
  });
}

class ObservatoryModule {
  static const String surfacePuzzle = 'obs_complete';
  static const String surfaceMarkerPuzzle = 'obs_surface_complete';
  static const String deepMarkerPuzzle = 'obs_deep_complete';

  static const Map<String, Map<String, String>> exitGates = {
    'obs_antechamber': {'north': 'lenses_combined'},
    'obs_corridor': {'west': 'heisenberg_walked', 'east': 'heisenberg_walked'},
    'obs_void': {'south': 'void_fluctuation_measured'},
    'obs_archive': {'south': 'archive_constant_entered'},
    'obs_calibration': {'north': 'obs_calibrated'},
  };

  static const Map<String, String> gateHints = {
    'lenses_combined':
        'The corridor is dark. The telescope mount is incomplete.\n\n'
            'Hint: combine lens [Moon] [Mercury] [Sun].',
    'heisenberg_walked':
        'The branches of the corridor are inaccessible. Sight is the obstacle.\n\n'
            'Hint: walk blindfolded.',
    'void_fluctuation_measured':
        'The calibration chamber is sealed. The void has not spoken.\n\n'
            'Hint: wait seven times — then measure fluctuation.',
    'archive_constant_entered':
        'The calibration chamber cannot be reached. The panel awaits.\n\n'
            'Hint: enter [the value that underlies all constants].',
    'obs_calibrated':
        'The dome is locked. The instrument needs its reference point.\n\n'
            'Hint: calibrate [the only honest coordinates].',
  };

  static const Map<String, NodeDef> roomDefinitions = {
    'obs_antechamber': NodeDef(
      title: 'The Blind Observatory — Antechamber of Lenses',
      description: 'The cobalt door opens to cold glass.\n\n'
          'Three lenses rest in separate cradles along the north wall, '
          'each engraved with a celestial name. A brass telescope mount '
          'at the centre holds three empty slots.\n\n'
          'The labels read: Sun — Mercury — Moon.\n\n'
          'To the north: the Corridor of Hypotheses.',
      exits: {
        'north': 'obs_corridor',
        'west': 'la_soglia',
        'back': 'la_soglia'
      },
      examines: {
        'lenses': 'Three lenses: Sun (large, amber), Mercury (small, dense), '
            'Moon (silvered, cold).\n\nThe labels invite the obvious order. The mount does not.',
        'lens':
            'Sun, Mercury, Moon.\n\nIf you test an order, begin with what feels least dominant.',
        'sun': 'The largest lens. Its apparent primacy may be the problem.',
        'mercury': 'Small and heavy. The glass feels older.',
        'moon': 'Cold to the touch. It seems to absorb rather than bend.',
        'mount':
            'Three vertical slots, one lens each.\n\nIt responds to sequence, not size.',
        'slots':
            'Upper, middle, lower. Their relative sizes suggest an ordering.',
      },
    ),
    'obs_corridor': NodeDef(
      title: 'Corridor of Hypotheses',
      description:
          'A long corridor. The walls are lined with framed statements, '
          'each crossed out in red. Not false — abandoned.\n\n'
          'The corridor branches: west to a dark hall, east to an archive.\n\n'
          'A placard: "The act of looking disturbs the looked-at. This has been proven."',
      exits: {
        'south': 'obs_antechamber',
        'west': 'obs_void',
        'east': 'obs_archive'
      },
      examines: {
        'hypotheses': '"Light behaves as a wave." Crossed out. '
            '"Light behaves as a particle." Crossed out. '
            'Beneath both: "Light behaves."',
        'placard': '"The act of looking disturbs the looked-at.\n'
            'Position and momentum resist simultaneous knowledge.\n'
            'Uncertainty is not ignorance. It is precision."',
        'branches': 'West: absolute darkness. East: an archive of glass.',
      },
    ),
    'obs_void': NodeDef(
      title: 'Hall of Void',
      description: 'A perfectly dark room. No walls visible.\n\n'
          'You know they are there. The silence has texture — '
          'a grain, as if vibrating just below hearing.\n\n'
          'A measurement panel glows faintly: one dial, no pointer.',
      exits: {
        'east': 'obs_corridor',
        'south': 'obs_calibration',
        'back': 'obs_corridor'
      },
      examines: {
        'panel': 'A single dial. No pointer. '
            'Label: QUANTUM FLUCTUATION.\n'
            '"Measure only when the instrument has forgotten it is measuring."',
        'darkness': 'True darkness — the kind that has never been interrupted.',
        'silence': 'The presence of something that has not yet decided '
            'whether to become sound.',
        'dial': 'The needle does not exist. Or does not yet.',
      },
    ),
    'obs_archive': NodeDef(
      title: 'Archive of Constants',
      description: 'Glass cabinets line every wall, each holding a constant '
          'of nature, labelled and lit.\n\n'
          'The speed of light. Planck constant. '
          'The gravitational constant. The fine-structure constant. Others.\n\n'
          'At the far end: a panel with a single input slot.\n'
          '"Enter the value that underlies them all."',
      exits: {
        'west': 'obs_corridor',
        'south': 'obs_calibration',
        'back': 'obs_corridor'
      },
      examines: {
        'constants': 'Each cabinet: a number, a name, a unit. '
            'In natural units, stripped of measurement, they all reduce.',
        'panel': '"Enter the value that underlies them all.\n'
            'Not a measurement. A statement."',
        'speed of light': '"c". In natural units: 1.',
        'planck constant': '"h". In natural units: 1.',
        'fine-structure': 'Approximately 1/137. Dimensionless. '
            'The most fundamental number — still not 1.',
        'input': 'A slot for a single number. What do all constants '
            'become when you stop measuring in human units?',
      },
    ),
    'obs_calibration': NodeDef(
      title: 'Calibration Chamber',
      description: 'A room of instruments, all zeroed.\n\n'
          'At the centre: a calibration station. Three dials, each reading "???". '
          'A placard: "Set the reference point. '
          'All measurement flows from the chosen origin."\n\n'
          'To the north: the dome.',
      exits: {'north': 'obs_dome', 'west': 'obs_void', 'east': 'obs_archive'},
      examines: {
        'dials': 'Three dials, each marked "???". They accept numeric input.',
        'placard': '"There is no absolute origin. The origin is chosen.\n'
            'The honest instrument knows this and starts from zero."',
        'station': 'Three coordinates: X, Y, Z. All reading "???".',
        'door': 'The dome door is sealed. The calibration must be set first.',
      },
    ),
    'obs_dome': NodeDef(
      title: 'Telescope Dome',
      description: 'The dome opens to a sky that is not a sky.\n\n'
          'No stars — or all stars at once, so dense they form a white field. '
          'At the centre: the telescope, massive, angled toward the sky.\n\n'
          'A brass plate on the base: "Primary mirror — forward-facing."',
      exits: {'south': 'obs_calibration', 'back': 'obs_calibration'},
      examines: {
        'telescope':
            'The primary mirror faces outward — toward that impossible sky. '
                'It has been forward-facing since before you arrived.',
        'sky': 'Not stars. Frequencies. Every point of light is a wave '
            'collapsed by the act of being seen.',
        'mirror': 'Primary mirror, facing outward. '
            '"Inversion requires confirmation."',
        'plate':
            '"Primary mirror — forward-facing.\nInversion requires confirmation."',
      },
    ),
  };

  static bool isObservatoryNode(String nodeId) => nodeId.startsWith('obs_');

  static bool isSurfaceComplete(Set<String> puzzles) =>
      puzzles.contains(surfacePuzzle);

  static bool isDeepComplete({
    required Set<String> puzzles,
    required Map<String, int> counters,
  }) {
    final depth = counters['depth_observatory'] ?? 0;
    final lensModes = <int>{};
    if ((counters['obs_lens_mode_moon'] ?? 0) > 0) lensModes.add(1);
    if ((counters['obs_lens_mode_mercury'] ?? 0) > 0) lensModes.add(2);
    if ((counters['obs_lens_mode_sun'] ?? 0) > 0) lensModes.add(3);
    return isSurfaceComplete(puzzles) &&
        puzzles.contains('obs_revisited') &&
        puzzles.contains('obs_cross_sector_hint') &&
        depth >= 7 &&
        lensModes.length >= 2;
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
      adds.add('sys_deep_observatory');
    }
    return adds;
  }

  static int _activeLensMode(ObservatoryStateView state) {
    final moon = state.puzzleCounters['obs_lens_mode_moon'] ?? 0;
    final mercury = state.puzzleCounters['obs_lens_mode_mercury'] ?? 0;
    final sun = state.puzzleCounters['obs_lens_mode_sun'] ?? 0;
    final maxVal = [moon, mercury, sun].reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return 0;
    final winners = [moon == maxVal, mercury == maxVal, sun == maxVal]
        .where((v) => v)
        .length;
    if (winners > 1) return 0;
    if (moon == maxVal) return 1;
    if (mercury == maxVal) return 2;
    return 3;
  }

  static String _lensName(int mode) {
    switch (mode) {
      case 1:
        return 'Moon';
      case 2:
        return 'Mercury';
      case 3:
        return 'Sun';
      default:
        return 'none';
    }
  }

  static EngineResponse? onEnterNode({
    required String fromNode,
    required String destNode,
    required ObservatoryStateView state,
  }) {
    if (destNode == 'obs_antechamber' &&
        state.completedPuzzles.contains(surfacePuzzle) &&
        !state.completedPuzzles.contains('obs_revisited')) {
      return const EngineResponse(
        narrativeText: 'Antechamber (returned)\n\n'
            'The lenses no longer look like instruments. They look like stances.\n\n'
            'From the southern wing of the Archive, a brief glint answers the cobalt light.',
        newNode: 'obs_antechamber',
        needsDemiurge: true,
        completePuzzle: 'obs_revisited',
      );
    }
    return null;
  }

  static EngineResponse? handleExamine({
    required String nodeId,
    required String target,
    required ObservatoryStateView state,
  }) {
    if (nodeId == 'obs_corridor' &&
        (target.contains('hypoth') ||
            target.contains('placard') ||
            target.contains('branch'))) {
      if (state.completedPuzzles.contains('heisenberg_walked')) return null;
      final lens = _activeLensMode(state);
      if (lens == 1) {
        return const EngineResponse(
          narrativeText:
              'Through the Moon lens the crossed-out statements blur into kinship.\n\n'
              'Wave and particle stop competing and begin to alternate.\n\n'
              'The branches remain sealed. Looking is still the obstacle.',
          needsDemiurge: true,
        );
      }
      if (lens == 2) {
        return const EngineResponse(
          narrativeText:
              'Through the Mercury lens every sentence shivers between claims.\n\n'
              'Nothing holds long enough to become final.\n\n'
              'The branches remain sealed. Precision is not passage.',
          needsDemiurge: true,
        );
      }
      if (lens == 3) {
        return const EngineResponse(
          narrativeText:
              'Through the Sun lens the red strikes become a command: choose one, exclude the rest.\n\n'
              'The corridor hardens under that demand.\n\n'
              'The branches remain sealed. Certainty is the lock.',
          needsDemiurge: true,
        );
      }
      return const EngineResponse(
        narrativeText: 'You inspect each statement until your eyes ache.\n\n'
            'The branches do not open. The corridor is asking for a walk that does not depend on looking.',
      );
    }

    if (nodeId == 'obs_archive' && target.contains('constant')) {
      final lens = _activeLensMode(state);
      if (lens == 0) return null;
      return EngineResponse(
        narrativeText: lens == 1
            ? 'Moon lens: constants read like relations, not absolutes.\n\n'
                'They change meaning with what they are compared to.'
            : lens == 2
                ? 'Mercury lens: each constant appears as a limit-process.\n\n'
                    'Stable only because instability is bounded.'
                : 'Sun lens: each plaque pretends to be final law.\n\n'
                    'The brightness hides the unit conventions beneath it.',
        needsDemiurge: true,
      );
    }

    if (nodeId == 'la_soglia' &&
        target.contains('pedestal') &&
        state.completedPuzzles.contains(surfacePuzzle) &&
        !state.completedPuzzles.contains('obs_cross_sector_hint')) {
      return const EngineResponse(
        narrativeText: 'The Constant warms your palm.\n\n'
            'The golden wing answers with a mirrored pulse, as if proportion had been waiting for a reference.',
        completePuzzle: 'obs_cross_sector_hint',
        needsDemiurge: true,
      );
    }

    return null;
  }

  static EngineResponse? handleTake({
    required ParsedCommand cmd,
    required ObservatoryStateView state,
  }) {
    if (state.nodeId != 'obs_antechamber' || cmd.args.isEmpty) return null;
    final target = cmd.args.join(' ');
    String? lens;
    if (target.contains('moon')) lens = 'moon';
    if (target.contains('mercury')) lens = 'mercury';
    if (target.contains('sun')) lens = 'sun';
    if (lens == null || !target.contains('lens')) return null;

    final puzzle = 'obs_lens_${lens}_taken';
    if (state.completedPuzzles.contains(puzzle)) {
      return EngineResponse(
        narrativeText: 'You already carry the ${lens} lens.',
      );
    }
    return EngineResponse(
      narrativeText: 'You lift the ${lens} lens from its cradle.\n\n'
          'Its weight is less physical than interpretive.',
      needsDemiurge: true,
      grantItem: '${lens} lens',
      weightDelta: 1,
      completePuzzle: puzzle,
    );
  }

  static EngineResponse? handleUse({
    required ParsedCommand cmd,
    required ObservatoryStateView state,
  }) {
    if (!isObservatoryNode(state.nodeId) || cmd.args.isEmpty) return null;
    if (!state.completedPuzzles.contains('lenses_combined')) {
      return const EngineResponse(
        narrativeText: 'The mount is not assembled yet.\n\n'
            'Combine Moon, Mercury, and Sun before selecting an optical stance.',
      );
    }

    final target = cmd.args.join(' ');
    if (target.contains('moon') && target.contains('lens')) {
      return const EngineResponse(
        narrativeText: 'You slide the Moon lens into focus.\n\n'
            'Edges soften. Relations become visible before identities.',
        needsDemiurge: true,
        incrementCounter: 'obs_lens_mode_moon',
      );
    }
    if (target.contains('mercury') && target.contains('lens')) {
      return const EngineResponse(
        narrativeText: 'You set the Mercury lens.\n\n'
            'Transitions sharpen; certainty refuses to settle.',
        needsDemiurge: true,
        incrementCounter: 'obs_lens_mode_mercury',
      );
    }
    if (target.contains('sun') && target.contains('lens')) {
      return const EngineResponse(
        narrativeText: 'You engage the Sun lens.\n\n'
            'Everything brightens into apparent hierarchy.',
        needsDemiurge: true,
        incrementCounter: 'obs_lens_mode_sun',
      );
    }

    return EngineResponse(
      narrativeText:
          'Use which lens? Available stances: Moon, Mercury, Sun.\n\n'
          'Current stance: ${_lensName(_activeLensMode(state))}.',
    );
  }

  static EngineResponse? handleCombine({
    required ParsedCommand cmd,
    required ObservatoryStateView state,
  }) {
    if (state.nodeId != 'obs_antechamber') return null;
    if (state.completedPuzzles.contains('lenses_combined')) {
      return const EngineResponse(
        narrativeText:
            'The lenses are already in place. The corridor north is open.',
      );
    }
    final args = cmd.args.join(' ');
    final hasMoon = args.contains('moon');
    final hasMercury = args.contains('mercury');
    final hasSun = args.contains('sun');
    final moonFirst = hasMoon &&
        hasMercury &&
        hasSun &&
        args.indexOf('moon') < args.indexOf('mercury') &&
        args.indexOf('mercury') < args.indexOf('sun');

    if (moonFirst) {
      return const EngineResponse(
        narrativeText:
            'You slot the lenses in inverted order: Moon, Mercury, Sun.\n\n'
            'The mount clicks. A faint hum — as if the instrument '
            'recognised that the obvious order was the wrong one.\n\n'
            'The corridor north is open.',
        needsDemiurge: true,
        lucidityDelta: 8,
        completePuzzle: 'lenses_combined',
      );
    }
    if (hasMoon && hasMercury && hasSun) {
      return const EngineResponse(
        narrativeText: 'The mount rejects this sequence.\n\n'
            'The obvious hierarchy is a decoy.\n\n'
            'Begin with the cold lens, then the dense one, then the bright one.',
      );
    }
    return const EngineResponse(
      narrativeText: 'The mount stays inert.\n\n'
          'It only answers to a full sequence.\n\n'
          'Bring Moon, Mercury, and Sun into one deliberate order.',
    );
  }

  static EngineResponse? handleWalk({
    required ParsedCommand cmd,
    required ObservatoryStateView state,
  }) {
    if (state.nodeId != 'obs_corridor') return null;

    final mode = cmd.args.join(' ');
    if (mode.contains('blind') || mode == 'blindfolded') {
      if (state.completedPuzzles.contains('heisenberg_walked')) {
        return const EngineResponse(
          narrativeText: 'You have already demonstrated this understanding. '
              'Both branches are open.',
        );
      }
      return const EngineResponse(
        narrativeText:
            'You close your eyes — then something more than eyes.\n\n'
            'You walk. Without looking, you arrive. '
            'You do not know exactly where. You do not know exactly how.\n\n'
            'That is the point.\n\n'
            'The branches open: west to the void, east to the archive.',
        needsDemiurge: true,
        lucidityDelta: 8,
        anxietyDelta: -5,
        completePuzzle: 'heisenberg_walked',
      );
    }

    return const EngineResponse(
      narrativeText: 'You walk while watching every step.\n\n'
          'The corridor offers distance, not passage. The branches stay sealed.',
    );
  }

  static EngineResponse? handleWait({
    required ObservatoryStateView state,
  }) {
    if (state.nodeId != 'obs_void') return null;

    if (state.completedPuzzles.contains('void_silence_complete')) {
      return const EngineResponse(
        narrativeText:
            'The void has already spoken. Measure fluctuation to proceed.',
      );
    }
    final silence = (state.puzzleCounters['void_silence'] ?? 0) + 1;
    if (silence < 7) {
      return EngineResponse(
        narrativeText: 'You do nothing.\n\nThe void notes this. '
            '$silence of seven turnings.',
        incrementCounter: 'void_silence',
      );
    }
    return const EngineResponse(
      narrativeText: 'The seventh turning.\n\n'
          'A light — brief, inexplicable — crosses the darkness from no direction. '
          'You are briefly not here. A road between two church steeples at dusk, '
          'a light that moved and became something else.\n\n'
          'The dial now has a pointer. It is trembling.\n\n'
          'Now: measure fluctuation.',
      needsDemiurge: true,
      incrementCounter: 'void_silence',
      completePuzzle: 'void_silence_complete',
      lucidityDelta: -5,
      anxietyDelta: 5,
      audioTrigger: 'sfx:proustian_trigger',
    );
  }

  static EngineResponse? handleMeasure({
    required ObservatoryStateView state,
  }) {
    if (state.nodeId != 'obs_void') return null;
    if (!state.completedPuzzles.contains('void_silence_complete')) {
      return const EngineResponse(
        narrativeText: 'The dial has no pointer yet.\n\n'
            'The void must be given time. Wait.',
      );
    }
    if (state.completedPuzzles.contains('void_fluctuation_measured')) {
      return const EngineResponse(
        narrativeText:
            'The fluctuation has been measured. The passage south is open.',
      );
    }
    return const EngineResponse(
      narrativeText: 'You read the dial.\n\n'
          'The pointer rests at a value that cannot be zero and cannot be fixed. '
          'It fluctuates between two states that should exclude each other.\n\n'
          'You absorb it. The difference between noting and understanding is not large here.\n\n'
          'The passage south opens.',
      needsDemiurge: true,
      lucidityDelta: 8,
      completePuzzle: 'void_fluctuation_measured',
    );
  }

  static EngineResponse? handleEnterValue({
    required ParsedCommand cmd,
    required ObservatoryStateView state,
  }) {
    if (state.nodeId != 'obs_archive') return null;
    final value = cmd.args.join(' ').trim().toLowerCase();
    if (value.isEmpty) {
      return const EngineResponse(
        narrativeText:
            'Enter what? The panel is waiting for the constant beneath constants.',
      );
    }
    if (state.completedPuzzles.contains('archive_constant_entered')) {
      return const EngineResponse(
        narrativeText:
            'The panel already has its answer. The passage south is open.',
      );
    }

    const trueValues = {'1', '1.0', 'one', 'unity'};
    const partialValues = {
      'c',
      'h',
      'g',
      'alpha',
      '1/137',
      '137',
      'fine structure',
      'fine-structure'
    };

    if (trueValues.contains(value)) {
      return const EngineResponse(
        narrativeText: 'You enter: 1.\n\n'
            'The panel accepts it without comment.\n\n'
            'In natural units, all constants equal one — not because they are '
            'the same, but because measurement is always a comparison, '
            'and the only honest comparison is with the thing itself.\n\n'
            'The passage south opens.',
        needsDemiurge: true,
        lucidityDelta: 10,
        completePuzzle: 'archive_constant_entered',
      );
    }

    if (partialValues.contains(value)) {
      return EngineResponse(
        narrativeText: '"$value" is internally consistent, but incomplete.\n\n'
            'You entered a constant, not what underlies constants.\n\n'
            'The panel waits for the unitless origin.',
        incrementCounter: 'archive_partial_attempts',
      );
    }

    return EngineResponse(
      narrativeText: '"$value" is not accepted.\n\n'
          'What do all constants become when you stop measuring in human units?',
    );
  }

  static EngineResponse? handleCalibrate({
    required ParsedCommand cmd,
    required ObservatoryStateView state,
  }) {
    if (state.nodeId != 'obs_calibration') return null;
    if (state.completedPuzzles.contains('obs_calibrated')) {
      return const EngineResponse(
          narrativeText: 'The calibration is set. The dome is open.');
    }
    final normalized = cmd.args
        .join(' ')
        .replaceAll(',', '')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
    final isZero = normalized == '0 0 0';
    if (isZero) {
      return const EngineResponse(
        narrativeText: 'You set all three dials to zero.\n\n'
            'A hum from the mount above. The dome door opens.\n\n'
            'The reference point is chosen. Everything flows from here.',
        needsDemiurge: true,
        lucidityDelta: 10,
        completePuzzle: 'obs_calibrated',
      );
    }
    return const EngineResponse(
      narrativeText: 'The mount rejects those coordinates.\n\n'
          'The only honest origin makes no claim to be absolute.\n\n'
          'Hint: calibrate [X] [Y] [Z]',
    );
  }

  static EngineResponse? handleInvert({
    required ParsedCommand cmd,
    required ObservatoryStateView state,
  }) {
    if (state.nodeId != 'obs_dome') return null;
    if (state.completedPuzzles.contains('obs_confirmed')) {
      return const EngineResponse(
        narrativeText: 'The mirror is inverted and confirmed. You may observe.',
      );
    }
    if (state.completedPuzzles.contains('obs_mirror_inverted')) {
      return const EngineResponse(
        narrativeText:
            'The inversion is in progress. Confirm three times to commit.',
      );
    }
    if (cmd.rawInput.toLowerCase().contains('mirror')) {
      return const EngineResponse(
        narrativeText: 'You reach for the inversion mechanism.\n\n'
            'The primary mirror rotates — slowly, '
            'with the sound of something large being reconsidered.\n\n'
            'It now faces inward. The telescope looks at the room, not the sky.\n\n'
            '"Inversion requires confirmation. Confirm three times to proceed."',
        completePuzzle: 'obs_mirror_inverted',
      );
    }
    return const EngineResponse(
        narrativeText: 'Invert what? The primary mirror is the instrument.');
  }

  static EngineResponse? handleConfirm({
    required ObservatoryStateView state,
  }) {
    if (state.nodeId != 'obs_dome') return null;
    if (!state.completedPuzzles.contains('obs_mirror_inverted')) {
      return const EngineResponse(
          narrativeText: 'There is nothing awaiting confirmation.');
    }
    if (state.completedPuzzles.contains('obs_confirmed')) {
      return const EngineResponse(
        narrativeText:
            'Already confirmed. The telescope is ready. You may observe.',
      );
    }
    final count = (state.puzzleCounters['obs_confirm_count'] ?? 0) + 1;
    if (count < 3) {
      return EngineResponse(
        narrativeText: 'Confirmation $count of three.\n\nThe mechanism holds.',
        incrementCounter: 'obs_confirm_count',
      );
    }
    return const EngineResponse(
      narrativeText: 'Third confirmation.\n\n'
          'The mechanism locks. The mirror is committed.\n\n'
          'The telescope is ready. You may now observe.',
      incrementCounter: 'obs_confirm_count',
      completePuzzle: 'obs_confirmed',
    );
  }

  static EngineResponse? handleObserve({
    required ObservatoryStateView state,
  }) {
    if (state.nodeId != 'obs_dome') return null;
    if (!state.completedPuzzles.contains('obs_confirmed')) {
      return const EngineResponse(
        narrativeText: 'The telescope is not ready.\n\n'
            'Invert the primary mirror and confirm three times first.',
      );
    }
    if (state.completedPuzzles.contains('obs_complete')) {
      return const EngineResponse(
        narrativeText:
            'The observation is complete. The Constant is already in your hands.',
      );
    }
    return const EngineResponse(
      narrativeText: 'You look into the inverted telescope.\n\n'
          'It shows you the room — and within the room, yourself. '
          'A figure of precise but unmeasurable dimensions.\n\n'
          'At the centre of the image, superimposed on your chest: '
          'a light source the instrument cannot locate, '
          'because it is no longer looking outward.\n\n'
          'In your hands: a prism of tangible light. It is warm. '
          'It refracts you. The Constant.\n\n'
          '✦ You have recovered the constant. The Archive marks the moment.',
      needsDemiurge: true,
      lucidityDelta: 15,
      anxietyDelta: -10,
      audioTrigger: 'simulacrum',
      grantItem: 'the constant',
      completePuzzle: 'obs_complete',
    );
  }
}
