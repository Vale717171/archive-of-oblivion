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

  // Asset audio da mettere in assets/audio/
  final Map<String, String> _ambienceAssets = {
    'calm': 'assets/audio/void_ambient.ogg',
    'anxious': 'assets/audio/anxiety_pulse.ogg',
    'oblivion': 'assets/audio/echo_chamber.ogg',
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
        if (profile != null) _updateAmbience(profile);
      },
    );
  }

  void _updateAmbience(PsychoProfile profile) async {
    String newAmbienceKey = 'calm';
    if (profile.anxiety > 70) {
      newAmbienceKey = 'anxious';
    } else if (profile.oblivionLevel > 60) {
      newAmbienceKey = 'oblivion';
    }

    if (_currentAmbienceKey == newAmbienceKey) return; // già corretto
    _currentAmbienceKey = newAmbienceKey;

    try {
      // Crossfade manuale: just_audio non supporta duration su setVolume
      await _rampVolume(0.0);
      await _backgroundPlayer.setAsset(_ambienceAssets[newAmbienceKey]!);
      await _backgroundPlayer.play();
      await _rampVolume(0.85);
    } catch (e) {
      // Fallback silenzioso — non crasha mai su 3 GB RAM
      // ignore: avoid_print
      print('Audio fallback: $e');
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
    await sfxPlayer.setAsset(sfxAsset);
    await sfxPlayer.play();
    sfxPlayer.processingStateStream
        .firstWhere((s) => s == ProcessingState.completed)
        .then((_) => sfxPlayer.dispose());
  }

  void dispose() {
    _psychoSubscription?.close();
    _backgroundPlayer.dispose();
  }
}

// Provider globale
final audioServiceProvider = Provider<AudioService>((ref) => AudioService());
