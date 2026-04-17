import '../../parser/parser_state.dart';
import '../game_node.dart';

class ChamberAnswerState {
  final bool answered;
  final bool specific;
  final bool costly;

  const ChamberAnswerState({
    required this.answered,
    required this.specific,
    required this.costly,
  });
}

class MemoryEpitaphInput {
  final Set<String> answeredChambers;
  final int specificAnswers;
  final int costlyAnswers;
  final String dominantWeightAxis;
  final int contradictionCount;
  final int unresolvedProtections;
  final int simulacraCount;

  const MemoryEpitaphInput({
    required this.answeredChambers,
    required this.specificAnswers,
    required this.costlyAnswers,
    required this.dominantWeightAxis,
    required this.contradictionCount,
    required this.unresolvedProtections,
    required this.simulacraCount,
  });
}

class MemoryRuntimeModel {
  final ChamberAnswerState childhood;
  final ChamberAnswerState youth;
  final ChamberAnswerState maturity;
  final ChamberAnswerState oldAge;

  final Set<String> cupPlaced;
  final bool ritualStirred;
  final bool ritualComplete;

  final bool chambersComplete;
  final bool descentReady;
  final bool revisited;
  final bool crossSectorHintUnlocked;

  final int depthSignals;
  final int quoteExposureSeen;
  final bool depthThresholdMet;
  final bool quoteThresholdMet;

  final MemoryEpitaphInput epitaphInput;

  const MemoryRuntimeModel({
    required this.childhood,
    required this.youth,
    required this.maturity,
    required this.oldAge,
    required this.cupPlaced,
    required this.ritualStirred,
    required this.ritualComplete,
    required this.chambersComplete,
    required this.descentReady,
    required this.revisited,
    required this.crossSectorHintUnlocked,
    required this.depthSignals,
    required this.quoteExposureSeen,
    required this.depthThresholdMet,
    required this.quoteThresholdMet,
    required this.epitaphInput,
  });
}

class MemoryStateView {
  final String nodeId;
  final Set<String> completedPuzzles;
  final Map<String, int> puzzleCounters;
  final List<String> inventory;
  final int psychoWeight;
  final MemoryRuntimeModel runtime;

  const MemoryStateView({
    required this.nodeId,
    required this.completedPuzzles,
    required this.puzzleCounters,
    required this.inventory,
    required this.psychoWeight,
    required this.runtime,
  });
}

class AnswerEvaluation {
  final bool accepted;
  final bool specific;
  final bool costly;
  final String? rejection;

  const AnswerEvaluation({
    required this.accepted,
    required this.specific,
    required this.costly,
    this.rejection,
  });
}

class MemoryModule {
  static const String surfacePuzzle = 'ritual_complete';
  static const String surfaceMarkerPuzzle = 'memory_surface_complete';
  static const String deepMarkerPuzzle = 'memory_deep_complete';

  static const int depthThresholdToNucleo = 4;
  static const int quoteExposureThresholdToNucleo = 18;

  static const Set<String> _simulacra = {
    'ataraxia',
    'the constant',
    'the proportion',
    'the catalyst',
  };

  static const Set<String> _chamberPuzzles = {
    'memory_childhood',
    'memory_youth',
    'memory_maturity',
    'memory_old_age',
  };

  static const Set<String> _genericPhrases = {
    'life is beautiful',
    'be yourself',
    'i dont know',
    'i do not know',
    'everything is fine',
    'nothing special',
    'just a memory',
  };

  static const Set<String> _specificTerms = {
    'name',
    'street',
    'house',
    'room',
    'winter',
    'summer',
    'station',
    'ticket',
    'telephone',
    'clock',
    'door',
    'hand',
    'voice',
    'balbec',
    'seventeen',
    'five',
    'pm',
    'am',
  };

  static const Set<String> _costTerms = {
    'afraid',
    'ashamed',
    'forgive',
    'apologize',
    'apologise',
    'regret',
    'loss',
    'hurt',
    'wound',
    'left',
    'betray',
    'failed',
    'failure',
    'did not',
    'never said',
  };

  static const Map<String, Map<String, String>> exitGates = {
    'quinto_childhood': {'back': 'memory_childhood'},
    'quinto_youth': {'back': 'memory_youth'},
    'quinto_maturity': {'back': 'memory_maturity'},
    'quinto_old_age': {'back': 'memory_old_age'},
    'quinto_landing': {'down': 'memory_descent_ready'},
    'quinto_ritual_chamber': {'down': 'ritual_complete'},
  };

  static const Map<String, String> gateHints = {
    'memory_childhood':
        'The room does not release you yet.\n\nWrite the first word you truly understood, not a decorative answer.',
    'memory_youth':
        'The promise still holds you here.\n\nName one unkept promise concretely and without ornament.',
    'memory_maturity':
        'The line remains open.\n\nSay what was never said in a specific voice, not a slogan.',
    'memory_old_age':
        'The room asks for one truthful quality.\n\nWrite it in terms that cost you something to admit.',
    'memory_descent_ready':
        'The lower chamber is still sealed.\n\nPay all four memory prices and let the fifth sector settle before descending.',
    'ritual_complete':
        'The passage down is sealed.\n\nPlace each simulacrum in the cup, stir the infusion, then drink.',
  };

  static const Map<String, NodeDef> roomDefinitions = {
    'quinto_landing': NodeDef(
      title: 'The Fifth Sector — Memory',
      description: 'A spiral staircase brought you here.\n\n'
          'Each candle on the descent was a different age.\n\n'
          'The smell: Earl Grey, dust, and paper that has held ideas for a long time.\n\n'
          'Distant: the Siciliano in B minor.\n\n'
          '"The real life, the life finally discovered and illuminated, '
          'the only life therefore really lived, is literature."\n\n'
          'Four doors stand at the compass points. Each opens onto a different age.\n\n'
          'Below: a sealed chamber that will open when all four prices have been paid.',
      exits: {
        'east': 'quinto_childhood',
        'west': 'quinto_youth',
        'north': 'quinto_maturity',
        'south': 'quinto_old_age',
        'down': 'quinto_ritual_chamber',
        'up': 'la_soglia',
        'back': 'la_soglia',
      },
      examines: {
        'doors':
            'Four doors. East: CHILDHOOD. West: YOUTH. North: MATURITY. South: OLD AGE.',
        'staircase':
            'The spiral you descended. Each candle burns at its own age.',
        'smell':
            'Earl Grey. Dust. Something written by someone who is no longer here.',
        'candles':
            'They burn without depleting. Each is a different temperature of light.',
      },
    ),
    'quinto_childhood': NodeDef(
      title: 'Childhood',
      description:
          'A small room. The light is the exact quality of a morning you almost remember.\n\n'
          'On the table: a madeleine of carved wood. '
          'It does not smell of anything, which is somehow its point.\n\n'
          'A card on the wall:\n\n'
          '"Write the first word you truly learned — '
          'not the first word you were taught, but the first one you understood."\n\n'
          'The price of this room is a word.',
      exits: {'back': 'quinto_landing'},
      examines: {
        'madeleine': 'Carved from pale wood. You know what it refers to.',
        'card': '"Write the first word you truly learned.\n'
            'Not the one you were taught. The one you understood."',
        'light': 'The quality of Saturday morning, before obligation.',
        'table': 'Simple. The madeleine rests at its centre.',
      },
      takeable: {'madeleine'},
    ),
    'quinto_youth': NodeDef(
      title: 'Youth',
      description: 'A room with the feeling of being in transit.\n\n'
          'Luggage partially packed. A train schedule half-read and set down.\n\n'
          'On the table: a train ticket to Balbec, never used.\n\n'
          'A card:\n\n'
          '"Write a promise you did not keep — not in accusation, but in acknowledgement."\n\n'
          'The price of this room is an admission.',
      exits: {'back': 'quinto_landing'},
      examines: {
        'ticket':
            'Balbec. The date is illegible. It has always been slightly too late.',
        'card':
            '"Write a promise you did not keep.\nNot in accusation.\nIn acknowledgement."',
        'luggage':
            'Half-packed. As if someone was interrupted before completing the idea.',
        'schedule': 'Times and stations. The departures are all behind you.',
      },
      takeable: {'ticket'},
    ),
    'quinto_maturity': NodeDef(
      title: 'Maturity',
      description: 'A study. Books on every surface.\n\n'
          'A telephone on the desk, receiver off the hook.\n\n'
          'On the desk: a pair of glasses, fogged from breath.\n\n'
          'A card:\n\n'
          '"Answer the telephone. Say what you have never said to the person on the other end."\n\n'
          'The price of this room is speech.',
      exits: {'back': 'quinto_landing'},
      examines: {
        'telephone': 'Off the hook. The line is open. Someone is waiting.',
        'glasses': 'Fogged. You cannot see through them.\n'
            'That is the point — seeing through your own condensation.',
        'card': '"Answer the telephone.\nSay what you have never said."',
        'books': 'Every subject. Evidence of a life that tried to understand.',
      },
      takeable: {'glasses'},
    ),
    'quinto_old_age': NodeDef(
      title: 'Old Age',
      description: 'A room that has settled into itself completely.\n\n'
          'Everything is in its place. Everything has a history visible in its surface.\n\n'
          'On the mantelpiece: a clock. The hands are stopped at 17:00. '
          'The light through the window matches.\n\n'
          'A card:\n\n'
          '"Write what you wish to be remembered as. Not an achievement. A quality."\n\n'
          'The price of this room is a truth.',
      exits: {'back': 'quinto_landing'},
      examines: {
        'clock':
            'Stopped at 17:00. The afternoon light through the window is exact.',
        'card':
            '"Write what you wish to be remembered as.\nNot an achievement.\nA quality."',
        'mantelpiece':
            'The clock. A photograph facing away. A small plant, dried.',
        'light':
            'Afternoon, late. The hour just before evening becomes certain.',
      },
      takeable: {'clock'},
    ),
    'quinto_ritual_chamber': NodeDef(
      title: 'The Ritual Chamber',
      description: 'A circular room, low-ceilinged.\n\n'
          'At the centre: a cup of extraordinary simplicity. '
          'Five-sided, made of no material you can name. '
          'It holds a liquid that is neither clear nor coloured.\n\n'
          'This is what the four simulacra were for. '
          'This is what the four sectors have been building toward.\n\n'
          'Place each simulacrum in the cup. Then stir. Then drink.',
      exits: {
        'up': 'quinto_landing',
        'back': 'quinto_landing',
        'down': 'il_nucleo'
      },
      examines: {
        'cup':
            'Five-sided. No joins. The liquid inside anticipates your decision.',
        'liquid':
            'Neither clear nor coloured. It is waiting for what you have found.',
        'room':
            'Circular. Five-sided symmetry. The geometry is familiar — you have seen it before.',
      },
    ),
  };

  static bool isMemoryNode(String nodeId) => nodeId.startsWith('quinto_');

  static bool isSurfaceComplete(Set<String> puzzles) =>
      puzzles.contains(surfacePuzzle);

  static bool isDeepComplete({
    required Set<String> puzzles,
    required Map<String, int> counters,
  }) {
    final runtime = deriveRuntime(
      puzzles: puzzles,
      counters: counters,
      inventory: const ['notebook'],
      psychoWeight: 0,
    );
    return isSurfaceComplete(puzzles) &&
        runtime.revisited &&
        puzzles.contains('memory_epitaph_ready') &&
        runtime.depthThresholdMet;
  }

  static Set<String> completionMarkers({
    required Set<String> puzzles,
    required Map<String, int> counters,
  }) {
    final runtime = deriveRuntime(
      puzzles: puzzles,
      counters: counters,
      inventory: const ['notebook'],
      psychoWeight: 0,
    );

    final adds = <String>{};

    if (runtime.chambersComplete) adds.add('memory_chambers_complete');
    if (runtime.chambersComplete && runtime.depthThresholdMet) {
      adds.add('memory_descent_ready');
    }
    if (runtime.epitaphInput.specificAnswers >= 3 &&
        runtime.epitaphInput.costlyAnswers >= 2) {
      adds.add('memory_epitaph_ready');
    }
    if (isSurfaceComplete(puzzles)) adds.add(surfaceMarkerPuzzle);

    if (isDeepComplete(puzzles: puzzles.union(adds), counters: counters)) {
      adds.add(deepMarkerPuzzle);
      adds.add('sys_deep_memory');
    }

    return adds;
  }

  static MemoryRuntimeModel deriveRuntime({
    required Set<String> puzzles,
    required Map<String, int> counters,
    required List<String> inventory,
    required int psychoWeight,
  }) {
    final childhood = _chamberState('memory_childhood', puzzles, counters);
    final youth = _chamberState('memory_youth', puzzles, counters);
    final maturity = _chamberState('memory_maturity', puzzles, counters);
    final oldAge = _chamberState('memory_old_age', puzzles, counters);

    final cupPlaced = <String>{
      if (puzzles.contains('cup_ataraxia')) 'ataraxia',
      if (puzzles.contains('cup_the_constant')) 'the constant',
      if (puzzles.contains('cup_the_proportion')) 'the proportion',
      if (puzzles.contains('cup_the_catalyst')) 'the catalyst',
    };

    final depthSignals = counters['depth_memory'] ?? 0;
    final quoteSeen = counters['quote_exposure_seen'] ?? 0;
    final chambersComplete = _chamberPuzzles.every(puzzles.contains);

    final epitaphInput = buildEpitaphInput(
      puzzles: puzzles,
      counters: counters,
      inventory: inventory,
      psychoWeight: psychoWeight,
    );

    return MemoryRuntimeModel(
      childhood: childhood,
      youth: youth,
      maturity: maturity,
      oldAge: oldAge,
      cupPlaced: cupPlaced,
      ritualStirred: puzzles.contains('ritual_stirred'),
      ritualComplete: puzzles.contains('ritual_complete'),
      chambersComplete: chambersComplete,
      descentReady: chambersComplete && depthSignals >= depthThresholdToNucleo,
      revisited: puzzles.contains('memory_revisited'),
      crossSectorHintUnlocked: puzzles.contains('memory_cross_sector_hint'),
      depthSignals: depthSignals,
      quoteExposureSeen: quoteSeen,
      depthThresholdMet: depthSignals >= depthThresholdToNucleo,
      quoteThresholdMet: quoteSeen >= quoteExposureThresholdToNucleo,
      epitaphInput: epitaphInput,
    );
  }

  static MemoryEpitaphInput buildEpitaphInput({
    required Set<String> puzzles,
    required Map<String, int> counters,
    required List<String> inventory,
    required int psychoWeight,
  }) {
    final answered = <String>{
      if (puzzles.contains('memory_childhood')) 'childhood',
      if (puzzles.contains('memory_youth')) 'youth',
      if (puzzles.contains('memory_maturity')) 'maturity',
      if (puzzles.contains('memory_old_age')) 'old_age',
    };

    final specificCount = (counters['memory_childhood_specific_count'] ?? 0) +
        (counters['memory_youth_specific_count'] ?? 0) +
        (counters['memory_maturity_specific_count'] ?? 0) +
        (counters['memory_old_age_specific_count'] ?? 0) +
        (counters['memory_childhood_costly_count'] ?? 0) +
        (counters['memory_youth_costly_count'] ?? 0) +
        (counters['memory_maturity_costly_count'] ?? 0) +
        (counters['memory_old_age_costly_count'] ?? 0);

    final costlyCount = (counters['memory_childhood_costly_count'] ?? 0) +
        (counters['memory_youth_costly_count'] ?? 0) +
        (counters['memory_maturity_costly_count'] ?? 0) +
        (counters['memory_old_age_costly_count'] ?? 0);

    final verbal = counters['sys_weight_verbal'] ?? 0;
    final symbolic = counters['sys_weight_symbolic'] ?? 0;
    final material = psychoWeight;
    final dominant = material >= verbal && material >= symbolic
        ? 'material'
        : verbal >= symbolic
            ? 'verbal'
            : 'symbolic';

    final contradictions = counters['sys_contradictions'] ?? 0;
    final unresolved = contradictions +
        inventory
            .where((i) => !_simulacra.contains(i) && i != 'notebook')
            .length;
    final simulacraCount = _simulacra.where(inventory.contains).length;

    return MemoryEpitaphInput(
      answeredChambers: answered,
      specificAnswers: specificCount,
      costlyAnswers: costlyCount,
      dominantWeightAxis: dominant,
      contradictionCount: contradictions,
      unresolvedProtections: unresolved,
      simulacraCount: simulacraCount,
    );
  }

  static EngineResponse? onEnterNode({
    required String fromNode,
    required String destNode,
    required MemoryStateView state,
  }) {
    if (destNode == 'quinto_landing' &&
        state.runtime.ritualComplete &&
        !state.runtime.revisited) {
      return const EngineResponse(
        narrativeText: 'Fifth Sector Landing (returned)\n\n'
            'The candles no longer mark age. They mark what was admitted.\n\n'
            'The central stair answers with a lower resonance, as if a final argument had already begun below language.',
        newNode: 'quinto_landing',
        needsDemiurge: true,
        completePuzzle: 'memory_revisited',
      );
    }
    return null;
  }

  static EngineResponse? handleExamine({
    required String nodeId,
    required String target,
    required MemoryStateView state,
  }) {
    if (nodeId == 'la_soglia' &&
        target.contains('pedestal') &&
        state.runtime.ritualComplete &&
        !state.runtime.crossSectorHintUnlocked) {
      return const EngineResponse(
        narrativeText: 'The fifth recess warms.\n\n'
            'No wing answers this time. The silence itself does.\n\n'
            'It is not asking where to go. It is asking what argument remains.',
        needsDemiurge: true,
        completePuzzle: 'memory_cross_sector_hint',
      );
    }
    return null;
  }

  static EngineResponse? handleWrite({
    required ParsedCommand cmd,
    required MemoryStateView state,
  }) {
    switch (state.nodeId) {
      case 'quinto_childhood':
        return _handleChamberAnswer(
          cmd: cmd,
          state: state,
          puzzleId: 'memory_childhood',
          prompt:
              'Write the first word you truly understood. One true word is enough; decoration is not.',
          mode: _AnswerMode.singleWord,
        );
      case 'quinto_youth':
        return _handleChamberAnswer(
          cmd: cmd,
          state: state,
          puzzleId: 'memory_youth',
          prompt:
              'Write one promise you did not keep, concretely and without self-protection.',
          mode: _AnswerMode.narrative,
        );
      case 'quinto_old_age':
        return _handleChamberAnswer(
          cmd: cmd,
          state: state,
          puzzleId: 'memory_old_age',
          prompt:
              'Write the quality you want to be remembered by, in terms that cost you something to claim.',
          mode: _AnswerMode.narrative,
        );
      case 'quinto_maturity':
        return _handleChamberAnswer(
          cmd: cmd,
          state: state,
          puzzleId: 'memory_maturity',
          prompt:
              'Write what you have never said. The line accepts specificity, not elegant evasion.',
          mode: _AnswerMode.narrative,
          spoken: true,
        );
      default:
        return null;
    }
  }

  static EngineResponse? handleSay({
    required ParsedCommand cmd,
    required MemoryStateView state,
  }) {
    if (state.nodeId != 'quinto_maturity') return null;
    return _handleChamberAnswer(
      cmd: cmd,
      state: state,
      puzzleId: 'memory_maturity',
      prompt: 'Say what was never said. The line is open.',
      mode: _AnswerMode.narrative,
      spoken: true,
    );
  }

  static EngineResponse? handleUnknown({
    required ParsedCommand cmd,
    required MemoryStateView state,
  }) {
    if (state.nodeId != 'quinto_maturity') return null;
    final raw = cmd.rawInput.toLowerCase().trim();
    if (!(raw.startsWith('say ') ||
        raw.startsWith('answer ') ||
        raw.startsWith('tell '))) {
      return null;
    }
    final content = raw.replaceFirst(RegExp(r'^(say|answer|tell)\s+'), '');
    return handleSay(
      cmd: ParsedCommand(
        verb: CommandVerb.say,
        args: content.split(RegExp(r'\s+')),
        rawInput: 'say $content',
      ),
      state: state,
    );
  }

  static EngineResponse? handleDrop({
    required ParsedCommand cmd,
    required MemoryStateView state,
  }) {
    if (state.nodeId != 'quinto_ritual_chamber') return null;

    final raw = cmd.rawInput.toLowerCase();
    if (!raw.contains('cup')) {
      final target = cmd.args.join(' ');
      final match = state.inventory
          .where((i) => i.contains(target) || target.contains(i))
          .firstOrNull;
      if (match == null) {
        return const EngineResponse(
            narrativeText: 'You are not carrying that.');
      }
      return EngineResponse(
        narrativeText: 'You set down the $match.',
        weightDelta: _simulacra.contains(match) ? 0 : -1,
        anxietyDelta: _simulacra.contains(match) ? 0 : -1,
      );
    }

    String? simFound;
    for (final sim in _simulacra) {
      if (raw.contains(sim) && state.inventory.contains(sim)) {
        simFound = sim;
        break;
      }
    }

    if (simFound == null) {
      final mundane = state.inventory.where((i) => !_simulacra.contains(i));
      for (final item in mundane) {
        if (raw.contains(item)) {
          return const EngineResponse(
            narrativeText: 'The cup does not accept mundane things.\n\n'
                'Only the four simulacra belong here.',
          );
        }
      }
      return const EngineResponse(
        narrativeText: 'Place what in the cup?\n\n'
            'The four simulacra must be placed: '
            'ataraxia, the constant, the proportion, the catalyst.',
      );
    }

    final puzzleId = 'cup_${simFound.replaceAll(' ', '_')}';
    if (state.completedPuzzles.contains(puzzleId)) {
      return EngineResponse(
        narrativeText: 'You have already placed $simFound in the cup.',
      );
    }

    final after = Set<String>.from(state.completedPuzzles)..add(puzzleId);
    final allPlaced = _allCupPlaced(after);
    final remaining = 4 - after.where((p) => p.startsWith('cup_')).length;

    return EngineResponse(
      narrativeText: allPlaced
          ? 'You place $simFound in the cup.\n\n'
              'All four simulacra settle into one liquid geometry.\n\n'
              'Now: stir.'
          : 'You place $simFound in the cup.\n\n'
              '$remaining more to place.',
      needsDemiurge: allPlaced,
      completePuzzle: puzzleId,
      lucidityDelta: allPlaced ? 5 : null,
    );
  }

  static EngineResponse? handleStir({
    required MemoryStateView state,
  }) {
    if (state.nodeId != 'quinto_ritual_chamber') return null;

    if (!_allCupPlaced(state.completedPuzzles)) {
      final missing = _missingCupItems(state.completedPuzzles);
      return EngineResponse(
        narrativeText: 'The cup is not ready.\n\n'
            'Still to be placed: ${missing.join(', ')}.',
      );
    }

    if (state.runtime.ritualStirred) {
      return const EngineResponse(
        narrativeText: 'The infusion has already been stirred. Now drink.',
      );
    }

    return const EngineResponse(
      narrativeText: 'You stir the infusion.\n\n'
          'The four elements spiral together — each distinct, all one.\n\n'
          'The infusion is ready. Drink.',
      needsDemiurge: true,
      completePuzzle: 'ritual_stirred',
      audioTrigger: 'calm',
      lucidityDelta: 8,
    );
  }

  static EngineResponse? handleDrink({
    required MemoryStateView state,
  }) {
    if (state.nodeId != 'quinto_ritual_chamber') return null;

    if (!_allCupPlaced(state.completedPuzzles)) {
      final missing = _missingCupItems(state.completedPuzzles);
      return EngineResponse(
        narrativeText: 'The cup is not complete.\n\n'
            'Still to be placed: ${missing.join(', ')}.',
      );
    }

    if (!state.runtime.ritualStirred) {
      return const EngineResponse(
        narrativeText: 'Stir the infusion before drinking.',
      );
    }

    if (state.runtime.ritualComplete) {
      return const EngineResponse(
        narrativeText:
            'You have already drunk the infusion. The passage below is open.',
      );
    }

    if (!state.runtime.depthThresholdMet) {
      return EngineResponse(
        narrativeText: depthGateTextForNucleo(),
      );
    }

    if (!state.runtime.quoteThresholdMet) {
      return EngineResponse(
        narrativeText: quoteExposureGateText(),
      );
    }

    return const EngineResponse(
      narrativeText: 'You drink.\n\n'
          'The taste is impossible — all four at once and separately: '
          'emptiness, light, proportion, and the warm quickening of breath.\n\n'
          'For a moment the cup is the Archive and the Archive is the cup.\n\n'
          'Then: the silence before a question that has waited a very long time.\n\n'
          'The passage below opens.',
      needsDemiurge: true,
      lucidityDelta: 15,
      anxietyDelta: -20,
      audioTrigger: 'calm',
      completePuzzle: 'ritual_complete',
      newNode: 'il_nucleo',
    );
  }

  static String depthGateTextForNucleo() {
    return 'The lower chamber waits, but does not open.\n\n'
        'The fifth sector is still thin under your feet.\n\n'
        'Walk through Memory a little longer. Let it acquire depth before descent.';
  }

  static String quoteExposureGateText() {
    return 'The cup clouds, then clears without changing.\n\n'
        'It has not yet absorbed enough voices from this run.\n\n'
        'Listen longer. Let more of the Archive answer before you descend.';
  }

  static ChamberAnswerState _chamberState(
    String key,
    Set<String> puzzles,
    Map<String, int> counters,
  ) {
    return ChamberAnswerState(
      answered: puzzles.contains(key),
      specific: (counters['${key}_specific_count'] ?? 0) > 0 ||
          (counters['${key}_costly_count'] ?? 0) > 0,
      costly: (counters['${key}_costly_count'] ?? 0) > 0,
    );
  }

  static EngineResponse _handleChamberAnswer({
    required ParsedCommand cmd,
    required MemoryStateView state,
    required String puzzleId,
    required String prompt,
    required _AnswerMode mode,
    bool spoken = false,
  }) {
    if (state.completedPuzzles.contains(puzzleId)) {
      return const EngineResponse(
        narrativeText: 'The price has been paid. You may leave.',
      );
    }

    if (cmd.args.isEmpty) {
      return EngineResponse(
        narrativeText:
            spoken ? 'Say what?\n\n$prompt' : 'Write what?\n\n$prompt',
      );
    }

    final text = cmd.args.join(' ').trim();
    final evaluation = evaluateAnswer(text, mode: mode);
    if (!evaluation.accepted) {
      return EngineResponse(
        narrativeText: evaluation.rejection ??
            'The room refuses the answer. It asks for specificity.',
      );
    }

    return EngineResponse(
      narrativeText: spoken
          ? 'You speak into the open line.\n\n'
              '"$text"\n\n'
              'The room acknowledges the sentence and loosens its hold.\n\n'
              'You may now leave.'
          : 'You write.\n\n'
              '"$text"\n\n'
              'The room acknowledges the line and loosens its hold.\n\n'
              'You may now leave.',
      needsDemiurge: evaluation.costly,
      completePuzzle: puzzleId,
      playerMemoryKey: puzzleId,
      lucidityDelta: evaluation.costly ? 8 : 6,
      audioTrigger: 'calm',
      incrementCounter: evaluation.costly
          ? '${puzzleId}_costly_count'
          : evaluation.specific
              ? '${puzzleId}_specific_count'
              : null,
    );
  }

  static AnswerEvaluation evaluateAnswer(
    String input, {
    required _AnswerMode mode,
  }) {
    final text = input.toLowerCase().trim();
    if (text.isEmpty) {
      return const AnswerEvaluation(
        accepted: false,
        specific: false,
        costly: false,
        rejection: 'Silence is not yet an answer.',
      );
    }

    if (_genericPhrases.contains(text)) {
      return const AnswerEvaluation(
        accepted: false,
        specific: false,
        costly: false,
        rejection: 'The room rejects decorative language. Be specific.',
      );
    }

    final words =
        text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final hasSpecific = _specificTerms.any(text.contains) ||
        text.contains('my ') ||
        text.contains('i ');
    final hasCost = _costTerms.any(text.contains) ||
        text.contains('i failed') ||
        text.contains('i lied') ||
        text.contains('i left');

    if (mode == _AnswerMode.singleWord) {
      if (words.length > 3) {
        return const AnswerEvaluation(
          accepted: false,
          specific: false,
          costly: false,
          rejection: 'Childhood asks for one word, not a paragraph.',
        );
      }
      if (words.first.length < 3) {
        return const AnswerEvaluation(
          accepted: false,
          specific: false,
          costly: false,
          rejection: 'That word is too thin to hold memory.',
        );
      }
      return AnswerEvaluation(
        accepted: true,
        specific: hasSpecific || words.first.length >= 5,
        costly: hasCost,
      );
    }

    if (words.length < 5) {
      return const AnswerEvaluation(
        accepted: false,
        specific: false,
        costly: false,
        rejection: 'The room asks for more than a fragment.',
      );
    }

    if (!hasSpecific) {
      return const AnswerEvaluation(
        accepted: false,
        specific: false,
        costly: false,
        rejection: 'The room asks for concrete detail, not abstraction.',
      );
    }

    return AnswerEvaluation(
      accepted: true,
      specific: true,
      costly: hasCost,
    );
  }

  static bool _allCupPlaced(Set<String> puzzles) {
    return puzzles.contains('cup_ataraxia') &&
        puzzles.contains('cup_the_constant') &&
        puzzles.contains('cup_the_proportion') &&
        puzzles.contains('cup_the_catalyst');
  }

  static List<String> _missingCupItems(Set<String> puzzles) {
    final missing = <String>[];
    if (!puzzles.contains('cup_ataraxia')) missing.add('ataraxia');
    if (!puzzles.contains('cup_the_constant')) missing.add('the constant');
    if (!puzzles.contains('cup_the_proportion')) missing.add('the proportion');
    if (!puzzles.contains('cup_the_catalyst')) missing.add('the catalyst');
    return missing;
  }
}

enum _AnswerMode {
  singleWord,
  narrative,
}
