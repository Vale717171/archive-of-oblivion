import '../parser/parser_state.dart';

class WeightState {
  final int material;
  final int verbal;
  final int symbolic;

  const WeightState({
    required this.material,
    required this.verbal,
    required this.symbolic,
  });
}

class NotebookState {
  final int pages;
  final int hiddenPages;
  final int tornPages;
  final int habitationScore;

  const NotebookState({
    required this.pages,
    required this.hiddenPages,
    required this.tornPages,
    required this.habitationScore,
  });
}

class CoherenceState {
  final int contradictionCount;

  const CoherenceState({required this.contradictionCount});
}

class SectorState {
  final int depthSignals;
  final bool surfaceComplete;
  final bool deepComplete;

  const SectorState({
    required this.depthSignals,
    required this.surfaceComplete,
    required this.deepComplete,
  });
}

class ZoneState {
  final int pressure;

  const ZoneState({required this.pressure});
}

class ThresholdState {
  final int resonance;
  final bool unstableLight;
  final bool incompleteStair;

  const ThresholdState({
    required this.resonance,
    required this.unstableLight,
    required this.incompleteStair,
  });
}

class EndingState {
  final bool acceptanceEligible;
  final bool oblivionEligible;
  final bool eternalZoneEligible;

  const EndingState({
    required this.acceptanceEligible,
    required this.oblivionEligible,
    required this.eternalZoneEligible,
  });
}

class SystemicRuntimeState {
  final WeightState weight;
  final NotebookState notebook;
  final CoherenceState coherence;
  final Map<String, SectorState> sectors;
  final ZoneState zone;
  final ThresholdState threshold;
  final EndingState ending;

  const SystemicRuntimeState({
    required this.weight,
    required this.notebook,
    required this.coherence,
    required this.sectors,
    required this.zone,
    required this.threshold,
    required this.ending,
  });
}

class SystemicStateCodec {
  static const _weightVerbal = 'sys_weight_verbal';
  static const _weightSymbolic = 'sys_weight_symbolic';
  static const _notebookPages = 'sys_notebook_pages';
  static const _notebookHidden = 'sys_notebook_hidden_pages';
  static const _notebookTorn = 'sys_notebook_torn_pages';
  static const _notebookHabitation = 'sys_notebook_habitation';
  static const _contradictions = 'sys_contradictions';
  static const _zonePressure = 'sys_zone_pressure';
  static const _thresholdResonance = 'sys_threshold_resonance';

  static const _painRelics = <String>{
    'mirror shard',
    'rusted key',
    'torn page',
    'earth',
    'gold coin',
    'ancient book',
    'key',
    'page',
  };

  static const Map<String, String> _surfacePuzzleBySector = {
    'garden': 'garden_complete',
    'observatory': 'obs_complete',
    'gallery': 'gallery_complete',
    'laboratory': 'lab_complete',
    'memory': 'ritual_complete',
  };

  static const _sectors = <String>[
    'garden',
    'observatory',
    'gallery',
    'laboratory',
    'memory',
  ];

  static int _counter(Map<String, int> counters, String key) =>
      counters[key] ?? 0;

  static int _clamp(int value, {int min = 0, int max = 100}) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  static bool _containsPainRelic(List<String> inventory) =>
      inventory.any((item) =>
          _painRelics.any((relic) => item.contains(relic) || relic == item));

  static String _seedKeyForNode(String nodeId) => 'sys_notebook_seed_$nodeId';

  static String _deepKey(String sector) => 'sys_deep_$sector';

  static int _deepCount(Set<String> puzzles) =>
      _sectors.where((s) => puzzles.contains(_deepKey(s))).length;

  static SystemicRuntimeState fromSnapshot({
    required int psychoWeight,
    required Map<String, int> counters,
    required Set<String> puzzles,
  }) {
    final sectors = <String, SectorState>{
      for (final sector in _sectors)
        sector: SectorState(
          depthSignals: counters['depth_$sector'] ?? 0,
          surfaceComplete:
              puzzles.contains(_surfacePuzzleBySector[sector] ?? '__none__'),
          deepComplete: puzzles.contains(_deepKey(sector)),
        ),
    };

    final contradictions = _counter(counters, _contradictions);
    final deepCount = _deepCount(puzzles);
    final resonance = _counter(counters, _thresholdResonance);

    return SystemicRuntimeState(
      weight: WeightState(
        material: psychoWeight,
        verbal: _counter(counters, _weightVerbal),
        symbolic: _counter(counters, _weightSymbolic),
      ),
      notebook: NotebookState(
        pages: _counter(counters, _notebookPages),
        hiddenPages: _counter(counters, _notebookHidden),
        tornPages: _counter(counters, _notebookTorn),
        habitationScore: _counter(counters, _notebookHabitation),
      ),
      coherence: CoherenceState(contradictionCount: contradictions),
      sectors: sectors,
      zone: ZoneState(pressure: _counter(counters, _zonePressure)),
      threshold: ThresholdState(
        resonance: resonance,
        unstableLight: puzzles.contains('sys_threshold_unstable_light'),
        incompleteStair: puzzles.contains('sys_threshold_incomplete_stair'),
      ),
      ending: EndingState(
        acceptanceEligible: contradictions <= 3 && deepCount >= 2,
        oblivionEligible: contradictions >= 4,
        eternalZoneEligible: deepCount < 4,
      ),
    );
  }

  static void applyShells({
    required ParsedCommand cmd,
    required EngineResponse response,
    required String nodeId,
    required List<String> beforeInventory,
    required List<String> afterInventory,
    required int psychoWeight,
    required Map<String, int> counters,
    required Set<String> puzzles,
  }) {
    if (cmd.verb == CommandVerb.say ||
        cmd.verb == CommandVerb.write ||
        cmd.verb == CommandVerb.observe) {
      counters[_weightVerbal] = _clamp(_counter(counters, _weightVerbal) + 1);
      counters[_notebookHabitation] =
          _clamp(_counter(counters, _notebookHabitation) + 1);
    }

    if (response.needsDemiurge || response.completePuzzle != null) {
      counters[_weightSymbolic] =
          _clamp(_counter(counters, _weightSymbolic) + 1);
    }

    if (response.playerMemoryKey != null ||
        cmd.verb == CommandVerb.write ||
        cmd.verb == CommandVerb.say) {
      final seed = _seedKeyForNode(nodeId);
      if (!puzzles.contains(seed)) {
        puzzles.add(seed);
        counters[_notebookPages] =
            _clamp(_counter(counters, _notebookPages) + 1);
      }
    }

    if (response.completePuzzle == 'ritual_complete') {
      counters[_notebookHidden] =
          _clamp(_counter(counters, _notebookHidden) + 1, max: 12);
    }

    final droppedSomething = afterInventory.length < beforeInventory.length;
    if (droppedSomething &&
        (cmd.verb == CommandVerb.drop || cmd.verb == CommandVerb.deposit)) {
      counters[_notebookHabitation] =
          _clamp(_counter(counters, _notebookHabitation) + 2);
    }

    final raw = cmd.rawInput.toLowerCase();
    final saidLetGo = raw.contains('let go') ||
        raw.contains('i am empty') ||
        raw.contains('i released') ||
        raw.contains('i have released');
    if (saidLetGo && _containsPainRelic(afterInventory)) {
      counters[_contradictions] =
          _clamp(_counter(counters, _contradictions) + 1);
      counters[_zonePressure] = _clamp(_counter(counters, _zonePressure) + 2);
    }

    if (response.grantItem != null &&
        (response.grantItem == 'ataraxia' ||
            response.grantItem == 'the constant' ||
            response.grantItem == 'the proportion' ||
            response.grantItem == 'the catalyst')) {
      counters[_zonePressure] = _clamp(_counter(counters, _zonePressure) + 1);
    }

    for (final sector in _sectors) {
      final depth = counters['depth_$sector'] ?? 0;
      final surface =
          puzzles.contains(_surfacePuzzleBySector[sector] ?? '__none__');
      if (surface && depth >= 7) {
        puzzles.add(_deepKey(sector));
      }
    }

    final deepCount = _deepCount(puzzles);
    final contradictions = _counter(counters, _contradictions);
    final resonance = deepCount + contradictions;
    counters[_thresholdResonance] = _clamp(resonance, max: 50);
    if (resonance >= 2) {
      puzzles.add('sys_threshold_unstable_light');
    }

    final hasAllSimulacra = const {
      'ataraxia',
      'the constant',
      'the proportion',
      'the catalyst',
    }.every(afterInventory.contains);
    if (hasAllSimulacra && deepCount < 4) {
      puzzles.add('sys_threshold_incomplete_stair');
    }

    // material axis follows the existing psycho-weight.
    if (psychoWeight <= 0 && droppedSomething) {
      counters[_notebookTorn] = _clamp(_counter(counters, _notebookTorn) + 1);
    }
  }

  static double zoneActivationBoost(Map<String, int> counters) {
    final pressure = _counter(counters, _zonePressure);
    final boost = pressure * 0.03;
    return boost > 0.20 ? 0.20 : boost;
  }

  static void onZoneActivated(Map<String, int> counters) {
    final pressure = _counter(counters, _zonePressure);
    counters[_zonePressure] = pressure <= 0 ? 0 : pressure - 1;
  }

  static String notebookExamineText(SystemicRuntimeState s) {
    return 'Notebook\n\n'
        'Pages inscribed: ${s.notebook.pages}.\n'
        'Hidden pages revealed: ${s.notebook.hiddenPages}.\n'
        'Pages torn free: ${s.notebook.tornPages}.\n'
        'Habitation score: ${s.notebook.habitationScore}.\n\n'
        'Weight axes — material ${s.weight.material}, verbal ${s.weight.verbal}, symbolic ${s.weight.symbolic}.\n'
        'Contradictions recorded: ${s.coherence.contradictionCount}.';
  }

  static String? thresholdReturnSignal({
    required String nodeId,
    required Map<String, int> counters,
    required Set<String> puzzles,
  }) {
    if (nodeId != 'la_soglia') return null;
    final state = fromSnapshot(
      psychoWeight: 0,
      counters: counters,
      puzzles: puzzles,
    );

    final lines = <String>[];
    if (state.threshold.unstableLight) {
      lines.add('The light above the pedestal flickers, then steadies.');
    }
    if (state.threshold.incompleteStair) {
      lines.add('The upper stair appears for an instant, then retracts.');
    }
    if (state.zone.pressure >= 3) {
      lines.add('A faint geometric hum crosses the marble and vanishes.');
    }
    return lines.isEmpty ? null : lines.join('\n');
  }
}
