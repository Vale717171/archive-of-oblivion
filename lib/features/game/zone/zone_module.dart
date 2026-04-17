import '../memory/memory_module.dart';
import '../../parser/parser_state.dart';

class ZoneTurnResolution {
  final EngineResponse response;
  final Set<String> puzzleAdds;
  final Map<String, int> counterUpdates;

  const ZoneTurnResolution({
    required this.response,
    this.puzzleAdds = const {},
    this.counterUpdates = const {},
  });
}

class ZonePrompt {
  final String verse;
  final String environment;
  final String question;
  final String source;
  final Set<String> tags;

  const ZonePrompt({
    required this.verse,
    required this.environment,
    required this.question,
    required this.source,
    required this.tags,
  });
}

class ZoneEvaluation {
  final int qualityTier;
  final bool accepted;
  final bool specific;
  final bool costly;
  final bool contradictionAligned;
  final Set<String> tags;

  const ZoneEvaluation({
    required this.qualityTier,
    required this.accepted,
    required this.specific,
    required this.costly,
    required this.contradictionAligned,
    required this.tags,
  });
}

class ZoneModule {
  static const String zoneNodeId = 'la_zona';

  static const Set<String> _simulacra = {
    'ataraxia',
    'the constant',
    'the proportion',
    'the catalyst',
  };

  static const List<String> _tarkovskyVerses = [
    '"I was ill, or perhaps merely alive,\nand you came from a time that did not yet exist."',
    '"What has been will be again.\nI shall arrange it differently next time."',
    '"Life is not so short,\nand not so long — it is exactly as long as it needs to be."',
    '"The soul has no shoulders\nand cannot carry what the body carried."',
    '"From beyond the mirror, a world\nthat has always been waiting."',
    '"All that glitters is not gold,\nbut all that disappears was real."',
    '"I dreamed the world was a staircase\nand I was neither ascending nor descending."',
    '"Nothing can be taken away\nthat was not, once, truly given."',
  ];

  static const List<String> _zoneEnvironments = [
    'A corridor that is also a room. The walls meet at angles that should not exist.',
    'The floor continues past where the floor should end. Below: the same floor, continuing.',
    'Three shadows — yours, and two others whose sources cannot be located.',
    'A staircase descending to the level you are standing on.',
    'The ceiling is very close. Then it is very far. The distance does not change.',
    'A window onto a room exactly like this one, except in that room there is no window.',
    'Sound arrives before the movement that caused it.',
    'The walls are made of the same light as what falls through windows you cannot find.',
  ];

  static const Set<String> _genericPhrases = {
    'i dont know',
    'i do not know',
    'nothing',
    'everything',
    'it depends',
    'maybe',
    'whatever',
    'no answer',
    'no idea',
    'just because',
  };

  static const Set<String> _specificTerms = {
    'name',
    'street',
    'room',
    'winter',
    'summer',
    'clock',
    'door',
    'voice',
    'train',
    'ticket',
    'balbec',
    'seventeen',
    'five',
    'pm',
    'am',
    'yesterday',
    'today',
    'monday',
  };

  static const Set<String> _costTerms = {
    'afraid',
    'ashamed',
    'regret',
    'forgive',
    'apologize',
    'apologise',
    'hurt',
    'wound',
    'betray',
    'failed',
    'failure',
    'left',
    'lie',
    'lied',
    'coward',
    'cowardice',
    'blame',
  };

  static const Set<String> _deflectTerms = {
    'nothing',
    'no one',
    'nobody',
    'fate',
    'destiny',
    'all of them',
    'everyone',
    'just happened',
  };

  static bool transitEligibleForZone(String fromNodeId, String destNodeId) {
    if (fromNodeId == destNodeId ||
        fromNodeId == zoneNodeId ||
        destNodeId == zoneNodeId) {
      return false;
    }

    const blockedPrefixes = [
      'finale_',
      'il_nucleo',
      'intro_',
      'quinto_',
      'memory_',
    ];

    for (final prefix in blockedPrefixes) {
      if (fromNodeId.startsWith(prefix) || destNodeId.startsWith(prefix)) {
        return false;
      }
    }
    return true;
  }

  static ZonePrompt previewPrompt({
    required int encounter,
    required Set<String> puzzles,
    required Map<String, int> counters,
    required List<String> inventory,
    required int psychoWeight,
  }) {
    final verse = _tarkovskyVerses[encounter % _tarkovskyVerses.length];
    final environment =
        _zoneEnvironments[(encounter * 3 + 1) % _zoneEnvironments.length];
    final memoryInput = MemoryModule.buildEpitaphInput(
      puzzles: puzzles,
      counters: counters,
      inventory: inventory,
      psychoWeight: psychoWeight,
    );

    final contradictions = counters['sys_contradictions'] ?? 0;
    final unresolvedProtections = _unresolvedProtections(
      contradictions: contradictions,
      inventory: inventory,
      memoryCostlyAnswers: memoryInput.costlyAnswers,
    );
    final deepCount = _deepSectorCount(puzzles);
    final habitation = counters['sys_notebook_habitation'] ?? 0;
    final dominant = _dominantWeightAxis(counters, psychoWeight);

    if (contradictions >= 3) {
      return ZonePrompt(
        verse: verse,
        environment: environment,
        source: 'contradiction',
        tags: const {'contradiction', 'ownership', 'proof'},
        question:
            'You declared release, yet traces remain. Which trace still proves you, and why are you preserving it?',
      );
    }

    if (unresolvedProtections >= 5) {
      return ZonePrompt(
        verse: verse,
        environment: environment,
        source: 'protection',
        tags: const {'protection', 'burden', 'fear'},
        question:
            'Which protection still guards you even now, and what honest cost does it exact each day?',
      );
    }

    if (memoryInput.specificAnswers < 2 || memoryInput.costlyAnswers < 1) {
      return ZonePrompt(
        verse: verse,
        environment: environment,
        source: 'memory_readiness',
        tags: const {'memory', 'age', 'confession'},
        question:
            'Name one age of your life you still narrate from a safe distance. What do you refuse to say in first person?',
      );
    }

    if (deepCount <= 1) {
      return ZonePrompt(
        verse: verse,
        environment: environment,
        source: 'depth',
        tags: const {'depth', 'return', 'cost'},
        question:
            'Which room did you leave at the surface because depth would have cost too much?',
      );
    }

    if (habitation < 5) {
      return ZonePrompt(
        verse: verse,
        environment: environment,
        source: 'notebook',
        tags: const {'notebook', 'voice', 'inhabitation'},
        question:
            'Your notebook still sounds like someone else in places. Which page is least inhabited, and what true line belongs there?',
      );
    }

    switch (dominant) {
      case 'material':
        return ZonePrompt(
          verse: verse,
          environment: environment,
          source: 'weight_material',
          tags: const {'material', 'body', 'holding'},
          question:
              'Your body leads this run. What are your hands still holding that your words already renounced?',
        );
      case 'symbolic':
        return ZonePrompt(
          verse: verse,
          environment: environment,
          source: 'weight_symbolic',
          tags: const {'symbolic', 'ritual', 'form'},
          question:
              'You trust forms. Which ritual have you mistaken for transformation?',
        );
      default:
        return ZonePrompt(
          verse: verse,
          environment: environment,
          source: 'weight_verbal',
          tags: const {'verbal', 'speech', 'evasion'},
          question:
              'You trust language. Which sentence of yours has become an elegant evasion?',
        );
    }
  }

  static ZoneTurnResolution resolveTurn({
    required ParsedCommand cmd,
    required String nodeId,
    required EngineResponse evaluationResponse,
    required Set<String> puzzles,
    required Map<String, int> counters,
    required List<String> inventory,
    required int psychoWeight,
    required double randomRoll,
  }) {
    if (nodeId == zoneNodeId &&
        (cmd.verb == CommandVerb.unknown ||
            cmd.verb == CommandVerb.say ||
            cmd.verb == CommandVerb.write)) {
      return resolveZoneResponse(
        rawInput: cmd.rawInput,
        puzzles: puzzles,
        counters: counters,
      );
    }

    final dest = evaluationResponse.newNode;
    if (dest == null) {
      return ZoneTurnResolution(response: evaluationResponse);
    }

    final navUpdates = _navigationCounterUpdates(
      fromNode: nodeId,
      destNode: dest,
      counters: counters,
    );

    if (!transitEligibleForZone(nodeId, dest)) {
      return ZoneTurnResolution(
        response: evaluationResponse,
        counterUpdates: navUpdates,
      );
    }

    final probability = activationProbability(
      fromNode: nodeId,
      destNode: dest,
      puzzles: puzzles,
      counters: counters,
      inventory: inventory,
      psychoWeight: psychoWeight,
    );

    if (probability <= 0 || randomRoll >= probability) {
      return ZoneTurnResolution(
        response: evaluationResponse,
        counterUpdates: navUpdates,
      );
    }

    final encountersBefore = counters['zone_encounters'] ?? 0;
    final encounter = encountersBefore + 1;
    final prompt = previewPrompt(
      encounter: encountersBefore,
      puzzles: puzzles,
      counters: counters,
      inventory: inventory,
      psychoWeight: psychoWeight,
    );

    final updates = Map<String, int>.from(navUpdates)
      ..['zone_encounters'] = encounter
      ..['consecutive_transits'] = 0
      ..['sys_zone_pressure'] =
          _nonNegative((counters['sys_zone_pressure'] ?? 0) - 1);

    final promptMarkers = <String>{
      'zone_prompt_${encounter}_source_${prompt.source}',
      for (final tag in prompt.tags) 'zone_prompt_${encounter}_tag_$tag',
    };

    final response = EngineResponse(
      narrativeText:
          '${prompt.verse}\n\n${prompt.environment}\n\n${prompt.question}',
      newNode: zoneNodeId,
      needsDemiurge: true,
      anxietyDelta: 5,
      incrementCounter: 'zone_source_${prompt.source}_seen',
    );

    return ZoneTurnResolution(
      response: response,
      counterUpdates: updates,
      puzzleAdds: promptMarkers,
    );
  }

  static ZoneTurnResolution resolveZoneResponse({
    required String rawInput,
    required Set<String> puzzles,
    required Map<String, int> counters,
  }) {
    final encounters = counters['zone_encounters'] ?? 0;
    final respondedKey = 'zone_responded_$encounters';

    if (puzzles.contains(respondedKey)) {
      return const ZoneTurnResolution(
        response: EngineResponse(
          narrativeText: 'The Zone has heard you. The Archive is back.',
          newNode: 'la_soglia',
        ),
      );
    }

    final promptTags = _tagsForEncounter(puzzles, encounters);
    final promptSource = _sourceForEncounter(puzzles, encounters);
    final evaluation = evaluateResponse(
      rawInput: rawInput,
      expectedTags: promptTags,
      contradictionSensitive: promptSource == 'contradiction',
    );

    final currentContradictions = counters['sys_contradictions'] ?? 0;
    final currentPressure = counters['sys_zone_pressure'] ?? 0;
    final currentHabitation = counters['sys_notebook_habitation'] ?? 0;

    final updatedContradictions = evaluation.qualityTier == 0
        ? currentContradictions + 1
        : (evaluation.qualityTier >= 2 && evaluation.contradictionAligned)
            ? _nonNegative(currentContradictions - 1)
            : currentContradictions;
    final updatedPressure = evaluation.qualityTier == 0
        ? currentPressure + 2
        : evaluation.qualityTier >= 2
            ? _nonNegative(currentPressure - 2)
            : _nonNegative(currentPressure - 1);

    final updates = <String, int>{
      'sys_contradictions': updatedContradictions,
      'sys_zone_pressure': updatedPressure,
      'zone_meta_quality_sum':
          (counters['zone_meta_quality_sum'] ?? 0) + evaluation.qualityTier,
      'zone_meta_responses': (counters['zone_meta_responses'] ?? 0) + 1,
      'zone_meta_specific_count': (counters['zone_meta_specific_count'] ?? 0) +
          (evaluation.specific ? 1 : 0),
      'zone_meta_costly_count': (counters['zone_meta_costly_count'] ?? 0) +
          (evaluation.costly ? 1 : 0),
      'zone_meta_quality_tier_${evaluation.qualityTier}':
          (counters['zone_meta_quality_tier_${evaluation.qualityTier}'] ?? 0) +
              1,
      'zone_meta_source_${promptSource}_count':
          (counters['zone_meta_source_${promptSource}_count'] ?? 0) + 1,
      'zone_meta_contradiction_aligned_count':
          (counters['zone_meta_contradiction_aligned_count'] ?? 0) +
              (evaluation.contradictionAligned ? 1 : 0),
      'zone_meta_contradiction_intensified_count':
          (counters['zone_meta_contradiction_intensified_count'] ?? 0) +
              (evaluation.qualityTier == 0 ? 1 : 0),
      'zone_meta_contradiction_resolved_count':
          (counters['zone_meta_contradiction_resolved_count'] ?? 0) +
              (evaluation.qualityTier >= 2 && evaluation.contradictionAligned
                  ? 1
                  : 0),
      'sys_notebook_habitation':
          currentHabitation + (evaluation.accepted ? 1 : 0),
    };

    for (final tag in evaluation.tags) {
      final key = 'zone_meta_tag_${tag}_count';
      updates[key] = (counters[key] ?? 0) + 1;
    }

    final metadataMarkers = <String>{
      'zone_meta_encounter_${encounters}_quality_${evaluation.qualityTier}',
      'zone_meta_encounter_${encounters}_source_$promptSource',
      if (evaluation.contradictionAligned)
        'zone_meta_encounter_${encounters}_aligned',
      for (final tag in evaluation.tags)
        'zone_meta_encounter_${encounters}_tag_$tag',
    };

    if (!evaluation.accepted) {
      return ZoneTurnResolution(
        response: const EngineResponse(
          narrativeText: 'The Zone does not accept the half-answer.\n\n'
              'It waits. Something in the geometry tightens.\n\n'
              'Try again — more fully.',
          anxietyDelta: 5,
          weightDelta: 1,
        ),
        counterUpdates: updates,
        puzzleAdds: metadataMarkers,
      );
    }

    return ZoneTurnResolution(
      response: EngineResponse(
        narrativeText: 'The Zone receives your answer without comment.\n\n'
            '${_crypticResponseFor(promptSource, evaluation)}',
        needsDemiurge: evaluation.qualityTier >= 2,
        newNode: 'la_soglia',
        completePuzzle: respondedKey,
        lucidityDelta: evaluation.qualityTier >= 2 ? -3 : -1,
        anxietyDelta: evaluation.qualityTier >= 2 ? -5 : -2,
        weightDelta: evaluation.qualityTier >= 2 ? -1 : 0,
        playerMemoryKey: 'zone_$encounters',
      ),
      counterUpdates: updates,
      puzzleAdds: metadataMarkers,
    );
  }

  static ZoneEvaluation evaluateResponse({
    required String rawInput,
    required Set<String> expectedTags,
    required bool contradictionSensitive,
  }) {
    final text = rawInput.toLowerCase().trim();
    final words =
        text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    if (words.length < 5) {
      return const ZoneEvaluation(
        qualityTier: 0,
        accepted: false,
        specific: false,
        costly: false,
        contradictionAligned: false,
        tags: {},
      );
    }

    if (_genericPhrases.contains(text) ||
        _genericPhrases.any((g) => text == g || text.contains('$g.'))) {
      return const ZoneEvaluation(
        qualityTier: 0,
        accepted: false,
        specific: false,
        costly: false,
        contradictionAligned: false,
        tags: {},
      );
    }

    final specific = _specificTerms.any(text.contains) ||
        words.any((w) => RegExp(r'\d').hasMatch(w)) ||
        (words.length >= 8 && text.contains('i '));
    final costly = _costTerms.any(text.contains);

    final tags = <String>{
      for (final tag in expectedTags)
        if (_tagMatchesText(tag, text)) tag,
    };

    final contradictionAligned = contradictionSensitive
        ? _isContradictionAligned(text)
        : !_deflectTerms.any(text.contains);

    final hasSubstance = specific || costly || words.length >= 10;
    if (!hasSubstance) {
      return ZoneEvaluation(
        qualityTier: 0,
        accepted: false,
        specific: specific,
        costly: costly,
        contradictionAligned: contradictionAligned,
        tags: tags,
      );
    }

    final substantial =
        specific && (costly || tags.isNotEmpty) && contradictionAligned;

    return ZoneEvaluation(
      qualityTier: substantial ? 2 : 1,
      accepted: true,
      specific: specific,
      costly: costly,
      contradictionAligned: contradictionAligned,
      tags: tags,
    );
  }

  static double activationProbability({
    required String fromNode,
    required String destNode,
    required Set<String> puzzles,
    required Map<String, int> counters,
    required List<String> inventory,
    required int psychoWeight,
  }) {
    final encounters = counters['zone_encounters'] ?? 0;
    final consecutive = counters['consecutive_transits'] ?? 0;
    final simulacraCount = _simulacra.where(inventory.contains).length;
    final hasAllSimulacra = simulacraCount == _simulacra.length;

    if (encounters > 0 && !puzzles.contains('zone_responded_$encounters')) {
      return 0;
    }

    final hasExplored = simulacraCount > 0 ||
        puzzles.any((p) => !p.startsWith('zone_') && p.endsWith('_complete'));
    if (!hasExplored) return 0;

    double probability;
    if (hasAllSimulacra && encounters == 0) {
      probability = 0.75;
    } else if (simulacraCount >= 3) {
      probability = 0.50;
    } else if (consecutive >= 2) {
      probability = 0.40;
    } else if (_isSectorCompletion(fromNode, puzzles)) {
      probability = 0.25;
    } else if (fromNode == 'la_soglia' || destNode == 'la_soglia') {
      probability = 0.15;
    } else {
      return 0;
    }

    final contradictions = counters['sys_contradictions'] ?? 0;
    final habitation = counters['sys_notebook_habitation'] ?? 0;
    final memoryInput = MemoryModule.buildEpitaphInput(
      puzzles: puzzles,
      counters: counters,
      inventory: inventory,
      psychoWeight: psychoWeight,
    );

    if (contradictions >= 3) probability += 0.08;
    if (memoryInput.costlyAnswers < 1 && simulacraCount >= 2)
      probability += 0.05;
    if (habitation < 5) probability += 0.03;

    final pressure = counters['sys_zone_pressure'] ?? 0;
    probability += (pressure * 0.03).clamp(0, 0.20);
    probability += simulacraCount * 0.05;

    return probability.clamp(0.0, 0.9);
  }

  static bool canLeaveZone({
    required Set<String> puzzles,
    required Map<String, int> counters,
  }) {
    final encounters = counters['zone_encounters'] ?? 0;
    final respondedKey = 'zone_responded_$encounters';
    return puzzles.contains(respondedKey);
  }

  static Map<String, int> _navigationCounterUpdates({
    required String fromNode,
    required String destNode,
    required Map<String, int> counters,
  }) {
    final updates = <String, int>{};
    final isTransit = fromNode == 'la_soglia' || destNode == 'la_soglia';
    if (isTransit && destNode != zoneNodeId) {
      updates['consecutive_transits'] =
          (counters['consecutive_transits'] ?? 0) + 1;
    } else if (!isTransit && destNode != zoneNodeId) {
      updates['consecutive_transits'] = 0;
    }
    return updates;
  }

  static bool _isSectorCompletion(String fromNode, Set<String> puzzles) {
    if (fromNode == 'garden_grove' && puzzles.contains('garden_complete')) {
      return true;
    }
    if (fromNode == 'obs_dome' && puzzles.contains('obs_complete')) return true;
    if (fromNode == 'gallery_central' && puzzles.contains('gallery_complete')) {
      return true;
    }
    if (fromNode == 'lab_sealed' && puzzles.contains('lab_complete'))
      return true;
    if (fromNode == 'quinto_ritual_chamber' &&
        puzzles.contains('ritual_complete')) {
      return true;
    }
    return false;
  }

  static int _deepSectorCount(Set<String> puzzles) {
    const deepKeys = {
      'sys_deep_garden',
      'sys_deep_observatory',
      'sys_deep_gallery',
      'sys_deep_laboratory',
      'sys_deep_memory',
    };
    return deepKeys.where(puzzles.contains).length;
  }

  static String _dominantWeightAxis(
      Map<String, int> counters, int psychoWeight) {
    final verbal = counters['sys_weight_verbal'] ?? 0;
    final symbolic = counters['sys_weight_symbolic'] ?? 0;
    final material = psychoWeight;

    if (material >= verbal && material >= symbolic) return 'material';
    if (symbolic >= verbal) return 'symbolic';
    return 'verbal';
  }

  static int _unresolvedProtections({
    required int contradictions,
    required List<String> inventory,
    required int memoryCostlyAnswers,
  }) {
    final mundane = inventory
        .where((i) => !_simulacra.contains(i) && i != 'notebook')
        .length;
    return contradictions + mundane + (memoryCostlyAnswers < 2 ? 1 : 0);
  }

  static String _sourceForEncounter(Set<String> puzzles, int encounter) {
    const sources = {
      'contradiction',
      'protection',
      'memory_readiness',
      'depth',
      'notebook',
      'weight_material',
      'weight_symbolic',
      'weight_verbal',
    };
    for (final source in sources) {
      if (puzzles.contains('zone_prompt_${encounter}_source_$source')) {
        return source;
      }
    }
    return 'weight_verbal';
  }

  static Set<String> _tagsForEncounter(Set<String> puzzles, int encounter) {
    const tags = {
      'contradiction',
      'ownership',
      'proof',
      'protection',
      'burden',
      'fear',
      'memory',
      'age',
      'confession',
      'depth',
      'return',
      'cost',
      'notebook',
      'voice',
      'inhabitation',
      'material',
      'body',
      'holding',
      'symbolic',
      'ritual',
      'form',
      'verbal',
      'speech',
      'evasion',
    };
    return {
      for (final tag in tags)
        if (puzzles.contains('zone_prompt_${encounter}_tag_$tag')) tag,
    };
  }

  static String _crypticResponseFor(String source, ZoneEvaluation evaluation) {
    if (evaluation.qualityTier >= 2) {
      switch (source) {
        case 'contradiction':
          return 'The Zone records the contradiction as location, not shame. The corridor loosens.';
        case 'memory_readiness':
          return 'A younger voice answers from behind the wall. The Archive is through here.';
        case 'notebook':
          return 'A blank page stops being blank. The geometry softens.';
        default:
          return 'Something in the architecture shifts — very slightly, but permanently. The Archive is north.';
      }
    }
    return 'The Zone keeps this as a partial coordinate. You may return, but it will ask again later.';
  }

  static bool _tagMatchesText(String tag, String text) {
    switch (tag) {
      case 'contradiction':
      case 'ownership':
      case 'proof':
        return text.contains('i said') ||
            text.contains('still carry') ||
            text.contains('proof') ||
            text.contains('contradiction');
      case 'protection':
      case 'burden':
      case 'fear':
        return text.contains('protect') ||
            text.contains('shield') ||
            text.contains('fear');
      case 'memory':
      case 'age':
      case 'confession':
        return text.contains('child') ||
            text.contains('youth') ||
            text.contains('old') ||
            text.contains('remember');
      case 'depth':
      case 'return':
      case 'cost':
        return text.contains('surface') ||
            text.contains('return') ||
            text.contains('cost') ||
            text.contains('deep');
      case 'notebook':
      case 'voice':
      case 'inhabitation':
        return text.contains('notebook') ||
            text.contains('page') ||
            text.contains('voice');
      case 'material':
      case 'body':
      case 'holding':
        return text.contains('hand') ||
            text.contains('body') ||
            text.contains('hold');
      case 'symbolic':
      case 'ritual':
      case 'form':
        return text.contains('ritual') ||
            text.contains('symbol') ||
            text.contains('form');
      case 'verbal':
      case 'speech':
      case 'evasion':
        return text.contains('sentence') ||
            text.contains('word') ||
            text.contains('say');
      default:
        return false;
    }
  }

  static bool _isContradictionAligned(String text) {
    if (_deflectTerms.any(text.contains)) return false;
    final ownership = text.contains('i still') ||
        text.contains('i kept') ||
        text.contains('because') ||
        text.contains('i was afraid');
    return ownership;
  }

  static int _nonNegative(int value) => value < 0 ? 0 : value;
}
