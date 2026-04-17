import '../../parser/parser_state.dart';
import '../game_node.dart';

enum AlembicDegree {
  cold,
  gentle,
  warm,
  hot,
  intense,
  fierce,
  total,
  unknown,
}

enum BainMarieStage {
  idle,
  seeded,
  maturing,
  complete,
}

enum GreatWorkPhase {
  saturn,
  jupiter,
  mars,
  sun,
  venus,
  mercury,
  moon,
  complete,
}

class LaboratoryRuntimeModel {
  final int offeringsAccepted;
  final int offeringsRejected;
  final Set<String> offeredConcepts;

  final bool symbolsDeciphered;
  final Set<String> substancesCollected;
  final bool substancesReady;

  final bool furnaceStarted;
  final int furnaceWaits;
  final bool furnaceCalcinated;

  final AlembicDegree alembicDegree;
  final bool alembicSet;

  final BainMarieStage bainMarieStage;
  final int bainMarieExternalVisits;

  final int greatWorkStep;
  final GreatWorkPhase greatWorkPhase;
  final bool greatWorkComplete;

  final bool processReady;
  final bool simulacrumAcquired;

  final bool revisited;
  final bool crossSectorHintUnlocked;

  const LaboratoryRuntimeModel({
    required this.offeringsAccepted,
    required this.offeringsRejected,
    required this.offeredConcepts,
    required this.symbolsDeciphered,
    required this.substancesCollected,
    required this.substancesReady,
    required this.furnaceStarted,
    required this.furnaceWaits,
    required this.furnaceCalcinated,
    required this.alembicDegree,
    required this.alembicSet,
    required this.bainMarieStage,
    required this.bainMarieExternalVisits,
    required this.greatWorkStep,
    required this.greatWorkPhase,
    required this.greatWorkComplete,
    required this.processReady,
    required this.simulacrumAcquired,
    required this.revisited,
    required this.crossSectorHintUnlocked,
  });
}

class LaboratoryNavigationProgress {
  final Set<String> puzzles;
  final Map<String, int> counters;

  const LaboratoryNavigationProgress({
    required this.puzzles,
    required this.counters,
  });
}

class LaboratoryStateView {
  final String nodeId;
  final Set<String> completedPuzzles;
  final Map<String, int> puzzleCounters;
  final List<String> inventory;
  final int psychoWeight;
  final LaboratoryRuntimeModel runtime;

  const LaboratoryStateView({
    required this.nodeId,
    required this.completedPuzzles,
    required this.puzzleCounters,
    required this.inventory,
    required this.psychoWeight,
    required this.runtime,
  });
}

class LaboratoryModule {
  static const String surfacePuzzle = 'lab_complete';
  static const String surfaceMarkerPuzzle = 'lab_surface_complete';
  static const String deepMarkerPuzzle = 'lab_deep_complete';

  static const List<String> _planetOrder = [
    'saturn',
    'jupiter',
    'mars',
    'sun',
    'venus',
    'mercury',
    'moon',
  ];

  static const Set<String> _genericOfferConcepts = {
    'truth',
    'love',
    'pain',
    'memory',
    'time',
    'life',
    'death',
    'hope',
    'fear',
    'change',
    'light',
    'dark',
  };

  static const Set<String> _validSubstances = {
    'mercury',
    'sulphur',
    'salt',
  };

  static const Map<String, Map<String, String>> exitGates = {
    'lab_vestibule': {'south': 'lab_offers_complete'},
    'lab_substances': {
      'west': 'lab_substances_ready',
      'south': 'lab_substances_ready',
      'east': 'lab_substances_ready',
    },
    'lab_furnace': {'south': 'furnace_calcinated'},
    'lab_alembic': {'south': 'alembic_temperature_set'},
    'lab_bain_marie': {'south': 'bain_marie_complete'},
    'lab_great_work': {'south': 'lab_process_ready'},
  };

  static const Map<String, String> gateHints = {
    'lab_offers_complete': 'The Hall of Substances remains closed.\n\n'
        'The statues receive only deliberate offerings: distinct concepts, each with contour and consequence.',
    'lab_substances_ready': 'The branches remain sealed.\n\n'
        'The triangle must be read, then all three principles gathered: mercury, sulphur, salt.',
    'furnace_calcinated': 'The furnace branch is not finished.\n\n'
        'Calcination must begin, then endure five turnings before ash becomes passage.',
    'alembic_temperature_set': 'The alembic branch rejects this state.\n\n'
        'The vessel opens only to the gentlest degree of fire.',
    'bain_marie_complete': 'The bain-marie has not matured.\n\n'
        'Begin the bath, then leave. Return only after time has done work without you.',
    'lab_process_ready':
        'The sealed chamber does not yet acknowledge convergence.\n\n'
            'The three channels must be complete, and the seven circles of the Work must be placed in order.',
  };

  static const Map<String, NodeDef> roomDefinitions = {
    'lab_vestibule': NodeDef(
      title: 'The Alchemical Laboratory — Vestibule of Principles',
      description:
          'The violet door opens onto sulphur and something sweeter.\n\n'
          'A vestibule of grey stone. Three niches, each containing '
          'a statue in posture of reception — hands open, waiting. '
          'Each statue has a different bearing: resigned, expectant, indifferent.\n\n'
          'To the south: the Hall of Substances.',
      exits: {
        'south': 'lab_substances',
        'east': 'la_soglia',
        'back': 'la_soglia'
      },
      examines: {
        'statues':
            'Three figures with open hands. They accept without judgement.',
        'niches': 'One resigned. One expectant. One indifferent.',
        'first statue': 'Resigned. Hands open but expecting nothing.',
        'second statue': 'Expectant. Face turned slightly upward.',
        'third statue': 'Indifferent. Hands open because it is the position.',
        'sulphur': 'The base smell of transformation. Beneath it: something '
            'sweeter, harder to place.',
      },
    ),
    'lab_substances': NodeDef(
      title: 'Hall of Substances',
      description: 'A wide hall, its walls covered in alchemical symbols.\n\n'
          'Hundreds of them — spirals, triangles, crosses. Unlabelled. '
          'Their meaning must be decoded from their relationships.\n\n'
          'Three doorways: west to the furnace, south to the alembic, '
          'east to the bain-marie.',
      exits: {
        'north': 'lab_vestibule',
        'west': 'lab_furnace',
        'south': 'lab_alembic',
        'east': 'lab_bain_marie',
      },
      examines: {
        'symbols': 'A dense field. Some familiar: lead, gold. '
            'Three near the centre form a triangle.',
        'triangle': 'Three symbols: Mercury, Sulphur, Salt — the Tria Prima. '
            'The three principles of alchemical transformation.',
        'doorways':
            'Three branches. Each requires a different substance, a different patience.',
      },
    ),
    'lab_furnace': NodeDef(
      title: 'Furnace',
      description: 'An iron furnace, cold.\n\n'
          'The grate is empty. A tray beside it holds grey-white material. '
          'On the wall: "Calcinate. Reduce to essential ash. '
          'Five turnings of the wheel are required."',
      exits: {
        'east': 'lab_substances',
        'south': 'lab_great_work',
        'back': 'lab_substances'
      },
      examines: {
        'furnace': 'Cold iron. The grate is empty. Ready.',
        'tray': 'Grey-white material. Dense.',
        'instruction': '"Calcinate. Reduce to essential ash.\n'
            'Five turnings of the wheel.\n'
            'Patience is the reagent that cannot be purchased."',
      },
    ),
    'lab_alembic': NodeDef(
      title: 'Alembic',
      description:
          'A glass vessel — wide at the base, drawing to a narrow point.\n\n'
          'A liquid of indeterminate colour rests in the lower bulb. '
          'The temperature control accepts a degree '
          'on the alchemical scale: Cold, Gentle, Warm, Hot, Intense, Fierce, Total.\n\n'
          'A crystalline residue coats the inner walls like dried frost.',
      exits: {
        'north': 'lab_substances',
        'south': 'lab_great_work',
        'back': 'lab_substances'
      },
      examines: {
        'vessel':
            'Glass, clear. The liquid shifts colour — not due to chemistry.',
        'temperature':
            'The control accepts: Cold, Gentle, Warm, Hot, Intense, Fierce, Total.',
        'liquid': 'Below boiling. Waiting for the correct temperature.',
        'residue': 'Crystalline. Mineral. Ancient.',
        'scale':
            '"Each degree named for its effect on the substance, not the vessel."',
      },
    ),
    'lab_bain_marie': NodeDef(
      title: 'Bain-Marie',
      description: 'A water bath — the gentlest form of heat.\n\n'
          'The outer vessel holds cold water. The inner vessel holds '
          'a preparation that cannot be rushed. A placard:\n'
          '"Leave. Return when the water remembers what it has been asked to do.\n'
          'Some transformations begin only in the absence of the one who wants them."\n\n'
          'The preparation has not yet begun.',
      exits: {
        'west': 'lab_substances',
        'south': 'lab_great_work',
        'back': 'lab_substances'
      },
      examines: {
        'bath': 'Outer vessel: cold water. Inner: a thick opaque preparation.',
        'preparation': 'It has not begun its transformation.',
        'placard': '"Leave. Return when the water remembers.\n'
            'Some things begin only in absence."',
      },
    ),
    'lab_great_work': NodeDef(
      title: 'Table of the Great Work',
      description: 'A stone table at the convergence of three channels.\n\n'
          'On its surface: a diagram of seven concentric circles, each labelled '
          'with a planetary name. Each circle has a recess for a prepared substance.\n\n'
          'The order is inscribed at the rim:\n'
          'Saturn — Jupiter — Mars — Sun — Venus — Mercury — Moon.\n\n'
          'At the south end: the sealed chamber.',
      exits: {
        'north': 'lab_furnace',
        'west': 'lab_alembic',
        'east': 'lab_bain_marie',
        'south': 'lab_sealed',
      },
      examines: {
        'circles': 'Seven circles, Saturn outermost, Moon innermost. '
            'The alchemical descent: lead to silver, darkness to light.',
        'recesses':
            'Each circle has a recess waiting for a prepared substance.',
        'order': 'Saturn → Jupiter → Mars → Sun → Venus → Mercury → Moon. '
            'The Opus Magnum. The order must be exact.',
        'sealed': 'The sealed chamber is south. '
            'It opens when all seven circles are complete '
            'and all three preparation paths have been followed.',
      },
    ),
    'lab_sealed': NodeDef(
      title: 'Sealed Chamber',
      description: 'A small chamber, sealed until now.\n\n'
          'At its centre: an alembic of extraordinary delicacy — glass so thin '
          'it is held together by the substance within. '
          'The substance glows faintly, pulsing at irregular intervals.\n\n'
          'A card at the base: "The catalyst is not chemical. '
          'It cannot be purchased or synthesised. '
          'You have carried it since before you arrived. Breathe."',
      exits: {'north': 'lab_great_work', 'back': 'lab_great_work'},
      examines: {
        'alembic':
            'Glass so thin the substance seems to float without a container.',
        'substance': 'Luminescent. Pulsing — the way a heartbeat is regular.',
        'card': '"The catalyst is not chemical.\n'
            'It cannot be purchased or synthesised.\n'
            'You have carried it since before you arrived.\n'
            'Breathe."',
      },
    ),
  };

  static bool isLaboratoryNode(String nodeId) => nodeId.startsWith('lab_');

  static bool isSurfaceComplete(Set<String> puzzles) =>
      puzzles.contains(surfacePuzzle);

  static bool isDeepComplete({
    required Set<String> puzzles,
    required Map<String, int> counters,
  }) {
    final depth = counters['depth_laboratory'] ?? 0;
    return isSurfaceComplete(puzzles) &&
        puzzles.contains('lab_revisited') &&
        puzzles.contains('lab_cross_sector_hint') &&
        puzzles.contains('lab_process_ready') &&
        depth >= 7;
  }

  static Set<String> completionMarkers({
    required Set<String> puzzles,
    required Map<String, int> counters,
  }) {
    final adds = <String>{};

    if (_hasAllSubstances(puzzles)) {
      adds.add('lab_substances_ready');
    }

    if (_isProcessReady(puzzles)) {
      adds.add('lab_process_ready');
    }

    final step = counters['great_work_step'] ?? 0;
    if (step > 0) adds.add('lab_great_work_started');
    if (step >= 7) adds.add('lab_great_work_complete');

    if (isSurfaceComplete(puzzles)) {
      adds.add(surfaceMarkerPuzzle);
    }

    if (isDeepComplete(puzzles: puzzles.union(adds), counters: counters)) {
      adds.add(deepMarkerPuzzle);
      adds.add('sys_deep_laboratory');
    }

    return adds;
  }

  static LaboratoryRuntimeModel deriveRuntime({
    required Set<String> puzzles,
    required Map<String, int> counters,
  }) {
    final offeringsAccepted = counters['lab_offers_count'] ?? 0;
    final offeringsRejected = counters['lab_offers_rejected'] ?? 0;
    final offeredConcepts = puzzles
        .where((p) => p.startsWith('lab_offer_concept_'))
        .map((p) =>
            p.replaceFirst('lab_offer_concept_', '').replaceAll('_', ' '))
        .toSet();

    final substancesCollected = <String>{
      if (puzzles.contains('lab_mercury_collected')) 'mercury',
      if (puzzles.contains('lab_sulphur_collected')) 'sulphur',
      if (puzzles.contains('lab_salt_collected')) 'salt',
    };

    final greatStep = counters['great_work_step'] ?? 0;
    final phase = greatStep >= 7
        ? GreatWorkPhase.complete
        : GreatWorkPhase.values[greatStep];

    final bathStage = puzzles.contains('bain_marie_complete')
        ? BainMarieStage.complete
        : puzzles.contains('bain_marie_left')
            ? BainMarieStage.maturing
            : puzzles.contains('bain_marie_seeded')
                ? BainMarieStage.seeded
                : BainMarieStage.idle;

    return LaboratoryRuntimeModel(
      offeringsAccepted: offeringsAccepted,
      offeringsRejected: offeringsRejected,
      offeredConcepts: offeredConcepts,
      symbolsDeciphered: puzzles.contains('lab_symbols_deciphered'),
      substancesCollected: substancesCollected,
      substancesReady: _hasAllSubstances(puzzles),
      furnaceStarted: puzzles.contains('furnace_calcinating'),
      furnaceWaits: counters['furnace_waits'] ?? 0,
      furnaceCalcinated: puzzles.contains('furnace_calcinated'),
      alembicDegree: _degreeFromState(puzzles, counters),
      alembicSet: puzzles.contains('alembic_temperature_set'),
      bainMarieStage: bathStage,
      bainMarieExternalVisits: counters['bain_marie_external'] ?? 0,
      greatWorkStep: greatStep,
      greatWorkPhase: phase,
      greatWorkComplete: puzzles.contains('lab_great_work_complete'),
      processReady: _isProcessReady(puzzles),
      simulacrumAcquired: puzzles.contains('lab_complete'),
      revisited: puzzles.contains('lab_revisited'),
      crossSectorHintUnlocked: puzzles.contains('lab_cross_sector_hint'),
    );
  }

  static LaboratoryNavigationProgress applyNavigationTransition({
    required String fromNode,
    required String destNode,
    required Set<String> puzzles,
    required Map<String, int> counters,
  }) {
    final nextPuzzles = Set<String>.from(puzzles);
    final nextCounters = Map<String, int>.from(counters);

    if (fromNode == 'lab_bain_marie') {
      nextPuzzles.add('bain_marie_seeded');
      nextPuzzles.add('bain_marie_left');
    }

    final isExternalDestination = !destNode.startsWith('lab_');
    if (isExternalDestination &&
        nextPuzzles.contains('bain_marie_left') &&
        !nextPuzzles.contains('bain_marie_complete')) {
      final visits = (nextCounters['bain_marie_external'] ?? 0) + 1;
      nextCounters['bain_marie_external'] = visits;
      if (visits >= 3) {
        nextPuzzles.add('bain_marie_complete');
      }
    }

    return LaboratoryNavigationProgress(
      puzzles: nextPuzzles,
      counters: nextCounters,
    );
  }

  static EngineResponse? onEnterNode({
    required String fromNode,
    required String destNode,
    required LaboratoryStateView state,
  }) {
    if (destNode == 'lab_vestibule' &&
        state.runtime.simulacrumAcquired &&
        !state.runtime.revisited) {
      return const EngineResponse(
        narrativeText: 'Vestibule of Principles (returned)\n\n'
            'The statues no longer look passive. Their silence now reads as discernment.\n\n'
            'From the central pedestal at the Threshold, a measured pulse answers the violet wing.',
        newNode: 'lab_vestibule',
        needsDemiurge: true,
        completePuzzle: 'lab_revisited',
      );
    }

    if (destNode == 'lab_bain_marie' &&
        state.runtime.bainMarieStage == BainMarieStage.complete) {
      return const EngineResponse(
        narrativeText: 'Bain-Marie\n\n'
            'The outer water has changed. It is warm — not because of heat, but because of duration.\n\n'
            'The inner preparation has matured without your insistence.\n\n'
            'The southern branch now yields.',
        newNode: 'lab_bain_marie',
        needsDemiurge: true,
      );
    }

    return null;
  }

  static EngineResponse? handleExamine({
    required String nodeId,
    required String target,
    required LaboratoryStateView state,
  }) {
    if (nodeId == 'la_soglia' &&
        target.contains('pedestal') &&
        state.runtime.simulacrumAcquired &&
        !state.runtime.crossSectorHintUnlocked) {
      return const EngineResponse(
        narrativeText: 'The Catalyst warms in your palm.\n\n'
            'The amber wing answers with a dry vegetal breath, as if quiet pleasure were waiting for a reagent of patience.',
        completePuzzle: 'lab_cross_sector_hint',
        needsDemiurge: true,
      );
    }
    return null;
  }

  static EngineResponse? handleOffer({
    required ParsedCommand cmd,
    required LaboratoryStateView state,
  }) {
    if (state.nodeId != 'lab_vestibule') return null;

    if (state.completedPuzzles.contains('lab_offers_complete')) {
      return const EngineResponse(
        narrativeText:
            'The three statues have already received. The Hall of Substances remains open.',
      );
    }

    if (cmd.args.isEmpty) {
      return const EngineResponse(
        narrativeText: 'Offer what?\n\n'
            'The statues receive concepts, not objects. Speak a distinct principle with consequence.',
      );
    }

    final concept = _normaliseConcept(cmd.args.join(' '));
    final conceptWords = concept.split(' ').where((w) => w.isNotEmpty).toList();
    final conceptKey = _offerConceptPuzzleKey(concept);

    if (conceptWords.length < 2 || _genericOfferConcepts.contains(concept)) {
      return const EngineResponse(
        narrativeText: 'The statues remain open-handed.\n\n'
            'They reject generic abstractions. Offer something more specific and lived.',
        incrementCounter: 'lab_offers_rejected',
      );
    }

    if (state.completedPuzzles.contains(conceptKey)) {
      return const EngineResponse(
        narrativeText: 'The statues do not accept repetition.\n\n'
            'That concept has already been offered. Bring a different one.',
        incrementCounter: 'lab_offers_rejected',
      );
    }

    final nextCount = state.runtime.offeringsAccepted + 1;
    if (nextCount < 3) {
      return EngineResponse(
        narrativeText: 'You offer "$concept."\n\n'
            'One statue closes its hands briefly, then opens them again.\n\n'
            '$nextCount of three offerings accepted.',
        incrementCounter: 'lab_offers_count',
        completePuzzle: conceptKey,
      );
    }

    return EngineResponse(
      narrativeText: 'You offer "$concept."\n\n'
          'The third statue closes its hands. The vestibule recognises completion.\n\n'
          'The Hall of Substances opens to the south.',
      needsDemiurge: true,
      incrementCounter: 'lab_offers_count',
      completePuzzle: 'lab_offers_complete',
      lucidityDelta: 5,
    );
  }

  static EngineResponse? handleDecipher({
    required LaboratoryStateView state,
  }) {
    if (state.nodeId != 'lab_substances') return null;

    if (state.runtime.symbolsDeciphered) {
      return const EngineResponse(
        narrativeText:
            'The symbols are already decoded: mercury, sulphur, salt.\n\nCollect each to proceed.',
      );
    }

    return const EngineResponse(
      narrativeText: 'You study the central triangle.\n\n'
          'The three vertices decode:\n'
          'Mercury — the spirit, quicksilver, volatility.\n'
          'Sulphur — the soul, combustion, will.\n'
          'Salt — the body, fixity, matter.\n\n'
          'The Tria Prima. All transformation passes through these three.\n\n'
          'Now: collect mercury — collect sulphur — collect salt.',
      lucidityDelta: 5,
      completePuzzle: 'lab_symbols_deciphered',
    );
  }

  static EngineResponse? handleCollect({
    required ParsedCommand cmd,
    required LaboratoryStateView state,
  }) {
    if (state.nodeId != 'lab_substances') return null;

    final rawSubstance = cmd.args.join(' ').trim().toLowerCase();
    if (rawSubstance.isEmpty) {
      return const EngineResponse(
        narrativeText:
            'Collect what? The room distinguishes mercury, sulphur, and salt.',
      );
    }

    if (!state.runtime.symbolsDeciphered) {
      return const EngineResponse(
        narrativeText:
            'You do not yet know what to collect.\n\nDecipher the symbols first.',
      );
    }

    final substance = (rawSubstance == 'sulfur' || rawSubstance == 'sulphur')
        ? 'sulphur'
        : rawSubstance;
    if (!_validSubstances.contains(substance)) {
      return EngineResponse(
        narrativeText: '"$rawSubstance" is not one of the three substances.\n\n'
            'Collect: mercury, sulphur, or salt.',
      );
    }

    final puzzleId = 'lab_${substance}_collected';
    if (state.completedPuzzles.contains(puzzleId)) {
      return EngineResponse(
        narrativeText: 'You have already collected the $substance.',
      );
    }

    final nextCollected = Set<String>.from(state.runtime.substancesCollected)
      ..add(substance);
    final lastNeeded = nextCollected.length == 3;

    return EngineResponse(
      narrativeText: lastNeeded
          ? 'You collect the $substance.\n\n'
              'All three substances of the Tria Prima are gathered.\n\n'
              'The three branches open: furnace, alembic, bain-marie.'
          : 'You collect the $substance. It settles with a faint warmth.',
      needsDemiurge: lastNeeded,
      completePuzzle: puzzleId,
      lucidityDelta: lastNeeded ? 8 : null,
    );
  }

  static EngineResponse? handleUnknown({
    required ParsedCommand cmd,
    required LaboratoryStateView state,
  }) {
    final raw = cmd.rawInput.toLowerCase().trim();
    if (state.nodeId == 'lab_furnace' && raw == 'calcinate') {
      if (!state.runtime.substancesReady) {
        return const EngineResponse(
          narrativeText: 'The furnace does not answer yet.\n\n'
              'Gather and prepare the three principles in the Hall of Substances first.',
        );
      }
      if (state.runtime.furnaceCalcinated) {
        return const EngineResponse(
          narrativeText:
              'The calcination is complete. The ash awaits integration.',
        );
      }
      if (state.runtime.furnaceStarted) {
        return const EngineResponse(
          narrativeText:
              'The calcination is already underway. Endure the remaining turnings.',
        );
      }
      return const EngineResponse(
        narrativeText: 'You light the furnace.\n\n'
            'The material begins to reduce. Smoke rises: loss becoming method.\n\n'
            'Five turnings are required. Wait.',
        completePuzzle: 'furnace_calcinating',
      );
    }

    return null;
  }

  static EngineResponse? handleWait({
    required LaboratoryStateView state,
  }) {
    if (state.nodeId != 'lab_furnace') return null;

    if (!state.runtime.furnaceStarted) {
      return const EngineResponse(
        narrativeText: 'The furnace is cold. Nothing is calcinating yet.\n\n'
            'Begin with calcination first.',
      );
    }

    if (state.runtime.furnaceCalcinated) {
      return const EngineResponse(
        narrativeText:
            'The calcination is already complete. The ash is ready for convergence.',
      );
    }

    final turns = state.runtime.furnaceWaits + 1;
    if (turns < 5) {
      return EngineResponse(
        narrativeText:
            'The furnace glows. Reduction continues. $turns of five turnings.',
        incrementCounter: 'furnace_waits',
      );
    }

    return const EngineResponse(
      narrativeText: 'The fifth turning.\n\n'
          'The material reduces to pale ash: stripped, but not empty.\n\n'
          'The furnace path south is clear.',
      needsDemiurge: true,
      incrementCounter: 'furnace_waits',
      completePuzzle: 'furnace_calcinated',
      lucidityDelta: 5,
    );
  }

  static EngineResponse? handleSetParam({
    required ParsedCommand cmd,
    required LaboratoryStateView state,
  }) {
    if (state.nodeId != 'lab_alembic') return null;

    if (state.runtime.alembicSet) {
      return const EngineResponse(
        narrativeText:
            'The temperature is already set to the degree that opens the vessel.',
      );
    }

    if (cmd.args.isEmpty) {
      return const EngineResponse(
        narrativeText: 'Set what?\n\n'
            'The control accepts one degree of the alchemical scale.',
      );
    }

    final degree = _parseDegree(cmd.args.join(' '));
    switch (degree) {
      case AlembicDegree.gentle:
        return const EngineResponse(
          narrativeText: 'You set the alembic to Gentle.\n\n'
              'The liquid does not boil; it consents.\n\n'
              'The southern branch opens.',
          needsDemiurge: true,
          lucidityDelta: 8,
          completePuzzle: 'alembic_temperature_set',
          incrementCounter: 'lab_alembic_degree_gentle',
        );
      case AlembicDegree.cold:
      case AlembicDegree.warm:
        return EngineResponse(
          narrativeText: degree == AlembicDegree.cold
              ? 'Too cold. The substance contracts and refuses exchange.'
              : 'Too warm. The surface stirs, but the core remains closed.',
          incrementCounter: 'lab_alembic_misfires',
          completePuzzle: 'lab_alembic_last_${degree.name}',
        );
      case AlembicDegree.hot:
      case AlembicDegree.intense:
      case AlembicDegree.fierce:
      case AlembicDegree.total:
        return const EngineResponse(
          narrativeText: 'The vessel recoils from violence.\n\n'
              'In this operation, force is failure. The degree must be Gentle.',
          incrementCounter: 'lab_alembic_misfires',
          completePuzzle: 'lab_alembic_overheated',
        );
      case AlembicDegree.unknown:
        return const EngineResponse(
          narrativeText:
              'The scale reads: Cold, Gentle, Warm, Hot, Intense, Fierce, Total.\n\n'
              'Name one degree.',
        );
    }
  }

  static EngineResponse? handleDrop({
    required ParsedCommand cmd,
    required LaboratoryStateView state,
  }) {
    if (state.nodeId != 'lab_great_work') return null;

    if (state.runtime.greatWorkComplete) {
      return const EngineResponse(
        narrativeText: 'The Great Work is already complete.',
      );
    }

    if (cmd.args.isEmpty) {
      return const EngineResponse(
        narrativeText: 'Place what?\n\n'
            'Name the planetary circle currently due in the sequence.',
      );
    }

    final step = state.runtime.greatWorkStep;
    if (step >= _planetOrder.length) {
      return const EngineResponse(
        narrativeText: 'The Great Work is already complete.',
      );
    }

    final expectedPlanet = _planetOrder[step];
    final raw = cmd.rawInput.toLowerCase();
    if (!raw.contains(expectedPlanet)) {
      return EngineResponse(
        narrativeText: 'That is not the circle currently due.\n\n'
            'The next placement belongs to $expectedPlanet.\n\n'
            'Order: ${_planetOrder.join(' → ')}',
      );
    }

    final isLast = step == _planetOrder.length - 1;
    return EngineResponse(
      narrativeText: isLast
          ? 'The seventh placement settles.\n\n'
              'All circles ignite in sequence. The Work is complete.\n\n'
              'The convergence is ready.'
          : 'You place the preparation in the $expectedPlanet circle.\n\n'
              '${_planetOrder.length - step - 1} placements remain.',
      needsDemiurge: isLast,
      incrementCounter: 'great_work_step',
      completePuzzle: isLast ? 'lab_great_work_complete' : null,
      lucidityDelta: isLast ? 10 : null,
    );
  }

  static EngineResponse? handleBlow({
    required LaboratoryStateView state,
  }) {
    if (state.nodeId != 'lab_sealed') return null;

    if (state.runtime.simulacrumAcquired) {
      return const EngineResponse(
        narrativeText: 'The Catalyst has already been released.',
      );
    }

    if (!state.runtime.processReady) {
      return const EngineResponse(
        narrativeText: 'The sealed vessel does not yet respond.\n\n'
            'The process is unfinished: the three channels and seven-circle Work must fully converge first.',
      );
    }

    return const EngineResponse(
      narrativeText: 'You breathe into the alembic.\n\n'
          'Warm air, water, trace salts of a lived body touch the prepared substance.\n\n'
          'It does not react. It recognises.\n\n'
          'In your hands now: a small vessel of lucid pulse-light. The Catalyst.',
      grantItem: 'the catalyst',
      completePuzzle: 'lab_complete',
      lucidityDelta: 12,
      anxietyDelta: -15,
      needsDemiurge: true,
    );
  }

  static String _normaliseConcept(String raw) =>
      raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '').trim();

  static String _offerConceptPuzzleKey(String concept) {
    final base = concept
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    return 'lab_offer_concept_$base';
  }

  static bool _hasAllSubstances(Set<String> puzzles) {
    return puzzles.contains('lab_mercury_collected') &&
        puzzles.contains('lab_sulphur_collected') &&
        puzzles.contains('lab_salt_collected');
  }

  static bool _isProcessReady(Set<String> puzzles) {
    return puzzles.contains('furnace_calcinated') &&
        puzzles.contains('alembic_temperature_set') &&
        puzzles.contains('bain_marie_complete') &&
        puzzles.contains('lab_great_work_complete');
  }

  static AlembicDegree _parseDegree(String raw) {
    final text = raw.toLowerCase();
    if (text.contains('gentle') ||
        text.contains('balneum') ||
        text.contains('1')) {
      return AlembicDegree.gentle;
    }
    if (text.contains('cold')) return AlembicDegree.cold;
    if (text.contains('warm')) return AlembicDegree.warm;
    if (text.contains('hot')) return AlembicDegree.hot;
    if (text.contains('intense')) return AlembicDegree.intense;
    if (text.contains('fierce')) return AlembicDegree.fierce;
    if (text.contains('total')) return AlembicDegree.total;
    return AlembicDegree.unknown;
  }

  static AlembicDegree _degreeFromState(
    Set<String> puzzles,
    Map<String, int> counters,
  ) {
    if ((counters['lab_alembic_degree_gentle'] ?? 0) > 0 ||
        puzzles.contains('alembic_temperature_set')) {
      return AlembicDegree.gentle;
    }
    if (puzzles.contains('lab_alembic_last_cold')) return AlembicDegree.cold;
    if (puzzles.contains('lab_alembic_last_warm')) return AlembicDegree.warm;
    if (puzzles.contains('lab_alembic_overheated')) return AlembicDegree.hot;
    return AlembicDegree.unknown;
  }
}
