import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:archive_of_oblivion/features/audio/audio_track_catalog.dart';

void main() {
  group('audio manifest consistency', () {
    final manifestFile = File('assets/audio/manifest.json');

    test('declares every runtime audio asset except synthetic silence', () async {
      expect(manifestFile.existsSync(), isTrue);

      final jsonMap = jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
      final tracks = jsonMap['tracks'] as List<dynamic>;
      final manifestAssets = {
        for (final track in tracks)
          (track as Map<String, dynamic>)['asset'] as String,
      };

      final runtimeAssets = Set<String>.from(AudioTrackCatalog.ambienceAssets.values);
      expect(runtimeAssets.difference(manifestAssets), isEmpty);
    });

    test('uses unique keys in the manifest', () async {
      final jsonMap = jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
      final tracks = jsonMap['tracks'] as List<dynamic>;
      final keys = [
        for (final track in tracks)
          (track as Map<String, dynamic>)['key'] as String,
      ];

      expect(keys.toSet().length, keys.length);
    });
  });
}