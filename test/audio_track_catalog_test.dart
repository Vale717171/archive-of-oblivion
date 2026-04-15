import 'package:flutter_test/flutter_test.dart';

import 'package:archive_of_oblivion/features/audio/audio_track_catalog.dart';
import 'package:archive_of_oblivion/features/ui/background_service.dart';

void main() {
  group('AudioTrackCatalog', () {
    test('returns explicit overrides for special nodes', () {
      expect(AudioTrackCatalog.trackForNode('quinto_landing'), 'siciliano');
      expect(AudioTrackCatalog.trackForNode('finale_acceptance'), 'aria_goldberg');
      expect(AudioTrackCatalog.trackForNode('finale_oblivion'), 'silence');
      expect(AudioTrackCatalog.trackForNode('la_zona'), 'zona');
    });

    test('falls back to sector base tracks when no node override exists', () {
      expect(AudioTrackCatalog.trackForNode('garden_cypress'), 'giardino');
      expect(AudioTrackCatalog.trackForNode('obs_library'), 'osservatorio');
      expect(AudioTrackCatalog.trackForNode('lab_substances'), 'laboratorio');
      expect(AudioTrackCatalog.trackForNode('unknown_node'), 'soglia');
    });

    test('recognises explicit track keys', () {
      expect(AudioTrackCatalog.isExplicitTrack('siciliano'), isTrue);
      expect(AudioTrackCatalog.isExplicitTrack('aria_goldberg'), isTrue);
      expect(AudioTrackCatalog.isExplicitTrack('silence'), isTrue);
      expect(AudioTrackCatalog.isExplicitTrack('nonexistent_track'), isFalse);
      expect(
        AudioTrackCatalog.assetForKey('siciliano'),
        'assets/audio/bach_siciliano_bwv1017.ogg',
      );
      expect(AudioTrackCatalog.assetForKey('silence'), isNull);
    });

    test('exposes per-track mix bias only for calibrated outliers', () {
      expect(AudioTrackCatalog.mixVolumeBiasForKey('soglia'), 0.10);
      expect(AudioTrackCatalog.mixVolumeBiasForKey('aria_goldberg'), 0.08);
      expect(AudioTrackCatalog.mixVolumeBiasForKey('galleria_dark'), -0.07);
      expect(AudioTrackCatalog.mixVolumeBiasForKey('giardino_fountain'), 0.0);
      expect(AudioTrackCatalog.mixVolumeBiasForKey('nonexistent_track'), 0.0);
    });

    test('maps representative nodes to expected sectors', () {
      expect(AudioTrackCatalog.sectorForNode('intro_void'), 'soglia');
      expect(AudioTrackCatalog.sectorForNode('gallery_light'), 'galleria');
      expect(AudioTrackCatalog.sectorForNode('quinto_ritual_chamber'), 'memoria');
      expect(AudioTrackCatalog.sectorForNode('finale_oblivion'), 'memoria');
      expect(AudioTrackCatalog.sectorForNode('unknown_node'), 'soglia');
    });

    test('keeps audio and background sector families aligned for representative nodes', () {
      expect(AudioTrackCatalog.sectorForNode('garden_fountain'), 'giardino');
      expect(
        BackgroundService.getBackgroundForNode('garden_fountain'),
        'assets/images/bg_giardino.jpg',
      );

      expect(AudioTrackCatalog.sectorForNode('quinto_landing'), 'memoria');
      expect(
        BackgroundService.getBackgroundForNode('quinto_landing'),
        'assets/images/bg_memoria.jpg',
      );

      expect(AudioTrackCatalog.sectorForNode('la_zona'), 'la_zona');
      expect(
        BackgroundService.getBackgroundForNode('la_zona'),
        'assets/images/bg_zona.jpg',
      );
    });
  });
}
