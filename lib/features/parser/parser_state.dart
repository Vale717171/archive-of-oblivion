// lib/features/parser/parser_state.dart
// Author: GitHub Copilot — 2026-04-02
// State machine models for the text parser interaction loop.
// See docs/parser_state_machine.md for the full state diagram.

/// The six phases of the parser interaction micro-loop.
///
/// Transitions:
///   idle → parsing → evaluating → llmPending → displaying → idle
///                              └─→ eventResolved → displaying → idle
///                  └─→ idle (on unrecognised command)
enum ParserPhase {
  idle,
  parsing,
  evaluating,
  llmPending,
  displaying,
  eventResolved,
}

/// All verbs the parser can recognise from player input.
enum CommandVerb {
  go, // go north/south/east/west
  examine, // examine X / look at X / look
  take, // take X / get X
  drop, // drop X
  use, // use X
  wait, // wait / z
  deposit, // deposit everything
  inventory, // inventory / i
  smell, // smell [X] — Proustian trigger
  taste, // taste [X] — Proustian trigger (Lab)
  arrange, // arrange leaves [order] — Cypress Avenue puzzle
  walk, // walk through / walk blindfolded
  combine, // combine X, Y — Observatory puzzle
  press, // press X — Gallery puzzle
  offer, // offer [concept] — Lab puzzle
  write, // write / inscribe / describe / paint / draw — creative text input
  measure, // measure X — Observatory Hall of Void
  calibrate, // calibrate X,Y,Z — Observatory Calibration Chamber
  invert, // invert X — Observatory mirror
  confirm, // confirm / yes — multi-step confirmation
  breakObj, // break / shatter — Gallery mirror
  blow, // blow X — Lab alembic finale
  setParam, // set X — Lab alembic temperature
  drink, // drink / sip — Fifth Sector ritual
  stir, // stir / mix — Fifth Sector ritual
  help, // help / ?
  unknown, // unrecognised input
}

/// A fully parsed player command, ready for the game engine.
class ParsedCommand {
  final CommandVerb verb;

  /// Normalised argument tokens (lower-case, stop words removed).
  final List<String> args;

  /// Original raw input from the player.
  final String rawInput;

  const ParsedCommand({
    required this.verb,
    required this.args,
    required this.rawInput,
  });
}

/// The game engine's response to a [ParsedCommand].
class EngineResponse {
  /// Text to display to the player (typewriter effect in UI).
  final String narrativeText;

  /// When true, [narrativeText] is a fallback; the LLM should augment it.
  final bool needsLlm;

  /// Navigate to this node (null = stay in place).
  final String? newNode;

  /// Weight delta from this action (usually +1 for taking mundane objects).
  final int weightDelta;

  /// Deltas for the psycho profile (null = no change).
  final int? lucidityDelta;
  final int? anxietyDelta;
  final int? oblivionDelta;

  /// Audio trigger key: 'calm' | 'anxious' | 'oblivion' | 'sfx:<name>'.
  final String? audioTrigger;

  const EngineResponse({
    required this.narrativeText,
    this.needsLlm = false,
    this.newNode,
    this.weightDelta = 0,
    this.lucidityDelta,
    this.anxietyDelta,
    this.oblivionDelta,
    this.audioTrigger,
  });
}

/// A single line in the visible conversation history.
class GameMessage {
  final String text;
  final MessageRole role;

  const GameMessage({required this.text, required this.role});
}

enum MessageRole {
  player, // what the player typed
  narrative, // the Archive's response
  error, // parser / engine error feedback
}
