import 'package:flutter_test/flutter_test.dart';

import 'package:archive_of_oblivion/features/ui/background_service.dart';

void main() {
  group('BackgroundService', () {
    test('maps sectors to the expected background assets', () {
      expect(
        BackgroundService.getBackgroundForSector('giardino'),
        'assets/images/bg_giardino.jpg',
      );
      expect(
        BackgroundService.getBackgroundForSector('memoria'),
        'assets/images/bg_memoria.jpg',
      );
      expect(BackgroundService.getBackgroundForSector('missing'), isNull);
    });

    test('maps representative nodes to the correct background family', () {
      expect(
        BackgroundService.getBackgroundForNode('intro_void'),
        'assets/images/bg_soglia.jpg',
      );
      expect(
        BackgroundService.getBackgroundForNode('garden_fountain'),
        'assets/images/bg_giardino.jpg',
      );
      expect(
        BackgroundService.getBackgroundForNode('obs_dome'),
        'assets/images/bg_osservatorio.jpg',
      );
      expect(
        BackgroundService.getBackgroundForNode('gallery_central'),
        'assets/images/bg_galleria.jpg',
      );
      expect(
        BackgroundService.getBackgroundForNode('quinto_landing'),
        'assets/images/bg_memoria.jpg',
      );
      expect(
        BackgroundService.getBackgroundForNode('la_zona'),
        'assets/images/bg_zona.jpg',
      );
    });

    test('falls back to startup background when node is absent', () {
      expect(
        BackgroundService.getBackgroundForNodeOrDefault(null),
        BackgroundService.defaultBackgroundAsset,
      );
      expect(
        BackgroundService.getBackgroundForNodeOrDefault(''),
        BackgroundService.defaultBackgroundAsset,
      );
      expect(
        BackgroundService.getBackgroundForNodeOrDefault('unknown_node'),
        BackgroundService.defaultBackgroundAsset,
      );
    });
  });
}