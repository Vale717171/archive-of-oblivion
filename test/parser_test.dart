// test/parser_test.dart
//
// Unit tests for ParserService.
// Pure synchronous — no Flutter binding, no sqflite, no Riverpod.

import 'package:flutter_test/flutter_test.dart';

import 'package:archive_of_oblivion/features/parser/parser_service.dart';
import 'package:archive_of_oblivion/features/parser/parser_state.dart';

void main() {
  // ── Empty / whitespace ────────────────────────────────────────────────────

  group('empty input', () {
    test('empty string → unknown', () {
      final cmd = ParserService.parse('');
      expect(cmd.verb, CommandVerb.unknown);
      expect(cmd.args, isEmpty);
    });

    test('whitespace only → unknown', () {
      final cmd = ParserService.parse('   ');
      expect(cmd.verb, CommandVerb.unknown);
    });
  });

  // ── Single-word shortcuts ─────────────────────────────────────────────────

  group('single-word shortcuts', () {
    for (final input in ['i', 'inv', 'inventory']) {
      test('"$input" → inventory', () {
        expect(ParserService.parse(input).verb, CommandVerb.inventory);
      });
    }

    for (final input in ['l', 'look']) {
      test('"$input" → examine (no args)', () {
        final cmd = ParserService.parse(input);
        expect(cmd.verb, CommandVerb.examine);
        expect(cmd.args, isEmpty);
      });
    }

    for (final input in ['wait', 'z']) {
      test('"$input" → wait', () {
        expect(ParserService.parse(input).verb, CommandVerb.wait);
      });
    }

    for (final input in ['help', '?']) {
      test('"$input" → help', () {
        expect(ParserService.parse(input).verb, CommandVerb.help);
      });
    }

    for (final input in ['hint', 'clue', 'nudge']) {
      test('"$input" → hint', () {
        expect(ParserService.parse(input).verb, CommandVerb.hint);
      });
    }

    for (final input in ['confirm', 'yes']) {
      test('"$input" → confirm', () {
        expect(ParserService.parse(input).verb, CommandVerb.confirm);
      });
    }
  });

  // ── Bare direction shortcuts ──────────────────────────────────────────────

  group('bare direction shortcuts', () {
    test('"n" → go north', () {
      final cmd = ParserService.parse('n');
      expect(cmd.verb, CommandVerb.go);
      expect(cmd.args, ['north']);
    });

    test('"s" → go south', () {
      final cmd = ParserService.parse('s');
      expect(cmd.verb, CommandVerb.go);
      expect(cmd.args, ['south']);
    });

    test('"e" → go east', () {
      final cmd = ParserService.parse('e');
      expect(cmd.verb, CommandVerb.go);
      expect(cmd.args, ['east']);
    });

    test('"w" → go west', () {
      final cmd = ParserService.parse('w');
      expect(cmd.verb, CommandVerb.go);
      expect(cmd.args, ['west']);
    });

    test('"north" → go north', () {
      final cmd = ParserService.parse('north');
      expect(cmd.verb, CommandVerb.go);
      expect(cmd.args, ['north']);
    });
  });

  // ── Navigation verbs ──────────────────────────────────────────────────────

  group('go / move / head / travel', () {
    for (final verb in ['go', 'move', 'head', 'travel']) {
      test('"$verb north" → go north', () {
        final cmd = ParserService.parse('$verb north');
        expect(cmd.verb, CommandVerb.go);
        expect(cmd.args.first, 'north');
      });

      test('"$verb n" normalises to north', () {
        final cmd = ParserService.parse('$verb n');
        expect(cmd.verb, CommandVerb.go);
        expect(cmd.args.first, 'north');
      });
    }

    test('"go" with no args → go with empty args', () {
      final cmd = ParserService.parse('go');
      expect(cmd.verb, CommandVerb.go);
      expect(cmd.args, isEmpty);
    });

    test('"go nowhere" → go with unknown args', () {
      final cmd = ParserService.parse('go nowhere');
      expect(cmd.verb, CommandVerb.go);
      expect(cmd.args, ['nowhere']);
    });
  });

  group('walk', () {
    test('"walk north" → go north', () {
      final cmd = ParserService.parse('walk north');
      expect(cmd.verb, CommandVerb.go);
      expect(cmd.args.first, 'north');
    });

    test('"walk blindfolded" → walk verb', () {
      final cmd = ParserService.parse('walk blindfolded');
      expect(cmd.verb, CommandVerb.walk);
      expect(cmd.args, ['blindfolded']);
    });

    test('"walk backward" → walk verb', () {
      final cmd = ParserService.parse('walk backward');
      expect(cmd.verb, CommandVerb.walk);
    });
  });

  // ── Examine / look ────────────────────────────────────────────────────────

  group('examine', () {
    for (final verb in ['examine', 'look', 'inspect', 'read']) {
      test('"$verb mirror" → examine [mirror]', () {
        final cmd = ParserService.parse('$verb mirror');
        expect(cmd.verb, CommandVerb.examine);
        expect(cmd.args, ['mirror']);
      });
    }

    test('stop words stripped: "look at the mirror" → examine [mirror]', () {
      final cmd = ParserService.parse('look at the mirror');
      expect(cmd.verb, CommandVerb.examine);
      expect(cmd.args, ['mirror']);
    });
  });

  // ── Inventory manipulation ────────────────────────────────────────────────

  group('take', () {
    for (final verb in ['take', 'get', 'pick']) {
      test('"$verb book" → take [book]', () {
        final cmd = ParserService.parse('$verb book');
        expect(cmd.verb, CommandVerb.take);
        expect(cmd.args, ['book']);
      });
    }

    test('stop words stripped: "take the book" → take [book]', () {
      final cmd = ParserService.parse('take the book');
      expect(cmd.verb, CommandVerb.take);
      expect(cmd.args, ['book']);
    });
  });

  group('drop', () {
    for (final verb in ['drop', 'put', 'leave', 'place', 'discard']) {
      test('"$verb notebook" → drop [notebook]', () {
        final cmd = ParserService.parse('$verb notebook');
        expect(cmd.verb, CommandVerb.drop);
        expect(cmd.args, ['notebook']);
      });
    }
  });

  // ── Domain-specific verbs ─────────────────────────────────────────────────

  group('write / inscribe / describe / paint / draw / construct', () {
    for (final verb in ['write', 'inscribe', 'describe', 'paint', 'draw', 'construct']) {
      test('"$verb pentagon" → write [pentagon]', () {
        final cmd = ParserService.parse('$verb pentagon');
        expect(cmd.verb, CommandVerb.write);
        expect(cmd.args, ['pentagon']);
      });
    }
  });

  group('combine / merge', () {
    for (final verb in ['combine', 'merge']) {
      test('"$verb lens moon" → combine [lens, moon]', () {
        final cmd = ParserService.parse('$verb lens moon');
        expect(cmd.verb, CommandVerb.combine);
        expect(cmd.args, ['lens', 'moon']);
      });
    }
  });

  group('offer / give', () {
    for (final verb in ['offer', 'give']) {
      test('"$verb time" → offer [time]', () {
        final cmd = ParserService.parse('$verb time');
        expect(cmd.verb, CommandVerb.offer);
        expect(cmd.args, ['time']);
      });
    }
  });

  group('say / answer / tell / speak', () {
    for (final verb in ['say', 'answer', 'tell', 'speak']) {
      test('"$verb hello" → say [hello]', () {
        final cmd = ParserService.parse('$verb hello');
        expect(cmd.verb, CommandVerb.say);
        expect(cmd.args, ['hello']);
      });
    }
  });

  group('observe / watch', () {
    for (final verb in ['observe', 'watch']) {
      test('"$verb stars" → observe [stars]', () {
        final cmd = ParserService.parse('$verb stars');
        expect(cmd.verb, CommandVerb.observe);
        expect(cmd.args, ['stars']);
      });
    }
  });

  group('press / push', () {
    for (final verb in ['press', 'push']) {
      test('"$verb tile" → press [tile]', () {
        final cmd = ParserService.parse('$verb tile');
        expect(cmd.verb, CommandVerb.press);
      });
    }
  });

  group('other domain verbs', () {
    test('"smell" → smell', () => expect(ParserService.parse('smell').verb, CommandVerb.smell));
    test('"sniff rose" → smell', () => expect(ParserService.parse('sniff rose').verb, CommandVerb.smell));
    test('"taste" → taste', () => expect(ParserService.parse('taste').verb, CommandVerb.taste));
    test('"measure fluctuation" → measure', () {
      final cmd = ParserService.parse('measure fluctuation');
      expect(cmd.verb, CommandVerb.measure);
      expect(cmd.args, ['fluctuation']);
    });
    test('"calibrate" → calibrate', () => expect(ParserService.parse('calibrate').verb, CommandVerb.calibrate));
    test('"invert" → invert', () => expect(ParserService.parse('invert').verb, CommandVerb.invert));
    test('"reverse image" → invert', () => expect(ParserService.parse('reverse image').verb, CommandVerb.invert));
    test('"break mirror" → breakObj', () => expect(ParserService.parse('break mirror').verb, CommandVerb.breakObj));
    test('"shatter glass" → breakObj', () => expect(ParserService.parse('shatter glass').verb, CommandVerb.breakObj));
    test('"blow" → blow', () => expect(ParserService.parse('blow').verb, CommandVerb.blow));
    test('"set temperature 37" → setParam', () {
      final cmd = ParserService.parse('set temperature 37');
      expect(cmd.verb, CommandVerb.setParam);
      expect(cmd.args, ['temperature', '37']);
    });
    test('"adjust" → setParam', () => expect(ParserService.parse('adjust').verb, CommandVerb.setParam));
    test('"drink" → drink', () => expect(ParserService.parse('drink').verb, CommandVerb.drink));
    test('"sip water" → drink', () => expect(ParserService.parse('sip water').verb, CommandVerb.drink));
    test('"stir" → stir', () => expect(ParserService.parse('stir').verb, CommandVerb.stir));
    test('"mix solution" → stir', () => expect(ParserService.parse('mix solution').verb, CommandVerb.stir));
    test('"enter 137" → enterValue [137]', () {
      final cmd = ParserService.parse('enter 137');
      expect(cmd.verb, CommandVerb.enterValue);
      expect(cmd.args, ['137']);
    });
    test('"collect fragments" → collect', () => expect(ParserService.parse('collect fragments').verb, CommandVerb.collect));
    test('"gather" → collect', () => expect(ParserService.parse('gather').verb, CommandVerb.collect));
    test('"decipher text" → decipher', () => expect(ParserService.parse('decipher text').verb, CommandVerb.decipher));
    test('"decode" → decipher', () => expect(ParserService.parse('decode').verb, CommandVerb.decipher));
    test('"deposit" → deposit', () => expect(ParserService.parse('deposit').verb, CommandVerb.deposit));
    test('"arrange leaves" → arrange', () {
      final cmd = ParserService.parse('arrange leaves');
      expect(cmd.verb, CommandVerb.arrange);
      expect(cmd.args, ['leaves']);
    });
    test('"order stones" → arrange', () => expect(ParserService.parse('order stones').verb, CommandVerb.arrange));
    test('"use key" → use [key]', () {
      final cmd = ParserService.parse('use key');
      expect(cmd.verb, CommandVerb.use);
      expect(cmd.args, ['key']);
    });
  });

  // ── Stop word stripping ───────────────────────────────────────────────────

  group('stop word stripping', () {
    test('"take the book" strips "the"', () {
      expect(ParserService.parse('take the book').args, ['book']);
    });

    test('"look at the mirror" strips "at" and "the"', () {
      expect(ParserService.parse('look at the mirror').args, ['mirror']);
    });

    test('"go into the vault" strips "into" and "the"', () {
      final cmd = ParserService.parse('go into the vault');
      // "vault" is not a direction so args preserved after stripping
      expect(cmd.verb, CommandVerb.go);
      expect(cmd.args, ['vault']);
    });

    test('"use the key on the door" strips stop words → [key, door]', () {
      final cmd = ParserService.parse('use the key on the door');
      expect(cmd.verb, CommandVerb.use);
      expect(cmd.args, ['key', 'door']);
    });

    test('"combine a lens to mercury" strips "a" and "to" → [lens, mercury]', () {
      final cmd = ParserService.parse('combine a lens to mercury');
      expect(cmd.verb, CommandVerb.combine);
      expect(cmd.args, ['lens', 'mercury']);
    });
  });

  // ── Unknown / unrecognised ────────────────────────────────────────────────

  group('unknown verb', () {
    test('unrecognised verb → unknown', () {
      final cmd = ParserService.parse('jump over fence');
      expect(cmd.verb, CommandVerb.unknown);
    });

    test('rawInput preserved verbatim', () {
      const raw = 'Jump OVER the Fence!';
      final cmd = ParserService.parse(raw);
      expect(cmd.rawInput, raw);
    });

    test('unknown verb args not stop-word-stripped', () {
      // default branch skips stripping and keeps all tokens after the verb
      final cmd = ParserService.parse('jump over fence');
      expect(cmd.args, ['over', 'fence']);
    });
  });

  // ── Case insensitivity ────────────────────────────────────────────────────

  group('case insensitivity', () {
    test('"LOOK" → examine', () => expect(ParserService.parse('LOOK').verb, CommandVerb.examine));
    test('"Go North" → go north', () {
      final cmd = ParserService.parse('Go North');
      expect(cmd.verb, CommandVerb.go);
      expect(cmd.args.first, 'north');
    });
    test('"WAIT" → wait', () => expect(ParserService.parse('WAIT').verb, CommandVerb.wait));
  });
}
