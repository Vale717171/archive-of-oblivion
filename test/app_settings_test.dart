import 'package:flutter_test/flutter_test.dart';

import 'package:archive_of_oblivion/features/settings/app_settings_provider.dart';

void main() {
  group('AppSettings', () {
    test('reads new audio fields from storage map', () {
      final settings = AppSettings.fromMap({
        'instant_text': 1,
        'reduce_motion': 0,
        'high_contrast': 1,
        'command_assist': 1,
        'music_enabled': 0,
        'music_volume': 0.35,
        'sfx_enabled': 1,
        'sfx_volume': 0.65,
        'text_scale': 1.2,
        'typewriter_millis': 18,
      });

      expect(settings.instantText, isTrue);
      expect(settings.highContrast, isTrue);
      expect(settings.musicEnabled, isFalse);
      expect(settings.musicVolume, 0.35);
      expect(settings.sfxEnabled, isTrue);
      expect(settings.sfxVolume, 0.65);
      expect(settings.textScale, 1.2);
      expect(settings.typewriterMillis, 18);
    });

    test('copyWith preserves unspecified values and updates provided ones', () {
      const initial = AppSettings(
        instantText: false,
        reduceMotion: false,
        highContrast: false,
        commandAssist: true,
        musicEnabled: true,
        musicVolume: 0.85,
        sfxEnabled: true,
        sfxVolume: 0.90,
        textScale: 1.0,
        typewriterMillis: 22,
        muteInBackground: true,
        enableHaptics: true,
      );

      final updated = initial.copyWith(
        musicEnabled: false,
        musicVolume: 0.25,
        sfxVolume: 0.40,
      );

      expect(updated.instantText, isFalse);
      expect(updated.commandAssist, isTrue);
      expect(updated.musicEnabled, isFalse);
      expect(updated.musicVolume, 0.25);
      expect(updated.sfxEnabled, isTrue);
      expect(updated.sfxVolume, 0.40);
      expect(updated.typewriterMillis, 22);
    });
  });
}