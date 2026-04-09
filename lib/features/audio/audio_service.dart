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
import '../settings/app_settings_provider.dart';
import '../state/game_state_provider.dart';
import '../state/psycho_provider.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  static const double _anxietyTriggerBoost = 0.08;
  static const double _anxietyVolumeScale = 0.08;
  static const double _oblivionVolumeScale = 0.12;
  static const double _lucidityVolumeScale = 0.04;
  static const double _baseTrackVolume = 0.74;
  static const double _ariaGoldbergVolume = 0.85;
  static const double _sicilianoVolume = 0.78;
  static const double _oblivionVolume = 0.50;
  static const double _zoneVolume = 0.68;
  static const double _minMixVolume = 0.25;
  static const double _maxMixVolume = 0.90;
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _backgroundPlayer = AudioPlayer();
  final Set<String> _availableAssets = {};
  final Set<String> _missingAssets = {};
  Future<void> _audioOperationQueue = Future.value();
  ProviderSubscription<AsyncValue<GameState>>? _gameStateSubscription;
  ProviderSubscription<AsyncValue<PsychoProfile>>? _psychoSubscription;
  ProviderSubscription<AsyncValue<AppSettings>>? _settingsSubscription;
  PsychoProfile? _lastProfile;
  AppSettings? _lastSettings;
  String? _currentAmbienceKey;
  String? _currentNodeId;

  // Fix #2: flag that tracks whether the 30-second silence-ending countdown
  // is still pending. Cleared by _crossfadeTo() when a new track starts.
  bool _silenceEndingActive = false;

  // Fix #3a: monotonically increasing counter — incremented at the start of
  // every _rampVolume call. Each ramp captures the generation at start and
  // aborts early if the counter has advanced (i.e. a newer ramp was begun).
  int _rampGeneration = 0;

  // Fix #3b: the most recently requested track key (set in syncForNode before
  // enqueuing). Allows _syncForNodeInternal to skip stale intermediate targets
  // when several node-change requests pile up in the queue.
  String? _latestRequestedTrackKey;

  // SFX (one-shot, do not loop)
  final Map<String, String> _sfxAssets = {
    'proustian_trigger': 'assets/audio/sfx_proustian_trigger.ogg',
  };

  Future<void> initialize(ProviderContainer container) async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    // Activate the session so Android grants audio focus before the first play().
    // Without this, just_audio plays silently on many Android devices.
    await session.setActive(true);

    await _backgroundPlayer.setLoopMode(LoopMode.one);
    await _backgroundPlayer.setVolume(0.0);

    _gameStateSubscription = container.listen<AsyncValue<GameState>>(
      gameStateProvider,
      (_, next) {
        final gameState = next.valueOrNull;
        if (gameState != null) {
          syncForNode(gameState.currentNode);
        }
      },
    );

    _settingsSubscription = container.listen<AsyncValue<AppSettings>>(
      appSettingsProvider,
      (_, next) {
        final settings = next.valueOrNull;
        if (settings != null) {
          _lastSettings = settings;
          _applySettings(settings);
        }
      },
    );

    // Ascolta psychoProfileProvider tramite ProviderContainer
    // (i provider Riverpod non sono Stream — richiede container.listen)
    _psychoSubscription = container.listen<AsyncValue<PsychoProfile>>(
      psychoProfileProvider,
      (_, next) {
        final profile = next.valueOrNull;
        if (profile != null) {
          _lastProfile = profile;
          _updateMixFromProfile(profile);
        }
      },
    );

    final initialProfile = container.read(psychoProfileProvider).valueOrNull;
    if (initialProfile != null) {
      _lastProfile = initialProfile;
    }
    final initialSettings = container.read(appSettingsProvider).valueOrNull;
    if (initialSettings != null) {
      _lastSettings = initialSettings;
    }
    final initialGameState = container.read(gameStateProvider).valueOrNull;
    if (initialGameState != null) {
      syncForNode(initialGameState.currentNode);
    }
  }

  Future<void> syncForNode(String nodeId, {bool force = false}) async {
    // Record the latest requested track key immediately, before enqueuing.
    // This lets _syncForNodeInternal detect and skip stale intermediate targets.
    final trackKey = AudioTrackCatalog.trackForNode(nodeId);
    if (trackKey != null) _latestRequestedTrackKey = trackKey;
    await _enqueueAudioOperation(() async {
      await _syncForNodeInternal(nodeId, force: force);
    });
  }

  Future<void> _syncForNodeInternal(String nodeId, {bool force = false}) async {
    final trackKey = AudioTrackCatalog.trackForNode(nodeId);
    if (trackKey == null) return;

    // Skip stale non-forced requests: if a newer node was requested after this
    // operation was enqueued (and it maps to a different track), there is no
    // point crossfading to an intermediate target — just let the later queued
    // operation handle the final destination.
    if (!force &&
        _latestRequestedTrackKey != null &&
        _latestRequestedTrackKey != trackKey &&
        trackKey != 'silence') {
      return;
    }

    final previousNodeId = _currentNodeId;
    _currentNodeId = nodeId;
    if (!force && previousNodeId == nodeId && _currentAmbienceKey == trackKey) {
      return;
    }
    if (!_isMusicEnabled) {
      _currentAmbienceKey = trackKey;
      await _backgroundPlayer.stop();
      await _backgroundPlayer.setVolume(0.0);
      return;
    }
    if (trackKey == 'silence') {
      final applied = await _handleSilenceEnding();
      if (applied) _currentAmbienceKey = trackKey;
      return;
    }
    final applied = await _crossfadeTo(trackKey);
    if (applied) _currentAmbienceKey = trackKey;
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
    await _enqueueAudioOperation(() async {
      if (trigger == null) return;
      if (!_isMusicEnabled && !trigger.startsWith('sfx:')) {
        return;
      }
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
      if (trigger == 'simulacrum') {
        await _applyCurrentMix(intensityOffset: 0.04);
        return;
      }
      if (trigger == 'anxious') {
        await _applyCurrentMix(intensityOffset: _anxietyTriggerBoost);
        return;
      }
      if (AudioTrackCatalog.isExplicitTrack(trigger)) {
        await _crossfadeTo(trigger);
      }
    });
  }

  Future<void> _updateMixFromProfile(PsychoProfile profile) async {
    await _enqueueAudioOperation(() async {
      // Profile-driven updates modulate the active room track, but never
      // replace explicit finale/memory cues.
      if (_currentAmbienceKey == null ||
          !_isMusicEnabled ||
          AudioTrackCatalog.specialTracks.contains(_currentAmbienceKey)) {
        return;
      }
      await _applyCurrentMix();
    });
  }

  Future<void> _applySettings(AppSettings settings) async {
    await _enqueueAudioOperation(() async {
      if (!settings.musicEnabled || settings.musicVolume <= 0) {
        await _backgroundPlayer.stop();
        await _backgroundPlayer.setVolume(0.0);
        return;
      }

      if (_currentNodeId != null) {
        final activeTrack = AudioTrackCatalog.trackForNode(_currentNodeId!);
        if (_currentAmbienceKey != activeTrack || !_backgroundPlayer.playing) {
          await _syncForNodeInternal(_currentNodeId!, force: true);
          return;
        }
      }

      await _applyCurrentMix();
    });
  }

  Future<bool> _crossfadeTo(String key) async {
    if (_currentAmbienceKey == key && _backgroundPlayer.playing) return true;
    final asset = AudioTrackCatalog.assetForKey(key);
    if (asset == null || !await _assetExists(asset)) return false;
    // Cancel any pending silence-ending phase 2 (fix #2).
    _silenceEndingActive = false;
    try {
      // Only ramp down if the player is already audible, to avoid a
      // needless 600 ms pause on startup when volume is already 0.
      if (_backgroundPlayer.volume > 0.05) {
        await _rampVolume(0.0);
      }
      await _backgroundPlayer.stop();
      await _backgroundPlayer.setAsset(asset);
      await _backgroundPlayer.play();
      await _rampVolume(_targetVolumeFor(key));
      return true;
    } catch (e) {
      // Fallback silenzioso — non crasha mai su 3 GB RAM
      // ignore: avoid_print
      print('Audio fallback [$key]: $e');
      return false;
    }
  }

  /// Finale 2 (Oblivion): 30 s silence → white-noise fade-in.
  ///
  /// **Phase 1** (runs inside the queue): ramp the background player to zero,
  /// stop it, mark [_silenceEndingActive] and return immediately — the queue
  /// is free for other operations during the wait.
  ///
  /// **Phase 2** (fire-and-forget, outside the queue): after 30 s the oblivion
  /// track is re-enqueued for fade-in. If [_silenceEndingActive] has been
  /// cleared in the meantime (e.g. by [_crossfadeTo] loading a new track), the
  /// phase-2 callback is a no-op.
  Future<bool> _handleSilenceEnding() async {
    // Phase 1 — runs inside the queue.
    try {
      await _rampVolume(0.0);
      await _backgroundPlayer.stop();
      _currentAmbienceKey = 'silence';
      _silenceEndingActive = true;
    } catch (e) {
      // ignore: avoid_print
      print('Audio silence-ending phase-1 fallback: $e');
      return false;
    }

    // Phase 2 — fire-and-forget: the 30 s countdown runs outside the queue.
    Future.delayed(const Duration(seconds: 30), () {
      // Early-out avoids adding a no-op to the queue when a new track has
      // already started (inner check inside the operation also guards this).
      if (!_silenceEndingActive) return;
      _enqueueAudioOperation(() async {
        if (!_silenceEndingActive) return;
        _silenceEndingActive = false;
        final oblivionAsset = AudioTrackCatalog.assetForKey('oblivion');
        if (oblivionAsset == null || !await _assetExists(oblivionAsset)) return;
        try {
          await _backgroundPlayer.setAsset(oblivionAsset);
          await _backgroundPlayer.setLoopMode(LoopMode.one);
          await _backgroundPlayer.play();
          await _rampVolume(0.3); // deliberately low — it is aftermath
          _currentAmbienceKey = 'oblivion';
        } catch (e) {
          // ignore: avoid_print
          print('Audio silence-ending phase-2 fallback: $e');
        }
      });
    });

    return true;
  }

  Future<void> _enqueueAudioOperation(Future<void> Function() operation) {
    _audioOperationQueue =
        _audioOperationQueue.then((_) => operation()).catchError((error, stackTrace) {
      // ignore: avoid_print
      print('Queued audio operation failed: $error\n$stackTrace');
    });
    return _audioOperationQueue;
  }

  Future<void> _applyCurrentMix({double intensityOffset = 0.0}) async {
    final currentKey = _currentAmbienceKey;
    if (currentKey == null || currentKey == 'silence' || !_isMusicEnabled) return;
    await _rampVolume(_targetVolumeFor(currentKey, intensityOffset: intensityOffset));
  }

  double _targetVolumeFor(String key, {double intensityOffset = 0.0}) {
    final musicScale = _musicVolumeScale;
    if (!_isMusicEnabled || musicScale <= 0) return 0.0;
    if (key == 'aria_goldberg') return _ariaGoldbergVolume * musicScale;
    if (key == 'siciliano') return _sicilianoVolume * musicScale;
    if (key == 'oblivion') return _oblivionVolume * musicScale;
    if (key == 'zona' || key == 'zona_eternal') return _zoneVolume * musicScale;

    final profile = _lastProfile;
    var target = _baseTrackVolume;
    if (profile != null) {
      target += (profile.anxiety / 100) * _anxietyVolumeScale;
      target -= (profile.oblivionLevel / 100) * _oblivionVolumeScale;
      target += (profile.lucidity / 100) * _lucidityVolumeScale;
    }
    return ((target + intensityOffset) * musicScale).clamp(0.0, _maxMixVolume);
  }

  bool get _isMusicEnabled => (_lastSettings?.musicEnabled ?? true);

  double get _musicVolumeScale => (_lastSettings?.musicVolume ?? 0.85).clamp(0.0, 1.0);

  bool get _isSfxEnabled => (_lastSettings?.sfxEnabled ?? true);

  double get _sfxVolumeScale => (_lastSettings?.sfxVolume ?? 0.90).clamp(0.0, 1.0);

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
      {int steps = 15, int msPerStep = 40}) async {
    // Capture the generation token before starting. If _rampGeneration
    // advances during the loop (because a concurrent path — e.g. the
    // silence-ending phase-2 — started a new ramp) the remaining steps are
    // abandoned, preventing the stale ramp from fighting the new one.
    _rampGeneration++;
    final generation = _rampGeneration;
    final current = _backgroundPlayer.volume;
    final delta = (target - current) / steps;
    for (int i = 0; i < steps; i++) {
      await Future.delayed(Duration(milliseconds: msPerStep));
      if (_rampGeneration != generation) return; // interrupted
      final next = (current + delta * (i + 1)).clamp(0.0, 1.0);
      await _backgroundPlayer.setVolume(next);
    }
  }

  Future<void> playSFX(String sfxAsset) async {
    if (!_isSfxEnabled || _sfxVolumeScale <= 0) return;
    if (!await _assetExists(sfxAsset)) return;
    final sfxPlayer = AudioPlayer();
    try {
      await sfxPlayer.setAsset(sfxAsset);
      await sfxPlayer.setVolume(_sfxVolumeScale);
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
    _settingsSubscription?.close();
    _backgroundPlayer.dispose();
  }
}

// Provider globale
final audioServiceProvider = Provider<AudioService>((ref) => AudioService());
