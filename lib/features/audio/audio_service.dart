// lib/features/audio/audio_service.dart
// Author: Grok (Audio & Immersion Specialist)
// Fix applied by Claude: replaced invalid Riverpod stream usage with
// ProviderContainer subscription (providers are not Streams).
// Note: setVolume() crossfade via duration param does not exist in just_audio —
// replaced with manual volume ramp via Future.delayed steps.
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'audio_track_catalog.dart';
import '../state/game_state_provider.dart';
import '../state/psycho_provider.dart';
import 'dart:async';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  static const double _anxietyTriggerBoost = 0.08;
  static const double _anxietyVolumeScale = 0.08;
  static const double _oblivionVolumeScale = 0.12;
  static const double _lucidityVolumeScale = 0.04;
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _backgroundPlayer = AudioPlayer();
  final Set<String> _availableAssets = <String>{};
  final Set<String> _missingAssets = <String>{};
  ProviderSubscription<AsyncValue<GameState>>? _gameStateSubscription;
  ProviderSubscription<AsyncValue<PsychoProfile>>? _psychoSubscription;
  PsychoProfile? _lastProfile;
  String? _currentAmbienceKey;
  String? _currentNodeId;

  // SFX (one-shot, do not loop)
  final Map<String, String> _sfxAssets = {
    'proustian_trigger': 'assets/audio/sfx_proustian_trigger.ogg',
  };

  Future<void> initialize(ProviderContainer container) async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    await _backgroundPlayer.setLoopMode(LoopMode.one);
    await _backgroundPlayer.setVolume(0.0);

    _gameStateSubscription = container.listen<AsyncValue<GameState>>(
      gameStateProvider,
      (_, next) {
        final gameState = next.valueOrNull;
        if (gameState != null) {
          unawaited(syncForNode(gameState.currentNode));
        }
      },
      fireImmediately: true,
    );

    // Ascolta psychoProfileProvider tramite ProviderContainer
    // (i provider Riverpod non sono Stream — richiede container.listen)
    _psychoSubscription = container.listen<AsyncValue<PsychoProfile>>(
      psychoProfileProvider,
      (_, next) {
        final profile = next.valueOrNull;
        if (profile != null) {
          _lastProfile = profile;
          unawaited(_updateMixFromProfile(profile));
        }
      },
      fireImmediately: true,
    );
  }

  Future<void> syncForNode(String nodeId) async {
    final trackKey = AudioTrackCatalog.trackForNode(nodeId);
    if (trackKey == null) return;
    if (_currentNodeId == nodeId && _currentAmbienceKey == trackKey) return;
    _currentNodeId = nodeId;
    if (trackKey == 'silence') {
      await _handleSilenceEnding();
      return;
    }
    await _crossfadeTo(trackKey);
  }

  /// Processes an [audioTrigger] string emitted by [EngineResponse].
  ///
  /// Triggers follow the convention:
  ///   - Explicit ambience keys ('oblivion', 'siciliano', 'aria_goldberg',
  ///     sector keys, room overrides) → crossfade the background player.
  ///   - Legacy mood modifiers ('calm', 'anxious') → keep the current room
  ///     track but re-apply intensity.
  ///   - 'sfx:<name>' → play one-shot SFX via a dedicated [AudioPlayer].
  ///   - 'silence' → 30 s of silence followed by white-noise fade-in
  ///     (Finale 2 — Oblivion ending).
  Future<void> handleTrigger(String? trigger) async {
    if (trigger == null) return;
    if (trigger.startsWith('sfx:')) {
      final sfxKey = trigger.substring(4); // strip 'sfx:' prefix
      final asset  = _sfxAssets[sfxKey];
      if (asset != null) await playSFX(asset);
      return;
    }
    if (trigger == 'silence') {
      await _handleSilenceEnding();
      return;
    }
    if (trigger == 'calm') {
      await _applyCurrentMix();
      return;
    }
    if (trigger == 'anxious') {
      await _applyCurrentMix(intensityOffset: _anxietyTriggerBoost);
      return;
    }
    if (AudioTrackCatalog.isExplicitTrack(trigger)) {
      await _crossfadeTo(trigger);
    }
  }

  Future<void> _updateMixFromProfile(PsychoProfile profile) async {
    // Profile-driven updates modulate the active room track, but never replace
    // explicit finale/memory cues.
    if (_currentAmbienceKey == null ||
        AudioTrackCatalog.specialTracks.contains(_currentAmbienceKey)) {
      return;
    }
    await _applyCurrentMix();
  }

  Future<void> _crossfadeTo(String key) async {
    if (_currentAmbienceKey == key) return;
    final asset = AudioTrackCatalog.assetForKey(key);
    if (asset == null || !await _assetExists(asset)) return;
    try {
      await _rampVolume(0.0);
      await _backgroundPlayer.setAsset(asset);
      await _backgroundPlayer.play();
      await _rampVolume(_targetVolumeFor(key));
      _currentAmbienceKey = key;
    } catch (e) {
      // Fallback silenzioso — non crasha mai su 3 GB RAM
      // ignore: avoid_print
      print('Audio fallback [$key]: $e');
    }
  }

  /// Finale 2 (Oblivion): 30 s silence → white-noise fade-in.
  /// Uses a separate one-shot player to avoid disrupting the background loop.
  Future<void> _handleSilenceEnding() async {
    try {
      await _rampVolume(0.0);
      await _backgroundPlayer.stop();
      _currentAmbienceKey = 'silence';
      await Future.delayed(const Duration(seconds: 30));
      // White noise / echo chamber is the closest available ambient track
      final oblivionAsset = AudioTrackCatalog.assetForKey('oblivion');
      if (oblivionAsset == null || !await _assetExists(oblivionAsset)) return;
      await _backgroundPlayer.setAsset(oblivionAsset);
      await _backgroundPlayer.setLoopMode(LoopMode.one);
      await _backgroundPlayer.play();
      await _rampVolume(0.3); // deliberately low — it is aftermath
    } catch (e) {
      // ignore: avoid_print
      print('Audio silence-ending fallback: $e');
    }
  }

  Future<void> _applyCurrentMix({double intensityOffset = 0.0}) async {
    final currentKey = _currentAmbienceKey;
    if (currentKey == null || currentKey == 'silence') return;
    await _rampVolume(_targetVolumeFor(currentKey, intensityOffset: intensityOffset));
  }

  double _targetVolumeFor(String key, {double intensityOffset = 0.0}) {
    if (key == 'aria_goldberg') return 0.85;
    if (key == 'siciliano') return 0.78;
    if (key == 'oblivion') return 0.50;
    if (key == 'zona' || key == 'zona_eternal') return 0.68;

    final profile = _lastProfile;
    var target = 0.74;
    if (profile != null) {
      target += (profile.anxiety / 100) * _anxietyVolumeScale;
      target -= (profile.oblivionLevel / 100) * _oblivionVolumeScale;
      target += (profile.lucidity / 100) * _lucidityVolumeScale;
    }
    return (target + intensityOffset).clamp(0.25, 0.9);
  }

  Future<bool> _assetExists(String asset) async {
    if (_availableAssets.contains(asset)) return true;
    if (_missingAssets.contains(asset)) return false;

    try {
      await rootBundle.load(asset);
      _availableAssets.add(asset);
      return true;
    } catch (_) {
      _missingAssets.add(asset);
      // ignore: avoid_print
      print('Audio asset missing: $asset');
      return false;
    }
  }

  Future<void> _rampVolume(double target,
      {int steps = 10, int msPerStep = 200}) async {
    final current = _backgroundPlayer.volume;
    final delta = (target - current) / steps;
    for (int i = 0; i < steps; i++) {
      await Future.delayed(Duration(milliseconds: msPerStep));
      final next = (current + delta * (i + 1)).clamp(0.0, 1.0);
      await _backgroundPlayer.setVolume(next);
    }
  }

  Future<void> playSFX(String sfxAsset) async {
    if (!await _assetExists(sfxAsset)) return;
    final sfxPlayer = AudioPlayer();
    try {
      await sfxPlayer.setAsset(sfxAsset);
      await sfxPlayer.play();
      // Dispose when done, with a safety timeout to avoid leaks
      sfxPlayer.processingStateStream
          .firstWhere((s) => s == ProcessingState.completed)
          .timeout(const Duration(seconds: 30))
          .then((_) => sfxPlayer.dispose())
          .catchError((_) => sfxPlayer.dispose());
    } catch (e) {
      sfxPlayer.dispose();
      // ignore: avoid_print
      print('SFX fallback [$sfxAsset]: $e');
    }
  }

  void dispose() {
    _gameStateSubscription?.close();
    _psychoSubscription?.close();
    _backgroundPlayer.dispose();
  }
}

// Provider globale
final audioServiceProvider = Provider<AudioService>((ref) => AudioService());
