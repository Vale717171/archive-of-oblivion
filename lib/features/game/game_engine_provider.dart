// lib/features/game/game_engine_provider.dart
// Author: GitHub Copilot — 2026-04-02
// Riverpod AsyncNotifier that drives the game loop.
// Holds the visible message history, current inventory, and psychological weight.
// Delegates navigation + weight to existing providers (gameStateProvider,
// psychoProfileProvider). Persists every exchange via DialogueHistoryService.
//
// LLM integration: stub only — replace _llmStub() with the real on-device call
// after Fase 0-omega validation (GDD section 17).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/dialogue_history_service.dart';
import '../parser/parser_service.dart';
import '../parser/parser_state.dart';
import '../state/game_state_provider.dart';
import '../state/psycho_provider.dart';

// ── Node data ────────────────────────────────────────────────────────────────

class _NodeDef {
  final String title;
  final String description;

  /// exits: direction/keyword → nodeId
  final Map<String, String> exits;

  /// examines: object keyword → display text
  final Map<String, String> examines;

  /// Objects the player can take; each adds +1 psychological weight.
  final Set<String> takeable;

  /// Simulacra: takeable but add 0 weight (the Archive's lesson).
  final Set<String> simulacra;

  const _NodeDef({
    required this.title,
    required this.description,
    required this.exits,
    this.examines = const <String, String>{},
    this.takeable = const <String>{},
    this.simulacra = const <String>{},
  });
}

// Nodes are defined in English as required by the GDD (section 1).
// Future: move bundle text to assets/texts/*.json (GDD section 18).
const Map<String, _NodeDef> _nodes = {
  // ── Starting void ────────────────────────────────────────────────────────
  'intro_void': _NodeDef(
    title: '',
    description: 'Silence.\n\n'
        'Then — awareness.\n\n'
        'You exist. You do not know why. A name surfaces and dissolves '
        'before you can hold it. There is no floor beneath you, no ceiling '
        'above. Only a faint luminescence that seems to come from everywhere '
        'and nowhere.\n\n'
        'In your pocket: a small empty Notebook.\n\n'
        'A path forms ahead.',
    exits: {'north': 'la_soglia', 'forward': 'la_soglia', 'ahead': 'la_soglia'},
    examines: {
      'notebook': 'A small notebook. Its pages are perfectly blank. '
          'The cover bears a symbol you almost recognise — then do not.',
      'light': 'It does not come from any source. It simply is.',
      'path': 'It was not there before. Now it leads north.',
    },
    takeable: {'notebook'},
  ),

  // ── The Threshold (hub) ───────────────────────────────────────────────────
  'la_soglia': _NodeDef(
    title: 'The Threshold',
    description: 'A circular rotunda of black marble veined with silver.\n\n'
        'Four doors stand at the cardinal points: amber to the north, '
        'cobalt blue to the east, golden to the south, violet to the west. '
        'At the centre, a pentagonal pedestal holds five recesses — each '
        'shaped for something you have not yet found.\n\n'
        'A clock without hands marks time in no direction you recognise.',
    exits: {
      'north': 'garden_portico',
      'east': 'observatory_stub',
      'south': 'gallery_stub',
      'west': 'lab_stub',
    },
    examines: {
      'pedestal': 'Five recesses. '
          'You read the inscribed names: Ataraxia. The Constant. Proportion. '
          'The Catalyst. A fifth shape you cannot name.',
      'clock': 'The numerals run counterclockwise. The hands are absent. '
          'Time, it seems, is not measured here — only observed.',
      'door': 'Four doors. The amber one to the north is ajar.',
      'north door': 'Amber, warm, slightly ajar. Beyond it: the scent of earth.',
      'east door': 'Cobalt blue, cold to the eye. A faint hum behind the glass.',
      'south door': 'Golden, polished to a mirror. Your reflection is slightly wrong.',
      'west door': 'Violet, heavy. The grain of the wood runs upward.',
    },
  ),

  // ── Garden of Epicurus ────────────────────────────────────────────────────
  'garden_portico': _NodeDef(
    title: 'The Garden of Epicurus — Portico',
    description: 'The amber door opens onto stillness.\n\n'
        'A portico of worn stone columns. Inscriptions run along each shaft. '
        'Beyond them, a path of pale stone leads north through cypress trees '
        'so tall their crowns disappear. The air carries a faint sweetness '
        'you cannot name.',
    exits: {
      'north': 'garden_cypress',
      'south': 'la_soglia',
      'back': 'la_soglia',
    },
    examines: {
      'columns': 'Each column bears a single word:\n'
          'ataraxia — aponia — philia — phronesis.\n'
          'The order, you sense, is not alphabetical.',
      'path': 'Cypress trees stand like sentinels. Their shadows are '
          'perfectly still despite a breeze you cannot feel but know is there.',
      'sweetness': 'You try to locate it. It fades as you focus. '
          'Perhaps it was never a smell at all.',
    },
  ),

  'garden_cypress': _NodeDef(
    title: 'Cypress Avenue',
    description: 'A long avenue of cypress trees.\n\n'
        'Leaves have fallen across the stone path, each perfectly preserved, '
        'each bearing a single word in faded ink. They are not arranged in '
        'any obvious order.\n\n'
        'To the north, the avenue opens onto a dry fountain.',
    exits: {
      'north': 'garden_fountain',
      'south': 'garden_portico',
    },
    examines: {
      'leaves': 'You crouch and read the words:\n'
          'pleasure — friendship — prudence — tranquillity — '
          'memory — simplicity — absence.\n\n'
          'They belong to an order. You sense it, but cannot yet name it.',
      'trees': 'Cypress trees, impossibly tall. Their roots disappear '
          'into ground that seems to have no depth.',
      'words': 'Seven words on seven leaves. One of them, you notice, '
          'is slightly darker than the rest.',
    },
  ),

  'garden_fountain': _NodeDef(
    title: 'Dry Fountain',
    description: 'A stone fountain, long dry.\n\n'
        'Its basin holds nothing but a fine grey dust. '
        'The air here is preternaturally still.\n\n'
        'Carved along the rim: "That which satisfies the body is sufficient '
        'for happiness." The stone is worn smooth, as if by many hands.\n\n'
        'To the north: a circle of standing stones.',
    exits: {
      'north': 'garden_stelae',
      'south': 'garden_cypress',
    },
    examines: {
      'fountain': 'Empty. The stone is worn smooth by many hands before yours.',
      'dust': 'Fine as ash. When you breathe on it, it forms brief, '
          'illegible shapes before settling again.',
      'inscription': '"That which satisfies the body is sufficient for happiness."\n'
          'You do not know who wrote it. You know it was not written for you.',
    },
  ),

  'garden_stelae': _NodeDef(
    title: 'Circle of Stelae',
    description: 'A circle of standing stones, each inscribed with a maxim.\n\n'
        'You count eleven. The twelfth stele is blank — its surface '
        'smooth and waiting. A stylus lies at its base.\n\n'
        'To the south, the dry fountain. To the north, the grove.',
    exits: {
      'north': 'garden_grove',
      'south': 'garden_fountain',
    },
    examines: {
      'stelae': 'Eleven maxims. The eleventh reads: '
          '"Death is nothing to us." The twelfth stele is blank.',
      'blank stele': 'Smooth stone. A stylus at its base. '
          'The missing maxim is known only to those who have understood the others.',
      'stylus': 'A simple instrument. It waits.',
    },
    takeable: {'stylus'},
  ),

  'garden_grove': _NodeDef(
    title: "Central Grove — Epicurus' Statue",
    description: 'A clearing of ancient trees.\n\n'
        'At the centre stands a marble statue of a seated figure. '
        'Its hands rest open on its knees, palms upward, holding nothing. '
        'The expression is one of complete, undemonstrative peace.\n\n'
        'To the east and west: two alcoves in the treeline.\n'
        'To the south: the circle of stelae.',
    exits: {
      'east': 'garden_alcove_pleasures',
      'west': 'garden_alcove_pains',
      'south': 'garden_stelae',
    },
    examines: {
      'statue': 'The hands hold nothing. The face asks nothing. '
          'You have the feeling it has been waiting for you specifically, '
          'and is not surprised you took this long.',
      'trees': 'Ancient. Still. Their roots break the stone path '
          'in patterns that almost look deliberate.',
      'clearing': 'No wind reaches here. Even sound seems to arrive '
          'slightly after it should.',
    },
  ),

  'garden_alcove_pleasures': _NodeDef(
    title: 'Alcove of Pleasures',
    description: 'A small alcove off the grove.\n\n'
        'Objects are arranged on low shelves: a coin worn smooth, '
        'a leather-bound book with gilded edges, a brass compass, '
        'a small oil lamp. Each is beautiful. Each gives you the '
        'faint sense that acquiring it would be a mistake.\n\n'
        'A linden tree grows in the corner. Its flowers are open.',
    exits: {'west': 'garden_grove', 'back': 'garden_grove'},
    examines: {
      'coin': 'A coin from no era you recognise. Heads: a face. '
          'Tails: the same face, older.',
      'book': 'The gilded title has worn away. Inside, every page is filled '
          'with handwriting you almost recognise as your own.',
      'compass': 'The needle points consistently in a direction '
          'that changes every time you look away.',
      'lamp': 'The flame is lit. You do not remember lighting it.',
      'linden': 'A linden tree in full flower. The scent is very faint — '
          'and then, suddenly, overwhelming.',
      'flowers': 'You lean close. A smell — not just of flowers, but of '
          'something older. A door somewhere. A specific afternoon.',
    },
    takeable: {'coin', 'book', 'compass', 'lamp'},
  ),

  'garden_alcove_pains': _NodeDef(
    title: 'Alcove of Pains',
    description: 'A small alcove off the grove.\n\n'
        'Objects here too: a rusted key, a torn page, '
        'a cracked mirror shard, a handful of dried earth.\n\n'
        'They are less beautiful than those across the grove. '
        'That, somehow, makes them harder to leave.',
    exits: {'east': 'garden_grove', 'back': 'garden_grove'},
    examines: {
      'key': 'Rusted. You do not know what it opens. '
          'You suspect the lock no longer exists.',
      'page': 'A single torn page. The text is in a language you do not '
          'speak, but you understand one word: remember.',
      'mirror': 'A shard of mirror. Your reflection is correct. '
          'That is somehow the most unsettling thing about this place.',
      'earth': 'Dry. Dark. The smell of it is the smell of the end of summer.',
    },
    takeable: {'key', 'page', 'mirror shard', 'earth'},
  ),

  // ── Sector stubs (not yet implemented) ───────────────────────────────────
  'observatory_stub': _NodeDef(
    title: 'The Blind Observatory',
    description: 'The cobalt door has not yet opened to you.\n\n'
        'A whisper through the gap: "Uncertainty is not ignorance. '
        'It is the only honest description of what is."',
    exits: {'west': 'la_soglia', 'back': 'la_soglia'},
  ),

  'gallery_stub': _NodeDef(
    title: 'The Gallery of Mirrors',
    description: 'The golden door shows you only yourself.\n\n'
        'You are not ready to see what it shows.',
    exits: {'north': 'la_soglia', 'back': 'la_soglia'},
  ),

  'lab_stub': _NodeDef(
    title: 'The Alchemical Laboratory',
    description: 'The violet door is sealed.\n\n'
        'Through the wood: a smell of sulphur and something sweeter. '
        'The transformation has not yet begun.',
    exits: {'east': 'la_soglia', 'back': 'la_soglia'},
  ),
};

// ── Engine state ──────────────────────────────────────────────────────────────

class GameEngineState {
  final List<GameMessage> messages;
  final ParserPhase phase;
  final int psychoWeight;
  final List<String> inventory;

  const GameEngineState({
    this.messages = const [],
    this.phase = ParserPhase.idle,
    this.psychoWeight = 0,
    this.inventory = const [],
  });

  GameEngineState copyWith({
    List<GameMessage>? messages,
    ParserPhase? phase,
    int? psychoWeight,
    List<String>? inventory,
  }) {
    return GameEngineState(
      messages: messages ?? this.messages,
      phase: phase ?? this.phase,
      psychoWeight: psychoWeight ?? this.psychoWeight,
      inventory: inventory ?? this.inventory,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class GameEngineNotifier extends AsyncNotifier<GameEngineState> {
  final _history = DialogueHistoryService.instance;

  @override
  Future<GameEngineState> build() async {
    // ref.read (not watch) — avoids resetting the message list on every navigation
    final savedState = await ref.read(gameStateProvider.future);
    final node = _nodes[savedState.currentNode] ?? _nodes['intro_void']!;
    final intro = _enterNode(node);

    await _history.save(role: 'system', content: 'Session started: ${node.title}');

    return GameEngineState(
      messages: [GameMessage(text: intro, role: MessageRole.narrative)],
      phase: ParserPhase.idle,
    );
  }

  /// Process raw player input through the full state machine cycle.
  Future<void> processInput(String raw) async {
    final current = state.valueOrNull;
    if (current == null || current.phase != ParserPhase.idle) return;

    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;

    // ── PARSING ──────────────────────────────────────────────────────────
    state = AsyncValue.data(current.copyWith(phase: ParserPhase.parsing));
    final cmd = ParserService.parse(trimmed);

    // Append player message to history
    final withPlayer = _appendMessage(
      current.copyWith(phase: ParserPhase.evaluating),
      GameMessage(text: '> $trimmed', role: MessageRole.player),
    );
    state = AsyncValue.data(withPlayer);

    await _history.save(role: 'user', content: trimmed);

    // ── EVALUATING ───────────────────────────────────────────────────────
    final savedState = await ref.read(gameStateProvider.future);
    final currentNodeId = savedState.currentNode;

    final response = _evaluate(cmd, currentNodeId, withPlayer);

    // ── EVENT_RESOLVED ───────────────────────────────────────────────────
    state = AsyncValue.data(withPlayer.copyWith(phase: ParserPhase.eventResolved));

    // Apply state changes
    int newWeight = withPlayer.psychoWeight + response.weightDelta;
    List<String> newInventory = List.from(withPlayer.inventory);

    if (response.weightDelta > 0 && cmd.verb == CommandVerb.take && cmd.args.isNotEmpty) {
      final item = cmd.args.join(' ');
      if (!newInventory.contains(item)) newInventory.add(item);
    }
    if (cmd.verb == CommandVerb.drop && cmd.args.isNotEmpty) {
      final item = cmd.args.join(' ');
      newInventory.remove(item);
    }
    if (cmd.verb == CommandVerb.deposit) {
      newInventory.clear();
      newWeight = 0;
    }

    if (response.newNode != null) {
      await ref.read(gameStateProvider.notifier).updateNode(response.newNode!);
    }

    // Apply psycho profile changes
    if (response.anxietyDelta != null ||
        response.lucidityDelta != null ||
        response.oblivionDelta != null) {
      final profile = await ref.read(psychoProfileProvider.future);
      await ref.read(psychoProfileProvider.notifier).updateParameter(
            lucidity: response.lucidityDelta != null
                ? (profile.lucidity + response.lucidityDelta!).clamp(0, 100)
                : null,
            anxiety: response.anxietyDelta != null
                ? (profile.anxiety + response.anxietyDelta!).clamp(0, 100)
                : null,
            oblivionLevel: response.oblivionDelta != null
                ? (profile.oblivionLevel + response.oblivionDelta!).clamp(0, 100)
                : null,
          );
    }

    // ── DISPLAYING ───────────────────────────────────────────────────────
    final narrativeText =
        response.needsLlm ? await _llmStub(response.narrativeText) : response.narrativeText;

    await _history.save(role: 'llm', content: narrativeText);

    final withNarrative = _appendMessage(
      withPlayer.copyWith(
        phase: ParserPhase.displaying,
        psychoWeight: newWeight,
        inventory: newInventory,
      ),
      GameMessage(text: narrativeText, role: MessageRole.narrative),
    );
    state = AsyncValue.data(withNarrative);

    // Small delay so the UI can render the typewriter effect before idle
    await Future.delayed(const Duration(milliseconds: 100));
    state = AsyncValue.data(withNarrative.copyWith(phase: ParserPhase.idle));
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  EngineResponse _evaluate(
    ParsedCommand cmd,
    String nodeId,
    GameEngineState engineState,
  ) {
    final node = _nodes[nodeId];

    if (node == null) {
      return const EngineResponse(
        narrativeText: 'The Archive does not recognise this place.',
      );
    }

    switch (cmd.verb) {
      case CommandVerb.help:
        return const EngineResponse(narrativeText: _helpText);

      case CommandVerb.inventory:
        return EngineResponse(
          narrativeText: engineState.inventory.isEmpty
              ? 'You carry nothing but a sense of incompleteness.'
              : 'You carry: ${engineState.inventory.join(", ")}.\n'
                  'Psychological weight: ${engineState.psychoWeight}.',
        );

      case CommandVerb.examine:
        return _handleExamine(cmd, node);

      case CommandVerb.go:
        return _handleGo(cmd, node);

      case CommandVerb.wait:
        return _handleWait(nodeId);

      case CommandVerb.take:
        return _handleTake(cmd, node, engineState);

      case CommandVerb.drop:
        return _handleDrop(cmd, engineState);

      case CommandVerb.deposit:
        return _handleDeposit(nodeId, engineState);

      case CommandVerb.smell:
        return _handleSmell(nodeId);

      case CommandVerb.taste:
        return _handleTaste(nodeId);

      case CommandVerb.walk:
        return _handleWalk(cmd, nodeId);

      case CommandVerb.arrange:
        return _handleArrange(nodeId);

      case CommandVerb.unknown:
        return const EngineResponse(
          narrativeText: 'The Archive does not understand.',
        );

      default:
        return const EngineResponse(
          narrativeText: 'Nothing happens. Perhaps the moment has not come.',
        );
    }
  }

  EngineResponse _handleExamine(ParsedCommand cmd, _NodeDef node) {
    if (cmd.args.isEmpty) {
      // "look" with no target = re-describe the room
      return EngineResponse(
        narrativeText: _enterNode(node),
        needsLlm: true,
      );
    }
    final target = cmd.args.join(' ');
    // Fuzzy match: accept if any key contains the target or vice versa
    final match = node.examines.entries
        .where((e) => e.key.contains(target) || target.contains(e.key))
        .map((e) => e.value)
        .firstOrNull;

    if (match != null) {
      return EngineResponse(narrativeText: match, needsLlm: true);
    }
    return const EngineResponse(
      narrativeText: 'You observe it closely. It offers nothing new.',
    );
  }

  EngineResponse _handleGo(ParsedCommand cmd, _NodeDef node) {
    if (cmd.args.isEmpty) {
      return const EngineResponse(narrativeText: 'Where do you wish to go?');
    }
    final direction = cmd.args.first;
    final dest = node.exits[direction];
    if (dest != null) {
      final destNode = _nodes[dest];
      if (destNode == null) {
        return const EngineResponse(narrativeText: 'That way is not yet open.');
      }
      return EngineResponse(
        narrativeText: _enterNode(destNode),
        newNode: dest,
        needsLlm: true,
      );
    }
    return const EngineResponse(
      narrativeText: 'There is nothing in that direction.',
    );
  }

  EngineResponse _handleWait(String nodeId) {
    if (nodeId == 'garden_fountain') {
      return const EngineResponse(
        narrativeText:
            'You wait.\n\nNothing comes. You wait again.\n\nA third time — and in the '
            'silence, a single drop of condensation forms at the fountain\'s lip, '
            'slides down the stone, and disappears into the dust.\n\n'
            'You have learned something. You are not sure what.',
        needsLlm: true,
        lucidityDelta: 3,
      );
    }
    return const EngineResponse(
      narrativeText: 'Time passes. The Archive observes.',
    );
  }

  EngineResponse _handleTake(
    ParsedCommand cmd,
    _NodeDef node,
    GameEngineState engineState,
  ) {
    if (cmd.args.isEmpty) {
      return const EngineResponse(narrativeText: 'Take what?');
    }
    final target = cmd.args.join(' ');

    // Check simulacra first (0 weight)
    final isSimulacrum = node.simulacra.any(
      (s) => s.contains(target) || target.contains(s),
    );
    if (isSimulacrum) {
      final name = node.simulacra.firstWhere(
        (s) => s.contains(target) || target.contains(s),
      );
      return EngineResponse(
        narrativeText: 'You take the $name. It weighs nothing.',
        needsLlm: true,
        weightDelta: 0,
      );
    }

    // Check takeable objects (+1 weight)
    final isTakeable = node.takeable.any(
      (t) => t.contains(target) || target.contains(t),
    );
    if (isTakeable) {
      final name =
          node.takeable.firstWhere((t) => t.contains(target) || target.contains(t));
      return EngineResponse(
        narrativeText: 'You pick up the $name.\n\n'
            'It settles into your hands with the comfortable weight of a decision.',
        needsLlm: true,
        weightDelta: 1,
        anxietyDelta: 2,
      );
    }

    return const EngineResponse(
      narrativeText: 'You cannot take that.',
    );
  }

  EngineResponse _handleDrop(ParsedCommand cmd, GameEngineState engineState) {
    if (cmd.args.isEmpty) {
      return const EngineResponse(narrativeText: 'Drop what?');
    }
    final target = cmd.args.join(' ');
    final match = engineState.inventory
        .where((i) => i.contains(target) || target.contains(i))
        .firstOrNull;
    if (match != null) {
      return EngineResponse(
        narrativeText: 'You set down the $match. It seems smaller without your hands around it.',
        weightDelta: -1,
        anxietyDelta: -1,
      );
    }
    return const EngineResponse(narrativeText: 'You are not carrying that.');
  }

  EngineResponse _handleDeposit(String nodeId, GameEngineState engineState) {
    if (nodeId != 'garden_grove') {
      return const EngineResponse(
        narrativeText: 'There is nowhere here to deposit anything.',
      );
    }
    if (engineState.inventory.isEmpty) {
      return const EngineResponse(
        narrativeText: 'You carry nothing. The statue\'s open hands seem to already know this.',
        needsLlm: true,
      );
    }
    return const EngineResponse(
      narrativeText:
          'You place everything you carry at the statue\'s feet.\n\n'
          'The objects arrange themselves in a loose circle without you touching them. '
          'They look smaller than you remember.\n\n'
          'The statue\'s expression does not change. You feel, for the first time '
          'in this place, something that resembles relief.\n\n'
          'In one of the open hands, where nothing rested a moment ago: '
          'a glass sphere, perfectly empty. Ataraxia.',
      needsLlm: true,
      // weightDelta is intentionally 0 here: processInput detects CommandVerb.deposit
      // and resets both inventory and psychoWeight to 0 unconditionally, regardless
      // of the current weight value (GDD section 6 — "deposit everything" zeroes the burden).
      weightDelta: 0,
      lucidityDelta: 10,
      anxietyDelta: -20,
      audioTrigger: 'calm',
    );
  }

  EngineResponse _handleSmell(String nodeId) {
    if (nodeId == 'garden_alcove_pleasures') {
      return const EngineResponse(
        narrativeText:
            'The scent of linden blossom.\n\n'
            'And then — without transition — a room you knew once. '
            'Not this Archive. Not a memory you can name. '
            'A door, half-open, and afternoon light coming through it.\n\n'
            '"l\'odore e il sapore restano ancora a lungo, come anime."\n\n'
            'The smell fades. The room does not.',
        needsLlm: true,
        lucidityDelta: -5,
        anxietyDelta: 5,
        audioTrigger: 'sfx:proustian_trigger',
      );
    }
    return const EngineResponse(
      narrativeText: 'The air here carries only itself.',
    );
  }

  EngineResponse _handleTaste(String nodeId) {
    // Proustian trigger: will match the crucible room once the Lab sector is implemented
    if (nodeId == 'lab_stub') {
      return const EngineResponse(
        narrativeText:
            'A taste of something burnt and sweet.\n\n'
            'You are somewhere else entirely, briefly — then back.',
        needsLlm: true,
        lucidityDelta: -8,
        audioTrigger: 'sfx:proustian_trigger',
      );
    }
    return const EngineResponse(
      narrativeText: 'You taste nothing of consequence.',
    );
  }

  EngineResponse _handleWalk(ParsedCommand cmd, String nodeId) {
    final mode = cmd.args.join(' ');
    if (nodeId == 'garden_alcove_pleasures' && mode == 'through') {
      return const EngineResponse(
        narrativeText:
            'You walk through without touching anything.\n\n'
            'It is harder than it sounds.',
        needsLlm: true,
        lucidityDelta: 5,
      );
    }
    return const EngineResponse(
      narrativeText: 'Nothing happens. Perhaps the moment has not come.',
    );
  }

  EngineResponse _handleArrange(String nodeId) {
    if (nodeId == 'garden_cypress') {
      return const EngineResponse(
        narrativeText:
            'The leaves shift at your touch — then settle back unchanged.\n\n'
            'The order matters. You need to understand it before you can name it.\n\n'
            'Hint: arrange leaves [word, word, word…] — seven words, '
            'in Epicurean order.',
      );
    }
    return const EngineResponse(
      narrativeText: 'There is nothing here to arrange.',
    );
  }

  String _enterNode(_NodeDef node) {
    final title = node.title.isEmpty ? '' : '${node.title}\n\n';
    return '$title${node.description}';
  }

  GameEngineState _appendMessage(GameEngineState s, GameMessage msg) {
    return s.copyWith(messages: [...s.messages, msg]);
  }

  /// LLM stub — returns the engine text as-is until Fase 0-omega.
  /// Replace this method with the actual on-device LLM call after validation.
  Future<String> _llmStub(String fallbackText) async {
    // TODO(post-0-omega): replace with LlmContextService + on-device model call
    return fallbackText;
  }
}

// ── Help text ────────────────────────────────────────────────────────────────

const _helpText = '''Commands:
  go [north/south/east/west]  — move
  examine [object]  /  look   — inspect
  take [object]               — pick up (may increase psychological weight)
  drop [object]               — set down
  deposit everything          — leave all at the statue (Garden finale)
  wait  /  z                  — let time pass
  smell [object]              — attend to a scent
  inventory  /  i             — list what you carry
  help  /  ?                  — this message''';

// ── Provider ─────────────────────────────────────────────────────────────────

final gameEngineProvider =
    AsyncNotifierProvider<GameEngineNotifier, GameEngineState>(
        GameEngineNotifier.new);
