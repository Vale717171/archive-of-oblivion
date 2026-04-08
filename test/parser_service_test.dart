import 'package:flutter_test/flutter_test.dart';

import 'package:archive_of_oblivion/features/parser/parser_service.dart';
import 'package:archive_of_oblivion/features/parser/parser_state.dart';

void main() {
  group('ParserService', () {
    test('normalises shortcuts and stop words', () {
      final look = ParserService.parse('look at the leaves');
      expect(look.verb, CommandVerb.examine);
      expect(look.args, ['leaves']);

      final pickup = ParserService.parse('pick up the notebook');
      expect(pickup.verb, CommandVerb.take);
      expect(pickup.args, ['notebook']);

      final inventory = ParserService.parse('i');
      expect(inventory.verb, CommandVerb.inventory);
      expect(inventory.args, isEmpty);
    });

    test('parses hint tiers', () {
      expect(ParserService.parse('hint').verb, CommandVerb.hint);
      expect(ParserService.parse('hint more').verb, CommandVerb.hint);
      expect(ParserService.parse('hint full').args, ['full']);
      expect(ParserService.parse('nudge full').args, ['full']);
    });

    test('parses new explicit special verbs', () {
      expect(ParserService.parse('observe').verb, CommandVerb.observe);
      expect(ParserService.parse('enter 1').verb, CommandVerb.enterValue);
      expect(ParserService.parse('collect mercury').verb, CommandVerb.collect);
      expect(ParserService.parse('decipher symbols').verb, CommandVerb.decipher);
      expect(ParserService.parse('say i remember').verb, CommandVerb.say);
    });

    test('accepts natural movement synonyms', () {
      final parsed = ParserService.parse('head north');
      expect(parsed.verb, CommandVerb.go);
      expect(parsed.args, ['north']);
    });

    test('keeps special creative and ritual verbs distinct', () {
      expect(ParserService.parse('write my true name').verb, CommandVerb.write);
      expect(ParserService.parse('stir').verb, CommandVerb.stir);
      expect(ParserService.parse('drink').verb, CommandVerb.drink);
      expect(ParserService.parse('walk north').verb, CommandVerb.go);
    });

    test('supports verb aliases for puzzle interactions', () {
      expect(ParserService.parse('push the button').verb, CommandVerb.press);
      expect(ParserService.parse('give memory').verb, CommandVerb.offer);
      expect(ParserService.parse('reverse the mirror').verb, CommandVerb.invert);
      expect(ParserService.parse('adjust the alembic to high').verb, CommandVerb.setParam);
      expect(ParserService.parse('speak the truth').verb, CommandVerb.say);
    });

    test('returns unknown for unsupported verbs while preserving raw input', () {
      final parsed = ParserService.parse('sing softly now');
      expect(parsed.verb, CommandVerb.unknown);
      expect(parsed.args, ['softly', 'now']);
      expect(parsed.rawInput, 'sing softly now');
    });
  });
}
