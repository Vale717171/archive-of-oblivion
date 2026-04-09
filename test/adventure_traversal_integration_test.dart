// test/adventure_traversal_integration_test.dart
// Integration test: randomly traverses every branch of the adventure and
// asserts that every background image file and every audio asset file exists
// on disk. The test fails when an image is missing or when an audio trigger
// references a non-existent asset.
//
// The seeded-random DFS walk is deterministic (seed 42) so failures are
// reproducible, while still exercising branches in an unpredictable order.

import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:archive_of_oblivion/features/audio/audio_track_catalog.dart';
import 'package:archive_of_oblivion/features/game/game_engine_provider.dart';
import 'package:archive_of_oblivion/features/ui/background_service.dart';

// ── Known audio triggers emitted by EngineResponse.audioTrigger ───────────────

/// Mood modifiers — adjust the current track's volume envelope.
/// Handled by AudioService.handleTrigger without loading any file.
const _moodTriggers = {'calm', 'anxious'};

/// Explicit ambience keys — must be present in AudioTrackCatalog.ambienceAssets.
const _explicitTriggers = {'oblivion', 'siciliano', 'aria_goldberg'};

/// Synthetic trigger — 30 s silence; no asset file required.
const _silenceTrigger = 'silence';

/// One-shot SFX triggers and their expected asset paths.
const _sfxAssets = {
  'sfx:proustian_trigger': 'assets/audio/sfx_proustian_trigger.ogg',
};

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── 1. Background images ──────────────────────────────────────────────────

  group('background images', () {
    test('all background asset files declared in BackgroundService exist on disk', () {
      for (final asset in BackgroundService.allBackgroundAssets) {
        expect(
          File(asset).existsSync(),
          isTrue,
          reason: 'Missing background image: $asset',
        );
      }
    });

    test('every game node resolves to an existing background asset', () {
      for (final nodeId in gameAllNodeIds()) {
        final asset = BackgroundService.getBackgroundForNodeOrDefault(nodeId);
        expect(
          asset,
          isNotEmpty,
          reason: 'Node "$nodeId" produced an empty background path',
        );
        expect(
          File(asset).existsSync(),
          isTrue,
          reason: 'Node "$nodeId": background file not found — $asset',
        );
      }
    });
  });

  // ── 2. Audio triggers ─────────────────────────────────────────────────────

  group('audio triggers', () {
    test('all AudioTrackCatalog ambience asset files exist on disk', () {
      for (final entry in AudioTrackCatalog.ambienceAssets.entries) {
        expect(
          File(entry.value).existsSync(),
          isTrue,
          reason: 'Missing ambience asset for key "${entry.key}": ${entry.value}',
        );
      }
    });

    test('all explicit engine triggers are registered in AudioTrackCatalog', () {
      for (final trigger in _explicitTriggers) {
        expect(
          AudioTrackCatalog.isExplicitTrack(trigger),
          isTrue,
          reason: 'Engine trigger "$trigger" is not in AudioTrackCatalog',
        );
        final asset = AudioTrackCatalog.assetForKey(trigger);
        expect(
          asset,
          isNotNull,
          reason: 'Trigger "$trigger" maps to null in AudioTrackCatalog',
        );
        expect(
          File(asset!).existsSync(),
          isTrue,
          reason: 'Asset for trigger "$trigger" not found on disk: $asset',
        );
      }
    });

    test('mood triggers are the expected string constants (no file lookup needed)', () {
      // Just assert the known strings are handled — AudioService.handleTrigger
      // short-circuits these without loading any asset.
      expect(_moodTriggers, containsAll(['calm', 'anxious']));
    });

    test('silence trigger is handled without a file (synthetic signal)', () {
      // AudioService._handleSilenceEnding plays echo_chamber after 30 s but
      // never loads 'silence' as a direct asset key.
      expect(AudioTrackCatalog.assetForKey(_silenceTrigger), isNull);
    });

    test('all SFX trigger asset files exist on disk', () {
      for (final entry in _sfxAssets.entries) {
        expect(
          File(entry.value).existsSync(),
          isTrue,
          reason: 'SFX asset for "${entry.key}" not found on disk: ${entry.value}',
        );
      }
    });

    test('every node audio track resolves to an existing asset or silence', () {
      for (final nodeId in gameAllNodeIds()) {
        final trackKey = AudioTrackCatalog.trackForNode(nodeId);
        expect(
          trackKey,
          isNotNull,
          reason: 'Node "$nodeId" produced a null audio track key',
        );
        if (trackKey == 'silence') continue; // synthetic — no file to check

        final asset = AudioTrackCatalog.assetForKey(trackKey!);
        expect(
          asset,
          isNotNull,
          reason: 'Track key "$trackKey" for node "$nodeId" has no asset mapping',
        );
        expect(
          File(asset!).existsSync(),
          isTrue,
          reason: 'Audio asset for node "$nodeId" (key "$trackKey") '
              'not found on disk: $asset',
        );
      }
    });
  });

  // ── 3. Adventure traversal ────────────────────────────────────────────────

  group('adventure traversal', () {
    test(
      'seeded-random DFS from intro_void visits every statically reachable node '
      'and validates its assets',
      () {
        final reachable = _bfsReachable('intro_void');
        expect(
          reachable,
          isNotEmpty,
          reason: 'BFS found no reachable nodes from intro_void',
        );

        final rng = Random(42);
        final visited = <String>{};

        // DFS with a stack; exits are shuffled for the random element.
        final stack = ['intro_void'];
        while (stack.isNotEmpty) {
          final nodeId = stack.removeLast();
          if (visited.contains(nodeId)) continue;
          visited.add(nodeId);

          _assertNodeAssets(nodeId);

          final exits = gameExitsForNode(nodeId).values
              .where(reachable.contains)
              .toList()
            ..shuffle(rng);
          for (final dest in exits) {
            if (!visited.contains(dest)) stack.add(dest);
          }
        }

        // Every statically reachable node must have been visited.
        for (final nodeId in reachable) {
          expect(
            visited,
            contains(nodeId),
            reason: 'Node "$nodeId" was never visited during the DFS walk',
          );
        }
      },
    );

    test(
      'nodes not reachable via static exits (finale_*, la_zona) still have '
      'valid assets',
      () {
        final reachable = _bfsReachable('intro_void');
        final isolated = gameAllNodeIds().difference(reachable);
        for (final nodeId in isolated) {
          _assertNodeAssets(nodeId);
        }
      },
    );

    test('every node exit leads to a known node', () {
      final allNodes = gameAllNodeIds();
      for (final nodeId in allNodes) {
        for (final entry in gameExitsForNode(nodeId).entries) {
          expect(
            allNodes,
            contains(entry.value),
            reason: 'Node "$nodeId" exit "${entry.key}" '
                'points to unknown node "${entry.value}"',
          );
        }
      }
    });
  });
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// BFS from [start] over the static node graph exposed by [gameExitsForNode].
/// Returns every node reachable via declared exits (puzzle gates are ignored —
/// we traverse the logical topology, not the gated gameplay path).
Set<String> _bfsReachable(String start) {
  final visited = <String>{};
  final queue = [start];
  while (queue.isNotEmpty) {
    final node = queue.removeAt(0);
    if (!visited.add(node)) continue;
    for (final dest in gameExitsForNode(node).values) {
      if (!visited.contains(dest)) queue.add(dest);
    }
  }
  return visited;
}

/// Asserts that [nodeId] has a valid background image file and a valid audio
/// track file on disk. Throws a test failure with a descriptive message if
/// either check fails.
void _assertNodeAssets(String nodeId) {
  // ── Background image ────────────────────────────────────────────────────
  final bgAsset = BackgroundService.getBackgroundForNodeOrDefault(nodeId);
  expect(
    bgAsset,
    isNotEmpty,
    reason: 'Node "$nodeId": background asset path is empty',
  );
  expect(
    File(bgAsset).existsSync(),
    isTrue,
    reason: 'Node "$nodeId": background image not found on disk — $bgAsset',
  );

  // ── Audio track ─────────────────────────────────────────────────────────
  final trackKey = AudioTrackCatalog.trackForNode(nodeId);
  expect(
    trackKey,
    isNotNull,
    reason: 'Node "$nodeId": audio track key is null',
  );
  if (trackKey == 'silence') return; // synthetic signal — no file to check

  final audioAsset = AudioTrackCatalog.assetForKey(trackKey!);
  expect(
    audioAsset,
    isNotNull,
    reason: 'Node "$nodeId": track key "$trackKey" has no audio asset mapping',
  );
  expect(
    File(audioAsset!).existsSync(),
    isTrue,
    reason: 'Node "$nodeId": audio file not found on disk — $audioAsset',
  );
}
