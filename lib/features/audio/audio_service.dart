// lib/features/audio/audio_service.dart
// Author: Grok (Audio & Immersion Specialist)
// Fix applied by Claude: replaced invalid Riverpod stream usage with
// ProviderContainer subscription (providers are not Streams).
// Note: setVolume() crossfade via duration param does not exist in just_audio —
// replaced with manual volume ramp via Future.delayed steps.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../state/psycho_provider.dart';
import 'dart:async';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _backgroundPlayer = AudioPlayer();
  ProviderSubscription<AsyncValue<PsychoProfile>>? _psychoSubscription;
  String? _currentAmbienceKey;

  // Ambience tracks (loop indefinitely)
  final Map<String, String> _ambienceAssets = {
    'calm':     'assets/audio/void_ambient.ogg',
    'anxious':  'assets/audio/anxiety_pulse.ogg',
    'oblivion': 'assets/audio/echo_chamber.ogg',
    // Fifth Sector — Siciliano BWV 1017 (Bach, Sonata for violin and harpsichord)
    'siciliano':    'assets/audio/bach_siciliano_bwv1017.ogg',
    // Finale 1 — Aria delle Variazioni Goldberg (ripresa dalla nota sospesa)
    'aria_goldberg': 'assets/audio/bach_aria_goldberg.ogg',
  };

  // SFX (one-shot, do not loop)
  final Map<String, String> _sfxAssets = {
    'proustian_trigger': 'assets/audio/sfx_proustian_trigger.ogg',
  };

  Future<void> initialize(ProviderContainer container) async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    await _backgroundPlayer.setLoopMode(LoopMode.one);
    await _backgroundPlayer.setVolume(0.7);

    // Ascolta psychoProfileProvider tramite ProviderContainer
    // (i provider Riverpod non sono Stream — richiede container.listen)
    _psychoSubscription = container.listen<AsyncValue<PsychoProfile>>(
      psychoProfileProvider,
      (_, next) {
        final profile = next.valueOrNull;
        if (profile != null) _updateAmbienceFromProfile(profile);
      },
    );
  }

  /// Processes an [audioTrigger] string emitted by [EngineResponse].
  ///
  /// Triggers follow the convention:
  ///   - Ambience keys ('calm', 'anxious', 'oblivion', 'siciliano',
  ///     'aria_goldberg') → crossfade the background player.
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
    if (_ambienceAssets.containsKey(trigger)) {
      await _crossfadeTo(trigger);
    }
  }

  void _updateAmbienceFromProfile(PsychoProfile profile) {
    String newKey = 'calm';
    if (profile.anxiety > 70) {
      newKey = 'anxious';
    } else if (profile.oblivionLevel > 60) {
      newKey = 'oblivion';
    }
    // Profile-driven ambience only changes if no special track is active
    // (siciliano / aria_goldberg take priority and are set by the engine)
    if (_currentAmbienceKey == 'siciliano' ||
        _currentAmbienceKey == 'aria_goldberg') {
      return;
    }
    _crossfadeTo(newKey);
  }

  Future<void> _crossfadeTo(String key) async {
    if (_currentAmbienceKey == key) return;
    _currentAmbienceKey = key;
    try {
      await _rampVolume(0.0);
      await _backgroundPlayer.setAsset(_ambienceAssets[key]!);
      await _backgroundPlayer.play();
      await _rampVolume(0.85);
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
      await _backgroundPlayer.setAsset(_ambienceAssets['oblivion']!);
      await _backgroundPlayer.setLoopMode(LoopMode.one);
      await _backgroundPlayer.play();
      await _rampVolume(0.3); // deliberately low — it is aftermath
    } catch (e) {
      // ignore: avoid_print
      print('Audio silence-ending fallback: $e');
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
    final sfxPlayer = AudioPlayer();
    try {
      await sfxPlayer.setAsset(sfxAsset);
      await sfxPlayer.play();
      sfxPlayer.processingStateStream
          .firstWhere((s) => s == ProcessingState.completed)
          .then((_) => sfxPlayer.dispose());
    } catch (e) {
      sfxPlayer.dispose();
      // ignore: avoid_print
      print('SFX fallback [$sfxAsset]: $e');
    }
  }

  void dispose() {
    _psychoSubscription?.close();
    _backgroundPlayer.dispose();
  }
}

// Provider globale
final audioServiceProvider = Provider<AudioService>((ref) => AudioService());
