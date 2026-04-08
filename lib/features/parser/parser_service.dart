// lib/features/parser/parser_service.dart
// Author: GitHub Copilot — 2026-04-02
// Pure stateless parser — converts raw text input into a ParsedCommand.
// No side effects, no state. Safe to call from any context.

import 'parser_state.dart';

class ParserService {
  static const _directions = {'n', 'north', 's', 'south', 'e', 'east', 'w', 'west'};
  static const _stopWords = {'the', 'a', 'an', 'at', 'to', 'into', 'up', 'on'};

  /// Parse [raw] input and return the best matching [ParsedCommand].
  static ParsedCommand parse(String raw) {
    final input = raw.trim().toLowerCase();

    if (input.isEmpty) {
      return ParsedCommand(verb: CommandVerb.unknown, args: const [], rawInput: raw);
    }

    // ── Single-word shortcuts ──────────────────────────────────────────────
    if (input == 'i' || input == 'inv' || input == 'inventory') {
      return ParsedCommand(verb: CommandVerb.inventory, args: const [], rawInput: raw);
    }
    if (input == 'l' || input == 'look') {
      return ParsedCommand(verb: CommandVerb.examine, args: const [], rawInput: raw);
    }
    if (input == 'wait' || input == 'z') {
      return ParsedCommand(verb: CommandVerb.wait, args: const [], rawInput: raw);
    }
    if (input == 'help' || input == '?') {
      return ParsedCommand(verb: CommandVerb.help, args: const [], rawInput: raw);
    }
    if (input == 'hint' || input == 'clue' || input == 'nudge') {
      return ParsedCommand(verb: CommandVerb.hint, args: const [], rawInput: raw);
    }
    if (input == 'confirm' || input == 'yes') {
      return ParsedCommand(verb: CommandVerb.confirm, args: const [], rawInput: raw);
    }
    // Bare direction shortcut
    if (_directions.contains(input)) {
      return ParsedCommand(
        verb: CommandVerb.go,
        args: [_normalizeDir(input)],
        rawInput: raw,
      );
    }

    // ── Multi-word commands ────────────────────────────────────────────────
    final tokens = input.split(RegExp(r'\s+'));
    final verb = tokens.first;
    final rest = _stripStopWords(tokens.skip(1).toList());

    switch (verb) {
      case 'go':
      case 'move':
      case 'head':
      case 'travel':
        if (rest.isNotEmpty && _directions.contains(rest.first)) {
          return ParsedCommand(
            verb: CommandVerb.go,
            args: [_normalizeDir(rest.first), ...rest.skip(1)],
            rawInput: raw,
          );
        }
        return ParsedCommand(verb: CommandVerb.go, args: rest, rawInput: raw);

      case 'walk':
        // "walk north" = go north; "walk through" / "walk blindfolded" = walk verb
        if (rest.isNotEmpty && _directions.contains(rest.first)) {
          return ParsedCommand(
            verb: CommandVerb.go,
            args: [_normalizeDir(rest.first), ...rest.skip(1)],
            rawInput: raw,
          );
        }
        return ParsedCommand(verb: CommandVerb.walk, args: rest, rawInput: raw);

      case 'examine':
      case 'look':
      case 'inspect':
      case 'read':
        return ParsedCommand(verb: CommandVerb.examine, args: rest, rawInput: raw);

      case 'take':
      case 'get':
      case 'pick':
        return ParsedCommand(verb: CommandVerb.take, args: rest, rawInput: raw);

      case 'drop':
      case 'put':
      case 'leave':
      case 'place':
      case 'discard':
        return ParsedCommand(verb: CommandVerb.drop, args: rest, rawInput: raw);

      case 'use':
        return ParsedCommand(verb: CommandVerb.use, args: rest, rawInput: raw);

      case 'deposit':
        return ParsedCommand(verb: CommandVerb.deposit, args: rest, rawInput: raw);

      case 'wait':
        return ParsedCommand(verb: CommandVerb.wait, args: rest, rawInput: raw);

      case 'smell':
      case 'sniff':
        return ParsedCommand(verb: CommandVerb.smell, args: rest, rawInput: raw);

      case 'taste':
      case 'lick':
        return ParsedCommand(verb: CommandVerb.taste, args: rest, rawInput: raw);

      case 'arrange':
      case 'order':
        return ParsedCommand(verb: CommandVerb.arrange, args: rest, rawInput: raw);

      case 'combine':
      case 'merge':
        return ParsedCommand(verb: CommandVerb.combine, args: rest, rawInput: raw);

      case 'press':
      case 'push':
        return ParsedCommand(verb: CommandVerb.press, args: rest, rawInput: raw);

      case 'offer':
      case 'give':
        return ParsedCommand(verb: CommandVerb.offer, args: rest, rawInput: raw);

      case 'write':
      case 'inscribe':
      case 'describe':
      case 'paint':
      case 'draw':
      case 'construct':
        return ParsedCommand(verb: CommandVerb.write, args: rest, rawInput: raw);

      case 'measure':
        return ParsedCommand(verb: CommandVerb.measure, args: rest, rawInput: raw);

      case 'calibrate':
        return ParsedCommand(verb: CommandVerb.calibrate, args: rest, rawInput: raw);

      case 'invert':
      case 'reverse':
        return ParsedCommand(verb: CommandVerb.invert, args: rest, rawInput: raw);

      case 'confirm':
      case 'yes':
        return ParsedCommand(verb: CommandVerb.confirm, args: rest, rawInput: raw);

      case 'break':
      case 'shatter':
      case 'smash':
        return ParsedCommand(verb: CommandVerb.breakObj, args: rest, rawInput: raw);

      case 'blow':
        return ParsedCommand(verb: CommandVerb.blow, args: rest, rawInput: raw);

      case 'set':
      case 'adjust':
        return ParsedCommand(verb: CommandVerb.setParam, args: rest, rawInput: raw);

      case 'drink':
      case 'sip':
        return ParsedCommand(verb: CommandVerb.drink, args: rest, rawInput: raw);

      case 'stir':
      case 'mix':
        return ParsedCommand(verb: CommandVerb.stir, args: rest, rawInput: raw);

      case 'observe':
      case 'watch':
        return ParsedCommand(verb: CommandVerb.observe, args: rest, rawInput: raw);

      case 'enter':
        return ParsedCommand(verb: CommandVerb.enterValue, args: rest, rawInput: raw);

      case 'collect':
      case 'gather':
        return ParsedCommand(verb: CommandVerb.collect, args: rest, rawInput: raw);

      case 'decipher':
      case 'decode':
      case 'translate':
        return ParsedCommand(verb: CommandVerb.decipher, args: rest, rawInput: raw);

      case 'say':
      case 'answer':
      case 'tell':
      case 'speak':
        return ParsedCommand(verb: CommandVerb.say, args: rest, rawInput: raw);

      case 'hint':
      case 'clue':
      case 'nudge':
        return ParsedCommand(verb: CommandVerb.hint, args: rest, rawInput: raw);

      case 'help':
        return ParsedCommand(verb: CommandVerb.help, args: const [], rawInput: raw);

      default:
        return ParsedCommand(verb: CommandVerb.unknown, args: tokens.skip(1).toList(), rawInput: raw);
    }
  }

  static String _normalizeDir(String d) {
    switch (d) {
      case 'n':
        return 'north';
      case 's':
        return 'south';
      case 'e':
        return 'east';
      case 'w':
        return 'west';
      default:
        return d;
    }
  }

  static List<String> _stripStopWords(List<String> tokens) =>
      tokens.where((t) => !_stopWords.contains(t)).toList();
}
