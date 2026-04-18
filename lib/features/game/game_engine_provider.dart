// lib/features/game/game_engine_provider.dart
// Author: GitHub Copilot — 2026-04-02 | Extended: 2026-04-03, 2026-04-04, 2026-04-05
// All four sectors + Fifth Sector + Final Boss + La Zona implemented.
// Narrator: DemiurgeService ("All That Is") — deterministic, offline (GDD §5).

import 'dart:math' show Random, max, min;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/database_service.dart';
import '../../core/storage/dialogue_history_service.dart';
import '../audio/audio_service.dart';
import '../../core/services/save_service.dart';
import '../demiurge/demiurge_service.dart';
import '../demiurge/echo_service.dart';
import '../parser/parser_service.dart';
import '../parser/parser_state.dart';
import 'gallery/gallery_module.dart';
import 'gallery/gallery_sector.dart';
import 'game_node.dart';
import 'garden/garden_module.dart';
import 'garden/garden_sector.dart';
import 'laboratory/laboratory_module.dart';
import 'laboratory/laboratory_sector.dart';
import 'memory/memory_module.dart';
import 'memory/memory_sector.dart';
import 'nucleus/nucleus_adjudication.dart';
import 'nucleus/nucleus_module.dart';
import 'observatory/observatory_module.dart';
import 'observatory/observatory_sector.dart';
import 'progression_service.dart';
import 'sector_contract.dart';
import 'sector_router.dart';
import 'systemic_state.dart';
import 'zone/zone_module.dart';
import '../state/game_state_provider.dart';
import '../state/psycho_provider.dart';

// ── Simulacra — weightless; dropping them does not reduce burden ──────────────

const Set<String> _simulacraNames = {
  'ataraxia',
  'the constant',
  'the proportion',
  'the catalyst',
};

const Set<String> simulacraItemNames = _simulacraNames;

enum BossUtteranceKind { surrender, remain, resolution, other }

// ── Exit gates: nodeId → {direction → requiredPuzzleId} ──────────────────────

const Map<String, Map<String, String>> _exitGates = {
  ...GardenModule.exitGates,
  ...ObservatoryModule.exitGates,
  ...GalleryModule.exitGates,
  ...LaboratoryModule.exitGates,
  ...MemoryModule.exitGates,
};

const Map<String, String> _gateHints = {
  ...GardenModule.gateHints,
  ...ObservatoryModule.gateHints,
  ...GalleryModule.gateHints,
  ...LaboratoryModule.gateHints,
  ...MemoryModule.gateHints,
};

// ── Depth / exposure gates (anti-speedrun, diegetic) ───────────────────────

const Map<String, int> _depthThresholdsToQuinto = {
  'garden': 5,
  'observatory': 5,
  'gallery': 5,
  'laboratory': 5,
};

// ── Node definitions ──────────────────────────────────────────────────────────
// Nodes are in English as required by GDD §1.
// Future: move text to assets/texts/*.json (GDD §18).

const Map<String, NodeDef> _nodes = {
  // ── Starting void ────────────────────────────────────────────────────────────
  'intro_void': NodeDef(
    title: '',
    description: 'Silence.\n\n'
        'Then — awareness.\n\n'
        'You exist. You do not know why. A name surfaces and dissolves '
        'before you can hold it. No floor, no ceiling. '
        'Only a luminescence that comes from everywhere and nowhere.\n\n'
        'In your pocket: a small empty Notebook.\n\n'
        'A path forms ahead.',
    exits: {'north': 'la_soglia', 'forward': 'la_soglia', 'ahead': 'la_soglia'},
    examines: {
      'notebook': 'A small notebook. Pages perfectly blank. '
          'The cover bears a symbol you almost recognise — then do not.',
      'light': 'It does not come from any source. It simply is.',
      'path': 'It was not there before. Now it leads north.',
    },
  ),

  // ── The Threshold (hub) ──────────────────────────────────────────────────────
  'la_soglia': NodeDef(
    title: 'The Threshold',
    description: 'A circular rotunda of black marble veined with silver.\n\n'
        'Four doors at the cardinal points: amber to the north, '
        'cobalt blue to the east, golden to the south, violet to the west. '
        'At the centre, a pentagonal pedestal holds five recesses — each '
        'shaped for something you have not yet found.\n\n'
        'A clock without hands marks time in no direction you recognise.',
    exits: {
      'north': 'garden_portico',
      'east': 'obs_antechamber',
      'south': 'gallery_hall',
      'west': 'lab_vestibule',
      'up': 'quinto_landing',
    },
    examines: {
      'pedestal': 'Five recesses. Inscribed: Ataraxia. The Constant. '
          'Proportion. The Catalyst. A fifth shape you cannot name.',
      'clock': 'Numerals run counterclockwise. The hands are absent.',
      'north door':
          'Amber, warm, slightly ajar. Beyond it: the scent of earth.',
      'east door': 'Cobalt blue, cold. A faint hum behind the glass.',
      'south door':
          'Golden, polished to a mirror. Your reflection is slightly wrong.',
      'west door': 'Violet, heavy. The grain of the wood runs upward.',
      'door': 'Four doors. The amber one to the north is ajar.',
    },
  ),

  // ── Garden of Epicurus ───────────────────────────────────────────────────────
  ...GardenModule.roomDefinitions,

  // ── Observatory ──────────────────────────────────────────────────────────────
  ...ObservatoryModule.roomDefinitions,

  // ── Gallery of Mirrors ───────────────────────────────────────────────────────
  ...GalleryModule.roomDefinitions,

  // ── Alchemical Laboratory ────────────────────────────────────────────────────
  ...LaboratoryModule.roomDefinitions,

  // ── Fifth Sector (Memory) ────────────────────────────────────────────────────
  ...MemoryModule.roomDefinitions,

  // ── Il Nucleo — The Final Confrontation (GDD §12) ─────────────────────────
  'il_nucleo': NodeDef(
    title: 'The Nucleus — The Final Confrontation',
    description: 'A space with no walls.\n\n'
        'Before you: a figure without a face. '
        'Its features shift — not as if changing, '
        'but as if the concept of features does not apply here.\n\n'
        'When it speaks, the voice is very calm. Very reasonable.\n\n'
        '"You have come a long way. You have carried a great deal. '
        'You have distilled something, I think, that you believe has value.\n\n'
        'I would like to offer you a different reading of what you\'ve found."\n\n'
        'It waits for you to respond.',
    exits: {},
    examines: {
      'figure':
          'It has no fixed form. This is not a threat — it is a property.',
      'voice': 'Calm. Reasonable. This is the most unsettling thing about it.',
      'space': 'No walls. No floor in the usual sense. '
          'Yet you are standing on something that holds.',
    },
  ),

  // ── I Tre Finali ──────────────────────────────────────────────────────────
  'finale_acceptance': NodeDef(
    title: 'Acceptance — The Revelation',
    description: 'The Archive grows transparent.\n\n'
        'Through the walls — walls that were always walls — '
        'a vastness opens that resembles coming home.\n\n'
        'Every tear. Every silence. Every imperfection. '
        'They were not failures: they were the raw materials of a soul.\n\n'
        '"Outside there is no Void. Outside there is everything."\n\n'
        'The Aria delle Goldberg resumes from its suspended note.\n\n'
        'Type WAKE UP when you are ready.',
    exits: {},
    examines: {
      'light': 'It is not dramatic. It is simply present.',
      'walls': 'They are still here. They are also something else now.',
    },
  ),

  'finale_oblivion': NodeDef(
    title: 'Oblivion',
    description: '...\n\n'
        '...\n\n'
        '...\n\n'
        '"Lived. Died. No one will remember."\n\n'
        '— Arseny Tarkovsky',
    exits: {},
    examines: {},
  ),

  'finale_eternal_zone': NodeDef(
    title: 'The Eternal Zone',
    description: 'You remain.\n\n'
        'The variations begin.\n\n'
        'They do not end.',
    exits: {'back': 'la_zona'},
    examines: {
      'variations': 'Infinite. Procedural. Each one specifically yours.',
    },
  ),

  'finale_testimony': NodeDef(
    title: 'Testimony',
    description: 'You stand between erasure and consolation.\n\n'
        'Not acquitted. Not condemned. Accountable.\n\n'
        'The Archive remains open as witness, not prison.\n\n'
        'Type WAKE UP when you are ready.',
    exits: {},
    examines: {
      'archive':
          'It is no longer asking for a perfect ending. It is asking for ongoing truth.',
      'witness':
          'To testify is to keep memory, cost, and future action in one sentence.',
    },
  ),

  // ── La Zona (GDD §10) ─────────────────────────────────────────────────────
  'la_zona': NodeDef(
    title: 'The Zone',
    description: 'Impossible geometry.\n\n'
        'A corridor that is also a room. '
        'The walls meet at an angle that should not exist.\n\n'
        'Something is asking you something.',
    exits: {'back': 'la_soglia'},
    examines: {
      'geometry': 'The walls agree only in the angle they refuse to make.',
      'walls': 'Present — but defined by their own impossibility.',
      'space': 'It is inside something. It is also outside it.',
    },
  ),
};

// ── Engine state ──────────────────────────────────────────────────────────────

class GameEngineState {
  static const Object _noSimulacrumChange = Object();

  final List<GameMessage> messages;
  final ParserPhase phase;
  final int psychoWeight;
  final List<String> inventory;
  final int screenResetCount;
  final bool isPuzzleSolved;
  final String? latestSimulacrum;
  final int psychoShiftCount;
  final bool latestPsychoShiftIsPhase;

  /// Puzzle IDs that have been solved, e.g. 'leaves_arranged'.
  final Set<String> completedPuzzles;

  /// Integer counters for multi-step puzzles, e.g. 'fountain_waits': 2.
  final Map<String, int> puzzleCounters;

  /// Session-total narrative quote/citation exposure tracked by the engine.
  final int quoteExposureSeen;

  const GameEngineState({
    this.messages = const [],
    this.phase = ParserPhase.idle,
    this.psychoWeight = 0,
    this.inventory = const [],
    this.screenResetCount = 0,
    this.isPuzzleSolved = false,
    this.latestSimulacrum,
    this.psychoShiftCount = 0,
    this.latestPsychoShiftIsPhase = false,
    this.completedPuzzles = const {},
    this.puzzleCounters = const {},
    this.quoteExposureSeen = 0,
  });

  GameEngineState copyWith({
    List<GameMessage>? messages,
    ParserPhase? phase,
    int? psychoWeight,
    List<String>? inventory,
    int? screenResetCount,
    bool? isPuzzleSolved,
    Object? latestSimulacrum = _noSimulacrumChange,
    int? psychoShiftCount,
    bool? latestPsychoShiftIsPhase,
    Set<String>? completedPuzzles,
    Map<String, int>? puzzleCounters,
    int? quoteExposureSeen,
  }) {
    return GameEngineState(
      messages: messages ?? this.messages,
      phase: phase ?? this.phase,
      psychoWeight: psychoWeight ?? this.psychoWeight,
      inventory: inventory ?? this.inventory,
      screenResetCount: screenResetCount ?? this.screenResetCount,
      isPuzzleSolved: isPuzzleSolved ?? this.isPuzzleSolved,
      latestSimulacrum: identical(latestSimulacrum, _noSimulacrumChange)
          ? this.latestSimulacrum
          : latestSimulacrum as String?,
      psychoShiftCount: psychoShiftCount ?? this.psychoShiftCount,
      latestPsychoShiftIsPhase:
          latestPsychoShiftIsPhase ?? this.latestPsychoShiftIsPhase,
      completedPuzzles: completedPuzzles ?? this.completedPuzzles,
      puzzleCounters: puzzleCounters ?? this.puzzleCounters,
      quoteExposureSeen: quoteExposureSeen ?? this.quoteExposureSeen,
    );
  }
}

class _PsychoShiftResult {
  final String text;
  final bool phaseChanged;

  const _PsychoShiftResult({
    required this.text,
    required this.phaseChanged,
  });
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class GameEngineNotifier extends AsyncNotifier<GameEngineState> {
  final _history = DialogueHistoryService.instance;
  final Random _random = Random();
  final SectorRouter _sectorRouter = SectorRouter([
    GardenSectorHandler(),
    ObservatorySectorHandler(),
    GallerySectorHandler(),
    LaboratorySectorHandler(),
    MemorySectorHandler(),
  ]);

  // ── Auto-save state (ephemeral — not persisted) ──────────────────────────
  int _commandsSinceAutoSave = 0;
  String _lastAutoSaveSector = '';
  final Map<String, int> _nonProductiveAttemptsByNode = <String, int>{};
  int _sessionQuoteExposureFloor = 0;

  // Maximum value for psychological weight and psycho-profile sliders.
  static const int _maxPsychoValue = 100;

  static const List<String> _unknownCommandFallbacks = [
    'The Archive listens, but does not parse this.',
    'Something was spoken. The Archive holds it, untranslated.',
    'The words arrive out of order.',
    'The sentence touches the room but does not settle into it.',
    'The Archive receives the sound and not the intention.',
    'Meaning approaches, then passes beside the door.',
    'The command almost becomes a key.',
    'The phrase enters the chamber unchanged and leaves altered.',
    'The Archive understands your presence more clearly than your syntax.',
    'Something in what you said belongs to another room.',
    'The Archive keeps the utterance without resolving it.',
    'These words do not fit the lock before you.',
  ];

  // ── Small helpers ───────────────────────────────────────────────────────────

  /// Returns true if [itemName] is one of the four weightless simulacra.
  static bool _isSimulacrum(String itemName) =>
      _simulacraNames.contains(itemName);

  SectorRuntimeSnapshot _sectorSnapshot(GameEngineState state) =>
      SectorRuntimeSnapshot(
        completedPuzzles: state.completedPuzzles,
        puzzleCounters: state.puzzleCounters,
        inventory: state.inventory,
        psychoWeight: state.psychoWeight,
      );

  EngineResponse? _routeSectorCommand({
    required ParsedCommand cmd,
    required String nodeId,
    required GameEngineState state,
  }) {
    final node = _nodes[nodeId];
    if (node == null) return null;
    return _sectorRouter.routeCommand(
      SectorCommandContext(
        cmd: cmd,
        nodeId: nodeId,
        node: node,
        snapshot: _sectorSnapshot(state),
      ),
    );
  }

  static String _hintRequestCounterKey(String nodeId) =>
      'hint_requests_$nodeId';

  List<String> _missingDepthSectorsForQuinto(GameEngineState s) {
    final missing = <String>[];
    for (final entry in _depthThresholdsToQuinto.entries) {
      final count =
          s.puzzleCounters[ProgressionService.depthCounterKey(entry.key)] ?? 0;
      if (count < entry.value) missing.add(entry.key);
    }
    return missing;
  }

  String _depthGateTextForQuinto(List<String> missingSectors) {
    final names = missingSectors.map((s) {
      switch (s) {
        case 'garden':
          return 'the Garden';
        case 'observatory':
          return 'the Observatory';
        case 'gallery':
          return 'the Gallery';
        case 'laboratory':
          return 'the Laboratory';
        default:
          return 'the Archive';
      }
    }).join(', ');
    return 'The fifth stair forms, then folds back into stone.\n\n'
        'The Archive has not heard you long enough in $names.\n\n'
        'Linger, answer, and let each wing leave its mark before you ascend.';
  }

  String _randomUnknownFallback() => _unknownCommandFallbacks[
      _random.nextInt(_unknownCommandFallbacks.length)];

  EngineResponse _simulacrumReward({
    required String narrativeText,
    required String itemName,
    required String completePuzzle,
    int? lucidityDelta,
    int? anxietyDelta,
    int? oblivionDelta,
    bool clearInventoryOnDeposit = false,
  }) {
    return EngineResponse(
      narrativeText:
          '$narrativeText\n\n✦ You have recovered $itemName. The Archive marks the moment.',
      needsDemiurge: true,
      lucidityDelta: lucidityDelta,
      anxietyDelta: anxietyDelta,
      oblivionDelta: oblivionDelta,
      audioTrigger: 'simulacrum',
      grantItem: itemName,
      completePuzzle: completePuzzle,
      clearInventoryOnDeposit: clearInventoryOnDeposit,
    );
  }

  @override
  Future<GameEngineState> build() async {
    final savedState = await ref.read(gameStateProvider.future);
    final node = _nodes[savedState.currentNode] ?? _nodes['intro_void']!;
    final intro = _enterNode(node);
    _sessionQuoteExposureFloor =
        savedState.puzzleCounters['quote_exposure_seen'] ?? 0;
    _nonProductiveAttemptsByNode.clear();
    await _history.save(
        role: 'system', content: 'Session started: ${node.title}');
    return GameEngineState(
      messages: [GameMessage(text: intro, role: MessageRole.narrative)],
      phase: ParserPhase.idle,
      inventory: savedState.inventory.isNotEmpty
          ? savedState.inventory
          : const ['notebook'],
      completedPuzzles: savedState.completedPuzzles,
      puzzleCounters: savedState.puzzleCounters,
      psychoWeight: savedState.psychoWeight,
      quoteExposureSeen: _sessionQuoteExposureFloor,
    );
  }

  Future<void> startNewGame() async {
    final introNode = _nodes['intro_void'];
    if (introNode == null) {
      throw StateError(
        'Missing intro_void node definition. Ensure _nodes is initialized with the intro node.',
      );
    }
    final introText = _enterNode(introNode);

    await _history.clear();
    await DatabaseService.instance.clearAllMemories();
    await ref.read(psychoProfileProvider.notifier).resetProfile();
    await ref.read(gameStateProvider.notifier).resetGameState();
    _nonProductiveAttemptsByNode.clear();
    _sessionQuoteExposureFloor = 0;
    await _history.save(
        role: 'system', content: 'Session started: ${introNode.title}');

    state = AsyncValue.data(
      GameEngineState(
        messages: [GameMessage(text: introText, role: MessageRole.narrative)],
        phase: ParserPhase.idle,
        inventory: const ['notebook'],
        completedPuzzles: const {},
        puzzleCounters: const {},
        psychoWeight: 0,
        quoteExposureSeen: 0,
        isPuzzleSolved: false,
        latestSimulacrum: null,
      ),
    );
  }

  // ── processInput ────────────────────────────────────────────────────────────

  Future<void> processInput(String raw) async {
    final current = state.valueOrNull;
    if (current == null || current.phase != ParserPhase.idle) return;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;

    try {
      final pendingState = current.copyWith(
        phase: ParserPhase.parsing,
        isPuzzleSolved: false,
        latestSimulacrum: null,
      );
      state = AsyncValue.data(pendingState);
      final cmd = ParserService.parse(trimmed);

      final withPlayer = _appendMessage(
        pendingState.copyWith(phase: ParserPhase.evaluating),
        GameMessage(text: '> $trimmed', role: MessageRole.player),
      );
      state = AsyncValue.data(withPlayer);
      await _history.save(role: 'user', content: trimmed);

      final savedState = await ref.read(gameStateProvider.future);
      final currentNodeId = savedState.currentNode;
      final evaluationResponse = _evaluate(cmd, currentNodeId, withPlayer);
      final zoneResolution = ZoneModule.resolveTurn(
        cmd: cmd,
        nodeId: currentNodeId,
        evaluationResponse: evaluationResponse,
        puzzles: withPlayer.completedPuzzles,
        counters: withPlayer.puzzleCounters,
        inventory: withPlayer.inventory,
        psychoWeight: withPlayer.psychoWeight,
        randomRoll: _random.nextDouble(),
      );
      final finalArcResolution = NucleusModule.resolveTurn(
        cmd: cmd,
        nodeId: currentNodeId,
        evaluationResponse: zoneResolution.response,
        puzzles: withPlayer.completedPuzzles,
        counters: withPlayer.puzzleCounters,
        inventory: withPlayer.inventory,
        psychoWeight: withPlayer.psychoWeight,
      );
      final response = finalArcResolution.response;
      final progressiveHintSuffix = _progressiveHintSuffix(
        cmd: cmd,
        response: response,
        nodeId: currentNodeId,
        stateSnapshot: withPlayer,
      );

      state = AsyncValue.data(
          withPlayer.copyWith(phase: ParserPhase.eventResolved));

      // ── Apply weight (never below 0 or above _maxPsychoValue) ──────────────
      int newWeight = (withPlayer.psychoWeight + response.weightDelta)
          .clamp(0, _maxPsychoValue);

      // ── Apply inventory changes ─────────────────────────────────────────────
      final beforeInventory = List<String>.from(withPlayer.inventory);
      List<String> newInventory = List.from(withPlayer.inventory);
      if (response.grantItem != null &&
          !newInventory.contains(response.grantItem!)) {
        newInventory.add(response.grantItem!);
      }
      // drop removes from inventory (except Great Work and Ritual Chamber placements)
      if (cmd.verb == CommandVerb.drop &&
          cmd.args.isNotEmpty &&
          currentNodeId != 'lab_great_work' &&
          currentNodeId != 'quinto_ritual_chamber') {
        newInventory.remove(cmd.args.join(' '));
      }
      // deposit clears mundane items only when the deposit actually succeeds.
      // Failed deposits (wrong node, alcoves not walked, etc.) must NOT clear
      // inventory — the player would lose all items with no benefit.
      // In boss context (il_nucleo): preserve simulacra — only remove mundane items.
      if (cmd.verb == CommandVerb.deposit && response.clearInventoryOnDeposit) {
        if (currentNodeId == 'il_nucleo') {
          newInventory = newInventory
              .where((item) => _isSimulacrum(item) || item == 'notebook')
              .toList();
        } else {
          newInventory =
              newInventory.where((item) => item == 'notebook').toList();
        }
        newWeight = 0;
        if (response.grantItem != null) newInventory.add(response.grantItem!);
      }

      // ── Apply puzzle state ──────────────────────────────────────────────────
      final Set<String> newPuzzles =
          Set<String>.from(withPlayer.completedPuzzles);
      final Map<String, int> newCounters =
          Map<String, int>.from(withPlayer.puzzleCounters);

      if (response.completePuzzle != null)
        newPuzzles.add(response.completePuzzle!);
      if (response.incrementCounter != null) {
        newCounters[response.incrementCounter!] =
            (newCounters[response.incrementCounter!] ?? 0) + 1;
      }
      newPuzzles.addAll(zoneResolution.puzzleAdds);
      for (final entry in zoneResolution.counterUpdates.entries) {
        newCounters[entry.key] = entry.value;
      }
      newPuzzles.addAll(finalArcResolution.puzzleAdds);
      for (final entry in finalArcResolution.counterUpdates.entries) {
        newCounters[entry.key] = entry.value;
      }

      // ── Navigation + sector transition tracking ────────────────────────────
      if (response.newNode != null) {
        // Node persistence is deferred to saveEngineState at the end of this method
        // so that all state changes (puzzles, counters, inventory) are written atomically.

        final labNav = LaboratoryModule.applyNavigationTransition(
          fromNode: currentNodeId,
          destNode: response.newNode!,
          puzzles: newPuzzles,
          counters: newCounters,
        );
        newPuzzles
          ..clear()
          ..addAll(labNav.puzzles);
        newCounters
          ..clear()
          ..addAll(labNav.counters);
      }

      // ── Shared progression pipeline (pure) ────────────────────────────────
      final progression = ProgressionService.applyTurn(
        cmd: cmd,
        response: response,
        nodeId: currentNodeId,
        puzzles: newPuzzles,
        counters: newCounters,
      );
      newPuzzles
        ..clear()
        ..addAll(progression.puzzles);
      newCounters
        ..clear()
        ..addAll(progression.counters);

      // ── Systemic shells (notebook / coherence / depth / threshold / weights)
      // Stored in counters+puzzles to remain save-slot compatible during refactor.
      SystemicStateCodec.applyShells(
        cmd: cmd,
        response: response,
        nodeId: currentNodeId,
        beforeInventory: beforeInventory,
        afterInventory: newInventory,
        psychoWeight: newWeight,
        counters: newCounters,
        puzzles: newPuzzles,
      );

      // ── Apply psycho profile ────────────────────────────────────────────────
      if (response.anxietyDelta != null ||
          response.lucidityDelta != null ||
          response.oblivionDelta != null) {
        final profile = await ref.read(psychoProfileProvider.future);
        await ref.read(psychoProfileProvider.notifier).updateParameter(
              lucidity: response.lucidityDelta != null
                  ? (profile.lucidity + response.lucidityDelta!)
                      .clamp(0, _maxPsychoValue)
                  : null,
              anxiety: response.anxietyDelta != null
                  ? (profile.anxiety + response.anxietyDelta!)
                      .clamp(0, _maxPsychoValue)
                  : null,
              oblivionLevel: response.oblivionDelta != null
                  ? (profile.oblivionLevel + response.oblivionDelta!)
                      .clamp(0, _maxPsychoValue)
                  : null,
            );
      }

      // ── Phase system: awareness + affinity increment (Option A overlay) ────────
      // Runs unconditionally — deltas are small and additive, never alter existing logic.
      final psychoShift = await _updateAwarenessFromCommand(
        cmd.verb,
        response,
        trimmed,
      );

      // ── Audio trigger (fire-and-forget — must not block game logic) ──────────
      AudioService().handleTrigger(response.audioTrigger);

      final psychoProfileFieldsPresent = response.anxietyDelta != null ||
          response.lucidityDelta != null ||
          response.oblivionDelta != null;

      // ── Player memory (proustian responses + zone responses) ─────────────────
      bool memoryWasSaved = false;
      if (response.playerMemoryKey != null) {
        final memoryContent = cmd.verb == CommandVerb.unknown
            ? trimmed
            : cmd.args.join(' ').trim();
        if (memoryContent.isNotEmpty) {
          await DatabaseService.instance.saveMemory(
            key: response.playerMemoryKey!,
            content: memoryContent,
          );
          _applyFinalArcMetadataFromMemory(
            memoryKey: response.playerMemoryKey!,
            memoryContent: memoryContent,
            counters: newCounters,
          );
          memoryWasSaved = true;
        }
      }

      // ── Display ─────────────────────────────────────────────────────────────
      final demiurgeNodeId = response.newNode ?? currentNodeId;
      final narrativeText = response.needsDemiurge
          ? _callNarrator(
              cmd.verb, response.narrativeText, demiurgeNodeId, trimmed)
          : response.narrativeText;
      final narrativeWithProgressiveHint = progressiveHintSuffix == null
          ? narrativeText
          : '$narrativeText$progressiveHintSuffix';
      final narrativeWithPsychoShift = psychoShift == null
          ? narrativeWithProgressiveHint
          : '$narrativeWithProgressiveHint\n\n${psychoShift.text}';
      final savedNodeId = response.newNode ?? currentNodeId;
      final thresholdSignal = SystemicStateCodec.thresholdReturnSignal(
        nodeId: savedNodeId,
        counters: newCounters,
        puzzles: newPuzzles,
      );
      final narrativeWithThreshold = thresholdSignal == null
          ? narrativeWithPsychoShift
          : '$narrativeWithPsychoShift\n\n$thresholdSignal';
      await _history.save(role: 'demiurge', content: narrativeWithThreshold);

      int quoteExposureSeen = withPlayer.quoteExposureSeen;
      if (response.needsDemiurge) {
        final next =
            (newCounters['quote_exposure_seen'] ?? quoteExposureSeen) + 1;
        newCounters['quote_exposure_seen'] = next;
        _sessionQuoteExposureFloor = max(_sessionQuoteExposureFloor, next);
        quoteExposureSeen = _sessionQuoteExposureFloor;
      } else {
        quoteExposureSeen = max(
          _sessionQuoteExposureFloor,
          newCounters['quote_exposure_seen'] ?? quoteExposureSeen,
        );
      }

      final finalState = withPlayer.copyWith(
        phase: ParserPhase.displaying,
        psychoWeight: newWeight,
        inventory: newInventory,
        isPuzzleSolved: response.completePuzzle != null,
        latestSimulacrum:
            _isSimulacrum(response.grantItem ?? '') ? response.grantItem : null,
        psychoShiftCount: psychoShift == null
            ? withPlayer.psychoShiftCount
            : withPlayer.psychoShiftCount + 1,
        latestPsychoShiftIsPhase:
            psychoShift?.phaseChanged ?? withPlayer.latestPsychoShiftIsPhase,
        completedPuzzles: newPuzzles,
        puzzleCounters: newCounters,
        quoteExposureSeen: quoteExposureSeen,
      );

      // ── Persist full engine state ─────────────────────────────────────────────
      await ref.read(gameStateProvider.notifier).saveEngineState(
            currentNode: savedNodeId,
            completedPuzzles: newPuzzles,
            puzzleCounters: newCounters,
            inventory: newInventory,
            psychoWeight: newWeight,
          );

      // Compare the pre-display engine snapshot against the post-logic snapshot
      // so the cue reacts only to gameplay state changes, not to appended UI text.
      final shouldResetScreen = _shouldResetVisibleTranscript(
        previousState: withPlayer,
        currentState: finalState,
        nodeChanged: savedNodeId != currentNodeId,
        memoryWasSaved: memoryWasSaved,
        psychoProfileFieldsPresent: psychoProfileFieldsPresent,
      );
      final withNarrative = shouldResetScreen
          ? finalState.copyWith(
              messages: [
                GameMessage(
                    text: narrativeWithThreshold, role: MessageRole.narrative)
              ],
              screenResetCount: current.screenResetCount + 1,
            )
          : _appendMessage(
              finalState,
              GameMessage(
                  text: narrativeWithThreshold, role: MessageRole.narrative),
            );
      if (response.audioTrigger == 'simulacrum') {
        // Let the dedicated reward banner land before the typewriter resumes so
        // the simulacrum acquisition reads as a distinct moment of progress.
        await Future.delayed(const Duration(milliseconds: 500));
      }
      state = AsyncValue.data(withNarrative);
      await Future.delayed(const Duration(milliseconds: 100));
      state = AsyncValue.data(withNarrative.copyWith(phase: ParserPhase.idle));

      // ── Auto-save (fire-and-forget — must not block the engine) ─────────────
      _commandsSinceAutoSave++;
      final currentSectorForSave = gameSectorLabel(savedNodeId);
      final sectorChanged = currentSectorForSave != _lastAutoSaveSector &&
          _lastAutoSaveSector.isNotEmpty;
      if (_commandsSinceAutoSave >= 6 || sectorChanged) {
        _commandsSinceAutoSave = 0;
        _lastAutoSaveSector = currentSectorForSave;
        // ignore: discarded_futures
        _triggerAutoSave(
          nodeId: savedNodeId,
          engineState: withNarrative,
          sectorLabel: currentSectorForSave,
        );
      } else if (_lastAutoSaveSector.isEmpty) {
        _lastAutoSaveSector = currentSectorForSave;
      }
    } catch (e, st) {
      // Safety net: any uncaught exception must not leave the phase stuck in
      // evaluating/parsing forever. Reset to idle and show a recoverable error.
      debugPrint('processInput error: $e\n$st');
      final recovery = state.valueOrNull ?? current;
      state = AsyncValue.data(
        _appendMessage(
          recovery.copyWith(phase: ParserPhase.idle),
          const GameMessage(
            text: 'The Archive shudders. Something went wrong — try again.',
            role: MessageRole.narrative,
          ),
        ),
      );
    }
  }

  // ── _evaluate ───────────────────────────────────────────────────────────────

  EngineResponse _evaluate(
    ParsedCommand cmd,
    String nodeId,
    GameEngineState s,
  ) {
    final node = _nodes[nodeId];
    if (node == null) {
      return const EngineResponse(
          narrativeText: 'The Archive does not recognise this place.');
    }

    switch (cmd.verb) {
      case CommandVerb.help:
        return const EngineResponse(narrativeText: _helpText);

      case CommandVerb.inventory:
        return EngineResponse(
          narrativeText: s.inventory.isEmpty
              ? 'You carry nothing but a sense of incompleteness.'
              : 'You carry: ${s.inventory.join(", ")}.\n\n'
                  'Psychological weight: ${s.psychoWeight}.',
        );

      case CommandVerb.examine:
        return _handleExamine(cmd, nodeId, node, s);

      case CommandVerb.go:
        return _handleGo(cmd, node, nodeId, s);

      case CommandVerb.wait:
        return _handleWait(nodeId, s);

      case CommandVerb.take:
        return _handleTake(cmd, nodeId, node, s);

      case CommandVerb.use:
        return _handleUse(cmd, nodeId, s);

      case CommandVerb.drop:
        return _handleDrop(cmd, nodeId, s);

      case CommandVerb.deposit:
        return _handleDeposit(nodeId, s);

      case CommandVerb.smell:
        return _handleSmell(nodeId);

      case CommandVerb.taste:
        return _handleTaste(nodeId);

      case CommandVerb.walk:
        return _handleWalk(cmd, nodeId, s);

      case CommandVerb.arrange:
        return _handleArrange(cmd, nodeId, s);

      case CommandVerb.write:
        return _handleWrite(cmd, nodeId, s);

      case CommandVerb.combine:
        return _handleCombine(cmd, nodeId, s);

      case CommandVerb.press:
        return _handlePress(cmd, nodeId, s);

      case CommandVerb.offer:
        return _handleOffer(cmd, nodeId, s);

      case CommandVerb.measure:
        return _handleMeasure(cmd, nodeId, s);

      case CommandVerb.calibrate:
        return _handleCalibrate(cmd, nodeId, s);

      case CommandVerb.invert:
        return _handleInvert(cmd, nodeId, s);

      case CommandVerb.confirm:
        return _handleConfirm(nodeId, s);

      case CommandVerb.breakObj:
        return _handleBreak(cmd, nodeId, s);

      case CommandVerb.blow:
        return _handleBlow(nodeId, s);

      case CommandVerb.setParam:
        return _handleSetParam(cmd, nodeId, s);

      case CommandVerb.drink:
        return _handleDrink(nodeId, s);

      case CommandVerb.stir:
        return _handleStir(nodeId, s);

      case CommandVerb.observe:
        return _handleObserve(nodeId, s);

      case CommandVerb.enterValue:
        return _handleEnterValue(cmd, nodeId, s);

      case CommandVerb.collect:
        return _handleCollect(cmd, nodeId, s);

      case CommandVerb.decipher:
        return _handleDecipher(nodeId, s);

      case CommandVerb.say:
        return _handleSay(cmd, nodeId, s);

      case CommandVerb.hint:
        return _handleHint(cmd, nodeId, s);

      case CommandVerb.unknown:
        return _handleUnknown(cmd, nodeId, s);

      default:
        return const EngineResponse(
          narrativeText: 'Nothing happens. Perhaps the moment has not come.',
        );
    }
  }

  // ── Handlers ─────────────────────────────────────────────────────────────────

  EngineResponse _handleExamine(
    ParsedCommand cmd,
    String nodeId,
    NodeDef node,
    GameEngineState s,
  ) {
    if (cmd.args.isEmpty) {
      return EngineResponse(
          narrativeText: _enterNode(node), needsDemiurge: true);
    }
    final target = cmd.args.join(' ');
    if (target.contains('notebook') || target == 'book') {
      final systemic = SystemicStateCodec.fromSnapshot(
        psychoWeight: s.psychoWeight,
        counters: s.puzzleCounters,
        puzzles: s.completedPuzzles,
      );
      return EngineResponse(
        narrativeText: SystemicStateCodec.notebookExamineText(systemic),
      );
    }

    final gardenResponse = _routeSectorCommand(
      cmd: cmd,
      nodeId: nodeId,
      state: s,
    );
    if (gardenResponse != null) return gardenResponse;
    final match = node.examines.entries
        .where((e) => e.key.contains(target) || target.contains(e.key))
        .map((e) => e.value)
        .firstOrNull;
    if (match != null)
      return EngineResponse(narrativeText: match, needsDemiurge: true);
    return const EngineResponse(
        narrativeText: 'You observe it closely. It offers nothing new.');
  }

  EngineResponse _handleGo(
    ParsedCommand cmd,
    NodeDef node,
    String nodeId,
    GameEngineState s,
  ) {
    if (cmd.args.isEmpty) {
      return const EngineResponse(narrativeText: 'Where do you wish to go?');
    }
    final direction = cmd.args.first;

    // Special: Quinto Settore requires all four simulacra
    if (direction == 'up' && nodeId == 'la_soglia') {
      final hasAll = _simulacraNames.every((n) => s.inventory.contains(n));
      if (!hasAll) {
        final missing =
            _simulacraNames.where((n) => !s.inventory.contains(n)).join(', ');
        return EngineResponse(
          narrativeText: 'The fifth recess on the pedestal is dark.\n\n'
              'Four simulacra must be held before the staircase forms.\n\n'
              'You are missing: $missing.',
        );
      }
      final missingDepth = _missingDepthSectorsForQuinto(s);
      if (missingDepth.isNotEmpty) {
        return EngineResponse(
          narrativeText: _depthGateTextForQuinto(missingDepth),
        );
      }
    }

    if (nodeId == 'la_zona' && direction == 'back') {
      final canLeave = ZoneModule.canLeaveZone(
        puzzles: s.completedPuzzles,
        counters: s.puzzleCounters,
      );
      if (!canLeave) {
        return const EngineResponse(
          narrativeText: 'The Zone does not release you yet.\n\n'
              'It is still waiting for your answer.',
        );
      }
    }

    // Exit gate check (all other gates)
    final requiredPuzzle = gameRequiredPuzzleForExit(nodeId, direction);
    if (requiredPuzzle != null &&
        !s.completedPuzzles.contains(requiredPuzzle)) {
      return EngineResponse(
        narrativeText: gameGateHintForPuzzle(requiredPuzzle) ??
            'Something holds you back. A condition has not yet been met.',
      );
    }

    final dest = node.exits[direction];
    if (dest == null) {
      return const EngineResponse(
          narrativeText: 'There is nothing in that direction.');
    }
    final destNode = _nodes[dest];
    if (destNode == null) {
      return const EngineResponse(narrativeText: 'That way is not yet open.');
    }

    final gardenEnterHook = _sectorRouter.onEnterNode(
      SectorEnterContext(
        fromNode: nodeId,
        destNode: dest,
        snapshot: _sectorSnapshot(s),
      ),
    );
    if (gardenEnterHook != null) return gardenEnterHook;

    return EngineResponse(
      narrativeText: _enterNode(destNode),
      newNode: dest,
      needsDemiurge: true,
      // Siciliano BWV 1017 when entering the Fifth Sector; silence for Oblivion finale
      audioTrigger: dest == 'quinto_landing'
          ? 'siciliano'
          : dest == 'finale_acceptance'
              ? 'aria_goldberg'
              : dest == 'finale_oblivion'
                  ? 'silence'
                  : dest == 'il_nucleo'
                      ? 'oblivion'
                      : null,
    );
  }

  EngineResponse _handleWait(String nodeId, GameEngineState s) {
    final sectorResponse = _routeSectorCommand(
      cmd: const ParsedCommand(
          verb: CommandVerb.wait, args: [], rawInput: 'wait'),
      nodeId: nodeId,
      state: s,
    );
    if (sectorResponse != null) return sectorResponse;

    return const EngineResponse(
        narrativeText: 'Time passes. The Archive observes.');
  }

  EngineResponse _handleTake(
      ParsedCommand cmd, String nodeId, NodeDef node, GameEngineState s) {
    final sectorResponse = _routeSectorCommand(
      cmd: cmd,
      nodeId: nodeId,
      state: s,
    );
    if (sectorResponse != null) return sectorResponse;

    if (cmd.args.isEmpty)
      return const EngineResponse(narrativeText: 'Take what?');
    final target = cmd.args.join(' ');

    // Takeable objects (+1 weight)
    final takeMatch = node.takeable
        .where((t) => t.contains(target) || target.contains(t))
        .firstOrNull;
    if (takeMatch != null) {
      if (s.inventory.contains(takeMatch)) {
        return EngineResponse(
            narrativeText: 'You already carry the $takeMatch.');
      }
      return EngineResponse(
        narrativeText: 'You pick up the $takeMatch.\n\n'
            'It settles into your hands with the weight of a decision.',
        needsDemiurge: true,
        weightDelta: 1,
        anxietyDelta: 2,
        grantItem: takeMatch,
      );
    }

    return const EngineResponse(narrativeText: 'You cannot take that.');
  }

  EngineResponse _handleUse(
      ParsedCommand cmd, String nodeId, GameEngineState s) {
    final sectorResponse =
        _routeSectorCommand(cmd: cmd, nodeId: nodeId, state: s);
    if (sectorResponse != null) return sectorResponse;
    return const EngineResponse(
      narrativeText:
          'Nothing here responds to use in that way. Try a more specific action.',
    );
  }

  EngineResponse _handleDrop(
      ParsedCommand cmd, String nodeId, GameEngineState s) {
    final sectorResponse =
        _routeSectorCommand(cmd: cmd, nodeId: nodeId, state: s);
    if (sectorResponse != null) return sectorResponse;

    if (cmd.args.isEmpty)
      return const EngineResponse(narrativeText: 'Drop what?');
    final target = cmd.args.join(' ');

    final match = s.inventory
        .where((i) => i.contains(target) || target.contains(i))
        .firstOrNull;
    if (match == null)
      return const EngineResponse(narrativeText: 'You are not carrying that.');
    if (match == 'notebook') {
      return const EngineResponse(
        narrativeText: 'The notebook resists your hand.\n\n'
            'It is not an object you can discard here.',
      );
    }

    final isSimulacrum = _isSimulacrum(match);

    return EngineResponse(
      narrativeText: 'You set down the $match. '
          'It seems smaller without your hands around it.',
      weightDelta: isSimulacrum ? 0 : -1,
      anxietyDelta: isSimulacrum ? 0 : -1,
    );
  }

  EngineResponse _handleDeposit(String nodeId, GameEngineState s) {
    final gardenResponse = _routeSectorCommand(
      cmd: const ParsedCommand(
        verb: CommandVerb.deposit,
        args: [],
        rawInput: 'deposit',
      ),
      nodeId: nodeId,
      state: s,
    );
    if (gardenResponse != null) return gardenResponse;
    return const EngineResponse(
      narrativeText: 'There is nowhere here to deposit anything.',
    );
  }

  EngineResponse _handleSmell(String nodeId) {
    if (nodeId == 'garden_alcove_pleasures') {
      return const EngineResponse(
        narrativeText: 'The scent of linden blossom.\n\n'
            'And then — without transition — a room you knew once. '
            'Not this Archive. A door, half-open, and afternoon light through it.\n\n'
            '"The smell and taste remain for a long time, like souls."\n\n'
            'The smell fades. The room does not.',
        needsDemiurge: true,
        lucidityDelta: -5,
        anxietyDelta: 5,
        audioTrigger: 'sfx:proustian_trigger',
      );
    }
    return const EngineResponse(
        narrativeText: 'The air here carries only itself.');
  }

  EngineResponse _handleTaste(String nodeId) {
    // Proustian trigger: crystal residue in lab furnace (GDD §9)
    if (nodeId == 'lab_furnace') {
      return const EngineResponse(
        narrativeText: 'A taste of something burnt and impossibly sweet.\n\n'
            'You are elsewhere — briefly. A kitchen. A morning. '
            'Something ordinary that was, in fact, everything.\n\n'
            '"The madeleine of Combray."\n\n'
            'You return. The ash on your lips is cold.',
        needsDemiurge: true,
        lucidityDelta: -8,
        anxietyDelta: 8,
        audioTrigger: 'sfx:proustian_trigger',
      );
    }
    return const EngineResponse(
        narrativeText: 'You taste nothing of consequence.');
  }

  EngineResponse _handleWalk(
      ParsedCommand cmd, String nodeId, GameEngineState s) {
    final gardenResponse =
        _routeSectorCommand(cmd: cmd, nodeId: nodeId, state: s);
    if (gardenResponse != null) return gardenResponse;

    return const EngineResponse(
        narrativeText: 'Nothing happens. Perhaps the moment has not come.');
  }

  EngineResponse _handleArrange(
      ParsedCommand cmd, String nodeId, GameEngineState s) {
    final gardenResponse =
        _routeSectorCommand(cmd: cmd, nodeId: nodeId, state: s);
    if (gardenResponse != null) return gardenResponse;
    return const EngineResponse(
        narrativeText: 'There is nothing here to arrange.');
  }

  EngineResponse _handleWrite(
      ParsedCommand cmd, String nodeId, GameEngineState s) {
    final sectorResponse =
        _routeSectorCommand(cmd: cmd, nodeId: nodeId, state: s);
    if (sectorResponse != null) return sectorResponse;

    return const EngineResponse(
      narrativeText: 'Nothing happens. The Archive observes your writing.',
    );
  }

  EngineResponse _handleCombine(
      ParsedCommand cmd, String nodeId, GameEngineState s) {
    final sectorResponse =
        _routeSectorCommand(cmd: cmd, nodeId: nodeId, state: s);
    if (sectorResponse != null) return sectorResponse;
    return const EngineResponse(narrativeText: 'Nothing here to combine.');
  }

  EngineResponse _handlePress(
      ParsedCommand cmd, String nodeId, GameEngineState s) {
    final sectorResponse =
        _routeSectorCommand(cmd: cmd, nodeId: nodeId, state: s);
    if (sectorResponse != null) return sectorResponse;
    return const EngineResponse(narrativeText: 'Nothing here to press.');
  }

  EngineResponse _handleOffer(
      ParsedCommand cmd, String nodeId, GameEngineState s) {
    final sectorResponse =
        _routeSectorCommand(cmd: cmd, nodeId: nodeId, state: s);
    if (sectorResponse != null) return sectorResponse;
    return const EngineResponse(
        narrativeText: 'There is no one here to receive an offering.');
  }

  EngineResponse _handleMeasure(
      ParsedCommand cmd, String nodeId, GameEngineState s) {
    final sectorResponse =
        _routeSectorCommand(cmd: cmd, nodeId: nodeId, state: s);
    if (sectorResponse != null) return sectorResponse;
    return const EngineResponse(narrativeText: 'Nothing here to measure.');
  }

  EngineResponse _handleCalibrate(
      ParsedCommand cmd, String nodeId, GameEngineState s) {
    final sectorResponse =
        _routeSectorCommand(cmd: cmd, nodeId: nodeId, state: s);
    if (sectorResponse != null) return sectorResponse;
    return const EngineResponse(narrativeText: 'Nothing here to calibrate.');
  }

  EngineResponse _handleInvert(
      ParsedCommand cmd, String nodeId, GameEngineState s) {
    final sectorResponse =
        _routeSectorCommand(cmd: cmd, nodeId: nodeId, state: s);
    if (sectorResponse != null) return sectorResponse;
    return const EngineResponse(narrativeText: 'Nothing here to invert.');
  }

  EngineResponse _handleConfirm(String nodeId, GameEngineState s) {
    final sectorResponse = _routeSectorCommand(
      cmd: const ParsedCommand(
        verb: CommandVerb.confirm,
        args: [],
        rawInput: 'confirm',
      ),
      nodeId: nodeId,
      state: s,
    );
    if (sectorResponse != null) return sectorResponse;
    return const EngineResponse(narrativeText: 'Nothing here to confirm.');
  }

  EngineResponse _handleBreak(
      ParsedCommand cmd, String nodeId, GameEngineState s) {
    final sectorResponse =
        _routeSectorCommand(cmd: cmd, nodeId: nodeId, state: s);
    if (sectorResponse != null) return sectorResponse;
    return const EngineResponse(
        narrativeText: 'There is nothing here to break.');
  }

  EngineResponse _handleBlow(String nodeId, GameEngineState s) {
    final sectorResponse = _routeSectorCommand(
      cmd: const ParsedCommand(
        verb: CommandVerb.blow,
        args: [],
        rawInput: 'blow',
      ),
      nodeId: nodeId,
      state: s,
    );
    if (sectorResponse != null) return sectorResponse;
    return const EngineResponse(narrativeText: 'Nothing here to blow into.');
  }

  EngineResponse _handleSetParam(
      ParsedCommand cmd, String nodeId, GameEngineState s) {
    final sectorResponse =
        _routeSectorCommand(cmd: cmd, nodeId: nodeId, state: s);
    if (sectorResponse != null) return sectorResponse;
    return const EngineResponse(
      narrativeText: 'Nothing here accepts parameter adjustments.',
    );
  }

  EngineResponse _handleObserve(String nodeId, GameEngineState s) {
    final sectorResponse = _routeSectorCommand(
      cmd: const ParsedCommand(
        verb: CommandVerb.observe,
        args: [],
        rawInput: 'observe',
      ),
      nodeId: nodeId,
      state: s,
    );
    if (sectorResponse != null) return sectorResponse;

    return const EngineResponse(
      narrativeText:
          'Observation changes nothing yet. Perhaps another verb belongs here.',
    );
  }

  EngineResponse _handleEnterValue(
      ParsedCommand cmd, String nodeId, GameEngineState s) {
    final sectorResponse =
        _routeSectorCommand(cmd: cmd, nodeId: nodeId, state: s);
    if (sectorResponse != null) return sectorResponse;
    return const EngineResponse(
        narrativeText: 'There is nothing here that accepts an entry.');
  }

  EngineResponse _handleDecipher(String nodeId, GameEngineState s) {
    final sectorResponse = _routeSectorCommand(
      cmd: const ParsedCommand(
        verb: CommandVerb.decipher,
        args: [],
        rawInput: 'decipher',
      ),
      nodeId: nodeId,
      state: s,
    );
    if (sectorResponse != null) return sectorResponse;
    return const EngineResponse(
        narrativeText: 'There is nothing here to decipher.');
  }

  EngineResponse _handleCollect(
      ParsedCommand cmd, String nodeId, GameEngineState s) {
    final sectorResponse =
        _routeSectorCommand(cmd: cmd, nodeId: nodeId, state: s);
    if (sectorResponse != null) return sectorResponse;
    return const EngineResponse(
        narrativeText: 'There is nothing here to collect.');
  }

  EngineResponse _handleSay(
      ParsedCommand cmd, String nodeId, GameEngineState s) {
    final sectorResponse =
        _routeSectorCommand(cmd: cmd, nodeId: nodeId, state: s);
    if (sectorResponse != null) return sectorResponse;
    return const EngineResponse(
        narrativeText: 'There is no listening line here.');
  }

  EngineResponse _handleHint(
      ParsedCommand cmd, String nodeId, GameEngineState s) {
    final args = cmd.args.join(' ').toLowerCase();
    final requestedLevel = args.contains('full') ||
            args.contains('explicit') ||
            args.contains('exact')
        ? 3
        : args.contains('more') ||
                args.contains('medium') ||
                args.contains('clearer')
            ? 2
            : 1;
    final key = _hintRequestCounterKey(nodeId);
    final requestCount = (s.puzzleCounters[key] ?? 0) + 1;
    final unlockedLevel = requestCount >= 4
        ? 3
        : requestCount >= 2
            ? 2
            : 1;
    final level = min(requestedLevel, unlockedLevel);
    final hintText = _hintTextForNode(nodeId, level, s);
    final softened = requestedLevel > unlockedLevel
        ? '$hintText\n\nThe Archive withholds the final contour for now. Ask again, and it will reveal more.'
        : hintText;
    return EngineResponse(
      narrativeText: softened,
      incrementCounter: key,
    );
  }

  /// Handles commands not recognised by the parser (contextual raw-input parsing).
  EngineResponse _handleUnknown(
      ParsedCommand cmd, String nodeId, GameEngineState s) {
    final sectorResponse =
        _routeSectorCommand(cmd: cmd, nodeId: nodeId, state: s);
    if (sectorResponse != null) return sectorResponse;

    return EngineResponse(
      narrativeText: _randomUnknownFallback(),
      needsDemiurge: true,
    );
  }

  // ── New handlers ─────────────────────────────────────────────────────────────

  EngineResponse _handleDrink(String nodeId, GameEngineState s) {
    final sectorResponse = _routeSectorCommand(
      cmd: const ParsedCommand(
        verb: CommandVerb.drink,
        args: [],
        rawInput: 'drink',
      ),
      nodeId: nodeId,
      state: s,
    );
    if (sectorResponse != null) return sectorResponse;
    return const EngineResponse(
        narrativeText: 'There is nothing to drink here.');
  }

  EngineResponse _handleStir(String nodeId, GameEngineState s) {
    final sectorResponse = _routeSectorCommand(
      cmd: const ParsedCommand(
        verb: CommandVerb.stir,
        args: [],
        rawInput: 'stir',
      ),
      nodeId: nodeId,
      state: s,
    );
    if (sectorResponse != null) return sectorResponse;
    return const EngineResponse(narrativeText: 'Nothing here to stir.');
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _enterNode(NodeDef node) {
    final title = node.title.isEmpty ? '' : '${node.title}\n\n';
    return '$title${node.description}';
  }

  String _hintTextForNode(String nodeId, int level, GameEngineState s) {
    switch (nodeId) {
      case 'garden_grove':
        return _selectHint(level, const [
          'The statue is asking for relinquishment, not acquisition.',
          'You must pass through pleasure and pain before the statue accepts what you carry.',
          'Relinquish one useful object, one identity-bound object, and one pain-bound object; then deposit everything at the statue.',
        ]);
      case 'gallery_copies':
        return _selectHint(level, const [
          'This wing rewards noticing absence.',
          'The copies are incomplete. Name what is missing more than once.',
          'Use describe / write / paint three times to identify the missing elements in the copies.',
        ]);
      case 'gallery_originals':
        return _selectHint(level, const [
          'This room refuses brevity.',
          'The canvas wants a specific invented work, not a sentence.',
          'Paint or describe an imaginary artwork in at least fifty words.',
        ]);
      case 'gallery_central':
        return _selectHint(level, const [
          'The mirror is not solved by contemplation alone.',
          'To gain the simulacrum, you must break the mirror with empty enough hands.',
          'When your psychological weight is 0, break mirror to receive The Proportion.',
        ]);
      case 'lab_substances':
        return _selectHint(level, const [
          'The triangle names three principles before it opens three paths.',
          'The symbols must be understood before the substances can be gathered.',
          'Use decipher symbols, then collect mercury, collect sulphur, and collect salt.',
        ]);
      case 'lab_great_work':
        return _selectHint(level, [
          'Order matters more than substance here.',
          'The circles accept a planetary descent, one stage at a time.',
          'Place each substance in order: Saturn → Jupiter → Mars → Sun → Venus → Mercury → Moon.',
        ]);
      case 'lab_sealed':
        return _selectHint(level, const [
          'The last reagent is not material.',
          'The chamber is waiting for something only a living body can provide.',
          'Blow into the alembic to complete the sector and receive The Catalyst.',
        ]);
      case 'quinto_ritual_chamber':
        return _selectHint(level, const [
          'The cup wants what the four sectors taught you.',
          'Each simulacrum must be placed before the infusion can be completed.',
          'Place ataraxia, the constant, the proportion, and the catalyst in the cup. Then stir. Then drink.',
        ]);
      case 'quinto_childhood':
      case 'quinto_youth':
      case 'quinto_old_age':
        return _selectHint(level, const [
          'This room opens when you answer it personally.',
          'A memory-price must be written here before you can leave.',
          'Write your answer directly. The room accepts personal text, not puzzle jargon.',
        ]);
      case 'quinto_maturity':
        return _selectHint(level, const [
          'The telephone is not decorative.',
          'This room accepts a spoken answer as well as written confession.',
          'Use say [what you never said] or write it to pay the room’s price.',
        ]);
      case 'il_nucleo':
        return _selectHint(level, const [
          'The argument changes when what you carry changes.',
          'If your words fail, your burden is probably answering against you.',
          'Drop or deposit mundane items until your psychological weight is zero, then answer the Antagonist again.',
        ]);
      case 'la_zona':
        return _selectHint(level, const [
          'The Zone wants an answer, not a keyword.',
          'Short replies are rejected; it is testing sincerity, not syntax.',
          'Answer the Zone’s question in at least a few words, then use back only after it accepts your response.',
        ]);
    }

    final gatedPuzzle = _exitGates[nodeId]?.values.firstOrNull;
    if (gatedPuzzle != null && !s.completedPuzzles.contains(gatedPuzzle)) {
      final explicit = _gateHints[gatedPuzzle] ??
          'Something holds you back. A condition has not yet been met.';
      return _selectHint(level, [
        'The room yields to its governing idea, not brute force.',
        explicit.split('\n\n').first,
        explicit,
      ]);
    }

    return _selectHint(level, const [
      'Try looking closely, checking your inventory, and listening to the room’s wording.',
      'The Archive usually names the verb it expects inside the room description or help text.',
      'Use look, examine [object], inventory, help, or a more specific room action.',
    ]);
  }

  String _selectHint(int level, List<String> hints) {
    if (hints.isEmpty) return 'No hint available.';
    final rawIndex = level - 1;
    final index = rawIndex < 0
        ? 0
        : rawIndex >= hints.length
            ? hints.length - 1
            : rawIndex;
    return 'Hint ${index + 1}/${hints.length}\n\n${hints[index]}';
  }

  GameEngineState _appendMessage(GameEngineState s, GameMessage msg) {
    return s.copyWith(messages: [...s.messages, msg]);
  }

  void _applyFinalArcMetadataFromMemory({
    required String memoryKey,
    required String memoryContent,
    required Map<String, int> counters,
  }) {
    final metadata = MemoryModule.evaluateAnswerMetadataForPersistence(
      memoryKey: memoryKey,
      content: memoryContent,
    );
    if (metadata == null) return;

    counters['memory_meta_quality_sum'] =
        (counters['memory_meta_quality_sum'] ?? 0) + metadata.qualityTier;
    counters['memory_meta_specific_count'] =
        (counters['memory_meta_specific_count'] ?? 0) +
            (metadata.specific ? 1 : 0);
    counters['memory_meta_costly_count'] =
        (counters['memory_meta_costly_count'] ?? 0) + (metadata.costly ? 1 : 0);
    counters['memory_meta_contradiction_ref_count'] =
        (counters['memory_meta_contradiction_ref_count'] ?? 0) +
            (metadata.contradictionReference ? 1 : 0);
    final chamberKey = 'memory_meta_chamber_${metadata.chamber}_count';
    counters[chamberKey] = (counters[chamberKey] ?? 0) + 1;

    for (final tag in metadata.tags) {
      final tagKey = 'memory_meta_tag_${tag}_count';
      counters[tagKey] = (counters[tagKey] ?? 0) + 1;
    }
  }

  bool _shouldResetVisibleTranscript({
    required GameEngineState previousState,
    required GameEngineState currentState,
    required bool nodeChanged,
    required bool memoryWasSaved,
    required bool psychoProfileFieldsPresent,
  }) {
    return nodeChanged ||
        memoryWasSaved ||
        psychoProfileFieldsPresent ||
        // Inventory burden is tracked separately from the psycho-profile sliders.
        previousState.psychoWeight != currentState.psychoWeight ||
        !listEquals(previousState.inventory, currentState.inventory) ||
        !setEquals(
            previousState.completedPuzzles, currentState.completedPuzzles) ||
        !mapEquals(previousState.puzzleCounters, currentState.puzzleCounters);
  }

  // ── Save / load ──────────────────────────────────────────────────────────────

  String _sessionNextThread({
    required String nodeId,
    required GameEngineState engineState,
  }) {
    final raw = _hintTextForNode(nodeId, 1, engineState).trim();
    final body =
        raw.contains('\n\n') ? raw.split('\n\n').skip(1).join(' ').trim() : raw;
    if (body.isEmpty)
      return 'Listen to the room, then act on the first concrete verb.';
    return body;
  }

  String _buildSessionRecap({
    required String nodeId,
    required GameEngineState engineState,
  }) {
    final sectorLabel = gameSectorLabel(nodeId);
    final nodeTitle = gameNodeTitle(nodeId);
    final nextThread = _sessionNextThread(
      nodeId: nodeId,
      engineState: engineState,
    );
    return 'Where: $sectorLabel - $nodeTitle.\n'
        'What: ${engineState.inventory.length} items carried, burden ${engineState.psychoWeight}, ${engineState.completedPuzzles.length} thresholds crossed.\n'
        'Next: $nextThread';
  }

  /// Writes the current game state to auto-save slot 0.
  /// Fire-and-forget — exceptions are swallowed to avoid disrupting gameplay.
  Future<void> _triggerAutoSave({
    required String nodeId,
    required GameEngineState engineState,
    required String sectorLabel,
  }) async {
    try {
      final profile = ref.read(psychoProfileProvider).valueOrNull;
      await SaveService.instance.saveToSlot(
        0,
        currentNode: nodeId,
        completedPuzzles: engineState.completedPuzzles,
        puzzleCounters: engineState.puzzleCounters,
        inventory: engineState.inventory,
        psychoWeight: engineState.psychoWeight,
        lucidity: profile?.lucidity ?? DatabaseService.defaultLucidity,
        oblivionLevel:
            profile?.oblivionLevel ?? DatabaseService.defaultOblivionLevel,
        anxiety: profile?.anxiety ?? DatabaseService.defaultAnxiety,
        phase: profile?.phase ?? 1,
        awarenessLevel: profile?.awarenessLevel ?? 0,
        proustAffinity: profile?.proustAffinity ?? 0,
        tarkovskijAffinity: profile?.tarkovskijAffinity ?? 0,
        sethAffinity: profile?.sethAffinity ?? 0,
        sectorLabel: sectorLabel,
      );
    } catch (e) {
      // Auto-save failures must not interrupt gameplay, but log for diagnostics.
      // ignore: avoid_print
      print('[Archive] auto-save failed: $e');
    }
  }

  /// Saves the current game to [slot] (1–3).
  Future<void> saveToSlot(int slot) async {
    assert(slot >= 1 && slot <= 3);
    final engineState = state.valueOrNull;
    if (engineState == null) return;
    final savedState = await ref.read(gameStateProvider.future);
    final sectorLabel = gameSectorLabel(savedState.currentNode);
    await _triggerAutoSave(
      nodeId: savedState.currentNode,
      engineState: engineState,
      sectorLabel: sectorLabel,
    );
    // Re-use _triggerAutoSave logic but target the requested slot directly.
    try {
      final profile = ref.read(psychoProfileProvider).valueOrNull;
      await SaveService.instance.saveToSlot(
        slot,
        currentNode: savedState.currentNode,
        completedPuzzles: engineState.completedPuzzles,
        puzzleCounters: engineState.puzzleCounters,
        inventory: engineState.inventory,
        psychoWeight: engineState.psychoWeight,
        lucidity: profile?.lucidity ?? DatabaseService.defaultLucidity,
        oblivionLevel:
            profile?.oblivionLevel ?? DatabaseService.defaultOblivionLevel,
        anxiety: profile?.anxiety ?? DatabaseService.defaultAnxiety,
        phase: profile?.phase ?? 1,
        awarenessLevel: profile?.awarenessLevel ?? 0,
        proustAffinity: profile?.proustAffinity ?? 0,
        tarkovskijAffinity: profile?.tarkovskijAffinity ?? 0,
        sethAffinity: profile?.sethAffinity ?? 0,
        sectorLabel: sectorLabel,
      );
    } catch (_) {
      rethrow; // Manual save failures are surfaced to the caller.
    }
  }

  /// Loads [slot] and reinitialises the engine.
  /// Restores both game state and psycho profile, then enters the loaded node.
  Future<void> loadSlot(SaveSlot slot) async {
    state = const AsyncValue.loading();

    // Write slot data back to the live DB rows.
    await SaveService.instance.restoreToLive(slot);

    // Refresh providers so they re-read from the updated DB rows.
    await ref.read(gameStateProvider.notifier).saveEngineState(
          currentNode: slot.currentNode,
          completedPuzzles: slot.completedPuzzles,
          puzzleCounters: slot.puzzleCounters,
          inventory: slot.inventory,
          psychoWeight: slot.psychoWeight,
        );
    // Write the full psycho profile directly (not as deltas).
    final db = await DatabaseService.instance.database;
    await db.update(
        'psycho_profile',
        {
          'lucidity': slot.lucidity,
          'oblivion_level': slot.oblivionLevel,
          'anxiety': slot.anxiety,
          'phase': slot.phase,
          'awareness_level': slot.awarenessLevel,
          'proust_affinity': slot.proustAffinity,
          'tarkovskij_affinity': slot.tarkovskijAffinity,
          'seth_affinity': slot.sethAffinity,
        },
        where: 'id = 1');
    // Force the provider to reload from the updated DB row.
    ref.invalidate(psychoProfileProvider);
    await ref.read(psychoProfileProvider.future);
    DemiurgeService.instance.restorePhase(slot.phase);

    final slotQuoteExposure = slot.puzzleCounters['quote_exposure_seen'] ?? 0;
    _sessionQuoteExposureFloor =
        max(_sessionQuoteExposureFloor, slotQuoteExposure);

    // Build a fresh engine state from the restored data.
    final restoredState = GameEngineState(
      phase: ParserPhase.idle,
      inventory: slot.inventory,
      completedPuzzles: slot.completedPuzzles,
      puzzleCounters: slot.puzzleCounters,
      psychoWeight: slot.psychoWeight,
      quoteExposureSeen: _sessionQuoteExposureFloor,
    );
    final node = _nodes[slot.currentNode];
    final recap = _buildSessionRecap(
      nodeId: slot.currentNode,
      engineState: restoredState,
    );
    final welcomeBack = node != null ? '$recap\n\n${_enterNode(node)}' : recap;

    state = AsyncValue.data(
      restoredState.copyWith(
        messages: [GameMessage(text: welcomeBack, role: MessageRole.narrative)],
      ),
    );

    // Reset auto-save counters.
    _commandsSinceAutoSave = 0;
    _lastAutoSaveSector = slot.sectorLabel;
    _nonProductiveAttemptsByNode.clear();
  }

  /// Appends a short three-line recap to the transcript when returning to the app.
  Future<void> appendSessionRecap() async {
    final engineState = state.valueOrNull;
    if (engineState == null || engineState.phase != ParserPhase.idle) return;
    final persisted = await ref.read(gameStateProvider.future);
    final recap = _buildSessionRecap(
      nodeId: persisted.currentNode,
      engineState: engineState,
    );
    await _history.save(role: 'system', content: 'Session recap emitted.');
    await _history.save(role: 'demiurge', content: recap);
    state = AsyncValue.data(
      _appendMessage(
        engineState,
        GameMessage(text: recap, role: MessageRole.narrative),
      ),
    );
  }

  bool _isProgressiveHintEligible(CommandVerb verb) {
    return verb != CommandVerb.hint &&
        verb != CommandVerb.help &&
        verb != CommandVerb.inventory;
  }

  bool _isProductiveOutcome(EngineResponse response) {
    return response.newNode != null ||
        response.completePuzzle != null ||
        response.grantItem != null ||
        response.incrementCounter != null ||
        response.clearInventoryOnDeposit ||
        response.weightDelta != 0 ||
        response.lucidityDelta != null ||
        response.anxietyDelta != null ||
        response.oblivionDelta != null ||
        response.playerMemoryKey != null;
  }

  String? _progressiveHintSuffix({
    required ParsedCommand cmd,
    required EngineResponse response,
    required String nodeId,
    required GameEngineState stateSnapshot,
  }) {
    if (!_isProgressiveHintEligible(cmd.verb)) return null;

    if (_isProductiveOutcome(response)) {
      _nonProductiveAttemptsByNode.remove(nodeId);
      return null;
    }

    final attempts = (_nonProductiveAttemptsByNode[nodeId] ?? 0) + 1;
    _nonProductiveAttemptsByNode[nodeId] = attempts;

    if (attempts != 3 && attempts != 5) return null;
    final hintLevel = attempts == 3 ? 1 : 2;
    final hintText = _hintTextForNode(nodeId, hintLevel, stateSnapshot);
    final hintBody = hintText.contains('\n\n')
        ? hintText.split('\n\n').skip(1).join('\n\n')
        : hintText;

    return '\n\nThe Archive does not correct you. It adjusts the light.\n\n$hintBody';
  }

  /// Returns a Demiurge ("All That Is") narrative response for the given node.
  /// Selects from curated citation bundles keyed to [nodeId]'s sector.
  /// Falls back to [fallbackText] when bundles are not yet loaded or empty.
  String _callDemiurge(String fallbackText, String nodeId) {
    final sector = DemiurgeService.sectorForNode(nodeId);
    return DemiurgeService.instance.respond(
      sector: sector,
      fallbackText: fallbackText,
    );
  }

  /// Chooses between an Echo persona and the Demiurge.
  ///
  /// Priority:
  ///   1. Keyword / summon trigger (phase-independent) — e.g. "summon proust"
  ///   2. Verb-based trigger (phase-dependent) — e.g. smell → Proust in phase 2+
  ///   3. Sector-thematic trigger — input contains thematic keywords for this sector
  ///   4. Archive-meta response (Seth-voice) for fully off-topic commands
  ///   5. Demiurge fallback
  String _callNarrator(
    CommandVerb verb,
    String fallbackText,
    String nodeId,
    String rawInput,
  ) {
    final sector = DemiurgeService.sectorForNode(nodeId);

    // ── 1. Keyword / summon (always active) ────────────────────────────────
    final keywordEcho = EchoService.echoForKeywords(rawInput);
    if (keywordEcho != null) {
      final echoText = EchoService.instance.respond(keywordEcho);
      if (echoText != null) return echoText;
    }

    // ── 2. Verb-based (phase + affinity gated) ─────────────────────────────
    final profile = ref.read(psychoProfileProvider).valueOrNull;
    if (profile != null) {
      final echo = EchoService.echoForCommand(
        verb.name,
        profile.phase,
        proustAffinity: profile.proustAffinity,
        tarkovskijAffinity: profile.tarkovskijAffinity,
        sethAffinity: profile.sethAffinity,
      );
      if (echo != null) {
        final echoText = EchoService.instance.respond(echo);
        if (echoText != null) return echoText;
      }
    }

    // ── 3. Sector-thematic (input is semantically "in sector" even if not a
    //        recognised verb). Prefers the sector's primary Echo persona.
    if (EchoService.isThematicForSector(rawInput, sector)) {
      final sectorEchoName = EchoService.sectorEcho[sector];
      if (sectorEchoName != null) {
        final echoText = EchoService.instance.respond(sectorEchoName);
        if (echoText != null) return echoText;
      }
    }

    // ── 4. Archive-meta (completely off-topic unknown command).
    //        Seth's voice turns every failure into a narrative moment.
    //        Only fires for unknown verbs — recognised-but-failed commands
    //        still deserve the Demiurge's full philosophical response.
    if (verb == CommandVerb.unknown) {
      return EchoService.instance.respondMeta();
    }

    // ── 5. Demiurge fallback ────────────────────────────────────────────────
    return _callDemiurge(fallbackText, nodeId);
  }

  /// Increments awareness and per-Echo affinity based on the command verb
  /// and, for unknown verbs, on keyword recognition in [rawInput].
  /// Pure side-effect — does not alter [response] or any existing game state.
  Future<_PsychoShiftResult?> _updateAwarenessFromCommand(
    CommandVerb verb,
    EngineResponse response,
    String rawInput,
  ) async {
    int awareness = 0;
    int proust = 0;
    int tarkovskij = 0;
    int seth = 0;

    // Sensory commands awaken Proust
    if (verb == CommandVerb.smell || verb == CommandVerb.taste) {
      awareness = 5;
      proust = 5;
    }
    // Observation / slowness commands awaken Tarkovskij
    // (examine covers 'look', 'look at', 'examine'; observe covers 'watch')
    else if (verb == CommandVerb.examine || verb == CommandVerb.observe) {
      awareness = 1;
      tarkovskij = 2;
    } else if (verb == CommandVerb.wait) {
      awareness = 2;
      tarkovskij = 3;
    }
    // Creative / writing commands awaken Seth
    // (write covers 'write', 'construct', 'describe', 'paint', 'draw')
    else if (verb == CommandVerb.write) {
      awareness = 3;
      seth = 4;
    }
    // Unknown verb: distinguish keyword/summon, sector-thematic, and meta cases.
    else if (verb == CommandVerb.unknown) {
      final keywordEcho = EchoService.echoForKeywords(rawInput);
      if (keywordEcho != null) {
        // Deliberate Echo invocation — large affinity bonus.
        awareness = 4;
        if (keywordEcho == 'proust') {
          proust = 8;
        } else if (keywordEcho == 'tarkovskij') {
          tarkovskij = 8;
        } else if (keywordEcho == 'seth') {
          seth = 8;
        }
      } else {
        // Check sector-thematic — wandering in the right direction.
        // We need the current node to determine the sector; read from saved state.
        final savedNode =
            ref.read(gameStateProvider).valueOrNull?.currentNode ?? '';
        final sector = DemiurgeService.sectorForNode(savedNode);
        if (EchoService.isThematicForSector(rawInput, sector)) {
          // Thematic but unrecognised — a gentle awareness + sector affinity boost.
          awareness = 3;
          final sectorEchoName = EchoService.sectorEcho[sector];
          if (sectorEchoName == 'proust') {
            proust = 4;
          } else if (sectorEchoName == 'tarkovskij') {
            tarkovskij = 4;
          } else if (sectorEchoName == 'seth') {
            seth = 4;
          }
        } else {
          // Completely off-topic — archive-meta response fires.
          // Small awareness gain (even mistakes teach) + modest oblivion increase.
          awareness = 2;
          // Oblivion bump for meta commands is applied via anxietyDelta path
          // in the engine response, so here we just note awareness.
        }
      }
    }
    // Any other Demiurge response (unrecognised but not unknown — edge case)
    else if (response.needsDemiurge) {
      awareness = 1;
    }

    // Puzzle solutions are insight moments
    if (response.completePuzzle != null) awareness += 8;

    if (awareness == 0 && proust == 0 && tarkovskij == 0 && seth == 0) {
      return null;
    }

    final before = await ref.read(psychoProfileProvider.future);
    await ref.read(psychoProfileProvider.notifier).updateAwareness(
          awarenessDelta: awareness > 0 ? awareness : null,
          proustDelta: proust > 0 ? proust : null,
          tarkovskijDelta: tarkovskij > 0 ? tarkovskij : null,
          sethDelta: seth > 0 ? seth : null,
        );
    final after = await ref.read(psychoProfileProvider.future);

    final awarenessDelta = after.awarenessLevel - before.awarenessLevel;
    final proustDelta = after.proustAffinity - before.proustAffinity;
    final tarkovskijDelta =
        after.tarkovskijAffinity - before.tarkovskijAffinity;
    final sethDelta = after.sethAffinity - before.sethAffinity;
    final phaseChanged = after.phase > before.phase;

    final fragments = <String>[];
    if (awarenessDelta > 0) {
      fragments.add('awareness +$awarenessDelta');
    }
    if (proustDelta > 0) {
      fragments.add('proust resonance +$proustDelta');
    }
    if (tarkovskijDelta > 0) {
      fragments.add('tarkovskij resonance +$tarkovskijDelta');
    }
    if (sethDelta > 0) {
      fragments.add('seth resonance +$sethDelta');
    }

    final phaseLine =
        phaseChanged ? 'A threshold yields. Phase ${after.phase} opens.' : null;
    final shiftLine = fragments.isEmpty
        ? null
        : 'The Archive notes a shift: ${fragments.join(' | ')}.';

    if (phaseLine == null && shiftLine == null) {
      return null;
    }

    final text = phaseLine == null
        ? shiftLine!
        : shiftLine == null
            ? phaseLine
            : '$phaseLine\n$shiftLine';
    return _PsychoShiftResult(
      text: text,
      phaseChanged: phaseChanged,
    );
  }
}

// ── Help text ─────────────────────────────────────────────────────────────────

const _helpText = '''Commands:
  go [north/south/east/west/up/down]   — move
  examine [object]  /  look            — inspect
  take [object]                        — pick up (increases psychological weight)
  drop [object]                        — set down
  deposit everything                   — leave all at the statue (Garden finale)
  wait  /  z                           — let time pass
  smell [object]                       — attend to a scent
  taste [object]                       — attend to a flavour
  hint / hint more / hint full         — layered contextual guidance
  arrange leaves [order]               — Cypress Avenue puzzle
  walk [mode]      — "walk blindfolded", "walk backward", "walk through"
  combine [items]                      — Observatory Antechamber puzzle
  press [target]                       — Gallery Corridor puzzle
  construct / describe / paint / write [content]   — writing puzzles
  offer [item/concept]                 — Garden statue or Lab Vestibule puzzle
  calibrate [x] [y] [z]               — Observatory Calibration puzzle
  invert [target]                      — Observatory Dome puzzle
  confirm  /  yes                      — multi-step confirmation
  break [target]                       — Gallery finale
  blow                                 — Lab sealed chamber finale
  set temperature [value]              — Lab Alembic puzzle
  decipher symbols                     — Lab Substances puzzle
  collect [substance]                  — Lab Substances puzzle
  calcinate                            — Lab Furnace puzzle
  enter [value]                        — Observatory Archive puzzle
  observe                              — Observatory Dome finale
  place [simulacrum] in cup            — Fifth Sector ritual
  stir                                 — Fifth Sector ritual
  drink                                — Fifth Sector ritual
  say [words]                          — Maturity room (Fifth Sector)
  inventory  /  i                      — list what you carry
  wake up                              — finale epilogue (Acceptance/Testimony)
  help  /  ?                           — this message''';

String gameNodeTitle(String nodeId) => _nodes[nodeId]?.title.isNotEmpty == true
    ? _nodes[nodeId]!.title
    : 'The Archive';

String? gameRequiredPuzzleForExit(String nodeId, String direction) =>
    _exitGates[nodeId]?[direction];

String? gameGateHintForPuzzle(String puzzleId) => _gateHints[puzzleId];

int? gameDepthThresholdForSectorToQuinto(String sector) =>
    _depthThresholdsToQuinto[sector];

int gameMemoryDepthThresholdToNucleo() => MemoryModule.depthThresholdToNucleo;

int gameQuoteExposureThresholdToNucleo() =>
    MemoryModule.quoteExposureThresholdToNucleo;

bool gameGardenSteleInscriptionLooksSpecific(String text) =>
    GardenModule.steleInscriptionLooksSpecific(text);

Map<String, bool> gameGardenRelinquishmentCoverage(Iterable<String> inventory) {
  return GardenModule.relinquishmentCoverage(inventory);
}

bool gameGardenSurfaceComplete(Set<String> puzzles) =>
    GardenModule.isSurfaceComplete(puzzles);

bool gameGardenDeepComplete({
  required Set<String> puzzles,
  required Map<String, int> counters,
}) =>
    GardenModule.isDeepComplete(puzzles: puzzles, counters: counters);

BossUtteranceKind classifyBossUtterance(String rawInput) {
  final stance = NucleusAdjudication.classifyStance(rawInput);
  switch (stance) {
    case NucleusStance.oblivion:
      return BossUtteranceKind.surrender;
    case NucleusStance.eternalZone:
      return BossUtteranceKind.remain;
    case NucleusStance.acceptance:
    case NucleusStance.testimony:
      return BossUtteranceKind.resolution;
    case NucleusStance.none:
      return BossUtteranceKind.other;
  }
}

bool gameTransitEligibleForZone(String fromNodeId, String destNodeId) {
  return ZoneModule.transitEligibleForZone(fromNodeId, destNodeId);
}

String gameSectorLabel(String nodeId) {
  if (nodeId == 'intro_void' || nodeId == 'la_soglia') return 'Threshold';
  if (nodeId.startsWith('garden')) return 'Garden';
  if (nodeId.startsWith('obs_')) return 'Observatory';
  if (nodeId.startsWith('gal_') || nodeId.startsWith('gallery_'))
    return 'Gallery';
  if (nodeId.startsWith('lab_')) return 'Laboratory';
  if (nodeId.startsWith('quinto_') || nodeId.startsWith('memory_'))
    return 'Memory';
  if (nodeId.startsWith('finale_') || nodeId == 'il_nucleo') return 'Finale';
  if (nodeId == 'la_zona') return 'Zone';
  return 'Archive';
}

/// All node IDs defined in the game. Exposed for static analysis and traversal tests.
Set<String> gameAllNodeIds() => Set<String>.unmodifiable(_nodes.keys.toSet());

/// All exits from [nodeId] as a direction → destination map.
/// Returns an empty map when [nodeId] is unknown or the node has no exits.
Map<String, String> gameExitsForNode(String nodeId) =>
    Map<String, String>.unmodifiable(_nodes[nodeId]?.exits ?? const {});

// ── Provider ──────────────────────────────────────────────────────────────────

final gameEngineProvider =
    AsyncNotifierProvider<GameEngineNotifier, GameEngineState>(
        GameEngineNotifier.new);
