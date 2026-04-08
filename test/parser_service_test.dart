import 'package:flutter_test/flutter_test.dart';

import 'package:archive_of_oblivion/features/parser/parser_service.dart';
import 'package:archive_of_oblivion/features/parser/parser_state.dart';

void main() {
  group('ParserService', () {
    test('parses hint tiers', () {
      expect(ParserService.parse('hint').verb, CommandVerb.hint);
      expect(ParserService.parse('hint more').verb, CommandVerb.hint);
      expect(ParserService.parse('hint full').args, ['full']);
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
  });
}
