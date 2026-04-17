import 'package:flutter_test/flutter_test.dart';

import 'package:archive_of_oblivion/features/game/game_engine_provider.dart';

void main() {
  group('game metadata helpers', () {
    test('exposes readable node titles', () {
      expect(gameNodeTitle('la_soglia'), 'The Threshold');
      expect(gameNodeTitle('missing_node'), 'The Archive');
    });

    test('maps sector labels for UI surfaces', () {
      expect(gameSectorLabel('garden_cypress'), 'Garden');
      expect(gameSectorLabel('obs_dome'), 'Observatory');
      expect(gameSectorLabel('quinto_landing'), 'Memory');
      expect(gameSectorLabel('finale_acceptance'), 'Finale');
      expect(gameSectorLabel('la_zona'), 'Zone');
      expect(gameSectorLabel('unknown_node'), 'Archive');
    });

    test(
        'falls back to generic archive title when nodes are untitled or missing',
        () {
      expect(gameNodeTitle('intro_void'), 'The Archive');
      expect(gameNodeTitle('unknown_node'), 'The Archive');
    });

    test('exposes required puzzle gates for representative exits', () {
      expect(gameRequiredPuzzleForExit('garden_cypress', 'north'),
          'leaves_arranged');
      expect(gameRequiredPuzzleForExit('obs_corridor', 'west'),
          'heisenberg_walked');
      expect(gameRequiredPuzzleForExit('quinto_ritual_chamber', 'down'),
          'ritual_complete');
      expect(gameRequiredPuzzleForExit('unknown_node', 'north'), isNull);
    });

    test('exposes gate hint text for known puzzles', () {
      expect(
          gameGateHintForPuzzle('leaves_arranged'), contains('arrange leaves'));
      expect(gameGateHintForPuzzle('ritual_complete'), contains('drink'));
      expect(gameGateHintForPuzzle('missing_puzzle'), isNull);
    });

    test('exposes depth and quote thresholds for finale progression gates', () {
      expect(gameDepthThresholdForSectorToQuinto('garden'), 5);
      expect(gameDepthThresholdForSectorToQuinto('observatory'), 5);
      expect(gameDepthThresholdForSectorToQuinto('gallery'), 5);
      expect(gameDepthThresholdForSectorToQuinto('laboratory'), 5);
      expect(gameDepthThresholdForSectorToQuinto('memory'), isNull);
      expect(gameMemoryDepthThresholdToNucleo(), 4);
      expect(gameQuoteExposureThresholdToNucleo(), 18);
    });

    test('evaluates garden stele specificity heuristics', () {
      expect(gameGardenSteleInscriptionLooksSpecific('friendship'), isFalse);
      expect(
        gameGardenSteleInscriptionLooksSpecific(
          'friendship asks me to return to that winter street and apologize by name',
        ),
        isTrue,
      );
    });

    test('classifies garden relinquishment categories from inventory', () {
      final coverage = gameGardenRelinquishmentCoverage(
        const ['book', 'mirror shard', 'coin'],
      );
      expect(coverage['useful'], isTrue);
      expect(coverage['identity'], isTrue);
      expect(coverage['pain'], isTrue);
    });

    test('classifies zone-eligible transits conservatively', () {
      expect(gameTransitEligibleForZone('garden_cypress', 'garden_fountain'),
          isTrue);
      expect(gameTransitEligibleForZone('la_zona', 'garden_fountain'), isFalse);
      expect(gameTransitEligibleForZone('garden_cypress', 'la_zona'), isFalse);
      expect(gameTransitEligibleForZone('quinto_landing', 'quinto_childhood'),
          isFalse);
      expect(gameTransitEligibleForZone('garden_cypress', 'finale_acceptance'),
          isFalse);
      expect(
          gameTransitEligibleForZone('il_nucleo', 'garden_cypress'), isFalse);
    });

    test('classifies boss utterances into finale-relevant categories', () {
      expect(classifyBossUtterance('I accept oblivion'),
          BossUtteranceKind.surrender);
      expect(classifyBossUtterance('I want to stay'), BossUtteranceKind.remain);
      expect(classifyBossUtterance('imperfection is human warmth'),
          BossUtteranceKind.resolution);
      expect(classifyBossUtterance('tell me what you are'),
          BossUtteranceKind.other);
    });
  });
}
