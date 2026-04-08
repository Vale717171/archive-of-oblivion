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
      expect(gameSectorLabel('la_zona'), 'Zone');
    });
  });
}
