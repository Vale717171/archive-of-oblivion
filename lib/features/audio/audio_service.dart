// lib/features/audio/audio_service.dart
// Author: Grok (Audio & Immersion Specialist)
// Fix applied by Claude: replaced invalid Riverpod stream usage with
// ProviderContainer subscription (providers are not Streams).
// Note: setVolume() crossfade via duration param does not exist in just_audio —
// replaced with manual volume ramp via Future.delayed steps.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'audio_track_catalog.dart';
import '../settings/app_settings_provider.dart';
import '../state/game_state_provider.dart';
import '../state/psycho_provider.dart';

class AudioService with WidgetsBindingObserver {
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
  static const double _maxMixVolume = 0.90;
  static const double _ambientVolume = 0.32; // ambient layer target (scales with musicVolume)
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _backgroundPlayer = AudioPlayer();
  final AudioPlayer _ambientPlayer = AudioPlayer();
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

  // True until the very first track successfully starts playing.
  // _crossfadeTo() uses a 2.5 s fade-in for this initial load so the
  // Archive "opens" softly rather than cutting in at full volume.
  bool _isFirstTrack = true;

  // Fix #3a: monotonically increasing counter — incremented at the start of
  // every _rampVolume call. Each ramp captures the generation at start and
  // aborts early if the counter has advanced (i.e. a newer ramp was begun).
  int _rampGeneration = 0;
  // Separate ramp-generation counter for the ambient player — allows ambient
  // and music ramps to run independently without interfering.
  int _ambientRampGeneration = 0;
  String? _currentAmbientKey;

  // Fix #3b: the most recently requested track key (set in syncForNode before
  // enqueuing). Allows _syncForNodeInternal to skip stale intermediate targets
  // when several node-change requests pile up in the queue.
  String? _latestRequestedTrackKey;

  // SFX (one-shot, do not loop)
  final Map<String, String> _sfxAssets = {
    'proustian_trigger':  'assets/audio/sfx_proustian_trigger.ogg',
    // Reuse the shipped cue until dedicated assets are added.
    'command_accepted':   'assets/audio/sfx_proustian_trigger.ogg',
    'command_rejected':   'assets/audio/sfx_proustian_trigger.ogg',
    'sector_entry':       'assets/audio/sfx_proustian_trigger.ogg',
  };

  // Dedicated reusable player for typewriter ticks.
  // One player seeked + replayed per character — never a new instance per tick.
  final AudioPlayer _typewriterPlayer = AudioPlayer();
  bool _typewriterPlayerLoaded = false;
  bool _typewriterPlayerLoading = false; // guard against concurrent first-load

  Future<void> initialize(ProviderContainer container) async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    // Activate the session so Android grants audio focus before the first play().
    // Without this, just_audio plays silently on many Android devices.
    await session.setActive(true);

    await _backgroundPlayer.setLoopMode(LoopMode.one);
    await _backgroundPlayer.setVolume(0.0);
    await _ambientPlayer.setLoopMode(LoopMode.one);
    await _ambientPlayer.setVolume(0.0);
    // Register for app lifecycle events to auto-pause/resume audio.
    WidgetsBinding.instance.addObserver(this);

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
    // Ambient runs on a separate player — fire independently so it is not
    // delayed by the (potentially 1 800 ms) music crossfade.
    // _ambientRampGeneration cancels any stale ambient ramp that is still running.
    // ignore: discarded_futures
    _syncAmbientForNode(nodeId);
  }

  Future<void> _syncForNodeInternal(String nodeId, {bool force = false}) async {
    final trackKey = AudioTrackCatalog.trackForNode(nodeId);
    if (trackKey == null) {
      // ignore: avoid_print
      print('[Audio] syncForNode: no track for node "$nodeId"');
      return;
    }

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
      // ignore: avoid_print
      print('[Audio] Music disabled — stopping player for node "$nodeId"');
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
      await _applyMoodEffects();
    });
  }

  /// Applies dynamic oblivion-driven mood effects to music speed and ambient volume.
  ///
  /// - Music playback rate slows by up to 15% at full oblivion (0.85× speed).
  /// - Ambient volume swells by up to +25% at full oblivion (more echo present).
  ///
  /// No-op for special tracks (siciliano, aria_goldberg, oblivion, silence) —
  /// those have their own fixed atmosphere. Call [_resetMoodEffects] to restore
  /// defaults when switching into a special track.
  Future<void> _applyMoodEffects() async {
    final profile = _lastProfile;
    if (profile == null || !_isMusicEnabled) return;
    if (AudioTrackCatalog.specialTracks.contains(_currentAmbienceKey)) return;

    final intensity = (profile.oblivionLevel / 100).clamp(0.0, 1.0);

    // Music slows as the player sinks deeper — 0.85× at maximum oblivion.
    final speed = (1.0 - intensity * 0.15).clamp(0.70, 1.0);
    await _backgroundPlayer.setSpeed(speed);

    // Ambient layer swells — the echo of oblivion grows louder.
    if (_currentAmbientKey != null) {
      final ambientTarget =
          ((_ambientVolume + intensity * 0.25) * _musicVolumeScale)
              .clamp(0.0, 0.60);
      // fire-and-forget — ambient ramp runs on its own generation counter
      // and does not block the music queue.
      // ignore: discarded_futures
      _rampAmbientVolume(ambientTarget);
    }
  }

  /// Resets speed to 1.0 when entering a special track that must not be
  /// affected by oblivion-driven distortion.
  Future<void> _resetMoodEffects() async {
    await _backgroundPlayer.setSpeed(1.0);
  }

  Future<void> _applySettings(AppSettings settings) async {
    await _enqueueAudioOperation(() async {
      if (!settings.musicEnabled || settings.musicVolume <= 0) {
        await _backgroundPlayer.stop();
        await _backgroundPlayer.setVolume(0.0);
        await _backgroundPlayer.setSpeed(1.0); // clear any oblivion speed distortion
        // Also silence ambient when music is globally disabled.
        _ambientRampGeneration++;
        await _ambientPlayer.stop();
        await _ambientPlayer.setVolume(0.0);
        _currentAmbientKey = null;
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
    if (asset == null) {
      // ignore: avoid_print
      print('[Audio] No asset mapped for key "$key"');
      return false;
    }
    if (!await _assetExists(asset)) return false;
    // Cancel any pending silence-ending phase 2 (fix #2).
    _silenceEndingActive = false;

    // Capture and clear the startup flag before any early-return paths so the
    // 2.5 s intro fade is consumed only once even if _crossfadeTo() is retried.
    final isStartup = _isFirstTrack;
    _isFirstTrack = false;

    // Detect cross-sector transition to use a longer cinematic fade-in.
    // Same-sector room overrides (e.g. giardino → giardino_fountain) stay fast.
    final oldFamily = _currentAmbienceKey != null
        ? AudioTrackCatalog.sectorFamilyForTrackKey(_currentAmbienceKey!)
        : null;
    final newFamily = AudioTrackCatalog.sectorFamilyForTrackKey(key);
    // Priority: startup (2.5 s) > sector change (1.8 s) > normal (600 ms).
    final fadeInSteps = isStartup ? 62
        : (oldFamily != null && oldFamily != newFamily) ? 45
        : 15;

    // Sector entry SFX — plays as the old music begins to fade out.
    // Skip on startup (no "entry" when the Archive first opens).
    if (!isStartup && fadeInSteps > 15) {
      final entryAsset = _sfxAssets['sector_entry'];
      if (entryAsset != null) {
        // ignore: discarded_futures
        playSFX(entryAsset); // independent AudioPlayer, no queue conflict
      }
    }

    try {
      // Only ramp down if the player is already audible, to avoid a
      // needless 600 ms pause on startup when volume is already 0.
      if (_backgroundPlayer.volume > 0.05) {
        await _rampVolume(0.0);
      }
      await _backgroundPlayer.stop();
      await _backgroundPlayer.setAsset(asset);
      // Do NOT await play() — just_audio's play() Future completes only when
      // the track ends, which never happens with LoopMode.one. Awaiting it
      // would block _crossfadeTo (and the volume ramp) indefinitely.
      // ignore: discarded_futures
      _backgroundPlayer.play();
      // Reset speed to 1.0 before starting a special track so it is never
      // played at the oblivion-distorted rate.
      if (AudioTrackCatalog.specialTracks.contains(key)) {
        await _resetMoodEffects();
      }
      final targetVol = _targetVolumeFor(key);
      // ignore: avoid_print
      final fadeLabel = isStartup ? ' — startup'
          : fadeInSteps > 15 ? ' — sector change'
          : '';
      debugPrint(
        '[Audio] Playing "$key" → $asset '
        '(target vol ${targetVol.toStringAsFixed(2)}, '
        'fade-in ${fadeInSteps * 40} ms$fadeLabel)',
      );
      await _rampVolume(targetVol, steps: fadeInSteps);
      // Apply oblivion mood effects once the track is at target volume.
      // _applyMoodEffects is a no-op for special tracks.
      await _applyMoodEffects();
      return true;
    } catch (e) {
      // Fallback silenzioso — non crasha mai su 3 GB RAM
      // ignore: avoid_print
      print('[Audio] Playback failed [$key]: $e');
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
          // ignore: discarded_futures
          _backgroundPlayer.play(); // fire-and-forget — see _crossfadeTo comment
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

  /// Volume ramp for the ambient player — mirrors [_rampVolume] but uses
  /// [_ambientRampGeneration] so ambient and music ramps never interrupt each other.
  Future<void> _rampAmbientVolume(double target,
      {int steps = 15, int msPerStep = 40}) async {
    _ambientRampGeneration++;
    final generation = _ambientRampGeneration;
    final current = _ambientPlayer.volume;
    final delta = (target - current) / steps;
    for (int i = 0; i < steps; i++) {
      await Future.delayed(Duration(milliseconds: msPerStep));
      if (_ambientRampGeneration != generation) return;
      final next = (current + delta * (i + 1)).clamp(0.0, 1.0);
      await _ambientPlayer.setVolume(next);
    }
  }

  /// Syncs the ambient layer for [nodeId]. Runs independently of the music
  /// queue — the two players never block each other.
  Future<void> _syncAmbientForNode(String nodeId) async {
    final sector = AudioTrackCatalog.sectorForNode(nodeId);
    final musicTrack = AudioTrackCatalog.trackForNode(nodeId);
    // Suppress ambient when the music track is already a special atmospheric cue
    // (silence, oblivion, aria_goldberg, siciliano) or when the sector itself
    // provides its own atmosphere (memoria, la_zona).
    final suppressAmbient = musicTrack != null &&
        AudioTrackCatalog.specialTracks.contains(musicTrack);
    final ambientKey = suppressAmbient
        ? null
        : AudioTrackCatalog.ambientKeyForSector(sector);

    if (ambientKey == null) {
      // Fade ambient out gracefully if it is playing.
      if (_ambientPlayer.volume > 0.02) {
        await _rampAmbientVolume(0.0);
      }
      await _ambientPlayer.stop();
      await _ambientPlayer.setVolume(0.0);
      _currentAmbientKey = null;
      return;
    }

    if (_currentAmbientKey == ambientKey && _ambientPlayer.playing) return;

    final asset = AudioTrackCatalog.assetForKey(ambientKey);
    if (asset == null || !await _assetExists(asset)) return;

    if (!_isMusicEnabled) return;

    try {
      if (_ambientPlayer.volume > 0.02) await _rampAmbientVolume(0.0);
      await _ambientPlayer.stop();
      await _ambientPlayer.setAsset(asset);
      // fire-and-forget — same reason as _backgroundPlayer.play()
      // ignore: discarded_futures
      _ambientPlayer.play();
      final targetVol = (_ambientVolume * _musicVolumeScale).clamp(0.0, 0.45);
      // ignore: avoid_print
      print('[Audio] Ambient "$ambientKey" → $asset (vol ${targetVol.toStringAsFixed(2)})');
      await _rampAmbientVolume(targetVol);
      _currentAmbientKey = ambientKey;
    } catch (e) {
      // ignore: avoid_print
      print('[Audio] Ambient playback failed [$ambientKey]: $e');
    }
  }

  /// Plays a very short typewriter-click SFX on each typewriter character tick.
  ///
  /// Uses a single cached [_typewriterPlayer] — seeked to position 0 and
  /// replayed per character — so no AudioPlayer leak during long narratives.
  ///
  /// Asset preference: `sfx_typewriter_tick.ogg` (add for best results) → falls
  /// back to `sfx_proustian_trigger.ogg` (existing) → silent if both missing.
  Future<void> playTypewriterTick() async {
    if (!_isSfxEnabled || _sfxVolumeScale <= 0) return;
    if (_typewriterPlayerLoading) return; // skip ticks during one-time setup

    if (!_typewriterPlayerLoaded) {
      _typewriterPlayerLoading = true;
      const primary  = 'assets/audio/sfx_typewriter_tick.ogg';
      const fallback = 'assets/audio/sfx_proustian_trigger.ogg';
      final asset = await _assetExists(primary)  ? primary
                  : await _assetExists(fallback) ? fallback
                  : null;
      if (asset != null) {
        try {
          await _typewriterPlayer.setAsset(asset);
          // Volume set once at load time; not repeated on every tick.
          await _typewriterPlayer.setVolume(
              (0.08 * _sfxVolumeScale).clamp(0.0, 0.12));
          _typewriterPlayerLoaded = true;
        } catch (_) { /* silently degrade */ }
      }
      _typewriterPlayerLoading = false;
      if (!_typewriterPlayerLoaded) return;
    }

    try {
      // Guard: skip this tick if the player is in an intermediate state
      // (loading or buffering).  Seeking during those states can produce an
      // audible click or a seek-into-void error.  ProcessingState.ready and
      // .completed are both safe — seek() returns the clip to the start,
      // play() fires it off.
      final ps = _typewriterPlayer.processingState;
      if (ps == ProcessingState.loading || ps == ProcessingState.buffering) {
        return;
      }
      await _typewriterPlayer.seek(Duration.zero);
      // fire-and-forget — completes when the short clip ends (no LoopMode).
      // ignore: discarded_futures
      _typewriterPlayer.play();
    } catch (_) { /* silently degrade */ }
  }

  /// Plays a one-shot SFX at [speed] (default 1.0).
  /// Setting [speed] below 1.0 pitches the sound down (just_audio couples speed
  /// and pitch by default).  Use 0.75 for a recognisable "rejection" tone.
  Future<void> playSFX(String sfxAsset, {double speed = 1.0}) async {
    if (!_isSfxEnabled || _sfxVolumeScale <= 0) return;
    if (!await _assetExists(sfxAsset)) return;
    final sfxPlayer = AudioPlayer();
    try {
      await sfxPlayer.setAsset(sfxAsset);
      await sfxPlayer.setVolume(_sfxVolumeScale);
      if (speed != 1.0) await sfxPlayer.setSpeed(speed.clamp(0.5, 2.0));
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

  /// Plays the command-rejected SFX pitched down to signal an invalid input.
  /// Speed 0.75× lowers the pitch by roughly a minor third — audibly "wrong"
  /// without being harsh.  Silent if the asset file is not yet present.
  Future<void> playCommandRejected() async {
    final asset = _sfxAssets['command_rejected'];
    if (asset != null) await playSFX(asset, speed: 0.75);
  }

  /// Pauses both players when the app goes to background and resumes them
  /// when it returns to foreground, if [AppSettings.muteInBackground] is on.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!(_lastSettings?.muteInBackground ?? true)) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _enqueueAudioOperation(() async {
        await _backgroundPlayer.pause();
        // Interrupt any running ambient ramp and pause immediately.
        _ambientRampGeneration++;
        await _ambientPlayer.pause();
      });
    } else if (state == AppLifecycleState.resumed) {
      _enqueueAudioOperation(() async {
        if (_isMusicEnabled && _currentAmbienceKey != null &&
            _currentAmbienceKey != 'silence') {
          // ignore: discarded_futures
          _backgroundPlayer.play();
        }
        if (_isMusicEnabled && _currentAmbientKey != null) {
          // ignore: discarded_futures
          _ambientPlayer.play();
        }
      });
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gameStateSubscription?.close();
    _psychoSubscription?.close();
    _settingsSubscription?.close();
    _backgroundPlayer.dispose();
    _ambientPlayer.dispose();
    _typewriterPlayer.dispose();
  }
}

// Provider globale
final audioServiceProvider = Provider<AudioService>((ref) => AudioService());
