import '../parser/parser_state.dart';
import 'garden/garden_module.dart';
import 'observatory/observatory_module.dart';

class ProgressionResult {
  final Set<String> puzzles;
  final Map<String, int> counters;

  const ProgressionResult({
    required this.puzzles,
    required this.counters,
  });
}

typedef DeepCompletionEvaluator = bool Function({
  required Set<String> puzzles,
  required Map<String, int> counters,
});

class SectorProgressionRule {
  final String sector;
  final String surfacePuzzle;
  final String deepPuzzle;
  final int minDepth;
  final Set<String> requiredPuzzles;
  final DeepCompletionEvaluator? deepEvaluator;

  const SectorProgressionRule({
    required this.sector,
    required this.surfacePuzzle,
    required this.deepPuzzle,
    this.minDepth = 7,
    this.requiredPuzzles = const {},
    this.deepEvaluator,
  });

  bool isSurfaceComplete(Set<String> puzzles) =>
      puzzles.contains(surfacePuzzle);

  bool isDeepComplete({
    required Set<String> puzzles,
    required Map<String, int> counters,
  }) {
    if (deepEvaluator != null) {
      return deepEvaluator!(puzzles: puzzles, counters: counters);
    }
    final depth = counters[ProgressionService.depthCounterKey(sector)] ?? 0;
    return isSurfaceComplete(puzzles) &&
        depth >= minDepth &&
        requiredPuzzles.every(puzzles.contains);
  }
}

class ProgressionService {
  static const String thresholdResonanceInputCounter =
      'progress_threshold_resonance_input';

  static const List<SectorProgressionRule> rules = [
    SectorProgressionRule(
      sector: 'garden',
      surfacePuzzle: 'garden_complete',
      deepPuzzle: 'sys_deep_garden',
      deepEvaluator: GardenModule.isDeepComplete,
    ),
    SectorProgressionRule(
      sector: 'observatory',
      surfacePuzzle: 'obs_complete',
      deepPuzzle: 'sys_deep_observatory',
      deepEvaluator: ObservatoryModule.isDeepComplete,
    ),
    SectorProgressionRule(
      sector: 'gallery',
      surfacePuzzle: 'gallery_complete',
      deepPuzzle: 'sys_deep_gallery',
    ),
    SectorProgressionRule(
      sector: 'laboratory',
      surfacePuzzle: 'lab_complete',
      deepPuzzle: 'sys_deep_laboratory',
    ),
    SectorProgressionRule(
      sector: 'memory',
      surfacePuzzle: 'ritual_complete',
      deepPuzzle: 'sys_deep_memory',
    ),
  ];

  static const Set<CommandVerb> _nonSignificantVerbs = {
    CommandVerb.help,
    CommandVerb.inventory,
    CommandVerb.hint,
    CommandVerb.unknown,
  };

  static String depthCounterKey(String sector) => 'depth_$sector';

  static String depthSignatureKey({
    required String sector,
    required String nodeId,
    required CommandVerb verb,
  }) =>
      'depth_sig_${sector}_${nodeId}_${verb.name}';

  static String? sectorForNode(String nodeId) {
    if (nodeId.startsWith('garden_')) return 'garden';
    if (nodeId.startsWith('obs_')) return 'observatory';
    if (nodeId.startsWith('gallery_') || nodeId.startsWith('gal_')) {
      return 'gallery';
    }
    if (nodeId.startsWith('lab_')) return 'laboratory';
    if (nodeId.startsWith('quinto_') || nodeId.startsWith('memory_')) {
      return 'memory';
    }
    return null;
  }

  static bool isSignificantInteraction(
    ParsedCommand cmd,
    EngineResponse response,
  ) {
    if (_nonSignificantVerbs.contains(cmd.verb)) return false;
    return response.completePuzzle != null ||
        response.grantItem != null ||
        response.incrementCounter != null ||
        response.playerMemoryKey != null ||
        response.newNode != null ||
        response.needsDemiurge;
  }

  static ProgressionResult applyTurn({
    required ParsedCommand cmd,
    required EngineResponse response,
    required String nodeId,
    required Set<String> puzzles,
    required Map<String, int> counters,
  }) {
    final nextPuzzles = Set<String>.from(puzzles);
    final nextCounters = Map<String, int>.from(counters);

    final sector = sectorForNode(nodeId);
    if (sector != null && isSignificantInteraction(cmd, response)) {
      final signature =
          depthSignatureKey(sector: sector, nodeId: nodeId, verb: cmd.verb);
      if (!nextPuzzles.contains(signature)) {
        nextPuzzles.add(signature);
        final key = depthCounterKey(sector);
        nextCounters[key] = (nextCounters[key] ?? 0) + 1;
      }
    }

    int deepCount = 0;
    for (final rule in rules) {
      if (rule.isSurfaceComplete(nextPuzzles)) {
        nextPuzzles.add('progress_surface_${rule.sector}');
      }
      if (rule.isDeepComplete(puzzles: nextPuzzles, counters: nextCounters)) {
        nextPuzzles.add(rule.deepPuzzle);
        nextPuzzles.add('progress_deep_${rule.sector}');
      }
      if (nextPuzzles.contains(rule.deepPuzzle)) deepCount++;
    }

    // Backward-compatible legacy markers for Garden.
    if (nextPuzzles.contains('garden_complete')) {
      nextPuzzles.add('garden_surface_complete');
    }
    if (nextPuzzles.contains('sys_deep_garden')) {
      nextPuzzles.add('garden_deep_complete');
    }
    nextPuzzles.addAll(
      ObservatoryModule.completionMarkers(
        puzzles: nextPuzzles,
        counters: nextCounters,
      ),
    );

    // Shared threshold resonance input consumed by SystemicStateCodec.
    nextCounters[thresholdResonanceInputCounter] = deepCount;

    return ProgressionResult(puzzles: nextPuzzles, counters: nextCounters);
  }
}
